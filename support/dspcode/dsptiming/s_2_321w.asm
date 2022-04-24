; s_2_321w.asm generic SW

FSXFER  DC	EFSXFER-FSXFER-2
	DC      SCLK+RGH		; reset
	DC      SCLK+RGL
	DC      SCLK+SWH		
	DC      SCLK+S1H		; 2+1
	DC      SCLK+S2L		; 1
	DC      SCLK+S3H		; 1+3
	DC      SCLK+S1L		; 3
	DC      SCLK+S2H		; 3+2
	DC      SCLK+S3L		; 2
	DC      SCLK+SWL
EFSXFER

SXFER0  DC	ESXFER0-SXFER0-2
	DC      VP+%00011101
	DC      SCLK+RGH		; reset
	DC      SCLK+RGL
	DC      SCLK+SWH
	DC      SCLK+S1H		; 2+1
	DC      SCLK+S2L		; 1
	DC      SCLK+S3H		; 1+3
	DC      SCLK+S1L		; 3
	DC      SCLK+S2H		; 3+2
	DC      SCLK+S3L		; 2
ESXFER0

SXFER1  DC	ESXFER1-SXFER1-2                     
	DC      SCLK+S1H		; 2+1
	DC      SCLK+S2L		; 1
	DC      SCLK+S3H		; 1+3
	DC      SCLK+S1L		; 3
	DC      SCLK+S2H		; 3+2
	DC      SCLK+S3L		; 2
ESXFER1

SXFER2  DC	ESXFER2-SXFER2-2
	INTNOISE
	DC      SCLK+SWL
	INTSIGNAL
ESXFER2
