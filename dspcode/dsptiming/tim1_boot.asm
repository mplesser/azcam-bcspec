       COMMENT *

This file is used to generate boot DSP code for the timing board. 
    This is Rev. 2.31 software.     

	*
        PAGE    132             ; Printronix page width - 132 columns

;  Define some useful DSP register locations
RST_ISR	EQU	$00	; Hardware reset interrupt 
ROM_ID  EQU     $06	; Location of program Identification = SWI interrupt
SSI_ISR EQU     $0C	; SSI serial receiver interrupt address
SSI_ERR EQU     $0E	; SSI interrupt with exception (error)
SCI_ISR EQU     $14	; SCI serial receiver interrupt address
SCI_ERR EQU     $16	; SCI interrupt with exception (error)
START   EQU     $18	; Program starting address
BUF_STR	EQU	$60	; Starting address of buffers in X:
BUF_LEN	EQU	$20	; Length of each buffer
SSI_BUF	EQU	BUF_STR		; Starting address of SSI buffer in X:
SCI_BUF	EQU	SSI_BUF+BUF_LEN	; Starting address of SCI buffer in X:
COM_BUF EQU     SCI_BUF+BUF_LEN	; Starting address of command buffer in X:
COM_TBL EQU     COM_BUF+BUF_LEN	; Starting address of command table in X:
NUM_COM EQU     24      ; Number of entries in command table
TIMEOUT	EQU	1111 	; Timeout for receiving complete command = 1 millisec
APL_ADR	EQU	$E8	; Starting P: address of application program
APL_LEN	EQU	$200-APL_ADR	; Maximum length of application program
LD_X	EQU	$4200	; Assembler loads X: starting at this EEPROM address
RD_X	EQU	$4600	; DSP reads X: from this EEPROM address
LD_OVL	EQU	$4300	; Assembler loads P: overlay starting at this address
ROM_OFF	EQU	$4000	; Boot program offset address in EEPROM

;  Define DSP port addresses
BCR     EQU     $FFFE   ; Bus (=Port A) Control Register -> Wait States
PCC     EQU     $FFE1   ; Port C Control Register
CRA     EQU     $FFEC   ; SSI Control Register A
CRB     EQU     $FFED   ; SSI Control Regsiter B
SSISR   EQU     $FFEE   ; SSI Status Register
RCVR    EQU     $FFEF   ; SSI Receive Register
IPR     EQU     $FFFF   ; Interrupt Priority Register
SCR     EQU     $FFF0   ; SCI Control Register
SSR     EQU     $FFF1   ; SCI Status Register
SCCR    EQU     $FFF2   ; SCI Clock Control Register
SRX     EQU     $FFF4   ; SCI receive data register

; Board status bits, defined at X:<STATUS = X:0
IDLING  EQU     0	; Set if in idle mode => clocking out
IDLMODE	EQU	1	; Set if need to idle after readout
ST_ISR	EQU	2	; Set if SSI, cleared if SCI
DEBUG	EQU	3	; Set if debug command
ST_RAMP	EQU	7	; Set if ramping DC bias supplies up

;  After RESET jump to initialization code
	ORG     P:RST_ISR,P:RST_ISR+ROM_OFF         

	JMP	<INIT	; Initialize DSP after hardware reset
	NOP

;  Put the SSI interrupt service routine where the DSP56001 expects it
        ORG     P:SSI_ISR,P:SSI_ISR+ROM_OFF
	MOVEP   X:RCVR,X:(R1)+  ; Put the word in the SSI buffer
	NOP

;  The SSI interrupts to here when there is an error.
        ORG     P:SSI_ERR,P:SSI_ERR+ROM_OFF       
        JSR     <CLR_SSI
        NOP

;  The SCI interrupts when it receives data from the utility board.
        ORG     P:SCI_ISR,P:SCI_ISR+ROM_OFF
	JSR     <SCI_RCV        ; Jump to long interrupt service routine
	NOP

;  The SCI interrupts to here when there is an error.
        ORG     P:SCI_ERR,P:SCI_ERR+ROM_OFF      
        JSR     <CLR_SCI
        NOP

;  Put the ID words for this version of the ROM code. It is placed at
;   the address of the SWI = software interrupt, which we never use. 
        ORG     P:ROM_ID,P:ROM_ID+ROM_OFF
        DC      $000000         ; Institution
                                ; Location
                                ; Instrument
        DC      $023102         ; Version 2.31, board #2 = timing

;**************************************************************************
;                                                                         *
;    Permanent address register assignments                               *
;	 R1 - Address of SSI receiver contents				  *
;	 R2 - Address of SCI receiver contents				  *
;        R3 - Pointer to current top of command buffer                    *
;        R4 - Pointer to processed contents of command buffer		  *
;        R5 - Temporary register for processing SSI and SCI contents      *
;        R6 - CCD clock driver address for CCD #0 = $FFB0                 *
;                It is also the A/D address of analog board #0            *
;                                                                         *
;    Other registers                                                      *
;        R0, R7 - Temporary registers used all over the place.            *
;        R5 - Can be used as a temporary register but is circular,        *
;               modulo 32.       					  *
;**************************************************************************

;  Start the command interpreting code just above the ISRs
        ORG     P:START,P:START+ROM_OFF         

;  Test receiver contents - both SSI and SCI
	JSET    #IDLING,X:STATUS,IDLE ; See if we're idling
L0	JSR	<RCV_TST	; Test to see if both receivers are empty
	JEQ	<L0		; If R1 and R2 are unchanged, keep trying

;  Check header ID = (S,D,N) for self-consistency
RCV_ID	MOVE	X:(R5),Y0	; Get candidate header ID
	MOVE    X:<MASK1,A1	; Test for S.LE.3 and D.LE.3 and N.LE.7
	AND     Y0,A		
        JNE     <RCV_SKP        ; Test failed, skip over header ID 
        MOVE    X:<MASK2,A1       
        AND     Y0,A		; Test for S.NE.0 or D.NE.0
       	JEQ     <RCV_SKP        ; Test failed, skip over header ID
	MOVE	#7,A1
        AND     Y0,A  		; Test for N.GE.1
        JNE     <RCV_PR         ; Test suceeded - process command
RCV_SKP MOVE    (R5)+		; Header ID is wrong - skip over it
	JSR	<R_PROC		; Update R#PROC
	JMP	<START		; Wait for the next command

; Get all the words of the command before processing it
RCV_PR	MOVE	A,Y0		; Number of words in command header
	DO	#TIMEOUT,TIM_OUT
	MOVE	R1,A
	JSET	#ST_ISR,X:STATUS,RCV_WT1
	MOVE	R2,A		
RCV_WT1	SUB	X0,A		; X0 = R#PROC from VME_TST or FO_TST
        JGE     <RCV_L1		; X1 = Destination mask $00FF00
        MOVE    X:<C32,X1	; Correct for circular buffer
        ADD     X1,A		; No MOVE here - it isn't always executed
RCV_L1	CMP	Y0,A  Y0,X:<NWORDS ; Y0 = NWORDS from above
	JLT	<RCV_L2
	ENDDO
	JMP	<MV_COM
RCV_L2	NOP
TIM_OUT
	JMP	<RCV_SKP	; Increment R5 and update R#PROC

; We've got the complete command, so put it on the COM_BUF stack
MV_COM	DO	X:<NWORDS,SSI_WR
	MOVE	X:(R5)+,A	; R5 = R#PROC from RCV_TST
	MOVE	A,X:(R3)+
SSI_WR
	JSR	<R_PROC

;  Process the receiver entry - is its destination number = D_BRD_ID?
PRC_RCV	MOVE    R3,A            ; Pointer to current contents of receiver
        MOVE    R4,X0           ; Pointer to processed contents
	CMP     X0,A  X:<DMASK,X1 ; Are they equal? Get destination mask
	JEQ	<START		; If unequal, there's a command to be processed
	MOVE    X:(R4),A	; Get the header ID
	MOVE    A,X:<HDR_ID	; Save header ID
	AND     X1,A  X:<DBRDID,X1 ; Extract destination byte only; Store ID
	CMP     X1,A   		; ID = destination number? 
	JEQ     <COMMAND	; Yes, process it as a command
	JLT     <FFO_XMT	; Test to send to the fast fiber optic

; Transmit words a byte at a time over the SCI to the Utility board
        DO      X:<NWORDS,DON_XMT ; Transmit NWORDS
        MOVE    X:<SRXFST,R0 	; $FFF4 = SCI first byte address
	DO      #3,SCI_SPT
SCI_XMT JCLR    #0,X:SSR,SCI_XMT ; Continue only if SCI XMT register is empty
        MOVE    X:(R4),X1
        MOVE    X1,X:(R0)+      ; Write to SCI buffer, increment byte pointer
SCI_SPT
	MOVE	(R4)+           ; Increment word pointer
DON_XMT 
	JMP     <START		; Check command continuation

;  Transmit 24-bit words to the host computer three bytes at a time
FFO_XMT	DO	X:<NWORDS,DON_FFO ; Transmit all the words in the command
	DO	#20,DLY_FFO	; Delay for the fast serial transmitter
        NOP
DLY_FFO
	MOVE	X:(R4)+,X1	; Get each word
        MOVE	X1,Y:(R6)	; And send it to the fast fiber optic
DON_FFO
	JMP	<START

;  Test SSI and SCI receiver buffer contents
RCV_TST	MOVE	X:<R1PROC,X0	; Get pointer to processed contents of buffer
	MOVE	R1,A		; Get current command buffer pointer
	CMP	X0,A  X0,R5
	JEQ	<SCI_TST
	BSET	#ST_ISR,X:<STATUS
	RTS

SCI_TST MOVE	X:<R2PROC,X0	; Get pointer to processed contents of buffer
	MOVE	R2,A		; Get current command buffer pointer
	CMP	X0,A  X0,R5
	JEQ	<SCI_RTS	; Process header ID if R# .NE. X:R#PROC
	BCLR	#ST_ISR,X:<STATUS
SCI_RTS	RTS

; Update the pointer to the already processed comamnds
R_PROC	JCLR	#ST_ISR,X:STATUS,SCI_L2 ; Does SSI or SCI have an entry?
	MOVE	R5,X:<R1PROC	; Update SSI pointer
	RTS
SCI_L2	MOVE	R5,X:<R2PROC	; Update SCI pointer
	RTS

;  Process the receiver entry - is it in the command table ?
COMMAND	MOVE    (R4)+           ; Increment over the header ID
	MOVE    X:(R4)+,A       ; Get the command buffer entry
	MOVE	#<COM_TBL,R0 	; Get command table starting address
	DO      #NUM_COM,END_COM ; Loop over command table
	MOVE    X:(R0)+,X1      ; Get the command table entry
	CMP     X1,A  X:(R0),R7	; Does receiver = table entries address?
	JNE     <NOT_COM        ; No, keep looping
	ENDDO                   ; Restore the DO loop system registers
	JMP     (R7)            ; Jump execution to the command
NOT_COM MOVE    (R0)+           ; Increment the register past the table address
END_COM

;  It's not in the command table - send an error message
ERROR   MOVE    X:<ERR,X0	; Send the message - there was an error
        JMP     <FINISH1	; This protects against unknown commands

; Send a reply packet - header ID and reply
FINISH  MOVE    X:<DON,X0	; Send a DONE message as a reply
FINISH1	MOVE    X:<HDR_ID,A	; Get header of incoming command
        MOVE    X:<SMASK,Y0	; This was the source byte, and is to 
	AND     Y0,A  X:<TWO,Y0	;    become the destination byte
        REP	#8		; Shift right one byte, add it to the
        LSR     A  Y0,X:<NWORDS	;     header, and put 2 as the number
        ADD     Y0,A  X:<SBRDID,Y0 ;  of words in the string
	ADD	Y0,A  X:<DMASK,X1 ; Add source boards ID, set X1 for above
        MOVE    A,X:(R3)+       ; Put header ID on the transmitter stack
	MOVE	X0,X:(R3)+	; Put value of XO on the transmitter stack
	JMP	<PRC_RCV	; Go get the next command

; Test Data Link - simply return value received after 'TDL'
TDL	MOVE    X:(R4)+,X0      ; Get data value
        JMP     <FINISH1	; Return from executing TDL command

; Interrupt service routine for SCI serial link to utility board
SCI_RCV	MOVEC   SR,X:<SAVE_SR	; Save Status Register
	MOVE	R0,X:<SAVE_R0	; Save R0
	MOVE	B1,X:<SAVE_B1	; Save B1
	MOVE	X1,X:<SAVE_X1	; Save X1
	MOVE	X:<SCI_R0,R0	; Get previous value of SCI R0
	MOVE	X:<SCI_B1,B1	; Get previous value of SCI B1
	MOVE    X:(R0),X1       ; Get the byte from the SCI
	BCLR    #1,R0		; Test for the address being $FFF6 = last byte
	OR      X1,B (R0)+      ; Add the byte into the 24-bit word
	JCC     <MID_BYT        ; Not the last byte => only restore registers
END_BYT MOVE    B1,X:(R2)+	; Put the 24-bit word in the command buffer
	MOVE	X:<SRXFST,R0	; Initialize R0 to start of SCI
	MOVE    #0,B1		; Zero SCI_B1 for next SCI use
MID_BYT	MOVE	R0,X:<SCI_R0	; Save SCI value of SCI address pointer
	MOVE	B1,X:<SCI_B1	; Save SCI_B1 for next SCI use
        MOVEC   X:<SAVE_SR,SR	; Restore Status Register
	MOVE	X:<SAVE_R0,R0	; Restore R0	
	MOVE	X:<SAVE_B1,B1	; Restore B1
	MOVE    X:<SAVE_X1,X1   ; Restore X1
        RTI                     ; Return from interrupt service

; Clear error condition and interrupt on SSI receiver
CLR_SSI MOVEP   X:SSISR,X:RCV_ERR ; Read SSI status register
        MOVEP   X:RCVR,X:RCV_ERR  ; Read receiver register to clear error
        RTI

; Clear error condition and interrupt on SSI receiver
CLR_SCI MOVEP   X:SSR,X:RCV_ERR     ; Read SCI status register
        MOVEP   X:SRX,X:RCV_ERR     ; Read register to clear error
        RTI

; Overlay processing code - get the EEPROM address of routine
OVL_RDM	MOVE	#L_RDMEM,X1
 	JMP	<OVL_LD
OVL_WRM	MOVE	#L_WRMEM,X1
  	JMP	<OVL_LD
OVL_LDA	MOVE	#L_LDA,X1
 	JMP	<OVL_LD
OVL_RST	MOVE	#L_RST,X1

; Load overlay code from EEPROM to DSP memory
OVL_LD	MOVE	X:<THREE,Y0
	MPY	X1,Y0,A
	ASR	A  #OVERLAY,R7
	BCLR	#15,A0
	MOVE	A0,R0		; R0 = address of routine*3 - $8000
	DO	#APL_ADR-OVERLAY,LD_OVL1 ; Maximum length of overlay
	DO	#3,LD_OVL2	; Three bytes of ROM per instruction
	MOVE	P:(R0)+,A2	; Read from EEPROM
	REP	#8
	ASR	A
	NOP			; DO loop restriction
LD_OVL2
	MOVE	A1,P:(R7)+	; Write to DSP P: memory
LD_OVL1	
OVERLAY				; Overlays go here

;  Specify the memory location where the readout program is to be loaded
	ORG	P:APL_ADR,P:APL_ADR+ROM_OFF

; Define these as simple jump addresses so bootrom program is sure to work
;   until the application program can be loaded
IDLE	JMP	<FINISH		; Reply and return

INIT				; Must define this address for all cases

;  Initialization of the DSP - system register, serial link, interrupts.
;    This is executed once on DSP boot from ROM, and is not incorporated
;    into any download code since its not needed.
	
	MOVEC   #$82,OMR        ; Operating Mode Register = Normal 
                                ;    Expanded - set after reset by hwd.

        MOVEP   #$6000,X:CRA    ; SSI programming - no prescaling, 
				;   24 bits/word, on-demand communications, 
				;   no divide, max. rate clock = 5.11 MHz,

        MOVEP   #$A830,X:CRB    ; SSI programming - OF0, OF1 don't apply; 
				;   SC0, SC1 are inputs, SC2 is output; 
				;   internal clock; word length frame sync; 
                                ;   asynchronous; continuous clock;
                                ;   network mode to get on-demand; 
                                ;   RCV and its interrupts enabled; 
				;   TX and its interrrupts disabled. 

        MOVEP   #$B000,X:IPR    ; Set interrupt priorities 
                                ;   Host = IRQA = IRQB = 0
                                ;   SCI = 1
                                ;   SSI = 2 (highest)

        MOVEP   #$0B04,X:SCR    ; SCI programming: 11-bit asynchronous
                                ;   protocol (1 start, 8 data, 1 even parity,
                                ;   1 stop); LSB before MSB; enable receiver
                                ;   and its interrupts; transmitter interrupts
				;   disabled.

        MOVEP   #$0000,X:SCCR   ; SCI clock: maximum asynchronous 
                                ;   data rate (312,500 kbits/sec); internal 
                                ;   clock.

        MOVEP   #$01FF,X:PCC    ; Port C are dedicated serial interface pins
                                ;   for the SSI and SCI. 

; Initialize X: data memory
        MOVE    #RD_X,R0 	; Starting X: address in EEPROM
        MOVE    #0,R1		; Put values starting at beginning of X:
	DO      #$100,X_MOVE	; Assume 256 = $100 values exist
        DO      #3,X_LOOP	; Reconstruct bytes to 24-bit words
        MOVE    P:(R0)+,A2	; Get one byte from EEPROM
	REP	#8
        ASR     A  		; Shift right 8 bits
	NOP			; DO loop restriction
X_LOOP
        MOVE    A1,X:(R1)+	; Write 24-bit words to X: memory
X_MOVE

; Initialize the permanent registers
	MOVE	#SSI_BUF,R1	; Starting address of SSI buffer
	MOVE	#SCI_BUF,R2	; Starting address of SCI buffer
        MOVE    #COM_BUF,R3	; Starting address of command buffer
	MOVE	R1,X:<R1PROC
	MOVE	R2,X:<R2PROC
	CLR	A  R3,R4
	MOVE	#31,M1		; All input buffers are circular, modulo 32
        MOVE    M1,M2		
	MOVE	M2,M3
	MOVE	M3,M4
	MOVE	M4,M5
	DO	#32,ZERO_Y	; Zero all command buffers for debugging
	MOVE	A,X:(R1)+
	MOVE	A,X:(R2)+
	MOVE	A,X:(R3)+
ZERO_Y
        MOVE    X:<CCDSEL0,R6	; Address of all CCD clocks and A/D #0

	MOVE	#$020002,A	; Send $020002 'RST' reply to host computer
	MOVE	A,X:(R3)+
	MOVE	#'RST',A
	MOVE	A,X:(R3)+
	MOVE	#>2,A
	MOVE	A,X:<NWORDS

        MOVEP	#$40,X:BCR	; Wait states for P: access = EEPROM
	ANDI    #$FC,MR		; Unmask all interrupts

; Initialize all bias DACs to midrange = $80 benign values
;   Don't bother compresing this code too much since its 
;   discarded after initialization
	MOVE	#$C00,X0
	MOVE	#$040D80,X1
	MOVE	#$1000,Y1	; Isolate CCD number
	CLR	B		; Initial value of CCD number	
	DO	#8,SLOOP	; Loop over 8 analog boards for now
	MOVE	B,A
	OR	X0,A  		; Add CCD number to register select
	MOVE	A,X:(R6)  
	MOVE	B,A
	OR	X1,A		; Add voltage to register select
	ADD	Y1,B  A,X:(R6)	; Write voltage, increment CCD number
SLOOP

; Put the video processor in a benign state
	MOVE	#$00F055,A	; Select VP lines, set to $4D
	MOVE	A,X:(R6)

;  All done with initialization code
	JMP	<PRC_RCV	; Go transmit 'RST' reply

; Check for overflow
        IF	@CVS(N,*)>$1FF
        WARN    'Internal P: memory overflow!'	; Make sure readout code
	ENDIF					;  will not be overwritten

; Here begin the BOOT overlay programs
; Put them starting at address LD_OVL in EEPROM

	ORG	P:OVERLAY,P:LD_OVL
L_RDMEM	SET	@LCV(L)		; Get load address for use in LD_OVL routine

; Read DSP or EEPROM memory ('RDM' address): read memory, reply with value
RDMEM	MOVE    X:(R4),R0	; Need the address in an address register
	MOVE	X:(R4)+,X1	; Need address also in a 24-bit register
        JCLR    #20,X1,RDX 	; Test address bit for Program memory
	MOVE	R0,Y0		; We need the 16-bit address in a data register
	MOVE	X:<C512,A
	CMP	Y0,A  X:<THREE,X1
	JLE	<RDROM 
        MOVE	P:(R0),X0	; Read from Program memory
        JMP     <FINISH1	; Send out a header ID with the value
RDX     JCLR    #21,X1,RDY 	; Test address bit for X: memory
        MOVE    X:(R0),X0	; Write to X data memory
        JMP     <FINISH1	; Send out a header ID with the value
RDY     JCLR    #22,X1,ERROR	; Test address bit for Y: memory
        MOVE    Y:(R0),X0	; Read from Y data memory
	JMP     <FINISH1	; Send out a header ID with the value

; Read from EEPROM. Read three bytes and concatenate them into
;   a 24-bit word before replying.
RDROM	MPY	X1,Y0,A		; Byte address = word address x 3
	ASR	A		; Eliminate zero fill of fractional multiply
	MOVE	A0,R0		; Need to address P: memory
	DO	#3,L1RDR
	MOVE	P:(R0)+,A2	; Read each ROM byte
	REP	#8
	ASR	A		; Move right into A1
	NOP
L1RDR
	MOVE	A1,X0		; FINISH1 transmits X0 as its reply
	JMP	<FINISH1

; Check that the overlay code is not too big
        IF	@CVS(N,*)>APL_ADR
        WARN    'RDMEM overlay is too big!'	; Make sure application code
	ENDIF					;  will not be overwritten


	ORG	P:OVERLAY,P:
L_WRMEM	SET	@LCV(L)		; Get load address for use in LD_OVL routine

; Program WRMEM ('WRM' address datum): write to memory, reply 'DON'.
WRMEM	MOVE    X:(R4),R0	; Get the desired address
	MOVE	X:(R4)+,X1	; We need a 24-bit version of the address
        MOVE    X:(R4)+,X0	; Get datum into X0 so MOVE works easily
        JCLR    #20,X1,WRX	; Test address bit for Program memory
	MOVE	R0,Y0		; We need the 16-bit address in a data register
	MOVE	X:<C512,A
	CMP	Y0,A  X:<THREE,X1
	JLE	<WRROM
        MOVE	X0,P:(R0)	; Write to Program memory
        JMP     <FINISH
WRX     JCLR    #21,X1,WRY	; Test address bit for X: memory
        MOVE    X0,X:(R0)	; Write to X: memory
        JMP     <FINISH
WRY     JCLR    #22,X1,ERROR	; Test address bit for Y: memory
        MOVE    X0,Y:(R0)	; Write to Y: memory
	JMP	<FINISH

; Write to ROM a byte at a time, delaying 10 milliseconds between each one
WRROM	MPY	X1,Y0,A		; Byte address = word address x 3
	ASR	A		; Eliminate zero fill of fractional multiply
	MOVE	A0,R0		; Need to address P: memory
	JSET	#14,R0,ERROR	; Write protect BOOTROM code
	MOVE	X0,A1		; Get data from command string
	DO	#3,L1WRR	; Least significant bytes at lower addresses
	MOVEM	A1,P:(R0)+	; Write least significant ROM byte
	REP	#8		; Not REP so its interrupteable
	ASR	A  X:<C50000,Y0	; Move right one byte, enter delay
	DO	Y0,L3WRR	; Delay by 10 milliseconds for EEPROM write
	NOP			; Assume 20 MHz DSP56001
	NOP
L3WRR
	NOP			; DO loop nesting restriction
L1WRR
	JMP	<FINISH

; Check that the overlay code is not too big
        IF	@CVS(N,*)>APL_ADR
        WARN    'WRMEM overlay is too big!'	; Make sure application code
	ENDIF					;  will not be overwritten


	ORG	P:OVERLAY,P:
L_LDA	SET	@LCV(L)		; Get load address for use in LD_OVL routine

;  Read EEPROM code into DSP memory starting at P:APL_ADR
	MOVE	X:(R4)+,X0	; Number of application program
	MOVE	X:<C600,Y0
	MPY	X0,Y0,A  X:<ZERO,X1
	ASR	A  X:<C300,X0
	SUB	X,A  #APL_ADR,R7
	MOVE	A0,R0		; EEPROM address = # x $600 - $300
	DO	#APL_LEN,LD_LA2 ; Load from APL_ADR to $200
	DO	#3,LD_LA1
	MOVE	P:(R0)+,A2	; Read from EEPROM
	REP	#8
	ASR	A
	NOP			; DO loop restriction
LD_LA1
	MOVE	A1,P:(R7)+	; Write to DSP P: memory
LD_LA2	

;  Splice the application and boot command tables together
	MOVE	#COM_TBL,R7	; Leave most of X: memory alone
	DO	#32,LD_LA4 	; 16 commands, 2 entries per command
	DO	#3,LD_LA3
	MOVE	P:(R0)+,A2	; Read from EEPROM
	REP	#8
	ASR	A
	NOP			; DO loop restriction
LD_LA3
	MOVE	A1,X:(R7)+	; Write to DSP X: memory
LD_LA4

;  Transfer Y: memory, containing waveforms and readout parameters
	MOVE	#0,R7		; Start at bottom of Y: memory
	DO	#$200-32-APL_LEN,LD_LA6	; Update Y: DSP memory
	DO	#3,LD_LA5
	MOVE	P:(R0)+,A2	; Read from EEPROM
	REP	#8
	ASR	A
	NOP			; DO loop restriction
LD_LA5
	MOVE	A1,Y:(R7)+	; Write to DSP Y: memory
LD_LA6
	JMP	<FINISH

; Check that the overlay code is not too big
        IF	@CVS(N,*)>APL_ADR
        WARN    'LDA overlay is too big!'	; Make sure application code
	ENDIF					;  will not be overwritten


	ORG	P:OVERLAY,P:
L_RST	SET	@LCV(L)		; Get load address for use in LD_OVL routine

;  Reset = Reboot
RST	RESET                   ; Reset SSI peripheral
	MOVE    X:<CFFFF,M0     ; Insure that its linear addressing
        MOVE    X:<CFFFF,M1
        MOVEP   X:ZERO,X:IPR    ; Clear Interrupt Priority Register
        MOVEP   X:CFFFF,X:BCR   ; Many Wait States for PROM accesses
        MOVEC   X:<ZERO,SP      ; Clear the stack pointer
        MOVEC   X:<C300,SR      ; Clear the Condition Code Register 
        MOVEC   #$01,OMR        ; Operating Mode Register = Reboot 
        NOP                     ; Allow one cycle delay for the remapping
        JMP     <$0             ; Begin bootstrap from internal ROM

; Check that the overlay code is not too big
        IF	@CVS(N,*)>APL_ADR
        WARN    'RST overlay is too big!'	; Make sure application code
	ENDIF					;  will not be overwritten

; End of overlay programs

;  ********* Beginning of X: definitions ************

; Status and header ID processing words
        ORG     X:0,X:LD_X
STATUS  DC      800000  ; Status word AzCam
OPTIONS DC      1       ; Software options
HDR_ID	DC	0	; Header ID of all commands
NWORDS	DC	0	; Number of words in command
R1PROC	DC	0	; Last processed value of SSI pointer R1
R2PROC	DC	0	; Last processed value of SCI pointer R2

;  Definitions in SCI ISR
SAVE_SR DC      0
SAVE_X1 DC      0
SAVE_B1	DC	0
SAVE_R0	DC	0
SCI_B1	DC	0
SCI_R0	DC	$FFF4	; Starting address of the SCI

;  Miscellaneous constant definitions
ZERO    DC      0
ONE	DC	1
TWO	DC	2
THREE	DC	3
C32	DC	32		; To correct for circular buffer addressing
C512	DC	512		; To read/write EEPROM
C300    DC      $300		; Constant for resetting the DSP
C600	DC	$600		; EEPROM space per application program
C4000	DC	$4000		; Offset into EEPROM for "boot" overlays
CFFFF   DC      $FFFF           ; Constant for resetting the DSP
C50000	DC	50000		; Delay for WRROM = 5 millisec
MASK1	DC	$FCFCF8		; Mask for checking header ID
MASK2	DC	$030300		; Mask for checking header ID
SBRDID  DC	$020000 	; Source Identification number
DBRDID  DC	$000200 	; Destination Identification number
DMASK   DC	$00FF00 	; Mask to get destination board number out
SMASK   DC	$FF0000 	; Mask to get source board number out
CCDSEL0 DC	$FFB0		; Select to update CCD clocks and CCD #0 A/D
SRXFST  DC      $FFF4		; Starting address of SCI receiver
ERR	DC	'ERR'		; An error occurred
DON	DC	'DON'		; Command was fully processed
RCV_ERR DC      0               ; Dummy location for receiver clearing

;  Command table resident in X: data memory
;  The last part of the command table is not defined for "bootrom"
;     because it contains application-specific commands

	ORG     X:COM_TBL,X:COM_TBL+LD_X
	DC	0,START,0,START,0,START,0,START ; This is where application
	DC	0,START,0,START,0,START,0,START	;   commands go
	DC	0,START,0,START,0,START,0,START
	DC	0,START,0,START,0,START,0,START
	DC      'TDL',TDL	; Test Data Link
	DC      'ERR',START	; Nothing special
	DC      'RDM',OVL_RDM	; Read from DSP memory - overlay         
	DC      'WRM',OVL_WRM	; Write to DSP memory        
	DC	'LDA',OVL_LDA	; Load progam from EEPROM to DSP
	DC      'RST',OVL_RST  	; Re-boot DSP from on-board ROM 
	DC	0,START,0,START	; Room for two more "boot" commands

;  End of command table


;  End of program
	END
