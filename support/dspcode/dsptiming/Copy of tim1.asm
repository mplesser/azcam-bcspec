       COMMENT *

This file is used to generate DSP code for the Gen 1 timing board.

-d DOWNLOAD 1	To generate code for downloading to DSP memory.
-d DOWNLOAD 0	To generate code for writing to the EEPROM.

Modified for AzCam and PCI interface
02Jan05 Last change MPL
	*

	PAGE    132     ; page width - 132 columns

; Define a section name so it doesn't conflict with other application programs
	SECTION	TIMAZCAM

; These are also defined in "timboot.asm", so be sure they agree
APL_NUM	EQU	1			; Application number from 1 to 10
APL_ADR	EQU	$E8			; P: memory location where application code begins
APL_LEN	EQU	$200-APL_ADR	; Maximum length of application program
COM_TBL	EQU	$C0			; Starting address of command table in X: memory

;  Define other useful constants
DACTIME	EQU	4		; Time to load the DC bias DACs
INV		EQU	255		; Because DAC's now invert

;  Define various hardware selection codes
CCD		EQU	$000000	; Select CCD clock drivers
DELAY		EQU	$010000	; Delay time byte
VP		EQU	$00F000	; Video Processor timing instructions
LATCH		EQU	$00F100	; Addressable latch
PULSE2	EQU	$00F200	; Pulse 2
BIASSEL	EQU	$000C00	; Select bias voltage DAC to update
BIASDAT	EQU	$000D00	; Set bias voltage

; Board status bits, defined at X:<STATUS = X:0
ST_RDC	EQU	4		; Set if executing 'RDC' command - reading out

;**************************************************************************
;                   	                                                  *
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

;  Specify execution and load addresses
	IF	DOWNLOAD
	ORG	P:APL_ADR,P:APL_ADR		; Download address
	ELSE
	ORG     P:APL_ADR,P:(2*APL_NUM-1)*$100	; EEPROM generation
	ENDIF

IDLE	JMP	<IDLE0

; Set software to IDLE mode
IDL     BSET    #IDLING,X:<STATUS
	JMP     <FINISH		; Need to send header ID and 'DON'

; Come to here on a 'STP' command so 'DON' can be sent
STP     BCLR    #IDLING,X:<STATUS
	JMP     <FINISH

;  Set bias voltages; assert LATCH6 to signal same
SETBIAS MOVE    Y:<ADACS,R0
	JSR     <CLOCK
	JMP     <FINISH 	; Send 'DON' message, then RCV

;HIGAIN  MOVE    Y:<HIGN,A
HIGAIN  MOVE    #$00F101,A
	MOVE    A,X:(R6)	; Set LATCH bit 0 to high gain
	JMP     <FINISH 	; Send 'DON' message, then RCV

;LOWGAIN MOVE    Y:<LOGN,A
LOWGAIN MOVE    #$00F100,A
	MOVE    A,X:(R6)	; Set LATCH bit 0 to low gain
	JMP     <FINISH 	; Send 'DON' message, then RCV

;  Operate the shutter - Shutter commands are included here for
;     backwards compatability with systems that do not have a
;     utility board.
;OSHUT   MOVE    Y:<SHUT_O,A     ; Open the shutter
OSHUT   MOVE    #$00F102,A     ; Open the shutter
	MOVE    A,X:(R6)
	JMP     <FINISH

;CSHUT   MOVE    Y:<SHUT_C,A     ; Close the shutter
CSHUT   MOVE    #$00F103,A     ; Close the shutter
	MOVE    A,X:(R6)
	JMP     <FINISH

; Reset and calibrate the A/D converter
;RAD	MOVE    Y:<RAD_K1,Y0    ; A/D reset low = active, delay
RAD	MOVE    #$FAF04C,Y0    ; A/D reset low = active, delay
	MOVE    Y0,X:(R6)
;        DO      Y:CDLY,DLY      ; Delay 1.5 seconds
        DO      #600,DLY2
        DO      #100,DLY        ; Delay 1.5 seconds
        MOVE    Y0,X:(R6)       ; Activate 10 microsec hardware delay
        MOVE    Y0,X:(R6)       ; Just a nop so delay counter is activated
DLY
	NOP
DLY2
;	MOVE    Y:<RAD_K2,Y0    ; Raise reset      
	MOVE    #$FAF04D,Y0    ; Raise reset      
	MOVE    Y0,X:(R6)
        JMP     <FINISH		; Send 'DON' reply

; Keep the CCD idling when not reading out
IDLE0
	MOVE	Y:<AFPXFER0,R0
	JSR	<CLOCK
	MOVE    #<IDLEONE,R0
        JSR     <PQSKIP
	JNE     <RCV_ID		; Go process header and command
	MOVE	Y:<AFPXFER2,R0
	JSR	<CLOCK
        MOVE    #<NSCLEAR,R0
	JSR	<FSSKIP

	JMP     <IDLE0

; Fast clear image before each exposure
CLEAR
	MOVE	Y:<ACLEAR0,R0
	JSR	<CLOCK
	MOVE	Y:<AFPXFER0,R0
	JSR	<CLOCK
	MOVE    #<NPCLEAR,R0
	JSR     <PQSKIP
	JNE	<START
	MOVE	Y:<AFPXFER2,R0
	JSR	<CLOCK
	MOVE    #<NSCLEAR,R0
	JSR	<FSSKIP
	MOVE	Y:<ACLEAR2,R0
	JSR	<CLOCK

	BCLR	#ST_RDC,X:<STATUS 		; No longer reading out MPL
	BCLR	#IDLMODE,X:<STATUS
	JCLR	#IDLING,X:<STATUS,FINISH

; Insure that idling resumes after readout but not during the exposure
	BSET	#IDLMODE,X:<STATUS ; Idle after readout
	BCLR    #IDLING,X:<STATUS ; Don't idle during exposure
	JMP     <FINISH 

; Reverse Vertical Shift
;RVXFER
;	MOVE	#<NPXSHIFT,R0
;	JSR	<RSKIP
;	JMP	<FINISH

; Alert the PCI interface board that images are coming soon
PCI_READ_IMAGE

;MPL 08Nov05				; add RDI command
	MOVE	#$020102,X0		; Send header word to the FO transmitter
	JSR	<XMT_FO
	MOVE	#'RDI',X0		; set PCI card to reading out mode
	JSR	<XMT_FO

	MOVE	#$020104,X0		; Command to PCI board
	JSR	<XMT_FO
	MOVE	#'RDA',X0
	JSR	<XMT_FO
	MOVE	Y:<NSIMAGE,X0		; Number of columns to read
	JSR	<XMT_FO
	MOVE	Y:<NPIMAGE,X0
	JSR	<XMT_FO
	RTS
; Transmit data on fiber
XMT_FO	MOVE	X0,Y:(R6)
	REP	#30			; Delay a bit for the transmission
	NOP
	RTS
                             
;  *** readout code ***

RDCCD	BSET	#ST_RDC,X:<STATUS 	; Set status to reading out
	JSR	<PCI_READ_IMAGE		; Wake up the PCI interface board

	MOVE	Y:<AFPXFER0,R0
	JSR	<CLOCK
	MOVE	#<FRAMET,R0
	JSR	<PQSKIP
	JNE	<START

	MOVE	#<NPPRESKIP,R0
	JSR	<PSKIP
	JNE	<START
	MOVE	Y:<AFPXFER2,R0
	JSR	<CLOCK

	MOVE	#<NSCLEAR,R0
	JSR	<FSSKIP

	MOVE	#<NPUNDERSCAN,R0
	JSR	<PDATA
	JNE	<START

	MOVE	Y:<AFPXFER0,R0
	JSR	<CLOCK
	MOVE	#<NPSKIP,R0
	JSR	<PSKIP
	JNE	<START
	MOVE	Y:<AFPXFER2,R0
	JSR	<CLOCK

	MOVE	#<NSCLEAR,R0
	JSR	<FSSKIP

	MOVE	#<NPDATA,R0		; data
	JSR	<PDATA
	JNE	<START

	MOVE	Y:<AFPXFER0,R0
	JSR	<CLOCK
	MOVE	#<NPPOSTSKIP,R0
	JSR	<PSKIP
	JNE	<START
	MOVE	Y:<AFPXFER2,R0
	JSR	<CLOCK

	MOVE	#<NSCLEAR,R0
	JSR	<FSSKIP

	MOVE	#<NPOVERSCAN,R0
	JSR	<PDATA
	JNE	<START

	JCLR	#IDLMODE,X:<STATUS,START	; Don't idle after readout
	BSET	#IDLING,X:<STATUS			; Idle after readout
 	JMP	<START				; Wait for a new command

PDATA
	MOVE	Y:(R0),A
	TST	A
	JLE	<PDATA0
	DO	Y:(R0),PDATA0
	MOVE	#<NPBIN,R0
	JSR	<PDSKIP
	JEQ	<PDATA1
	ENDDO
	JMP	<PDATA0
PDATA1
	MOVE	#<NSPRESKIP,R0
	JSR	<SSKIP
	MOVE	#<NSUNDERSCAN,R0
	JSR	<SDATA
	MOVE	#<NSSKIP,R0
	JSR	<SSKIP
	MOVE	#<NSDATA,R0
	JSR	<SDATA
	MOVE	#<NSPOSTSKIP,R0
	JSR	<SSKIP
	MOVE	#<NSOVERSCAN,R0
	JSR	<SDATA
	CLR	A			; set CC
PDATA0
	NOP
	RTS

PDSKIP
	MOVE	Y:(R0),A
	TST	A
	JLE	<PDSKIP0
	DO	Y:(R0),PDSKIP0
	MOVE	Y:<APDXFER,R0
	JSR	<PCLOCK
	JSR	<RCV_TST
	JEQ	<PDSKIP1
	ENDDO
PDSKIP1
	NOP
PDSKIP0
	NOP
	RTS

PSKIP
	MOVE	Y:(R0),A
	TST	A
	JLE	<PSKIP0
	DO	Y:(R0),PSKIP0
	MOVE	Y:<APXFER,R0
	JSR	<PCLOCK
	JSR	<RCV_TST
	JEQ	<PSKIP1
	ENDDO
PSKIP1
	NOP
PSKIP0
	NOP
	RTS

PQSKIP
	MOVE	Y:(R0),A
	TST	A
	JLE	<PQSKIP0
	DO	Y:(R0),PQSKIP0
	MOVE	Y:<APQXFER,R0
	JSR	<PCLOCK
	JSR	<RCV_TST
	JEQ	<PQSKIP1
	ENDDO
PQSKIP1
	NOP
PQSKIP0
	NOP
	RTS

RSKIP
	MOVE	Y:(R0),A
	TST	A
	JLE	<RSKIP0
	DO	Y:(R0),RSKIP0
	MOVE	Y:<ARXFER,R0
	JSR	<PCLOCK
	JSR	<RCV_TST
	JEQ	<RSKIP1
	ENDDO
RSKIP1
	NOP
RSKIP0
	NOP
	RTS

FSSKIP
	MOVE	Y:(R0),A
	TST	A
	JLE	<FSSKIP0
	DO	Y:(R0),FSSKIP0
	MOVE	Y:<AFSXFER,R0
	JSR	<CLOCK
	NOP
FSSKIP0
	NOP
	RTS

SSKIP
	MOVE	Y:(R0),A
	TST	A
	JLE	<SSKIP0
	DO	Y:(R0),SSKIP0
	MOVE	Y:<ASXFER0,R0
	JSR	<CLOCK
	MOVE	Y:<ASXFER2,R0
	JSR	<CLOCK
	NOP
SSKIP0
	NOP
	RTS

SDATA
	MOVE	Y:(R0),A
	TST	A
	JLE	<SDATA0
	DO	Y:(R0),SDATA0
	MOVE	Y:<ASXFER0,R0
	JSR	<CLOCK
	MOVE	X:<ONE,X0	; Get bin-1
	MOVE	Y:<NSBIN,A	;
	SUB	X0,A		;
	JLE	<SDATA1		;
	DO	A,SDATA1
	MOVE	Y:<ASXFER1,R0
	JSR	<CLOCK
	NOP
SDATA1
	MOVE	Y:<ASXFER2D,R0
	JSR	<CLOCK
; Read pixel datum from the A/D and send it along the serial transmitter
	MOVE    X:(R6),A        ; Get the A/D converter counts from #0 A/D
 	MOVE    A,Y:(R6)        ; Send them to the serial transmitter
SDATA0
	NOP
	RTS

; *******************************************************************
FOR_PSHIFT
	MOVE	#<NPXSHIFT,R0
	JSR	<PSKIP
	JMP	<FINISH

; *******************************************************************
REV_PSHIFT
	MOVE	#<NPXSHIFT,R0
	JSR	<RSKIP
	JMP	<FINISH

; *******************************************************************
;  This is the core subroutine for clocking out CCD charge
CLOCK
	MOVE    Y:(R0)+,X0      ; # of waveform entries 
	MOVE    Y:(R0)+,A       ; Start the pipeline
	DO      X0,CLK1                 ; Repeat X0 times
	MOVE    A,X:(R6) Y:(R0)+,A      ; Send out the waveform
CLK1
	MOVE    A,X:(R6)        ; Flush out the pipeline
	RTS                     ; Return from subroutine

; *******************************************************************
;  Slow clock for parallel shifts
PCLOCK	MOVE	Y:(R0)+,A	; # of waveform entries
	MOVE	X:<ONE,X0	; Add 1 - no pipeline prime
	ADD	X0,A
	DO	A,PCLK1
	MOVE	Y:(R0)+,A	; Get the waveform
	DO	Y:<PMULT,PCLK2
	MOVE	A,X:(R6)	; Send out the waveform
PCLK2
	NOP
PCLK1
	RTS                     ; Return from subroutine

; Check for program overflow
	IF	@CVS(N,*)>=$200
		WARN    'Application P: program is too large!'	; Make sure program
	ENDIF				;  will not overflow

; *** Macros ***

INTNOISE	MACRO
	; integrate noise
	DC      VP+002*DELAY+%00011001		; Start A/D
	DC      VP+000*DELAY+%00011101		; Continue A/D
	DC      VP+010*DELAY+%10010101		; Integrator Reset, latch data
	DC      VP+010*DELAY+%01010101		; DC Restore
	DC      VP+010*DELAY+%01011101		; End of Integrator Reset
	DC      VP+DWEL*DELAY+%01001101		; Start Integrate
	DC      VP+010*DELAY+%01011101		; Stop Integrate
	ENDM

INTSIGNAL	MACRO
	; integrate signal
	DC      VP+008*DELAY+%01111101	; Change Polarity
	DC      VP+DWEL*DELAY+%01101101	; Start Integrate
	DC      VP+004*DELAY+%01111101	; Stop Integrate
	DC      PULSE2				; Synchronize CK8
	DC      VP+%00011111			; Start Coarse Sample, Etc.
	ENDM

; *** Data areas ***

;  Command table
	IF	DOWNLOAD		; Memory offsets for downloading code
		ORG	X:COM_TBL,X:COM_TBL
	ELSE				; Memory offsets for generating EEPROMs
		ORG     P:COM_TBL,P:(2*APL_NUM-1)*$100+APL_LEN
	ENDIF

	DC	'IDL',IDL		; Put CCD in IDLE mode    
	DC	'STP',STP		; Exit IDLE mode
	DC	'SBV',SETBIAS 	; Set DC bias supply voltages  
	DC	'RDC',RDCCD 	; Begin CCD readout    
	DC	'CLR',CLEAR  	; Fast clear CCD   
	DC	'HGN',HIGAIN  	; Set analog boards to high gain      
	DC	'LGN',LOWGAIN	; Set analog boards to low gain   
	DC	'OSH',OSHUT		; Open shutter
	DC	'CSH',CSHUT		; Close shutter
      DC	'RAD',RAD		; Reset A/D - self-calibration for 1.5 sec
	DC	'DON',START		; Nothing special
	DC	0,START
	DC	'TST',FINISH	; Test to see if we are loaded
	DC	'FPX',FOR_PSHIFT	; Forward parallel shift
	DC	'RPX',REV_PSHIFT	; Reverse parallel shift
	DC	0,START

	IF	DOWNLOAD
		ORG	Y:0,Y:0	; Download address
	ELSE
		ORG     Y:0,P:	; EEPROM address continues from P: above
	ENDIF

; *** include waveform tables and device specific parameters ***
	INCLUDE "waveforms.asm"

; these values are at Y:0 and are overwritten by AzCam
DUMMY		DC	0
NSDATA	DC	2048	
NPDATA	DC	2048
NSBIN		DC	1	
NPBIN		DC	1
		DC	0
		DC	0
NSCLEAR	DC	2134
NPCLEAR	DC	2048
NSPRESKIP	DC	16
NSUNDERSCAN	DC	0
NSSKIP	DC	0
NSPOSTSKIP	DC	50
NSOVERSCAN	DC	20
NPPRESKIP 	DC	0
NPUNDERSCAN	DC	0
NPSKIP	DC	0
NPPOSTSKIP	DC	0
NPOVERSCAN	DC	0
NPXSHIFT	DC	0
		DC	0
FRAMET	DC	0
PREFLASH	DC	0
		DC	0
		DC	0
		DC	0
		DC	0
NSIMAGE	DC	0
NPIMAGE	DC	0
		DC	0
		DC	0
IDLEONE	DC	1

; *** these values are at Y:20 and are addresses ***
PMULT		DC	PARMULT
ACLEAR0	DC	TNOP		; Prepare prologue (biases)
ACLEAR2	DC	TNOP		; Prepare epilogue
AREAD0	DC	TNOP		; not used
AREAD8	DC	TNOP		; not used
AFPXFER0	DC	TNOP		; Fast parallel transfer prologue
AFPXFER2	DC	TNOP		; Fast parallel transfer epilogue
APXFER	DC	PXFER		; Parallel transfer - storage only
APDXFER	DC	PXFER		; Parallel transfer (data) - storage only
APQXFER	DC	PQXFER	; Parallel transfer - storage and image
ARXFER	DC	RXFER		; Reverse parallel transfer (for focus)
AFSXFER	DC	FSXFER	; Fast serial transfer
ASXFER0	DC	SXFER0	; Serial transfer prologue
ASXFER1	DC	SXFER1	; Serial transfer ( * colbin-1 )
ASXFER2	DC	SXFER2	; Serial transfer epilogue - no data
ASXFER2D	DC	SXFER2	; Serial transfer epilogue - data
ADACS		DC	BIAS

;  *** CCD clock select codes ***
RG	EQU	$000000	; Reset gate -10-+16
S1	EQU	$000100	; Serial clock phase 1 (-10:+10)
S2	EQU	$000200	; Serial clock phase 2 (-10:+10)
S3	EQU	$000300	; Serial clock phase 3 (-10:+10)
SW	EQU	$000400	; Output Summing Well (-10:+10)
P1	EQU	$000500	; Parallel clock phase 1 (-10:+10)
P2	EQU	$000600	; Parallel clock phase 2 (-10:+10)
P3	EQU	$000700	; Parallel clock phase 3 (-10:+10)
TG	EQU	$000800	; Transfer gate (-10:+10)
Q1	EQU	$000900	; Q1 (-10:+10)
Q2	EQU	$000A00	; Q2 (-10:+10)
Q3	EQU	$000B00	; Q3 (-10:+10)
OFFSET EQU	INV-1		; Video processor offset (-5:+5)
OD	EQU	INV-2		; Output Drain (0:30)
RD	EQU	INV-4		; Reset Drain (0:20)
B3	EQU	INV-8		; B3 (0:30)
OG	EQU	INV-16	; Output Gate (-5:+5)
B5	EQU	INV-32	; B5 (-10:+10)
B6	EQU	INV-64	; B6 (-10:+10)
B7	EQU	INV-128	; B7 (-10:+10)

; *** change clock decimal voltages to counts ***
RGH	EQU	RG+255-@CVI((RG_HI+10.0)/26.0*255)
RGL	EQU	RG+255-@CVI((RG_LO+10.0)/26.0*255)
S1H	EQU	S1+255-@CVI((S1_HI+10.0)/20.0*255)
S1L	EQU	S1+255-@CVI((S1_LO+10.0)/20.0*255)
S2H	EQU	S2+255-@CVI((S2_HI+10.0)/20.0*255)
S2L	EQU	S2+255-@CVI((S2_LO+10.0)/20.0*255)
S3H	EQU	S3+255-@CVI((S3_HI+10.0)/20.0*255)
S3L	EQU	S3+255-@CVI((S3_LO+10.0)/20.0*255)
SWH	EQU	SW+255-@CVI((SW_HI+10.0)/20.0*255)
SWL	EQU	SW+255-@CVI((SW_LO+10.0)/20.0*255)
P1H	EQU	P1+255-@CVI((P1_HI+10.0)/20.0*255)
P1L	EQU	P1+255-@CVI((P1_LO+10.0)/20.0*255)
P2H	EQU	P2+255-@CVI((P2_HI+10.0)/20.0*255)
P2L	EQU	P2+255-@CVI((P2_LO+10.0)/20.0*255)
P3H	EQU	P3+255-@CVI((P3_HI+10.0)/20.0*255)
P3L	EQU	P3+255-@CVI((P3_LO+10.0)/20.0*255)
TGH	EQU	TG+255-@CVI((TG_HI+10.0)/20.0*255)
TGL	EQU	TG+255-@CVI((TG_LO+10.0)/20.0*255)
Q1H	EQU	Q1+255-@CVI((Q1_HI+10.0)/20.0*255)
Q1L	EQU	Q1+255-@CVI((Q1_LO+10.0)/20.0*255)
Q2H	EQU	Q2+255-@CVI((Q2_HI+10.0)/20.0*255)
Q2L	EQU	Q2+255-@CVI((Q2_LO+10.0)/20.0*255)
Q3H	EQU	Q3+255-@CVI((Q3_HI+10.0)/20.0*255)
Q3L	EQU	Q3+255-@CVI((Q3_LO+10.0)/20.0*255)

; *** change bias decimal voltages to counts ***
VOFFD	EQU	@CVI((VOFFSET+5.0)/10.0*255)
VODD	EQU	@CVI((VOD+00.0)/26.7*255)
VRDD	EQU	@CVI((VRD+00.0)/18.6*255)
VOGD	EQU	@CVI((VOG+05.0)/10.0*255)
VB5D	EQU	@CVI((VB5+10.0)/20.0*255)
VB6D	EQU	@CVI((VB6+10.0)/20.0*255)
VB7D	EQU	@CVI((VB7+10.0)/20.0*255)

; BIAS and CLEAR0 code
BIAS
; Set DC bias supply voltages with DACs 
CLEAR0	DC	ECLEAR0-CLEAR0-2
; Set the bias DACs
; Set the video offset voltage
	DC      CCD+BIASDAT+VOFFD
	DC      CCD+DACTIME*DELAY+BIASSEL+OFFSET
	DC      CCD+BIASSEL+INV
; Set CCD Output Drain voltage Vod
	DC      CCD+BIASDAT+VODD
	DC      CCD+DACTIME*DELAY+BIASSEL+OD
	DC      CCD+BIASSEL+INV
; Set CCD Reset Drain voltage Vrd
	DC      CCD+BIASDAT+VRDD
	DC      CCD+DACTIME*DELAY+BIASSEL+RD
	DC      CCD+BIASSEL+INV
; Set CCD Output Transfer Gate voltage Vog
	DC      CCD+BIASDAT+VOGD
	DC      CCD+DACTIME*DELAY+BIASSEL+OG
	DC      CCD+BIASSEL+INV
; Set B5
	DC      CCD+BIASDAT+VB5D
	DC      CCD+DACTIME*DELAY+BIASSEL+B5
	DC      CCD+BIASSEL+INV
; Set B6
	DC      CCD+BIASDAT+VB6D
	DC      CCD+DACTIME*DELAY+BIASSEL+B6
	DC      CCD+BIASSEL+INV
; Set B7
	DC      CCD+BIASDAT+VB7D
	DC      CCD+DACTIME*DELAY+BIASSEL+B7
	DC      CCD+BIASSEL+INV
ECLEAR0

; *** shorthand for waveforms ***
P_DEL		EQU	@CVI((P_DELAY/50)-1)
S_DEL		EQU	@CVI((S_DELAY/50)-1)
DWEL		EQU	@CVI((DWELL/50)-1)
PCLK		EQU	CCD+P_DEL*DELAY
SCLK		EQU	CCD+S_DEL*DELAY

; *** timing NOP ***
TNOP	DC	ETNOP-TNOP-2
	DC	$000F00
	DC	$000F00
ETNOP

; *** code for generating waveforms ***
	IF	SHIFTLR
PXFER   DC	EPXFER-PXFER-2
	IF 	MPP
	INCLUDE "SHIFTLR_PAR_MPP"
	ELSE
	INCLUDE "SHIFTLR_PAR_NORM"
	ENDIF
EPXFER
	INCLUDE "SHIFTLR_SER"
	ENDIF

	IF	SHIFTLL
PXFER   DC	EPXFER-PXFER-2
	IF 	MPP
	INCLUDE "SHIFTLL_PAR_MPP"
	ELSE
	INCLUDE "SHIFTLL_PAR_NORM"
	ENDIF
EPXFER
	INCLUDE "SHIFTLL_SER"
	ENDIF

	IF	SHIFTUL
PXFER   DC	EPXFER-PXFER-2
	IF 	MPP
	INCLUDE "SHIFTUL_PAR_MPP"
	ELSE
	INCLUDE "SHIFTUL_PAR_NORM"
	ENDIF
EPXFER
	INCLUDE "SHIFTUL_SER"
	ENDIF

	IF	SHIFTUR
PXFER   DC	EPXFER-PXFER-2
	IF 	MPP
	INCLUDE "SHIFTUR_PAR_MPP"
	ELSE
	INCLUDE "SHIFTUR_PAR_NORM"
	ENDIF
EPXFER
	INCLUDE "SHIFTUR_SER"
	ENDIF

; *** reverse par shifting not used ***
RXFER		EQU	PXFER
PQXFER	EQU	PXFER

; Check for overflow in the EEPROM case
	IF !DOWNLOAD
		IF	@CVS(N,@LCV(L))>(2*APL_NUM+1)*$100
			WARN	'EEPROM overflow!'	; Make sure next application
		ENDIF						;  will not be overwritten
	ENDIF

	ENDSEC	; end of TIMAZCAM section

	END		; end of program
