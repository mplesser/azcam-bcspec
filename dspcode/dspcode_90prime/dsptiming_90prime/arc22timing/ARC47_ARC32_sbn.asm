; ARC47_ARC32_sbn.asm
; 02Apr10

; ST_GAIN
; SET_BIAS_NUMBER
; SET_VIDEO_OFFSET
; SET_MUX

; Set the video processor gain:   SGN  #GAIN  (0 TO 15)	
ST_GAIN	MOVE	X:(R3)+,A	; Gain value
	MOVE	#$0D0000,X0
	OR	X0,A		; Gain from 0 to $F
	JSR	<XMIT_A_WORD	; Transmit A to TIM-A-STD
	JMP	<FINISH

; Set a particular DAC numbers, for setting DC bias voltages, clock driver  
;   voltages and video processor offset
;
; SBN  #BOARD  ['CLK' or 'VID']  #DAC  voltage
;
;				#BOARD is from 0 to 15
;				#DAC number
;				#voltage is from 0 to 4095
SET_BIAS_NUMBER			; Set bias number
	BSET	#3,X:PCRD	; Turn on the serial clock

	MOVE	X:(R3)+,A	; First argument is board number, 0 to 15
	REP	#20
	LSL	A
	NOP
	MOVE	A,X0		; Board number is in bits #23-20
	MOVE	X0,X1		; MPL save board number for CLK
	MOVE	X:(R3)+,A	; Second argument is 'VID' or 'CLK'
	MOVE	#'VID',Y0
	CMP	Y0,A
	JEQ	<VID_SBN	; go to video board
	MOVE	#'CLK',Y0
	CMP	Y0,A
	JNE	<ERR_SBN

; **********************************************
; clock board SBN from ARC, does not seem to work with ARC48
;	MOVE	X:(R3)+,A	; Third argument is DAC number
;	REP	#14
;	LSL	A
;	OR	X0,A
;	NOP
;	MOVE	A,X0
;	
;	MOVE	X:(R3)+,A	; Fourth argument is voltage value, 0 to $fff
;	MOVE	#$000FFF,Y0	; Mask off just 12 bits to be sure
;	AND	Y0,A
;	OR	X0,A
;	JSR	<XMIT_A_WORD	; Transmit A to TIM-A-STD
;	JSR	<PAL_DLY	; Wait for the number to be sent
;	BCLR	#3,X:PCRD	; Turn off the serial clock
;	JMP	<FINISH
; **********************************************

; MPL - below is for ARC32 clock board with ARC47 video (from older ARC45 code)

; For ARC32 do some trickiness to set the chip select and address bits
	MOVE	X:(R3)+,A	; Third argument is DAC number
	NOP
	MOVE	A1,B
	REP	#14
	LSL	A
	MOVE	#$0E0000,X0
	AND	X0,A
	MOVE	#>7,X0
	AND	X0,B		; Get 3 least significant bits of clock #
	CMP	#0,B
	JNE	<CLK_1
	BSET	#8,A
	JMP	<BD_SET
CLK_1	CMP	#1,B
	JNE	<CLK_2
	BSET	#9,A
	JMP	<BD_SET
CLK_2	CMP	#2,B
	JNE	<CLK_3
	BSET	#10,A
	JMP	<BD_SET
CLK_3	CMP	#3,B
	JNE	<CLK_4
	BSET	#11,A
	JMP	<BD_SET
CLK_4	CMP	#4,B
	JNE	<CLK_5
	BSET	#13,A
	JMP	<BD_SET
CLK_5	CMP	#5,B
	JNE	<CLK_6
	BSET	#14,A
	JMP	<BD_SET
CLK_6	CMP	#6,B
	JNE	<CLK_7
	BSET	#15,A
	JMP	<BD_SET
CLK_7	CMP	#7,B
	JNE	<BD_SET
	BSET	#16,A

BD_SET	OR	X1,A		; Add on the board number
	NOP
	MOVE	A,X0
	MOVE	X:(R3)+,A	; Fourth argument is voltage value, 0 to $fff
	REP	#4
	LSR	A		; Convert 12 bits to 8 bits for ARC32
	MOVE	#>$FF,Y0	; Mask off just 8 bits
	AND	Y0,A
	OR	X0,A
	JSR	<XMIT_A_WORD	; Transmit A to TIM-A-STD
	JSR	<PAL_DLY	; Wait for the number to be sent
	BCLR	#3,X:PCRD	; Turn the serial clock off
	JMP	<FINISH

ERR_SBN	MOVE	X:(R3)+,A	; Read and discard the fourth argument
	BCLR	#3,X:PCRD	; Turn off the serial clock
	JMP	<ERROR

; ARC47 values below

VID_SBN	MOVE	X:(R3)+,A	; Third argument is DAC number
	CMP	#0,A
	JNE	<CMP1V
	MOVE	#$0E0000,A	; Magic number for channel #0, Vod0
	OR	X0,A
	JMP	<SVO_XMT
CMP1V	CMP	#1,A
	JNE	<CMP2V
	MOVE	#$0E0004,A	; Magic number for channel #1, Vrd0
	OR	X0,A
	JMP	<SVO_XMT
CMP2V	CMP	#2,A
	JNE	<CMP3V
	MOVE	#$0E0008,A	; Magic number for channel #2, Vog0
	OR	X0,A
	JMP	<SVO_XMT
CMP3V	CMP	#3,A
	JNE	<CMP4V
	MOVE	#$0E000C,A	; Magic number for channel #3, Vrsv0
	OR	X0,A
	JMP	<SVO_XMT

CMP4V	CMP	#4,A
	JNE	<CMP5V
	MOVE	#$0E0001,A	; Magic number for channel #4, Vod1
	OR	X0,A
	JMP	<SVO_XMT
CMP5V	CMP	#5,A
	JNE	<CMP6V
	MOVE	#$0E0005,A	; Magic number for channel #5, Vrd1
	OR	X0,A
	JMP	<SVO_XMT
CMP6V	CMP	#6,A
	JNE	<CMP7V
	MOVE	#$0E0009,A	; Magic number for channel #6, Vog1
	OR	X0,A
	JMP	<SVO_XMT
CMP7V	CMP	#7,A
	JNE	<CMP8V
	MOVE	#$0E000D,A	; Magic number for channel #7, Vrsv1
	OR	X0,A
	JMP	<SVO_XMT

CMP8V	CMP	#8,A
	JNE	<CMP9V
	MOVE	#$0E0002,A	; Magic number for channel #8, Vod2
	OR	X0,A
	JMP	<SVO_XMT
CMP9V	CMP	#9,A
	JNE	<CMP10V
	MOVE	#$0E0006,A	; Magic number for channel #9, Vrd2
	OR	X0,A
	JMP	<SVO_XMT
CMP10V	CMP	#10,A
	JNE	<CMP11V
	MOVE	#$0E000A,A	; Magic number for channel #10, Vog2
	OR	X0,A
	JMP	<SVO_XMT
CMP11V	CMP	#11,A
	JNE	<CMP12V
	MOVE	#$0E000E,A	; Magic number for channel #11, Vrsv2
	OR	X0,A
	JMP	<SVO_XMT
	
CMP12V	CMP	#12,A
	JNE	<CMP13V
	MOVE	#$0E0003,A	; Magic number for channel #12, Vod3
	OR	X0,A
	JMP	<SVO_XMT
CMP13V	CMP	#13,A
	JNE	<CMP14V
	MOVE	#$0E0007,A	; Magic number for channel #13, Vrd3
	OR	X0,A
	JMP	<SVO_XMT
CMP14V	CMP	#14,A
	JNE	<CMP15V
	MOVE	#$0E000B,A	; Magic number for channel #14, Vog3
	OR	X0,A
	JMP	<SVO_XMT
CMP15V	CMP	#15,A
	JNE	<CMP16V
	MOVE	#$0E000F,A	; Magic number for channel #15, Vrsv3
	OR	X0,A
	JMP	<SVO_XMT
	
CMP16V	CMP	#16,A
	JNE	<CMP17V
	MOVE	#$0E0010,A	; Magic number for channel #16, Vod4
	OR	X0,A
	JMP	<SVO_XMT
CMP17V	CMP	#17,A
	JNE	<CMP18V
	MOVE	#$0E0011,A	; Magic number for channel #17, Vrd4
	OR	X0,A
	JMP	<SVO_XMT
CMP18V	CMP	#18,A
	JNE	<CMP19V
	MOVE	#$0E0012,A	; Magic number for channel #18, Vog4
	OR	X0,A
	JMP	<SVO_XMT
CMP19V	CMP	#19,A
	JNE	<ERR_SV2
	MOVE	#$0E0013,A	; Magic number for channel #19, Vrsv4
	OR	X0,A
	JMP	<SVO_XMT
	

; Set the video offset for the ARC-47 4-channel CCD video board
; SVO  Board  DAC  voltage	Board number is from 0 to 15
;				DAC number from 0 to 7
;				voltage number is from 0 to 16,383 (14 bits)

SET_VIDEO_OFFSET
	BSET	#3,X:PCRD	; Turn on the serial clock
	MOVE	X:(R3)+,A	; First argument is board number, 0 to 15
	TST	A
	JLT	<ERR_SV1
	CMP	#15,A
	JGT	<ERR_SV1
	REP	#20
	LSL	A
	NOP
	MOVE	A,X0		; Board number is in bits #23-20
	MOVE	X:(R3)+,A	; Second argument is the video channel number
	CMP	#0,A
	JNE	<CMP1
	MOVE	#$0E0014,A	; Magic number for channel #0
	OR	X0,A
	JMP	<SVO_XMT
CMP1	CMP	#1,A
	JNE	<CMP2
	MOVE	#$0E0015,A	; Magic number for channel #1
	OR	X0,A
	JMP	<SVO_XMT
CMP2	CMP	#2,A
	JNE	<CMP3
	MOVE	#$0E0016,A	; Magic number for channel #2
	OR	X0,A
	JMP	<SVO_XMT
CMP3	CMP	#3,A
	JNE	<ERR_SV2
	MOVE	#$0E0017,A	; Magic number for channel #3
	OR	X0,A

SVO_XMT	JSR	<XMIT_A_WORD	; Transmit A to TIM-A-STD
	JSR	<PAL_DLY	; Wait for the number to be sent	
	MOVE	X:(R3)+,A	; Forth argument is the DAC voltage number
	TST	A
	JLT	<ERR_SV3	; Voltage number needs to be positive
	CMP	#$3FFF,A	; Voltage number needs to be 14 bits
	JGT	<ERR_SV3
	OR	X0,A
	OR	#$0FC000,A
	JSR	<XMIT_A_WORD	; Transmit A to TIM-A-STD
	JSR	<PAL_DLY
	BCLR	#3,X:PCRD	; Turn off the serial clock
	JMP	<FINISH	
ERR_SV1	BCLR	#3,X:PCRD	; Turn off the serial clock
	MOVE	X:(R3)+,A
	MOVE	X:(R3)+,A
	JMP	<ERROR
ERR_SV2	BCLR	#3,X:PCRD	; Turn off the serial clock
	MOVE	X:(R3)+,A
	JMP	<ERROR
ERR_SV3	BCLR	#3,X:PCRD	; Turn off the serial clock
	JMP	<ERROR
		
; Specify the MUX value to be output on the clock driver board
; Command syntax is  SMX  #clock_driver_board #MUX1 #MUX2
;				#clock_driver_board from 0 to 15
;				#MUX1, #MUX2 from 0 to 23

SET_MUX	MOVE	X:(R3)+,A	; Clock driver board number
	REP	#20
	LSL	A
	MOVE	#$003000,X0
	OR	X0,A
	NOP
	MOVE	A,X1		; Move here for storage

; Get the first MUX number
	MOVE	X:(R3)+,A	; Get the first MUX number
	JLT	ERR_SM1
	MOVE	#>24,X0		; Check for argument less than 32
	CMP	X0,A
	JGE	ERR_SM1
	MOVE	A,B
	MOVE	#>7,X0
	AND	X0,B
	MOVE	#>$18,X0
	AND	X0,A
	JNE	<SMX_1		; Test for 0 <= MUX number <= 7
	BSET	#3,B1
	JMP	<SMX_A
SMX_1	MOVE	#>$08,X0
	CMP	X0,A		; Test for 8 <= MUX number <= 15
	JNE	<SMX_2
	BSET	#4,B1
	JMP	<SMX_A
SMX_2	MOVE	#>$10,X0
	CMP	X0,A		; Test for 16 <= MUX number <= 23
	JNE	<ERR_SM1
	BSET	#5,B1
SMX_A	OR	X1,B1		; Add prefix to MUX numbers
	NOP
	MOVE	B1,Y1

; Add on the second MUX number
	MOVE	X:(R3)+,A	; Get the next MUX number
	JLT	<ERROR
	MOVE	#>24,X0		; Check for argument less than 32
	CMP	X0,A
	JGE	<ERROR
	REP	#6
	LSL	A
	NOP
	MOVE	A,B
	MOVE	#$1C0,X0
	AND	X0,B
	MOVE	#>$600,X0
	AND	X0,A
	JNE	<SMX_3		; Test for 0 <= MUX number <= 7
	BSET	#9,B1
	JMP	<SMX_B
SMX_3	MOVE	#>$200,X0
	CMP	X0,A		; Test for 8 <= MUX number <= 15
	JNE	<SMX_4
	BSET	#10,B1
	JMP	<SMX_B
SMX_4	MOVE	#>$400,X0
	CMP	X0,A		; Test for 16 <= MUX number <= 23
	JNE	<ERROR
	BSET	#11,B1
SMX_B	ADD	Y1,B		; Add prefix to MUX numbers
	NOP
	MOVE	B1,A
	JSR	<XMIT_A_WORD	; Transmit A to TIM-A-STD
	JSR	<PAL_DLY	; Delay for all this to happen
	JMP	<FINISH
ERR_SM1	MOVE	X:(R3)+,A
	JMP	<ERROR







