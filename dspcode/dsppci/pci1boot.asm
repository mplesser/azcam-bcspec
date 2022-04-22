	COMMENT *

This file is used to generate DSP code for the PCI interface 
	board using a DSP56301 as its main processor.

This version has been modified to work with Gen I timing boards - 24-bits 
	for all words (commands, replies and image data), taking the
	Rev. 1.6 Gen II code as the starting point. 

This is now Rev. 1.7 PCI code.

Special notes for Gen I operation -

	The MODE bit for Gen II systems that switches between 32-bit command
		and reply format (MODE = 1) and 16-bit image data (MODE = 0)
		must be left in 32-bit mode always because Gen I data is
		always 24-bit per word. Software in this file correctly
		extracts the appropriate bytes from the 24-bit word.

	*
	PAGE    132     ; Printronix page width - 132 columns

; Equates to define the X: memory tables
VAR_TBL		EQU	0	; Variables and constants table
ARG_TBL		EQU	$30	; Command arguments and addresses

; Various addressing control registers
BCR	EQU	$FFFFFB		; Bus Control Register
DCR	EQU	$FFFFFA		; DRAM Control Register
AAR0	EQU	$FFFFF9		; Address Attribute Register, channel 0	
AAR1	EQU	$FFFFF8		; Address Attribute Register, channel 1	
AAR2	EQU	$FFFFF7		; Address Attribute Register, channel 2	
AAR3	EQU	$FFFFF6		; Address Attribute Register, channel 3	
PCTL	EQU	$FFFFFD		; PLL control register
IPRP	EQU	$FFFFFE		; Interrupt Priority register - Peripheral
IPRC	EQU	$FFFFFF		; Interrupt Priority register - Core

; PCI control register
DTXS	EQU	$FFFFCD		; DSP Slave transmit data FIFO
DTXM	EQU	$FFFFCC		; DSP Master transmit data FIFO
DRXR	EQU	$FFFFCB		; DSP Receive data FIFO
DPSR	EQU	$FFFFCA		; DSP PCI Status Register 
DSR	EQU	$FFFFC9		; DSP Status Register
DPAR	EQU	$FFFFC8		; DSP PCI Address Register
DPMC	EQU	$FFFFC7		; DSP PCI Master Control Register 
DPCR	EQU	$FFFFC6		; DSP PCI Control Register
DCTR	EQU	$FFFFC5		; DSP Control Register

; Port E is the Synchronous Communications Interface (SCI) port
PCRE	EQU	$FFFF9F		; Port Control Register
PRRE	EQU	$FFFF9E		; Port Direction Register
PDRE	EQU	$FFFF9D		; Port Data Register

; Various PCI register bit equates
STRQ	EQU	1		; Slave transmit data request (DSR)
SRRQ	EQU	2		; Slave receive data request (DSR) 
HACT	EQU	23		; Host active, low true (DSR)
MTRQ	EQU	1		; Set whem master transmitter is not full (DPSR)
MARQ	EQU	4		; Master address request (DPSR)
TRTY	EQU	10		; PCI Target Retry (DPSR)
HCIE	EQU	0		; Host command interrupt enable (DCTR)

; DPCR bit definitions
CLRT	EQU	14		; Clear the master transmitter DTXM
MACE	EQU	18		; Master access counter enable
IAE	EQU	21		; Insert Address Enable

; Addresses of ESSI port
TX00	EQU	$FFFFBC		; Transmit Data Register 0
SSISR0	EQU	$FFFFB7		; Status Register
CRB0	EQU	$FFFFB6		; Control Register B
CRA0	EQU	$FFFFB5		; Control Register A

; SSI Control Register A Bit Flags
TDE	EQU	6		; Set when transmitter data register is empty

; Miscellaneous addresses
RDFIFO	EQU	$FFFFFF		; Read the FIFO for incoming fiber optic data
TCSR0	EQU	$FFFF8F		; Triple timer control and status register 0
TCSR1	EQU	$FFFF8B		; Triple timer control and status register 1
TCSR2	EQU	$FFFF87		; Triple timer control and status register 2

; Phase Locked Loop initialization
PLL_INIT EQU	$750012		; PLL = 33 MHz x 19 / 8 = 78.4 MHz

; Port C is Enhanced Synchronous Serial Port 0
PCRC	EQU	$FFFFBF		; Port C Control Register
PRRC	EQU	$FFFFBE		; Port C Data direction Register
PDRC	EQU	$FFFFBD		; Port C GPIO Data Register

; Port D is Enhanced Synchronous Serial Port 1
PCRD	EQU	$FFFFAF		; Port D Control Register
PRRD	EQU	$FFFFAE		; Port D Data direction Register
PDRD	EQU	$FFFFAD		; Port D GPIO Data Register

; Bit number definitions of GPIO pins on Port D
EF	EQU	0		; FIFO Empty flag, low true
HF	EQU	1		; FIFO Half Full flag, low true

; STATUS bit definition
ODD	EQU	0		; Set if odd number of pixels are in the image
DWNLD	EQU	1		; Set if downloading, so skip over special

; Special address for two words for the DSP to bootstrap code from the EEPROM
	IF	@SCP("DOWNLOAD","ROM")		; Boot from ROM on power-on
	ORG	P:0,P:0
	DC	END_ADR-INIT-2			; Number of boot words
	DC	INIT				; Starting address
	ORG	P:0,P:2
INIT	JMP	<INIT_PCI			; Configure PCI port
	NOP
	ENDIF

	IF	@SCP("DOWNLOAD","HOST")		; Download via host computer
	ORG	P:0,P:0
	DC	END_ADR-INIT			; Number of boot words
	DC	INIT				; Starting address
	ORG	P:0,P:0
INIT	JMP	<START
	NOP
	ENDIF

	IF	@SCP("DOWNLOAD","ONCE")		; Download via ONCE debugger
	ORG	P:0,P:0
INIT	JMP	<START
	NOP
	ENDIF

; Vectored interrupt table, addresses at the beginning are reserved
	DC	0,0,0,0,0,0,0,0,0,0,0,0,0,0	; $02-$0f Reserved
	DC	0,0				; $11 - IRQA* = FIFO EF*
	DC	0,0				; $13 - IRQB* = FIFO HF*
	JSR	CLEAN_UP_PCI			; $15 - Software reset switch
	DC	0,0,0,0,0,0,0,0,0,0,0,0		; Reserved for DMA and Timer
 	DC	0,0,0,0,0,0,0,0,0,0,0,0		;   interrupts
	JSR	DOWNLOAD_PCI_DSP_CODE		; $2F

; Now we're at P:$30, where some unused vector addresses are located

; This is ROM only code that is only executed once on power-up when the 
;   ROM code is downloaded. It is skipped over on OnCE or PCI downloads.
; Initialize the PLL - phase locked loop
INIT_PCI
	MOVEP	#PLL_INIT,X:PCTL	; Initialize PLL 
	NOP

; Program the PCI self-configuration registers
	MOVE 	#0,X0
	MOVEP	#$500000,X:DCTR		; Set self-configuration mode
	REP	#4
	MOVEP	X0,X:DPAR		; Dummy writes to configuration space
	MOVEP	#>$0000,X:DPMC		; Subsystem ID
	MOVEP	#>$0000,X:DPAR		; Subsystem Vendor ID

; PCI Personal reset
	MOVEP	X0,X:DCTR		; Personal software reset
	NOP
	NOP
	JSET	#HACT,X:DSR,*		; Test for personal reset completion
	MOVE	P:(*+3),X0		; Trick to write "JMP <START" to P:0
	MOVE	X0,P:(0)
	JMP	<START

DOWNLOAD_PCI_DSP_CODE
	BCLR	#IAE,X:DPCR		; Do not insert PCI address with data
DNL0	JCLR	#SRRQ,X:DSR,*		; Wait for a receiver word
	MOVEP	X:DRXR,A		; Read it
	CMP	#$555AAA,A		; Check for sanity header word
	JNE	<DNL0
	MOVE	OMR,A
	AND	#$FFFFF0,A
	OR	#$00000C,A
	NOP
	MOVE	A,OMR			; Set boot mode to $C = PCI
	JMP	$FF0000			; Jump to boot code internal to DSP

	DC	0,0,0,0,0,0,0,0,0,0,0,0	; Filler
	DC	0,0			; $60 - PCI Transaction Termination
	DC	0,0,0,0,0,0,0,0,0	; $62-$71 Reserved PCI
	DC	0,0,0,0,0,0,0,0,0 

; These interrupts are non-maskable, called from the host with $80xx
	JSR	READ_NUMBER_OF_PIXELS_READ	; $8075
	JSR	CLEAN_UP_PCI			; $8077	
	JSR	ABORT_READOUT			; $8079
	JSR	BOOT_EEPROM			; $807B
	DC	0,0,0,0				; Available

; These vector interrupts are masked at IPL = 1
	JSR	READ_REPLY_HEADER		; $81
	JSR	READ_REPLY_VALUE		; $83
	JSR	CLEAR_HOST_FLAG			; $85
	JSR	RESET_CONTROLLER		; $87
	JSR	READ_IMAGE			; $89
	DC	0,0				; Available
	JSR	WRITE_BASE_PCI_ADDRESS		; $8D

	DC	0,0,0,0				; Available
	DC	0,0,0,0,0,0,0,0,0,0,0,0,0,0
	DC	0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0		

; New manual command for Version 1.6
	JSR	WRITE_COMMAND			; $B1

START	MOVEP	#>$00001,X:DPMC		; 32-bit PCI <-> 24-bit DSP data
	BSET	#20,X:DCTR		; HI32 mode = 1 => PCI
	BCLR	#21,X:DCTR
	BCLR	#22,X:DCTR
	NOP
	JSET	#12,X:DPSR,*		; Host data transfer not in progress
	NOP
	BSET	#MACE,X:DPCR		; Master access counter enable
	NOP				; End of PCI programming

; Set operation mode register OMR to normal expanded
	MOVEC   #$0000,OMR	; Operating Mode Register = Normal Expanded
	MOVEC	#0,SP		; Reset the Stack Pointer SP

; Move the table of constants from P: space to X: space
	MOVE	#CONSTANTS_TBL_START,R1 	; Start of table of constants 
	MOVE	#2,R0				; Leave X:0 for STATUS
	DO	#CONSTANTS_TBL_LENGTH,L_WRITE
	MOVE	P:(R1)+,X0
	MOVE	X0,X:(R0)+			; Write the constants to X:
L_WRITE

; Program the serial port ESSI0 = Port C for serial transmission to 
;   the timing board
	MOVEP	#>0,X:PCRC	; Software reset of ESSI0
	MOVEP	#$000809,X:CRA0	; Divide 78.4 MHz by 20 to get 3.92 MHz
				; DC0-CD4 = 0 for non-network operation
				; WL0-WL2 = ALC = 0 for 2-bit data words
				; SSC1 = 0 for SC1 not used
	MOVEP	#$010120,X:CRB0	; SCKD = 1 for internally generated clock
				; SHFD = 0 for MSB shifted first
				; CKP = 0 for rising clock edge transitions
				; TE0 = 1 to enable transmitter #0
				; MOD = 0 for normal, non-networked mode
				; FSL1 = 1, FSL0 = 0 for on-demand transmit
	MOVEP	#%101000,X:PCRC	; Control Register (0 for GPIO, 1 for ESSI)
				; Set SCK0 = P3, STD0 = P5 to ESSI0
	MOVEP	#%010111,X:PRRC	; Data Direction Register (0 for In, 1 for Out)
	MOVEP	#%000101,X:PDRC	; Data Register - ROM/FIFO* = 0, SC02 = 0,
				;   AUX1 = 0, AUX2 = AUX3 = 1

; Conversion from software bits to schematic labels for Port C and D
;	PC0 = SC00 = AUX3		PD0 = SC10 = EF*
;	PC1 = SC01 = ROM/FIFO*		PD1 = SC11 = HF*
;	PC2 = SC02 = AUX2		PD2 = SC12 = RS*
;	PC3 = SCK0 = Serial clock	PD3 = SCK1 = FSYNC*
;	PC4 = SRD0 = AUX1		PD4 = SRD1 = MODE
;	PC5 = STD0 = Serial data	PD5 = STD1 = WRFIFO*

; Program the serial port ESSI1 = Port D for general purpose I/O (GPIO)
	MOVEP	#%000000,X:PCRD	; Control Register (0 for GPIO, 1 for ESSI)
	MOVEP	#%010100,X:PRRD	; Data Direction Register (0 for In, 1 for Out)
	MOVEP	#%010000,X:PDRD	; Data Register - Pulse RS* low, MODE = 1
	REP	#10
	NOP
	MOVEP	#%010100,X:PDRD

; Program the SCI port to benign values
	MOVEP	#%000,X:PCRE	; Port Control Register = GPIO
	MOVEP	#%110,X:PRRE	; Port Direction Register (0 = Input)
	MOVEP	#%110,X:PDRE	; Port Data Register
;	PE0 = RXD
;	PE1 = TXD
;	PE2 = SCLK

; Program the triple timer to assert TCI0 as a GPIO output = 1
	MOVEP	#$2800,X:TCSR0
	MOVEP	#$2800,X:TCSR1
	MOVEP	#$2800,X:TCSR2

; Program the AA1 pin to read the FIFO memory for incoming timing board data
	MOVEP	#$FFFC21,X:AAR1	; Y = $FFF000 to $FFFFFF asserts AA1 low true

; Program the DRAM memory access and addressing
	MOVEP	#$000020,X:BCR	; Bus Control Register
	MOVEP	#$893A05,X:DCR	; DRAM Control Register
	MOVEP	#$000122,X:AAR2	; Y: $000000 to $7FFFFF asserts AA2
	MOVEP	#$800122,X:AAR0	; Y: $800000 to $FFFFFF asserts AA0
	MOVEP	#$000112,X:AAR3	; X: $000000 to $7FFFFF asserts AA3

; Clear all PCI error conditions
	MOVEP	X:DPSR,A
	OR	#$1FE,A
	NOP
	MOVEP	A,X:DPSR

; Establish interrupt priority levels IPL
	MOVEP	#$0001C0,X:IPRC	; IRQC priority IPL = 2 (reset switch, edge)
				; IRQB priority IPL = 2 or 0 
				;     (FIFO half full - HF*, level)
	MOVEP	#>2,X:IPRP	; Enable PCI Host interrupts, IPL = 1
	BSET	#HCIE,X:DCTR	; Enable host command interrupts
	MOVE	#0,SR		; Don't mask any interrupts

; Initialize the fiber optic serial transmitter to zero
	JCLR	#TDE,X:SSISR0,*
	MOVEP	#$000000,X:TX00

; Clear out the PCI receiver and transmitter FIFOs
	BSET	#CLRT,X:DPCR		; Clear the master transmitter
	JSET	#CLRT,X:DPCR,*		; Wait for the clearing to be complete	
CLR0	JCLR	#SRRQ,X:DSR,CLR1	; Wait for the receiver to be empty
	MOVEP	X:DRXR,X0		; Read receiver to empty it
	NOP
	JMP	<CLR0
CLR1

; Repy = DONE host flags
	MOVE	X:<FLAG_DONE,X0		; Flag = 1 => Normal execution
	MOVE	X0,X:<HOST_FLAG	
	JSR	<FO_WRITE_HOST_FLAG

; ********************************************************************
;
;			REGISTER  USAGE
;
;	X0, X1, Y0, Y1, A and B are used freely in READ_IMAGE. Interrups
;		during readout will clobber these registers, as a result
;		of which only catastrophic commands such as ABORT_READOUT
;		and BOOT_EEPROM are allowed during readout.
;
;	X0, X1 and A are used for all interrupt handling routines, such
;		as CLEAR_HOST-FLAGS, command processing and so on. 
;
;	Y0, Y1 and B are used for all fiber optic processing routines,
;		which are not in interrupt service routines. 
;
; *********************************************************************


; ************  Start of command interpreting code  ******************

; Test for fiber optic data on the FIFO. Discard the header for now

; Check for the header $AC in the first byte = Y0. Wait a little while and
;  clear the FIFO if its not $AC - there was probably noise on the line.
; We assume only two word replies here - Header = (S,D,#words)  Reply

GET_FO	JCLR	#EF,X:PDRD,GET_FO	; Test for new fiber optic data
	JSR	<RD_FO_TIMEOUT		; Move the FIFO reply into A1
	JCS	<FO_ERR

; Check the header bytes for self-consistency
	MOVE	B1,Y0
	MOVE	#$FCFCF8,B		; Test for S.LE.3 and D.LE.3 and N.LE.7
	AND     Y0,B		
	JNE     <FO_ERR			; Test failed
	MOVE	#$030300,B		; Test for either S.NE.0 or D.NE.0
	AND     Y0,B
       	JEQ     <FO_ERR			; Test failed
	MOVE	#>7,B
	AND	Y0,B			; Extract NWORDS, must be >= 2
	CMP	#1,B
	JLE	<FO_ERR
	MOVE	Y0,B
	EXTRACTU #$008020,B,B		; Extract bits 15-8 = destination byte
	NOP
	MOVE	B0,X:<FO_DEST

; Read the reply or command from the fiber optics FIFO
	JSR	<RD_FO_TIMEOUT		; Move the FIFO reply into A1
	JCS	<FO_ERR
	JSET	#DWNLD,X:<STATUS,RPLY	; If downloading to the controller
	MOVE	B1,X:<FO_CMD

; Check for commands from the controller to the PCI board, FO_DEST = 1
	MOVE	X:<FO_DEST,B
	CMP	#1,B
	JNE	<HOSTCMD
	MOVE	X:<FO_CMD,B
	CMP	#'RDA',B		; Read the image
	JEQ	<READ_IMAGE
	CMP	#'IIA',B
	JEQ	<INITIALIZE_NUMBER_OF_PIXELS ; IPXLS = 0
	CMP	#'RDI',B
	JEQ	<READING_IMAGE		; Controller is reading an image
	CMP	#'RDO',B
	JEQ	<READING_IMAGE_OFF	; Controller no longer reading an image
	JMP	<GET_FO			; Not on the list -> just ignore it

; Check if the command or reply is for the host. If not just ignore it. 
HOSTCMD	MOVE	X:<FO_DEST,B
	CMP	#0,B
	JNE	<GET_FO
	MOVE	X:<FO_CMD,B
	CMP	#'DON',B
	JEQ	<CONTROLLER_DONE	; Normal DONE reply
	CMP	#'ERR',B
	JEQ	<CONTROLLER_ERROR	; Error reply
	CMP	#'BSY',B
	JEQ	<CONTROLLER_BUSY	; Controller is busy executing a command
	CMP	#'SYR',B
	JEQ	<CONTROLLER_RESET	; Controller system reset

; The controller reply is none of the above so return it as a reply
RPLY	MOVE	B1,X:<REPLY		; Report value
	MOVE	X:<FLAG_REPLY,Y0	; Flag = 2 => Reply with a value
	MOVE	Y0,X:<HOST_FLAG	
	JSR	<FO_WRITE_HOST_FLAG
	JMP	<GET_FO

CONTROLLER_DONE
	MOVE	X:<FLAG_DONE,Y0		; Flag = 1 => Normal execution
	MOVE	Y0,X:<HOST_FLAG	
	JSR	<FO_WRITE_HOST_FLAG
	JMP	<GET_FO			; Keep looping for fiber optic commands

CONTROLLER_ERROR
	MOVE	X:<FLAG_ERR,Y0		; Flag = 3 => controller error
	MOVE	Y0,X:<HOST_FLAG	
	JSR	<FO_WRITE_HOST_FLAG
	JMP	<GET_FO			; Keep looping for fiber optic commands

CONTROLLER_RESET
	MOVE	X:<FLAG_SYR,Y0		; Flag = 4 => controller reset
	MOVE	Y0,X:<HOST_FLAG	
	JSR	<FO_WRITE_HOST_FLAG
	JMP	<GET_FO			; Keep looping for fiber optic commands

CONTROLLER_BUSY
	MOVE	X:<FLAG_BUSY,Y0	; Flag = 6 => controller busy
	MOVE	Y0,X:<HOST_FLAG	
	JSR	<FO_WRITE_HOST_FLAG
	JMP	<GET_FO			; Keep looping for fiber optic commands

; A special handshaking here ensures that the host computer has read the 'DON'
;   reply to the start_exposure command before the reading_image state is
;   set in the host flags. Reading_image occurs only after a start_exposure
READING_IMAGE
	MOVE	X:<HOST_FLAG,B		; Retrieve current host flag value
	MOVE	X:<FLAG_RDI,X0
	CMP	X0,B			; If we're already in read_image 
	JEQ	<GET_FO			;   mode then do nothing
	TST	B			; Wait for flag to be cleared, which
	JNE	<READING_IMAGE		;  the host does when it gets the DONE

	BCLR	#HCIE,X:DCTR		; Disable host command interrupts
	MOVE	X:<FLAG_RDI,Y0
	MOVE	Y0,X:<HOST_FLAG
	JSR	<FO_WRITE_HOST_FLAG	; Set Host Flag to "reading out"
	JMP	<GET_FO			; Keep looping for fiber optic commands

READING_IMAGE_OFF			; Controller is no longer reading out
	MOVE	X:<FLAG_ZERO,Y0
	MOVE	Y0,X:<HOST_FLAG
	JSR	<FO_WRITE_HOST_FLAG
	BSET	#HCIE,X:DCTR		; Enable host command interrupts
	JMP	<GET_FO			; Keep looping for fiber optic commands

; Write X:<HOST_FLAG to the DCTR flag bits 5,4,3, as a subroutine
FO_WRITE_HOST_FLAG
	MOVE	X:DCTR,B
	MOVE	X:<HOST_FLAG,Y0	
	AND	#$FFFFC7,B		; Clear bits 5,4,3
	NOP
	OR	Y0,B			; Set flags appropriately
	NOP
	MOVE	B,X:DCTR
	RTS

; There was an erroneous word on the fiber optic line -> clear the FIFO 
FO_ERR	MOVEP	#%010000,X:PDRD		; Clear FIFO RESET* for 2 milliseconds
	MOVE	#200000,Y0
	DO	Y0,*+3
	NOP
	MOVEP	#%010100,X:PDRD		; Data Register - Set RS* high
	JMP	<GET_FO

; **************  Boot from byte-wide on-board EEPROM  *******************

BOOT_EEPROM
	MOVEP	#$0002A0,X:BCR		; Bus Control Register for slow EEPROM
	BSET	#1,X:PDRC		; ROM/FIFO* = 1 to select ROM
	MOVE	OMR,A
	AND	#$FFFFF0,A
	OR	#$000009,A		; Boot mode = $9 = byte-wide EEPROM
	NOP
	MOVE	A,OMR	
	JMP	$FF0000			; Jump to boot code internal to DSP

; ***************  Command processing  ****************

WRITE_COMMAND
	JCLR	#SRRQ,X:DSR,ERROR	; Error if receiver FIFO has no data
	MOVEP	X:DRXR,A		; Get the header
	NOP				; Pipeline restriction
	MOVE	A1,X:<HEADER

; Check the header bytes for self-consistency
	MOVE	A1,X0
	MOVE	#$FCFCF8,A		; Test for S.LE.3 and D.LE.3 and N.LE.7
	AND     X0,A		
	JNE     <ERROR			; Test failed
	MOVE	#$030300,A		; Test for either S.NE.0 or D.NE.0
	AND     X0,A
       	JEQ     <ERROR			; Test failed
	MOVE	#>7,A
	AND	X0,A			; Extract NUM_ARG, must be >= 0
	NOP				; Pipeline restriction
	SUB	#2,A
	JLT	<ERROR			; Number of arguments >= 0
	MOVE	A1,X:<NUM_ARG		; Store number of arguments in command
	CMP	#6,A			; Number of arguemnts <= 6
	JGT	<ERROR

; Get the DESTINATION number (1 = PCI, 2 = timing, 3 = utility)
	MOVE	X0,A			; Still the header
	LSR	#8,A
	AND	#>3,A			; Extract just three bits of 
	MOVE	A1,X:<DESTINATION	;   the destination byte
	JEQ	<ERROR			; Destination of zero = host not allowed
	CMP	#1,A			; Destination byte for PCI board
	JEQ	<PCI

; Write the controller command and its arguments to the fiber optics
	MOVE	X:<HEADER,A
	JSR	XMT_WRD			; Write the word to the fiber optics
	JCLR	#SRRQ,X:DSR,ERROR	; Error if receiver FIFO has no data
	MOVEP	X:DRXR,A		; Write the command
	JSR	<XMT_WRD		; Write the command to the fiber optics
	DO	X:<NUM_ARG,L_ARGS1	; Do loop won't execute if NUM_ARG = 0 
	MOVEP	X:DRXR,A		; Get the arguments
	JSR	<XMT_WRD		; Write the argument to the fiber optics
	NOP				; DO loop restriction
L_ARGS1	RTI				; The controller will generate the reply

; Since it's a PCI command store the command and its arguments in X: memory
PCI	JCLR	#SRRQ,X:DSR,ERROR	; Error if receiver FIFO has no data
	MOVEP	X:DRXR,X:COMMAND	; Get the command
	MOVE	X:<NUM_ARG,A		; Get number of arguments in command
	MOVE	#ARG1,R0		; Starting address of argument list
	DO	A,L_ARGS2		; DO loop won't execute if A = 0
	JCLR	#SRRQ,X:DSR,ERROR	; Error if receiver FIFO has no data
	MOVEP	X:DRXR,X:(R0)+		; Get arguments
L_ARGS2

; Process a PCI board non-vector command
PCI_COMMAND
	MOVE	X:<COMMAND,A		; Get the command
	CMP	#'TRM',A		; Is it the test DRAM command?
	JEQ	<TEST_DRAM
	CMP	#'TDL',A		; Is it the test data link command?
	JEQ	<TEST_DATA_LINK
	CMP	#'RDM',A
	JEQ	<READ_MEMORY		; Is it the read memory command?
	CMP	#'WRM',A
	JEQ	<WRITE_MEMORY		; Is it the write memory command?
	JMP	<ERROR			; Its not a recognized command

; ********************  Vector commands  *******************

READ_NUMBER_OF_PIXELS_READ		; Write the reply to the DTXS FIFO
	MOVEP	X:R_PXLS_0,X:DTXS	; DSP-to-host slave transmit
	NOP
	MOVEP	X:R_PXLS_1,X:DTXS	; DSP-to-host slave transmit
	RTI

; Reset controller is not implemented in Gen I controllers, so this just 
;  returns a "SYR" reply indicating 'successful' command completion
RESET_CONTROLLER
	JMP	<SYR			; Reply to host, return from interrupt

; ****************  Exposure and readout commands  ****************

WRITE_BASE_PCI_ADDRESS
	JCLR	#SRRQ,X:DSR,ERROR	; Error if receiver FIFO has no data
	MOVEP	X:DRXR,A0
	JCLR	#SRRQ,X:DSR,ERROR	; Error if receiver FIFO has no data
	MOVEP	X:DRXR,X0		; Get most significant word
	INSERT	#$010010,X0,A
	NOP
	MOVE	A0,X:<BASE_ADDR_0	; BASE_ADDR is 8 + 24 bits
	MOVE	A1,X:<BASE_ADDR_1
	JMP 	<FINISH			; Write 'DON' reply

; Write the base PCI image address to the PCI address
INITIALIZE_NUMBER_OF_PIXELS
	CLR	A
	NOP
	MOVE	A1,X:<R_PXLS_1		; Up counter of number of pixels read
	MOVE	A0,X:<R_PXLS_0

	MOVE	X:<BASE_ADDR_0,A0	; BASE_ADDR is 2 x 16-bits
	MOVE	X:<BASE_ADDR_1,A1
	NOP
	MOVE	A0,X:<PCI_ADDR_0	; PCI_ADDR is 8 + 24 bits
	MOVE	A1,X:<PCI_ADDR_1

	JMP 	<CONTROLLER_DONE	; Repy = DONE host flags

; Send an abort readout command to the controller to stop image transmission
ABORT_READOUT
	MOVE	X:<FLAG_DONE,X0
	MOVE	X0,X:<HOST_FLAG	
	JSR	<FO_WRITE_HOST_FLAG

	MOVE	X:<C000202,A
	JSR	<XMT_WRD		; Timing board header word
	MOVE	#'ABR',A
	JSR	<XMT_WRD		; Abort Readout

; Ensure that image data is no longer being received from the controller
ABR0	JCLR	#EF,X:PDRD,ABR2		; Test for incoming FIFO data
ABR1	MOVEP	Y:RDFIFO,X0		; Read the FIFO until its empty
	NOP
	JSET	#EF,X:PDRD,ABR1
ABR2	DO	#2400,ABR3		; Wait for about 30 microsec in case
	NOP				;   FIFO data is still arriving
ABR3	JSET	#EF,X:PDRD,ABR1		; Keep emptying if more data arrived

; Clean up the PCI board from wherever it was executing
CLEAN_UP_PCI
	MOVEP	#$0001C0,X:IPRC		; Disable HF* FIFO interrupt
	BSET	#HCIE,X:DCTR		; Enable host command interrupts
	MOVEC	#1,SP			; Point stack pointer to the top	
	MOVEC	#$000200,SSL		; SR = zero except for interrupts
	MOVEC	#0,SP			; Writing to SSH preincrements the SP
	MOVEC	#START,SSH		; Set PC to for full initialization
	NOP
	RTI

; *************************************************************************
;  There are several address register assignements in the Scatter/Gather 
;    routine that should not be disturbed
;
;	R1 - DRAM address of pixel being scaterred
;	R5 - DRAM address of pixel being gathered
;	R0, R3, R6 and R7 are not used in the Scatter/Gather routine
;
; *************************************************************************

; Read the image - change the serial receiver to expect 16-bit (image) data
READ_IMAGE
	BCLR	#HCIE,X:DCTR		; Disable host command interrupts
	MOVE	X:<FLAG_RDI,X0
	MOVE	X0,X:<HOST_FLAG
	JSR	<FO_WRITE_HOST_FLAG	; Set HCTR bits to "reading out"
	MOVEP	X:DPSR,A		; Clear all PCI error conditions
	OR	#$1FE,A
	NOP
	MOVEP	A,X:DPSR
	BSET	#CLRT,X:DPCR		; Clear the master transmitter FIFO
	JSET	#CLRT,X:DPCR,*		; Wait for the clearing to be complete

; Compute the number of pixels to read from the controller
	JSR	<RD_FO_TIMEOUT		; Read number of columns 
	JCS	<FO_ERR
	MOVE	B1,X1
	JSR	<RD_FO_TIMEOUT		; Read number of rows
	JCS	<FO_ERR
	MOVE	B1,Y1			; Number of rows to read is in Y1
	MPY	X1,Y1,A
	ASR	A			; Correct for 0 in LS bit after MPY
	CLR	B
	MOVE	A1,X:<NPXLS_1		; NPXLS set by controller
	MOVE	A0,X:<NPXLS_0
	MOVE	B1,X:<IPXLS_1		; IPXLS = 0 
	MOVE	B0,X:<IPXLS_0

; Get the current PCI address into the accumulator B
	MOVE	X:<PCI_ADDR_0,B0	; B will contain the current PCI address
	MOVE	X:<PCI_ADDR_1,B1

; There are three separate stages of writing the image to the PCI bus
;	a. Write complete 512 pixel FIFO half full blocks
;	b. Write the pixels left over from the last complete FIFO block
;	c. Write one pixel if the image has an odd number of pixels


; Compute the number of pixel pairs from the FIFO --> PCI bus
L_FIFO	MOVE	X:<C256,X0		; 1/2 the FIFO depth
	MOVE	#0,X1
	CLR	A
	MOVE	X:<NPXLS_1,A1		; Number of pixels to write to PCI
	MOVE	X:<NPXLS_0,A0
	MOVE	X:<IPXLS_1,Y1		; Compare it to image size
	MOVE	X:<IPXLS_0,Y0
	NOP
	SUB	Y,A			; If (Image size - Ipxls)  <= 512 
	NOP				;   we're at the end of the image
	SUB	X,A
	JLE	<WRITE_LAST_LITTLE_BIT_OF_IMAGE

; (a) Write complete 256 pixel (1/2 FIFO) image blocks to the PCI bus
	MOVE	X:<FOUR,Y0		; Number of bytes per PCI write
	MOVE	#0,Y1
WR_IMAGE
	JSET	#HF,X:PDRD,*		; Wait for FIFO to be half full + 1
	NOP
	NOP
	JSET	#HF,X:PDRD,WR_IMAGE	; Protection against metastability
	DO	#128,WR_BLK1
	EXTRACTU #$010010,B,A		; Get D31-16 bits only. FC = 0 (32-bit)
	NOP
	MOVEP	A0,X:DPMC		; DSP master control register
	NOP				; FC = 0 -> 32-bit PCI writes
	EXTRACTU #$010000,B,A
	NOP
	MOVE	A0,A1
	OR	#$070000,A		; A1 gets written to DPAR register
	MOVE	A1,X0
	JSR	<WR_PIX
	JSR	<WR_PIX
AGAIN1	MOVEP	X0,X:DPAR		; Write to PCI bus
	NOP				; Pipeline delay
	NOP				; Pipeline delay

	JCLR	#MARQ,X:DPSR,*		; Bit is clear if PCI still in progress
	JSET	#14,X:DPSR,WR_OK1	; MDT bit
	JCLR	#TRTY,X:DPSR,END_WR	; Error if its not a retry
	MOVEP	#$0400,X:DPSR		; Clear bit 10 = target retry bit
	JMP	<AGAIN1

WR_OK1	ADD	Y,B			; Increment PCI address
	NOP
WR_BLK1

; Re-calculate and store the PCI address where image data is being written to
	MOVE	X:<C256,X0		; 1/2 the FIFO depth
	MOVE	#0,X1
	MOVE	X:<IPXLS_0,A0		; Number of pixels to write to PCI
	MOVE	X:<IPXLS_1,A1
	ADD	X,A
	NOP
	MOVE	A0,X:<IPXLS_0		; Number of pixels to write to PCI
	MOVE	A1,X:<IPXLS_1
	JSR	<C_RPXLS		; Calculate number of pixels read
	JMP	<L_FIFO			; Go process the next 1/2 FIFO

; (b) Write the pixels left over
WRITE_LAST_LITTLE_BIT_OF_IMAGE
	BCLR	#ODD,X:<STATUS
	ADD	X,A
	NOP
	ASR	A			; Two pixels written per loop
	JCC	*+2
	BSET	#ODD,X:<STATUS		; ODD = 1 if carry bit is set
	MOVE	X:<FOUR,Y0		; Number of bytes per PCI write
	MOVE	#0,Y1

	DO	A0,WR_BLK2
	EXTRACTU #$010010,B,A		; Get D31-16 bits only. FC = 0 (32-bit)
	NOP
	MOVEP	A0,X:DPMC		; DSP master control register
	NOP				; FC = 0 -> 32-bit PCI writes
	EXTRACTU #$010000,B,A
	NOP
	MOVE	A0,A1
	OR	#$070000,A		; A1 gets written to DPAR register
	MOVE	A1,X0
	JSR	<WR_PIX
	JSR	<WR_PIX
AGAIN2	MOVEP	X0,X:DPAR		; Write to PCI bus
	NOP				; Pipeline delay
	NOP				; Pipeline delay

	JCLR	#MARQ,X:DPSR,*		; Bit is clear if PCI still in progress
	JSET	#14,X:DPSR,WR_OK2	; MDT bit
	JCLR	#TRTY,X:DPSR,END_WR	; Bit is set if its a retry
	MOVEP	#$0400,X:DPSR		; Clear bit 10 = target retry bit
	JMP	<AGAIN2

WR_OK2	ADD	Y,B			; Increment PCI address
	NOP
WR_BLK2

; (c) Write the very last pixel if there is an odd number of pixels in the image
	JCLR	#ODD,X:STATUS,END_WR
	EXTRACTU #$010010,B,A		; Get D31-16 bits only. FC = 0 (32-bit)
	NOP
	BSET	#22,A0			; FC mode = 1
	NOP
	MOVEP	A0,X:DPMC		; DSP master control register
	NOP
	EXTRACTU #$010000,B,A
	NOP
	MOVE	A0,A1
	OR	#$C70000,A		; Write 16 LS bits only
	MOVE	A1,X0
	ADD	#>2,B			; Increment PCI address
	JSR	<WR_PIX
AGAIN3	MOVEP	X0,X:DPAR		; Write to PCI bus
	NOP				; Pipeline delay
	NOP				; Pipeline delay

	JCLR	#MARQ,X:DPSR,*		; Bit is clear if PCI still in progress
	JSET	#14,X:DPSR,END_WR	; MDT bit
	JCLR	#TRTY,X:DPSR,END_WR	; Bit is set if its a retry
	MOVEP	#$0400,X:DPSR		; Clear bit 10 = target retry bit
	JMP	<AGAIN3

; Calculate and store the PCI address where image data is being written to
END_WR	JSR	<C_RPXLS		; Calculate number of pixels read
	MOVE	B0,X:<PCI_ADDR_0	; Update PCI Address
	MOVE	B1,X:<PCI_ADDR_1

	MOVE	X:<FLAG_DONE,X0
	MOVE	X0,X:<HOST_FLAG
	JSR	<FO_WRITE_HOST_FLAG	; Clear Host Flag to 'DONE'
	BSET	#HCIE,X:DCTR		; Enable host command interrupts
	JMP	<GET_FO			; We're all done, go process FO input

; Core routine for writing 24-bit fiber optic pixels to 16-bit PCI bus register
WR_PIX	JCLR	#EF,X:PDRD,*
	MOVEP	Y:RDFIFO,X1		; Read D15-D08
	JCLR	#EF,X:PDRD,*
	MOVEP	Y:RDFIFO,A0		; Read D08-D00
	EXTRACTU #$008008,A,A
	INSERT	 #$008008,X1,A
	NOP
	MOVEP	A0,X:DTXM
	RTS

; R_PXLS is the number of pixels read out since the last IIA command
C_RPXLS	MOVE	X:<BASE_ADDR_0,X0	; BASE_ADDR is 2 x 16-bits
	MOVE	X:<BASE_ADDR_1,X1
	CLR	A
	MOVE	B0,A0			; B is current PCI address
	MOVE	B1,A1
	SUB	X,A			; Current PCI address - BASE address
	ASR	A			; /2 => convert byte address to pixel
	NOP

	MOVE	A0,X:<R_PXLS_0		; R_PXLS is 2 x 16 bits, number of
	EXTRACTU #$010010,A,A		;   image pixels read so far
	NOP
	MOVE	A0,X:<R_PXLS_1
	RTS

; ***** Test Data Link, Read Memory and Write Memory Commands ******

; Test the data link by echoing back ARG1
TEST_DATA_LINK
	MOVE	X:<ARG1,X0
	JMP	<FINISH1

; Read from PCI memory. The address is masked to 16 bits, so only 
;   the bottom 64k words of DRAM will be accessed.
READ_MEMORY
	MOVE    X:<ARG1,A	; Get the address in an accumulator
	AND	#$FFFF,A	; Mask off only 16 address bits
	MOVE	A1,R0		; Get the address in an address register
	MOVE    X:<ARG1,A	; Get the address in an accumulator
	NOP
	JCLR    #20,A,RDX 	; Test address bit for Program memory
	MOVE	P:(R0),X0	; Read from Program Memory
        JMP     <FINISH1	; Send out a header with the value
RDX     JCLR    #21,A,RDY 	; Test address bit for X: memory
        MOVE    X:(R0),X0	; Write to X data memory
        JMP     <FINISH1	; Send out a header with the value
RDY     JCLR    #22,A,RDR	; Test address bit for Y: memory
        MOVE    Y:(R0),X0	; Read from Y data memory
	JMP     <FINISH1	; Send out a header with the value
RDR	JCLR	#23,A,ERROR	; Test address bit for read from EEPROM memory

; Read the word from the PCI board EEPROM
	BSET	#1,X:PDRC	; ROM/FIFO* = 1 to select ROM
	MOVEP	#$008C29,X:AAR1	; P: = $008000 to $008777 asserts AA1 low true
	MOVEP	#$0002A0,X:BCR	; Bus Control Register for slow EEPROM
	MOVE	X:<THREE,X1	; Convert to word address to a byte address
	MOVE	R0,X0		; Get 16-bit address in a data register
	MPY	X1,X0,A		; Multiply	
	ASR	A		; Eliminate zero fill of fractional multiply
	MOVE	A0,R0		; Need to address memory
	BSET	#15,R0		; Set bit so its in EEPROM space
	DO      #3,L1RDR
	MOVE    P:(R0)+,A2      ; Read each ROM byte
	ASR     #8,A,A		; Move right into A1
	NOP
L1RDR
	MOVE	A1,X0		; Prepare for FINISH1
	BCLR	#1,X:PDRC	; ROM/FIFO* = 0 to select FIFO
	MOVEP	#$FFFC21,X:AAR1	; Restore FIFO addressing
	MOVEP	#$000020,X:BCR	; Restore fast FIFO access
	JMP     <FINISH1

; Program WRMEM - write to PCI memory, reply = DONE host flags. The address is
;  masked to 16 bits, so only the bottom 64k words of DRAM will be accessed.
WRITE_MEMORY
	MOVE    X:<ARG1,A	; Get the address in an accumulator
	AND	#$FFFF,A	; Mask off only 16 address bits
	MOVE	A1,R0		; Get the address in an address register
	MOVE    X:<ARG1,A	; Get the address in an accumulator
	MOVE    X:<ARG2,X0	; Get the data to be written
        JCLR    #20,A,WRX	; Test address bit for Program memory
        MOVE	X0,P:(R0)	; Write to Program memory
        JMP     <FINISH
WRX     JCLR    #21,A,WRY	; Test address bit for X: memory
        MOVE    X0,X:(R0)	; Write to X: memory
        JMP     <FINISH
WRY     JCLR    #22,A,WRR	; Test address bit for Y: memory
        MOVE    X0,Y:(R0)	; Write to Y: memory
	JMP	<FINISH
WRR	JCLR	#23,A,ERROR	; Test address bit for write to EEPROM

; Write the word to the on-board PCI EEPROM
	BSET	#1,X:PDRC	; ROM/FIFO* = 1 to select ROM
	MOVEP	#$008C29,X:AAR1	; P: = $008000 to $008777 asserts AA1 low true
	MOVEP	#$0002A0,X:BCR	; Bus Control Register for slow EEPROM
	MOVE	X:<THREE,X1	; Convert to word address to a byte address
	MOVE	R0,X0		; Get 16-bit address in a data register
	MPY	X1,X0,A		; Multiply	
	ASR	A		; Eliminate zero fill of fractional multiply
	MOVE	A0,R0		; Need to address memory
	BSET	#15,R0		; Set bit so its in EEPROM space
	MOVE    X:<ARG2,A	; Get the data to be written, again 
	DO      #3,L1WRR	; Loop over three bytes of the word
	MOVE    A1,P:(R0)+      ; Write each EEPROM byte
	ASR     #8,A,A 		; Move right one byte
	MOVE	#400000,X0
	DO      X0,L2WRR	; Delay by 5 millisec for EEPROM write
	NOP
L2WRR
	NOP                     ; DO loop nesting restriction
L1WRR
	BCLR	#1,X:PDRC	; ROM/FIFO* = 0 to select FIFO
	MOVEP	#$FFFC21,X:AAR1	; Restore FIFO addressing
	MOVEP	#$000020,X:BCR	; Restore fast FIFO access
	JMP     <FINISH

;  ***** Subroutines for generating replies to command execution ******
; Return from the interrupt with a reply = DONE host flags
FINISH	MOVE	X:<FLAG_DONE,X0		; Flag = 1 => Normal execution
	MOVE	X0,X:<HOST_FLAG	
	JMP	<RTI_WRITE_HOST_FLAG

; Return from the interrupt with value in (X1,X0)
FINISH1	MOVE	X0,X:<REPLY		; Report value
	MOVE	X:<FLAG_REPLY,X0	; Flag = 2 => Reply with a value
	MOVE	X0,X:<HOST_FLAG	
	JMP	<RTI_WRITE_HOST_FLAG

; Routine for returning from the interrupt on an error
ERROR	MOVE	X:<FLAG_ERR,X0		; Flag = 3 => Error value
	MOVE	X0,X:<HOST_FLAG	
	JMP	<RTI_WRITE_HOST_FLAG

; Routine for returning from the interrupt with a system reset
SYR	MOVE	X:<FLAG_SYR,X0		; Flag = 4 => System reset
	MOVE	X0,X:<HOST_FLAG	
	JMP	<RTI_WRITE_HOST_FLAG

; Routine for returning a BUSY status from the controller
BUSY	MOVE	X:<FLAG_BUSY,X0	; Flag = 6 => Controller is busy
	MOVE	X0,X:<HOST_FLAG	
	JMP	<RTI_WRITE_HOST_FLAG

; Write X:<HOST_FLAG to the DCTR flag bits 5,4,3, as an interrupt
RTI_WRITE_HOST_FLAG
	MOVE	X:DCTR,A
	MOVE	X:<HOST_FLAG,X0	
	AND	#$FFFFC7,A		; Clear bits 5,4,3
	NOP
	OR	X0,A			; Set flags appropriately
	NOP
	MOVE	A,X:DCTR
	RTI

; Put the reply value into the transmitter FIFO
READ_REPLY_VALUE
	MOVEP	X:REPLY,X:DTXS		; DSP-to-host slave transmit
	RTI

READ_REPLY_HEADER
	MOVE	X:<HEADER,X0
	JMP	<FINISH1

; Clear the reply flags and receiver FIFO after a successful reply transaction,
;   but leave the Read Image flags set if the controller is reading out.
CLEAR_HOST_FLAG
	MOVE	X:<FLAG_ZERO,X0
	MOVE	X0,X:<HOST_FLAG
	MOVE	#$FFFFC7,X0
	MOVE	X:DCTR,A
	AND	X0,A
	NOP
	MOVE	A1,X:DCTR

CLR_RCV	JCLR	#SRRQ,X:DSR,CLR_RTS	; Wait for the receiver to be empty
	MOVEP	X:DRXR,X0		; Read receiver to empty it
	NOP				; Wait for flag to change
	JMP	<CLR_RCV
CLR_RTS
	RTI

; *************  Miscellaneous subroutines used everywhere  *************

; Transmit contents of Accumulator A1 to the timing board
XMT_WRD	MOVE	A,X:SV_A
	JCLR	#TDE,X:SSISR0,*
	MOVEP	#$000000,X:TX00
	JSR	<XMT_DLY
	JCLR	#TDE,X:SSISR0,*		; Start bit
	MOVEP	#$010000,X:TX00
	JSR	<XMT_DLY
	JCLR	#TDE,X:SSISR0,*
	DO	#3,L_XMIT
	JCLR	#TDE,X:SSISR0,*		; Three data bytes	
	MOVEP	A1,X:TX00
	JSR	<XMT_DLY
	LSL	#8,A
L_XMIT
	JCLR	#TDE,X:SSISR0,*		; Zeroes to bring TX00 low
	MOVEP	#$000000,X:TX00
	JSR	<XMT_DLY
	MOVE	X:SV_A,A
	REP	#4000			; Delay because Gen I timing board
	NOP				;   needs time between serial words
	RTS

; Short delay for reliability
XMT_DLY	NOP
	RTS

; Read one word of the fiber optic FIFO into B1 with a timeout
RD_FO_TIMEOUT
	MOVE	#1000000,Y0		; 13 millisecond timeout
	DO	Y0,LP_TIM
	JCLR	#EF,X:PDRD,NOT_YET	; Test for new fiber optic data
	NOP
	NOP
	JCLR	#EF,X:PDRD,NOT_YET	; For metastability, check it twice
	ENDDO
	JMP	<RD_FIFO		; Go read the FIFO word
NOT_YET	NOP
LP_TIM	NOP
	BSET	#0,SR			; Timeout reached, error return
	NOP
	RTS

; Read one word from the fiber optics FIFO and put it in A1
RD_FIFO	MOVEP	Y:RDFIFO,Y0		; Read D23-D08
	CLR	B
	REP	#50			; Wait for the next FIFO word
	NOP
	MOVEP	Y:RDFIFO,B0		; Read D07-D00
	ASR	#8,B,B			; Shift D07-D00 into LS bits
	INSERT	#$010008,Y0,B		; Move D23-D08 into A0
	NOP
	MOVE	B0,B			; Move it from B0 to B1
	NOP
	NOP
	BCLR	#0,SR			; Clear carry bit => no error
	NOP
	RTS

; ************************  Test on board DRAM  ***********************
; Test Y: memory mapped to AA0 and AA2 from $000000 to $FFFFFF (16 megapixels)
; DRAM definitions 

TEST_DRAM

; Test Y: memory mapped to AA0 and AA2 from $000000 to $FFFFFF (16 megapixels)
	CLR	A
	NOP
	MOVE	A,R0
	MOVE	#$FF0000,Y0		; Y:$000000 to Y:$FEFFFF
	DO	Y0,L_WRITE_RAM0	
	MOVE	A1,Y:(R0)+
	ADD	#1,A
	NOP
L_WRITE_RAM0

	CLR	A
	NOP
	MOVE	A,R0
	MOVE	#$FF0000,Y0
	DO	Y0,L_CHECK_RAM0
	MOVE	Y:(R0)+,X0
	CMPU	X0,A
	JEQ	<L_RAM4
	ENDDO
	JMP	<ERROR_Y
L_RAM4	ADD	#1,A
	NOP
L_CHECK_RAM0

; Test X: memory mapped to AA3 from $1000 to $7FFFFF (8 megapixels)
	CLR	A
	MOVE	#$1000,R0			; Skip over internal X: memory
	MOVE	#$7FF000,Y0			; X:$001000 to X:$7FFFFF
	DO	Y0,L_WRITE_RAM3	
	MOVE	A,X:(R0)+
	ADD	#1,A
	NOP
L_WRITE_RAM3

	CLR	A
	MOVE	#$1000,R0
	MOVE	#$7FF000,Y0
	DO	Y0,L_CHECK_RAM3	
	MOVE	X:(R0)+,X0
	CMPU	X0,A
	JEQ	<L_RAM5
	ENDDO
	JMP	<ERROR_X
L_RAM5	ADD	#1,A
	NOP
L_CHECK_RAM3
	JMP 	<FINISH

ERROR_Y	MOVE	#'__Y',X0
	MOVE	X0,X:<TRM_MEM
	MOVE	R0,X:<TRM_ADR	
	JMP	<ERROR
ERROR_X	MOVE	#'__X',X0
	MOVE	X0,X:<TRM_MEM
	MOVE	R0,X:<TRM_ADR	
	JMP	<ERROR

;  ****************  Setup memory tables in X: space ********************

; Define the address in P: space where the table of constants begins

        ORG     X:VAR_TBL,P:

; Parameters
STATUS		DC	0		; Execution status bits
		DC	0		; Reserved

	IF	@SCP("DOWNLOAD","HOST")	; Download via host computer
CONSTANTS_TBL_START	EQU	@LCV(L)
	ENDIF

	IF	@SCP("DOWNLOAD","ROM")	; Boot ROM code
CONSTANTS_TBL_START	EQU	@LCV(L)-2
	ENDIF

	IF	@SCP("DOWNLOAD","ONCE")	; Download via ONCE debugger
CONSTANTS_TBL_START	EQU	@LCV(L)
	ENDIF

; Parameter table in P: space to be copied into X: space during 
;   initialization, and must be copied from ROM in the boot process
ONE		DC	1		; One
THREE		DC	3		; Three
FOUR		DC	4		; Four

; Host flags are bits 5,4,3 of the HSTR
FLAG_ZERO	DC	0		; Flag = 0 => command executing
FLAG_DONE	DC	$000008		; Flag = 1 => DONE
FLAG_REPLY	DC	$000010		; Flag = 2 => reply value available
FLAG_ERR	DC	$000018		; Flag = 3 => error
FLAG_SYR	DC	$000020		; Flag = 4 => controller reset
FLAG_RDI	DC	$000028		; Flag = 5 => reading out image
FLAG_BUSY	DC	$000030		; Flag = 6 => controller is busy
C256		DC	256		; 1/2 the FIFO size
C00FF00		DC	$00FF00
C000202		DC	$000202		; Timing board header
TRM_MEM		DC	0		; Test DRAM, memory type of failure
TRM_ADR		DC	0		; Test DRAM, address of failure

; Tack the length of the variable table onto the length of code to be booted
CONSTANTS_TBL_LENGTH EQU	@CVS(P,*-ONE) ; Length of variable table

; Ending address of program so its length can be calculated for bootstrapping
; The constants defined after this are NOT initialized, so need not be 
;    downloaded. 

END_ADR	EQU	@LCV(L)		; End address of P: code written to ROM

; Miscellaneous variables
SV_A		DC	0	; Place for saving accumulator A
NPXLS_1		DC 	0	; # of pxls in current READ_IMAGE call, MS byte
NPXLS_0		DC 	0	; # of pxls in current READ_IMAGE, LS 24-bits
IPXLS_1		DC 	0	; Down pixel counter in READ_IMAGE, MS byte
IPXLS_0		DC 	0	; Down pixel counter in READ_IMAGE, 24-bits
R_PXLS_1	DC 	0	; Up Counter of # of pixels read, MS 16-bits
R_PXLS_0	DC 	0	; Up Counter of # of pixels read, LS 16-bits
BASE_ADDR_1	DC	0	; Starting PCI address of image, MS byte
BASE_ADDR_0	DC	0	; Starting PCI address of image, LS 24-bits
PCI_ADDR_1	DC	0	; Current PCI address of image, MS byte
PCI_ADDR_0	DC	0	; Current PCI address of image, LS 24-bits
REPLY	 	DC	0	; Reply value
HOST_FLAG	DC	0	; Value of host flags written to X:DCTR
FO_DEST		DC	0	; Whether host or PCI board receives command
FO_CMD		DC	0	; Fiber optic command or reply

; Check that the parameter table is not too big
        IF	@CVS(N,*)>=ARG_TBL
        WARN    'The parameter table is too big!'
	ENDIF

	ORG	X:ARG_TBL,P:

; Table that contains the header, command and its arguments
HEADER		DC	0	; (Source, Destination, Number of words)
COMMAND		DC	0	; Manual command	
ARG1		DC	0	; First command argument
ARG2		DC	0	; Second command argument
DESTINATION	DC	0	; Derived from header
NUM_ARG		DC	0	; Derived from header

; End of program
	END

