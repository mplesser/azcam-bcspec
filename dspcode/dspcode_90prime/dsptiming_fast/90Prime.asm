; 90Prime.asm
; STA2900 waveform code for 90Prime controller with 4 ARC47 video boards + ARC32 clock
; 02Sep15 last change MPL

; long delays needed for measured capacitance

; *** timing (40 - 5080 ns) ***
SERDEL	EQU	280	    ; S clock delay  - 280 (critical)
RSTDEL	EQU	280	    ; RG clock delay - 320 (no add 4 ticks) was 80

PARDEL	EQU	5000	    ; P clock delay
PARMULT	EQU	20	    ; 20

SAMPLE	EQU	1000	    ; sample time  was 2000

; Gain g = 0 to 14, Gain = 1.00 to 4.75 in steps of 0.25
VGAIN	EQU	6   ; 2 when slow - 2000

; Speed $c0 to $F0 time constant (first nib)
VSPEED	EQU	$f0  ; $c0 when slow

; *** video offsets ***
; ARC47 video offsets - 0 to $3fff video offset value
; about 1 DN/count

OFFSET	EQU	5000
	INCLUDE	"offsets.asm"

; *** bias voltages ***
VOD          EQU     24.0  ; Output Drain 24.0
VRD          EQU     14.5  ; Reset Drain  trails when > 15   14.5
VOG          EQU     -2.0  ; Output Gate (was 0)
VRSV         EQU      2.5  ; RTN lower more gain 2.0
VSCP         EQU     20.0  ; SCP 20

; *** clock voltages ***
RG_HI		EQU	 8.0  ; Reset Gate    8,-2
RG_LO		EQU	-2.0  

S_HI		EQU	+4.0  ; Serial clocks 4,-6	
S_LO		EQU	-6.0  ; important for CCD1 fat "cols"
  
SW_HI		EQU	+4.0  ; Summing Well +-4
SW_LO		EQU	-4.0  

P1HI		EQU	+1.5  ; 10789  2 but 1.5 better now
P1LO		EQU	-7.0  ;       -8

P2HI		EQU	+1.5  ; 10747  2
P2LO		EQU	-7.0  ;       -8

P3HI		EQU	+1.0  ; 10317  1
P3LO		EQU	-6.5  ;       -7 reduce for edge glow -6.5

P4HI		EQU	+1.0  ; 10764  2
P4LO		EQU	-8.0  ;       -8

; *** aliases ***
VSCP1		EQU	VSCP
VSCP2		EQU	VSCP
VSCP3		EQU	VSCP
VSCP4		EQU	VSCP

;                                        CHANNEL
VOD1		EQU	VOD-1.0   ; im4  - data[0]
VOD2		EQU	VOD-1.0   ; im3  - data[1]
VOD3		EQU	VOD-1.0   ; im2  - data[2]
VOD4		EQU	VOD-1.0   ; im1  - data[3]

VOD5		EQU	VOD+1.0   ; im8  - data[4]
VOD6		EQU	VOD+1.0   ; im7  - data[5]
VOD7		EQU	VOD+1.0   ; im6  - data[6]
VOD8		EQU	VOD+1.0   ; im5  - data[7]

VOD9		EQU	VOD+0.5   ; im9  - data[8]
VOD10		EQU	VOD+0.5   ; im10 - data[9]
VOD11		EQU	VOD+0.5   ; im11 - data[10]
VOD12		EQU	VOD+0.0   ; im12 - data[12]

VOD13		EQU	VOD+0.5   ; im13 - data[12]
VOD14		EQU	VOD+0.5   ; im14 - data[13]
VOD15		EQU	VOD+1.5   ; im15 - data[14] 1.5!
VOD16		EQU	VOD+0.5   ; im16 - data[15]

VOG1		EQU	0 ; VOG
VOG2		EQU	0
VOG3		EQU	0
VOG4		EQU	0

VOG5		EQU	1.5
VOG6		EQU	1.5
VOG7		EQU	1.5
VOG8		EQU	1.5

VOG9		EQU	-2.0 ; VOG
VOG10		EQU	0.0    
VOG11		EQU	0.0 
VOG12		EQU	0.0
 
VOG13		EQU	VOG
VOG14		EQU	VOG
VOG15		EQU     1.5  ; 1.5 !
VOG16		EQU    -0.5

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

	DEFINE	CHANNELS	'16'
 	DEFINE	CLOCKING	'clocking.asm'
