; SystemConfig.asm - defines the system configurations for an ARC controller
; Use 'null.asm' for boards which are not installed

	DEFINE	TIMBRD	'tim3.asm'             ; timing board (not used yet)

	DEFINE	VIDDEFS	'ARC47_defs.asm'        ; video board defs
	DEFINE	VIDBRD0	'ARC47_dacs_brd0.asm'	; video board 0
	DEFINE	VIDBRD1	'ARC47_dacs_brd1.asm'	; video board 1
	DEFINE	VIDBRD2	'ARC47_dacs_brd2.asm'	; video board 2
	DEFINE	VIDBRD3	'ARC47_dacs_brd3.asm'	; video board 3

	DEFINE	CLKBRD0	'ARC32_dacs.asm'        ; clock board 0
	DEFINE	CLKBRD1	'null.asm'              ; clock board 1

	DEFINE	SBNCODE	'ARC47_ARC32_sbn.asm'   ; video&clock SBN command

	DEFINE	CLKPINOUT '90PrimeClockPins.asm'   ; clock board pinout

	DEFINE	POWERCODE 'ARC47_power.asm'     ; power related code

	DEFINE	UTILBRD	'null.asm'              ; utility board

