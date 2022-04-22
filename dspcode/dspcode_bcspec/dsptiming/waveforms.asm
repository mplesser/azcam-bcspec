; waveforms.asm for STA0510A BCSpec
; Gen1 controller
; 10Aug11 last change MPL

; *** timing delays ***
P_DELAY		EQU	6000	; parallel clock delay nsecs (min 50)
S_DELAY		EQU	100	; S clock delay nsec (min 50)
DWELL		EQU	8000	; integration nsec (min 50)
PARMULT		EQU	4	; parallel delay multiplier

; *** clock rails ***
RG_HI		EQU	 +6.0	; Reset Gate
RG_LO		EQU	 -0.0
S_HI		EQU	 +4.0	; Serial clocks
S_LO		EQU	 -4.0
SW_HI		EQU	 +3.0	; Summing Well
SW_LO		EQU	 -3.0
P_HI		EQU	 +0.0	; Parallel clock phases 1 & 2
P_LO		EQU	 -8.0   ; 
PMPP_HI		EQU	 +1.0	; MPP phase
PMPP_LO		EQU	 -6.5   ; 
TG_HI		EQU	 +2.0	; Transfer gate
TG_LO		EQU	 -5.0

; *** bias voltages ***
VOD		EQU	+24.0	; Vod, originally 24
VRD		EQU	+13.5	; Vrd, originally 13.5
VOG		EQU	  0.0	; Vog
VB5		EQU	  0.0	; Bias5
VB6		EQU	  0.0	; Bias6
VB7		EQU	  0.0	; Bias7

; *** video processor offset ***
VOFFSET		EQU	 0.28  ; larger reduces bias

; *** clock rail aliases ***
S1_HI		EQU	S_HI
S1_LO		EQU	S_LO
S2_HI		EQU	S_HI
S2_LO		EQU	S_LO
S3_HI		EQU	S_HI
S3_LO		EQU	S_LO

P1_HI		EQU	P_HI
P1_LO		EQU	P_LO	
P2_HI		EQU	P_HI
P2_LO		EQU	P_LO
	IF	MPP
P3_HI		EQU	PMPP_HI
P3_LO		EQU	PMPP_LO
	ELSE
P3_HI		EQU	P_HI
P3_LO		EQU	P_LO
	ENDIF	
Q1_HI		EQU	P_HI
Q1_LO		EQU	P_LO	
Q2_HI		EQU	P_HI
Q2_LO		EQU	P_LO
	IF	MPP
Q3_HI		EQU	PMPP_HI
Q3_LO		EQU	PMPP_LO
	ELSE
Q3_HI		EQU	P_HI
Q3_LO		EQU	P_LO
	ENDIF

; *** set waveforms for each amp below ***
; both serial registers are 3-2-1-w to active amp

; ITL test lab in Kovar tub
; amp 3 U, 123t, 321w 
; amp 1 L, 321t, 321w

; 123t, 123w, not connected
; 321t, 123w, not connected 

	DEFINE	SHIFTLR_PAR_NORM	'p_12_321t.asm'     ; BCSpec
	DEFINE	SHIFTLR_PAR_MPP		'p_12_321t_mpp.asm'

;	DEFINE	SHIFTLR_PAR_NORM	'p_12_123t.asm'
;	DEFINE	SHIFTLR_PAR_MPP		'p_12_123t_mpp.asm'

	DEFINE	SHIFTLR_SER		's_2_321w.asm'


; *** end of waveform.asm ***
