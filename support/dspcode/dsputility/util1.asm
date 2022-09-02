       COMMENT *

This file is used to generate DSP code for the utility board. It will time
     the exposure, operate the shutter, control the CCD temperature and 
     turn the analog power on. This is Rev. 2.31 software. 
             	        
-d DOWNLOAD 1	To generate code for downloading to DSP memory.
-d DOWNLOAD 0	To generate code for writing to the EEPROM.

Modified by MPL for AzCam and PCI interface 12-Feb-04

last change 20Aug04 MPL
	*
        PAGE    132	; Printronix page width - 132 columns

; Name it a section so it doesn't conflict with other application programs
	SECTION	UTILICE

;  These are also defined in "utilboot.asm", so be sure they agree
APL_NUM	EQU	9		; Application number from 1 to 10
APL_ADR	EQU	$98		; Starting address of application program
BUF_STR	EQU	$80		; Starting address of buffers in X:
BUF_LEN	EQU	$20		; Length of buffers
SCI_BUF	EQU	BUF_STR		; Starting address of SCI buffer in X:
COM_BUF	EQU	SCI_BUF+BUF_LEN	; Starting address of command buffer in X:
COM_TBL	EQU	COM_BUF+BUF_LEN	; Starting address of command table in X:

;  Define some useful constants
APL_XY	EQU	$1EE0	; Starting address in EEPROM of X: and Y: values
DLY_MUX	EQU	70	; Number of DSP cycles to delay for MUX settling
DLY_AD	EQU	100	; Number of DSP cycles to delay for A/D settling

; Assign addresses to port B data register
PBD		EQU	$FFE4   ; Port B Data Register
IPR		EQU	$FFFF   ; Interrupt Priority Register

;  Addresses of memory mapped components in Y: data memory space
;  Write addresses first
WR_DIG	EQU	$FFF0		; was $FFFF  Write Digital output values D00-D15
WR_MUX	EQU	$FFF1		; Select MUX connected to A/D input - one of 16
EN_DIG	EQU	$FFF2		; Enable digital outputs
WR_DAC3	EQU	$FFF7		; Write to DAC#3 D00-D11
WR_DAC2	EQU	$FFF6		; Write to DAC#2 D00-D11
WR_DAC1	EQU	$FFF5		; Write to DAC#1 D00-D11
WR_DAC0	EQU	$FFF4		; Write to DAC#0 D00-D11

;  Read addresses next
RD_DIG	EQU	$FFF0   ; Read Digital input values D00-D15
STR_ADC	EQU	$FFF1   ; Start ADC conversion, ignore data
RD_ADC	EQU	$FFF2   ; Read A/D converter value D00-D11
WATCH		EQU	$FFF7   ; Watch dog timer - tell it that DSP is alive

;  Bit definitions of STATUS word
ST_SRVC	EQU	0	; Set if ADC routine needs executing
ST_EX   	EQU	1	; Set if timed exposure is in progress
ST_SH   	EQU	2	; Set if shutter is open
ST_READ 	EQU	3	; Set if a readout needs to be initiated

; Bit definitions of software OPTIONS word
OPT_SH	EQU     0	; Set to open and close shutter
OPT_RDC	EQU     1	; Set to readout CCD after expose

;  Bit definitions of Port B = Host Processor Interface
HVEN		EQU     0	; Enable high voltage PS (+36V nominal)- Output
LVEN		EQU     1	; Enable low voltage PS (+/-15 volt nominal) - Output
PWRST		EQU     2	; Reset power conditioner counter - Output
SHUTTER	EQU     3	; Control shutter - Output
IRQ_T		EQU     4	; Request interrupt service from timing board - Output
SYS_RST	EQU     5	; Reset entire system - Output
WATCH_T	EQU     8	; Processed watchdog signal from timing board - Input

;**************************************************************************
;                                                                         *
;    Register assignments  						  *
;	 R1 - Address of SCI receiver contents				  *
;	 R2 - Address of processed SCI receiver contents		  *
;        R3 - Pointer to current top of command buffer                    *
;        R4 - Pointer to processed contents of command buffer		  *
;	 N4 - Address for internal jumps after receiving 'DON' replies	  *
;        R0, R5, R6, A, X0, X1 and Y0 - For use by program only           *
;	 R7 - For use by SCI ISR only					  *
;        B and Y1 - For use by timer ISR only                             *
;									  *
;**************************************************************************

;  Specify execution and load addresses
	IF	DOWNLOAD
	ORG	P:APL_ADR,P:APL_ADR		; Download address
	ELSE
        ORG     P:APL_ADR,P:APL_NUM*$300+$1D00	; EEPROM generation
	ENDIF

;  The TIMER addresses must be defined here and SERVICE must follow to match
;    up with the utilboot code
	JMP	<SERVICE	; Millisecond timer interrupt

;  The TIMER interrupt service routine (ISR) keeps track of exposure times
TIMER	RTI				; RTI for now so downloading works
;TIMER	MOVEC	SR,Y:<SV_SR 		; Save Status Register
	JCLR    #ST_EX,X:STATUS,NO_TIM	; Continue on if we're not exposing
	MOVE	X:<ONE,B		; Constant to increment EL_TIM
	MOVE	Y:<EL_TIM,Y1 		; Get elapsed time
	ADD	Y1,B	Y:<TGT_TIM,Y1 	; Get Target time for code below
	MOVE	B,Y:<EL_TIM 		; EL_TIM = EL_TIM + 1
	SUB     Y1,B
	JLT     <NO_TIM			; If (EL .GE. TGT) we've timed out
	BSET    #ST_READ,X:<STATUS	; Set so a readout will be initiated

;  Close the shutter at once if needed; return from interrupt
	JCLR    #OPT_SH,X:OPTIONS,NO_TIM ; Close the shutter only if needed
	BCLR    #SHUTTER,X:PBD		; Set Port B bit #3 to close shutter
	BSET	#ST_SH,X:<STATUS	; Set status to mean shutter closed
NO_TIM	
	BSET    #ST_SRVC,X:<STATUS	; SERVICE needs executing
	MOVEC	Y:<SV_SR,SR		; Restore Status Register
	NOP
	RTI				; Return from TIMER interrupt

RDCCD
;	MOVE	X:<VME,B
;	MOVE	B,X:(R3)+		; Header ID from Utility to VME
;	MOVE	Y:<RDC,B
;	MOVE	B,X:(R3)+               ; Put VMEINF board in readout mode
;	MOVE	X:<TIMING,B
;	MOVE	B,X:(R3)+               ; Header ID from Utility to timing
;	MOVE	Y:<RDC,B
;	MOVE	B,X:(R3)+               ; Start reading out the CCD

; for AzCam, this is the readout only, not CLR, shutter, or exposure timing
	MOVE	X:<TIMING,B
	MOVE	B,X:(R3)+		; Header ID from Utility to timing
	MOVE	Y:<RDC,B
	MOVE	B,X:(R3)+		; Start reading out the CCD
	JMP	<START

; This long subroutine is executed every millisecond, but isn't an ISR so
;   that care need not be taken to preserve registers and stacks.
SERVICE	
	BCLR	#ST_SRVC,X:<STATUS	; Clear request to execute SERVICE
	JCLR	#ST_READ,X:<STATUS,UPD_DIG ; Initiate readout if timer done
	JCLR	#OPT_RDC,X:<OPTIONS,NO_RDC ; don't read as an option
	MOVE	X:<TIMING,A
	MOVE	A,X:(R3)+               ; Header ID from Utility to timing
	MOVE	Y:<RDC,A
	MOVE	A,X:(R3)+               ; Start reading out the CCD
NO_RDC
	BCLR	#ST_EX,X:<STATUS	; Exposure is no longer in progress
	BCLR	#ST_READ,X:<STATUS	; clear flag
	RTS				; Return now to save time

; Update all the digital input/outputs; reset watchdog timer
UPD_DIG	MOVEP   Y:RD_DIG,Y:DIG_IN  ; Read 16 digital inputs
	MOVEP	#1,Y:EN_DIG	   ; Enable digital outputs
	MOVEP   Y:DIG_OUT,Y:WR_DIG ; Write 16 digital outputs

; Update the 4 DACs
	MOVEP   Y:DAC0,Y:WR_DAC0 ; Write to DAC0
	MOVEP   Y:DAC1,Y:WR_DAC1 ; Write to DAC1
	MOVEP   Y:DAC2,Y:WR_DAC2 ; Write to DAC2
	MOVEP   Y:DAC3,Y:WR_DAC3 ; Write to DAC3

; Analog Input processor - read the 16 A/D inputs
        MOVE    X:<ONE,X0	; For incrementing accumulator to select MUX
        CLR     A  #<AD_IN,R5	; Will contain MUX number
        DO      Y:NUM_AD,LOOP_AD ; Loop over each A/D converter input
        MOVEP   A,Y:WR_MUX      ; Select MUX input
        REP	#DLY_MUX	; Wait for the MUX to settle
	MOVE	A1,Y:<SV_A1	; REP is OK since delay < SCI time per byte
        MOVEP   Y:STR_ADC,Y0    ; Start A/D conversion - dummy read
        REP     #DLY_AD		; Wait for the A/D to settle
        MOVE    X:<CFFF,Y0	
        MOVEP   Y:RD_ADC,A1     ; Get the A/D value
        AND     Y0,A            ; A/D is only valid to 12 bits
        BCHG    #11,A1		; Change 12-bit 2's complement to unipolar
        MOVE    A1,Y:(R5)+      ; Put the A/D value in the table
	MOVE	Y:<SV_A1,A1	; Restore A1 = MUX number
        ADD     X0,A		; Increment A = MUX number by one
LOOP_AD
	MOVEP	X:ONE,Y:WR_MUX ; Sample +5V when idle

; Control the CCD Temperature
; The algorithmn assumes a reverse biased diode whose A/D count A_CCDT 
;   is proportional to temperature. Don't start controlling temperature 
;   until it falls below target temperature. 

	MOVE    Y:<T_CCDT,X0	; Get actual CCD temperature
	MOVE    Y:<A_CCDT,A	; Get lower CCD temperature limit
	SUB	X0,A
	MOVE	A,X0
	MOVE	Y:<T_COEFF,Y0	
	MPY	X0,Y0,A		; A = (actual - target) * T_COEFF
	MOVE	Y:<DAC0,X1	; A positive -> actual > target ->
	MOVE	Y:<DAC0_LS,X0	;   too cold -> add more heat
	ADD	X,A		; Add both least and most significant
				;   words (X0 and X1) to accumulator A
	MOVE	Y:<C825,X0	; Heats greater than this are not allowed
	CMP	X0,A
	JLT	<TST_LOW
	MOVE	X0,A		; Make it the maximum heat
	JMP	<WR_DAC
TST_LOW	TST	A		; Heats of less than zero are not allowed
	JGT	<WR_DAC
	MOVE	X:<ZERO,A	; No heat
WR_DAC	MOVEP	A,Y:WR_DAC0	; Update DAC and record of it
	MOVE	A,Y:<DAC0
	MOVE	A0,Y:<DAC0_LS
	RTS			; Return from subroutine SERVICE call


; Shutter support subroutines for the TIMER executive
;   Also support shutter connection to timing board for now.
OSHUT	BSET    #SHUTTER,X:PBD  ; Clear Port B bit #3 to open shutter
        BCLR    #ST_SH,X:<STATUS ; Clear status bit to mean shutter open
        RTS

CSHUT	BCLR    #SHUTTER,X:PBD  ; Set Port B bit #3 to close shutter
        BSET    #ST_SH,X:<STATUS ; Set status to mean shutter closed
        RTS

; These are called directly by command, so need to call subroutines in turn
OPEN	JSR	OSHUT		; Call open shutter subroutine
	JMP	<FINISH		; Send 'DON' reply
CLOSE	JSR	CSHUT		; Call close shutter subroutine
	JMP	<FINISH		; Send 'DON' reply


;  **************  BEGIN  COMMAND  PROCESSING  ***************
; Start power-on cycle
P_ON	BSET	#PWRST,X:PBD	; Reset power control board
	BCLR	#PWRST,X:PBD

;  Set up the bias voltage DACs and clock drivers on the analog boards
	MOVE	X:<TIMING,A
	MOVE	A,X:(R3)+       ; Header ID from Utility to timing
	MOVE	Y:<IDL,A
	MOVE	A,X:(R3)+       ; Start up the clock drivers
	MOVE	#P_ON1,N4	; Set internal jump address after 'DON'
	JMP	<XMT_CHK	; Send out commands to timing board

;  Now ramp up the low voltages (+/- 15V) 
P_ON1	BSET	#LVEN,X:PBD	; Make sure line is high to start with
	REP	#255            ; The power conditioner board wants to
	BCHG    #LVEN,X:PBD	;   see 128 H --> L transitions 
	MOVEP   #2,Y:WR_MUX     ; Select +15V MUX input
        DO      X:<C50000,WT_PON2 ; Wait 60 millisec for settling
        REP	#4
	MOVEP	Y:WATCH,Y0	; Reset watchdog timer
WT_PON2
        MOVEP   Y:STR_ADC,Y0    ; Start A/D conversion - dummy read
        REP     #DLY_AD         ; Wait for the A/D to settle
        CLR     A  X:<CFFF,X0	; This saves some space
        MOVEP   Y:RD_ADC,A1     ; Get the A/D value
        AND     X0,A  Y:<T_P15,X0 ; A/D is only valid to 12 bits

; Test that the voltage is in the range abs(initial - target) < margin
        SUB     X0,A  A1,Y:<I_P15
        ABS     A  Y:<K_P15,X0
        SUB     X0,A
        JGT     <PERR           ; Take corrective action

TST_M15 MOVEP   #3,Y:WR_MUX     ; Select -15v MUX input
        REP     #DLY_MUX        ; Wait for the MUX to settle
        NOP
        MOVEP   Y:STR_ADC,Y0    ; Start A/D conversion - dummy read
        REP     #DLY_AD         ; Wait for the A/D to settle
        CLR     A  X:<CFFF,X0	; Clear A, so put it in REP argument
        MOVEP   Y:RD_ADC,A1     ; Get the A/D value
        AND     X0,A  Y:<T_M15,X0 ; A/D is only valid to 12 bits

; Test that the voltage is in the range abs(initial - target) < margin
        SUB     X0,A  A1,Y:<I_M15
        ABS     A  Y:<K_M15,X0
        SUB     X0,A
        JGT     <PERR

;  Now turn on the high voltage HV (nominally +36 volts)
HV_ON	BSET	#HVEN,X:PBD	; Make sure line is high to start with
	REP	#255            ; The power conditioner board wants to
	BCHG    #HVEN,X:PBD	;   see 128 H --> L transitions
	MOVEP   #1,Y:WR_MUX     ; Select high voltage MUX input
	DO      X:<C50000,WT_HV ; Wait 5 millisec for settling
	NOP
WT_HV
	MOVEP   Y:STR_ADC,Y0    ; Start A/D conversion - dummy read
	REP     #DLY_AD         ; Wait for the A/D to settle
	CLR     A  X:<CFFF,X0	; Clear A, so put it in REP argument
	MOVEP   Y:RD_ADC,A1     ; Get the A/D value
	AND     X0,A  Y:<T_HV,X0 ; A/D is only valid to 12 bits

; Test that the voltage is in the range abs(initial - target) < margin
	SUB     X0,A  A1,Y:<I_HV
	ABS     A  Y:<K_HV,X0
	SUB     X0,A
	JGT     <PERR           ; Take corrective action

; Command the timing board to turn on the analog board DC bias voltages
	MOVE	X:<TIMING,A
	MOVE	A,X:(R3)+       ; Header ID from Utility to timing
	MOVE	Y:<SBV,A
	MOVE	A,X:(R3)+       ; Set bias voltages
	MOVE	#P_ON2,N4	; Set internal jump address after 'DON'
	JMP	<XMT_CHK	; Send out commands to timing board

; Command the timing board to reset the analog board A/D converter(s)
P_ON2	MOVE	X:<TIMING,A
	MOVE	A,X:(R3)+       ; Header ID from Utility to timing
	MOVE	Y:<RAD,A
	MOVE	A,X:(R3)+       ; Set bias voltages
	MOVE	#P_ON3,N4	; Set internal jump address after 'DON'
	JMP	<XMT_CHK	; Send out commands to timing board

;  Reply with a nice DONE message to the host computer
P_ON3	MOVE    X:<HOST,A
	MOVE    A,X:(R3)+       ; Header ID to host
	MOVE    X:<DON,A
	MOVE    A,X:(R3)+       ; Power is now ON
	JMP     <XMT_CHK	; Go transmit reply

;  Or, return with an error message
PERR	MOVE    X:<HOST,A
	MOVE    A,X:(R3)+       ; Header ID to host
	MOVE    X:<ERR,A
        MOVE    A,X:(R3)+	; Power is ON
	JMP     <XMT_CHK	; Go transmit reply

; Power off
P_OFF	BSET	#PWRST,X:PBD	; Reset power control board
	BCLR	#PWRST,X:PBD
	JMP	<FINISH		; Reply 'DON'

; Reset the timing board
SYSRST	BCLR    #SYS_RST,X:PBD
	REP     #200            ; Circuit stabilization delay > 50T
	NOP
	BSET    #SYS_RST,X:PBD
	MOVE	#50000,A	; Delay 10 millisec for timing board
	DO	A,DLY_RST	;   to reset
	NOP
	NOP
DLY_RST
	JMP     <FINISH		; Reply 'DON'

; Start an exposure
; Modified for AzCam and V1.7
STRT_EX
;	BSET	#OPT_RDC,X:<OPTIONS	; starts readout in SERVICE when timer done
; this should be done optionally in azcam

;	MOVE	X:<TIMING,A
;	MOVE	A,X:(R3)+       ; Header ID from Utility to timing
;	MOVE	Y:<CLR,A
;	MOVE	A,X:(R3)+       ; Clear the CCD
;	MOVE	#DONECLR,N4	; Set internal jump address after 'DON'
;	JMP	<XMT_CHK	; Transmit these

; Come to here after timing board has signaled that CLEAR is done
; set shutter and load exposure time
DONECLR
	JSSET   #OPT_SH,X:<OPTIONS,OSHUT ; Open shutter if needed
	BSET    #ST_EX,X:<STATUS ; Set for exposure in progress
	CLR     A
	MOVE	A,Y:<EL_TIM     ; Initialize elapsed time

; issue IIA to init PCI card for readout
;	MOVE	#$030102,A
	MOVE	X:<VME,A
	MOVE	A,X:(R3)+
	MOVE	#'IIA',A	; Rev. 1.7 
	MOVE	A,X:(R3)+
	JMP	<XMT_CHK	; Issue IIA and send DON to host

PAUSE   BCLR    #ST_EX,X:<STATUS ; Take out of exposing mode
        JSSET   #OPT_SH,X:<OPTIONS,CSHUT ; Close shutter if needed
        JMP     <FINISH		; Issue 'DON' and get next command

RESUME	BSET    #ST_EX,X:<STATUS ; Put in exposing mode
	JSSET   #OPT_SH,X:<OPTIONS,OSHUT ; Open shutter if needed
        JMP     <FINISH		; Issue 'DON' and get next command

ABORT	BCLR    #ST_EX,X:<STATUS ; Take out of exposing mode
	MOVE    X:<TIMING,A
	MOVE    A,X:(R3)+       ; Header ID from Utility to timing
	MOVE    Y:<IDL,A
	MOVE    A,X:(R3)+       ; Put timing board in IDLE mode
	MOVE    X:<VME,A
	MOVE    A,X:(R3)+       ; Header ID to VME interface
	MOVE    Y:<ABR,A
	MOVE    A,X:(R3)+       ; Abort readout
	JSR     <CSHUT          ; To be sure
	JMP     <FINISH		; Issue 'DON' and get next command

;  A 'DON' reply has been received in response to a command issued by
;    the Utility board. Read the X:STATUS bits in responding to it.

;  Test if an internal program jump is needed fter receiving a 'DON' reply
PR_DONE	MOVE	N4,R0		; Get internal jump address
	MOVE	#<START,N4	; Set internal jump address to default
	JMP	(R0)		; Jump to the internal jump address

;  Check for program overflow - its hard to overflow since this application
;   can be very large indeed
	IF	@CVS(N,*)>APL_XY
        WARN    'Application P: overflow!'	; Make sure next application
	ENDIF					;  will not be overwritten

;  Command table resident in X: data memory
;  The last part of the command table is not defined for "bootrom"
;     because it contains application-specific commands
	
	IF	DOWNLOAD 	; Memory offsets for downloading code
	ORG	X:COM_TBL,X:COM_TBL
	ELSE			; Memory offsets for generating EEPROMs
        ORG     P:COM_TBL,P:APL_NUM*$300+$1D00+($200-APL_ADR)
	ENDIF
	DC	'PON',P_ON	; Power ON
	DC      'POF',P_OFF	; Power OFF
	DC	'SEX',STRT_EX	; Start exposure
	DC	'PEX',PAUSE	; Pause exposure
	DC	'REX',RESUME	; Resume exposure
	DC	'AEX',ABORT	; Abort exposure
	DC	'OSH',OPEN	; Open shutter
	DC	'CSH',CLOSE	; Close shutter
	DC	'SYR',SYSRST	; Reset system, that is, timing board
	DC      'DON',PR_DONE	; Process DON reply
	DC      'RDC',RDCCD
	DC      'TST',FINISH	; Test to see if we are loaded
	DC	0,START,0,START
	DC	0,START,0,START

; Y: parameter table definitions, containing no "bootrom" definitions
	IF	DOWNLOAD
	ORG	Y:0,Y:0		; Download address
	ELSE
        ORG     Y:0,P:		; EEPROM address continues from P: above
	ENDIF
DIG_IN  DC      0       ; Values of 16 digital input lines
DIG_OUT DC      0       ; Values of 16 digital output lines
DAC0    DC      0       ; Table of four DAC values to be output
DAC1    DC      1000               
DAC2    DC      2000            
DAC3    DC      3000            
NUM_AD  DC      16      ; Number of inputs to A/D converter
AD_IN   DC      0,0,0,0,0,0,0,0
        DC      0,0,0,0,0,0,0,0 ; Table of 16 A/D values
EL_TIM  DC      0       ; Number of milliseconds elapsed
TGT_TIM DC      6000    ; Number of milliseconds desired in exposure
U_CCDT  DC      $C20    ; Upper range of CCD temperature control loop
L_CCDT  DC      $C50    ; Lower range of CCD temperature control loop
K_CCDT  DC      85      ; Constant of proportionality for CCDT control
A_CCDT  EQU     AD_IN+5 ; Address of CCD temperature in A/D table
T_CCDT	DC	$0FFF	; Target CCD T for small increment algorithmn
T_COEFF	DC	$010000	; Coefficient for difference in temperatures
DAC0_LS	DC	0	; Least significant part of heater voltage

; Define power supply turn-on variables
T_HV	DC      $388    ; Target HV supply voltage
K_HV	DC      $248    ; Tolerance of HV supply voltage = LARGE
T_P15   DC      $580    ; Target +15 volts supply voltage
K_P15   DC      $80     ; Tolerance of +15 volts supply voltage = 0.5v
T_M15   DC      $A60    ; Target -15 volts supply voltage
K_M15   DC      $80     ; Tolerance of -15 volts supply voltage
I_HV	DC      0       ; Initial value of HV
I_P15   DC      0       ; Initial value of +15 volts
I_M15   DC      0       ; Initial value of -15 volts

; Define some command names
CLR     DC      'CLR'   ; Clear CCD
RDC     DC      'RDC'   ; Readout CCD
ABR     DC      'ABR'   ; Abort readout
OSH     DC      'OSH'   ; Open shutter connected to timing board
CSH     DC      'CSH'   ; Close shutter connected to timing board
POK     DC      'POK'   ; Message to host - power in OK
PER     DC      'PER'   ; Message to host - ERROR in power up sequence
SBV	DC	'SBV'	; Message to timing - set bias voltages
IDL	DC	'IDL'	; Message to timing - put camera in idle mode
RAD	DC	'RAD'	; Message to timing - reset A/D

; Miscellaneous
L_ADDR	DC	$200	; Last address written to EEPROM
AD_MASK	DC	$FFFFC0	; Mask for A6 - A15
SEX_ID	DC	0	; Header ID for reply to SEX command
C825	DC	$825
SV_A1	DC	0	; Save register A1 during analog processing
SV_SR	DC	0	; Save status register during timer processing
	DC	0	; pad (used by gen 2)
	DC	0
	DC	0
	DC	0

; During the downloading of this application program the one millisecond 
;   timer interrupts are enabled, so the utility board will attempt to execute 
;   the partially downloaded TIMER routine, and crash. A workaround is to 
;   put a RTI as the first instruction of TIMER so it doesn't execute, then 
;   write the correct instruction only after all the rest of the application 
;   program has been downloaded. Here it is - 

	IF	DOWNLOAD
	ORG	P:APL_ADR+1,P:APL_ADR+1
	ELSE
        ORG     P:APL_ADR+1,P:APL_NUM*$300+$1D00+1
	ENDIF
TIMER1	MOVEC	SR,Y:<SV_SR 		; Save Status Register


	ENDSEC		; End of SECTION UTILICE

; End of program
        END 
