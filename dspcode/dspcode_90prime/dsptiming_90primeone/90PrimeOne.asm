; 90PrimeOne.asm
; STA2900 waveform code for 90Prime controller with 4 ARC47 video boards + ARC32 clock
; 25Aug15 last change MPL

; long delays needed for measured capacitance

; *** timing (40 - 5080 ns) ***
SERDEL	EQU	280	    ; S clock delay  - 280 (critical)
RSTDEL	EQU	240	    ; RG clock delay - 320
VIDDEL	EQU	80          ; VP delay       -  80

PARDEL	EQU	5000	    ; P clock delay
PARMULT	EQU	20	    ; 

SAMPLE	EQU	2000	    ; sample time  was 2000

; Gain g = 0 to 14, Gain = 1.00 to 4.75 in steps of 0.25
VGAIN	EQU	1

; Speed $10 to $F0 time constant (first nib)
VSPEED	EQU	$f0

; *** video offsets ***
; ARC47 video offsets - 0 to $3fff video offset value
; about 1 DN/count

OFFSET	EQU	10000
	INCLUDE	"offsets.asm"

; *** bias voltages ***
VOD          EQU     25.0  ; Output Drain 24.0
VRD          EQU     14.5  ; Reset Drain  trails when > 15   14.8
VOG          EQU      0.0  ; Output Gate
VRSV         EQU      2.0  ; RTN lower more gain 2.0
VSCP         EQU     20.0  ; SCP 20

; *** clock voltages ***
RG_HI		EQU	 8.0  ; Reset Gate    8,-2
RG_LO		EQU	-2.0  

S_HI		EQU	+4.0  ; Serial clocks 4,-6	
S_LO		EQU	-6.0  ; important for CCD1 fat "cols"
  
SW_HI		EQU	+4.0  ; Summing Well +-4
SW_LO		EQU	-4.0  

P1HI		EQU	+2.0  ; 10789  2
P1LO		EQU	-8.0  ;       -8

P2HI		EQU	+1.0  ; 10747  1
P2LO		EQU	-8.0  ;       -8

P3HI		EQU	+1.0  ; 10317  1
P3LO		EQU	-7.0  ;       -8

P4HI		EQU	+1.0  ; 10764  1
P4LO		EQU	-8.0  ;       -8

; *** aliases ***
VSCP1		EQU	VSCP
VSCP2		EQU	VSCP
VSCP3		EQU	VSCP
VSCP4		EQU	VSCP

;                                        CHANNEL
VOD1		EQU	VOD     ; im4  - data[0]
VOD2		EQU	VOD     ; im3  - data[1]
VOD3		EQU	VOD     ; im2  - data[2]
VOD4		EQU	VOD     ; im1  - data[3]

VOD5		EQU	VOD     ; im8  - data[4]
VOD6		EQU	VOD+0.5 ; im7  - data[5]
VOD7		EQU	VOD+1.0 ; im6  - data[6] new, was 0.5
VOD8		EQU	VOD     ; im5  - data[7]

VOD9		EQU	VOD     ; im9  - data[8]
VOD10		EQU	VOD     ; im10 - data[9]
VOD11		EQU	VOD     ; im11 - data[10]
VOD12		EQU	VOD     ; im12 - data[12]

VOD13		EQU	VOD     ; im13 - data[12]
VOD14		EQU	VOD     ; im14 - data[13]
VOD15		EQU	VOD+1   ; im15 - data[14] new 03aug15
VOD16		EQU	VOD     ; im16 - data[15] bad

VOG1		EQU	-2.0    ; was -2 this device 
VOG2		EQU	VOG
VOG3		EQU	VOG
VOG4		EQU	VOG

VOG5		EQU	VOG
VOG6		EQU	VOG
VOG7		EQU	VOG
VOG8		EQU	-0.5

VOG9		EQU	VOG
VOG10		EQU	VOG
VOG11		EQU	VOG 
VOG12		EQU	VOG
 
VOG13		EQU	VOG
VOG14		EQU	VOG
VOG15		EQU	 1.5  ; new 03aug15
VOG16		EQU	-0.5  ; new

VRD1		EQU	VRD
VRD2		EQU	VRD
VRD3		EQU	VRD
VRD4		EQU	VRD
VRD5		EQU	VRD
VRD6		EQU	VRD
VRD7		EQU	VRD
VRD8		EQU	VRD
VRD9		EQU	VRD
VRD10		EQU	VRD
VRD11		EQU	VRD
VRD12		EQU	VRD
VRD13		EQU	VRD
VRD14		EQU	VRD
VRD15		EQU	VRD
VRD16		EQU	VRD

VRSV1		EQU	VRSV
VRSV2		EQU	VRSV
VRSV3		EQU	VRSV
VRSV4		EQU	VRSV

VRSV5		EQU	VRSV
VRSV6		EQU	VRSV
VRSV7		EQU	VRSV
VRSV8		EQU	VRSV

VRSV9		EQU	VRSV
VRSV10		EQU	VRSV
VRSV11		EQU	VRSV
VRSV12		EQU	VRSV

VRSV13		EQU	VRSV
VRSV14		EQU	VRSV
VRSV15		EQU	VRSV
VRSV16		EQU	VRSV

; clocks
RG1_HI		EQU	RG_HI
RG1_LO		EQU	RG_LO
RG2_HI		EQU	RG_HI
RG2_LO		EQU	RG_LO
RG3_HI		EQU	RG_HI
RG3_LO		EQU	RG_LO
RG4_HI		EQU	RG_HI
RG4_LO		EQU	RG_LO

SWL_HI		EQU	SW_HI
SWL_LO		EQU	SW_LO
SWR_HI		EQU	SW_HI
SWR_LO		EQU	SW_LO

S1_HI		EQU	S_HI
S1_LO		EQU	S_LO
S2_HI		EQU	S_HI
S2_LO		EQU	S_LO
S3_HI		EQU	S_HI
S3_LO		EQU	S_LO

P11_HI		EQU	P1HI
P11_LO		EQU	P1LO	
P21_HI		EQU	P1HI
P21_LO		EQU	P1LO
P31_HI		EQU	P1HI
P31_LO		EQU	P1LO

P12_HI		EQU	P2HI
P12_LO		EQU	P2LO	
P22_HI		EQU	P2HI
P22_LO		EQU	P2LO
P32_HI		EQU	P2HI
P32_LO		EQU	P2LO

P13_HI		EQU	P3HI
P13_LO		EQU	P3LO	
P23_HI		EQU	P3HI
P23_LO		EQU	P3LO
P33_HI		EQU	P3HI
P33_LO		EQU	P3LO

P14_HI		EQU	P4HI
P14_LO		EQU	P4LO	
P24_HI		EQU	P4HI
P24_LO		EQU	P4LO
P34_HI		EQU	P4HI
P34_LO		EQU	P4LO

; *** configurations ****

	DEFINE	CHANNELS	'0123'
 	DEFINE	CLOCKING	'clocking.asm'
