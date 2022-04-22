; STA2900A 90Prime clocking routines
; 03Sep13 MPL

; The direct controller serials operate the left serials
; The right serials are swapped S1-S2 relative to the left

; SW1 and SW3 are tied to SW (lefts)
; SW2 and SW4 are tied to TG (rights)

; Parallel P's are lower
; Parallel Q's are upper

; ***********************************************
;                  parallel
; ***********************************************
; shift into s1+s2

; wired as P1=Q2, P2=Q1, P3=Q3

P1H	EQU	P11H+P12H+P13H+P14H
P1L	EQU	P11L+P12L+P13L+P14L
P2H	EQU	P21H+P22H+P23H+P24H
P2L	EQU	P21L+P22L+P23L+P24L
P3H	EQU	P31H+P32H+P33H+P34H
P3L	EQU	P31L+P32L+P33L+P34L

; forward P (lower), reverse Q (upper) - Normal operation
PFOR	DC	EPFOR-PFOR-1
	DC	VIDEO+%0011000            ; Reset integ. and DC restore
	DC	CLK2+P_DELAY+P1L+P2H+P3L
	DC	CLK2+P_DELAY+P1L+P2H+P3H
	DC	CLK2+P_DELAY+P1L+P2L+P3H
	DC	CLK2+P_DELAY+P1H+P2L+P3H
	DC	CLK2+P_DELAY+P1H+P2L+P3L
	DC	CLK2+P_DELAY+P1H+P2H+P3L  ; last for center rows
EPFOR

; reverse P (lower), forward Q (upper) - Reverse operation
PREV    DC	EPREV-PREV-1
	DC	VIDEO+%0011000            ; Reset integ. and DC restore
	DC	CLK2+P_DELAY+P1H+P2L+P3L
	DC	CLK2+P_DELAY+P1H+P2L+P3H
	DC	CLK2+P_DELAY+P1L+P2L+P3H
	DC	CLK2+P_DELAY+P1L+P2H+P3H
	DC	CLK2+P_DELAY+P1L+P2H+P3L
	DC	CLK2+P_DELAY+P1H+P2H+P3L
EPREV

PXFER	EQU	PFOR
PQXFER	EQU	PXFER
RXFER	EQU	PREV

; ***********************************************
;                  Video
; ***********************************************
 
; ARC47:  |xfer|A/D|integ|polarity|not used|DC restore|rst| (1 => switch open)
;      polarity reversed from RevD to RevE

LATCH	MACRO
		DC	                VIDEO+%0011000	; Reset integ. and DC restore
	ENDM

INTNOISE	MACRO
; CDS integrate on noise
		DC	        VIDEO+$000000+%0011011  ; Stop resetting int
		DC	          VIDEO+DWELL+%0001011	; Integrate noise
		DC	    	VIDEO+$000000+%0011011  ; Stop int
	ENDM

INTSIGNAL	MACRO
; CDS integrate on signal
		DC	        VIDEO+$020000+%0010011	; change polarity
		DC	          VIDEO+DWELL+%0000011	; Integrate signal
		DC	        VIDEO+$030000+%0010011  ; Stop integrate, ADC is sampling
		DC	        VIDEO+$010000+%1110011  ; start A/D conversion
  		DC	        VIDEO+$000000+%0010010  ; End start A/D conv. pulse
	ENDM

; ***********************************************
;                  serial
; ***********************************************

; s2_123w for left
; s1_213w for right
; SW like S1
; TG like S2

RGH	EQU	RG1H+RG2H+RG3H+RG4H
RGL	EQU	RG1L+RG2L+RG3L+RG4L

FPXFER0	DC	EFPXFER0-FPXFER0-1
		DC	CLK3+S_DELAY+RGH+S1H+S2H+S3H+SWLH+SWRH
		DC	CLK3+S_DELAY+RGH+S1H+S2H+S3H+SWLH+SWRH
EFPXFER0

FPXFER2	DC	EFPXFER2-FPXFER2-1
		DC	CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLL+SWRL
		DC	CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLL+SWRL
EFPXFER2

FSXFER	DC	EFSXFER-FSXFER-1
		DC	CLK3+R_DELAY+RGH+S1L+S2H+S3L+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1L+S2H+S3H+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1L+S2L+S3H+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1H+S2L+S3H+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1H+S2L+S3L+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLL+SWRL
EFSXFER

SXFER0	DC	ESXFER0-SXFER0-1
	LATCH
		DC	CLK3+R_DELAY+RGH+S1H+S2H+S3L+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1L+S2H+S3L+SWLH+SWRH
		DC      VIDEO+$000000+%0011000                 ; Reset integrator
		DC	CLK3+S_DELAY+RGL+S1L+S2H+S3H+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1L+S2L+S3H+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1H+S2L+S3H+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1H+S2L+S3L+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLH+SWRH
ESXFER0

SXFER1	DC	ESXFER1-SXFER1-1
		DC	CLK3+S_DELAY+RGL+S1L+S2H+S3L+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1L+S2H+S3H+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1L+S2L+S3H+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1H+S2L+S3H+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1H+S2L+S3L+SWLH+SWRH
		DC	CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLH+SWRH
ESXFER1

SXFER2	DC	ESXFER2-SXFER2-1
	INTNOISE
		DC	CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLL+SWRL
	INTSIGNAL
ESXFER2

SXFER2D	DC	ESXFER2D-SXFER2D-1
		DC	SXMIT
	INTNOISE
		DC	CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLL+SWRL
	INTSIGNAL
ESXFER2D
