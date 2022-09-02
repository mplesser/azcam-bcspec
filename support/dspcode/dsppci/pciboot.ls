Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 1



1                                  COMMENT *
2      
3                          This file is used to generate DSP code for the PCI interface
4                                  board using a DSP56301 as its main processor.
5      
6                          This version has been modified to work with Gen I timing boards - 24-bits
7                                  for all words (commands, replies and image data), taking the
8                                  Rev. 1.6 Gen II code as the starting point.
9      
10                         This is now Rev. 1.7 PCI code.
11     
12                         Special notes for Gen I operation -
13     
14                                 The MODE bit for Gen II systems that switches between 32-bit command
15                                         and reply format (MODE = 1) and 16-bit image data (MODE = 0)
16                                         must be left in 32-bit mode always because Gen I data is
17                                         always 24-bit per word. Software in this file correctly
18                                         extracts the appropriate bytes from the 24-bit word.
19     
20                                 *
21                                   PAGE    132                               ; Printronix page width - 132 columns
22     
23                         ; Equates to define the X: memory tables
24        000000           VAR_TBL   EQU     0                                 ; Variables and constants table
25        000030           ARG_TBL   EQU     $30                               ; Command arguments and addresses
26     
27                         ; Various addressing control registers
28        FFFFFB           BCR       EQU     $FFFFFB                           ; Bus Control Register
29        FFFFFA           DCR       EQU     $FFFFFA                           ; DRAM Control Register
30        FFFFF9           AAR0      EQU     $FFFFF9                           ; Address Attribute Register, channel 0
31        FFFFF8           AAR1      EQU     $FFFFF8                           ; Address Attribute Register, channel 1
32        FFFFF7           AAR2      EQU     $FFFFF7                           ; Address Attribute Register, channel 2
33        FFFFF6           AAR3      EQU     $FFFFF6                           ; Address Attribute Register, channel 3
34        FFFFFD           PCTL      EQU     $FFFFFD                           ; PLL control register
35        FFFFFE           IPRP      EQU     $FFFFFE                           ; Interrupt Priority register - Peripheral
36        FFFFFF           IPRC      EQU     $FFFFFF                           ; Interrupt Priority register - Core
37     
38                         ; PCI control register
39        FFFFCD           DTXS      EQU     $FFFFCD                           ; DSP Slave transmit data FIFO
40        FFFFCC           DTXM      EQU     $FFFFCC                           ; DSP Master transmit data FIFO
41        FFFFCB           DRXR      EQU     $FFFFCB                           ; DSP Receive data FIFO
42        FFFFCA           DPSR      EQU     $FFFFCA                           ; DSP PCI Status Register
43        FFFFC9           DSR       EQU     $FFFFC9                           ; DSP Status Register
44        FFFFC8           DPAR      EQU     $FFFFC8                           ; DSP PCI Address Register
45        FFFFC7           DPMC      EQU     $FFFFC7                           ; DSP PCI Master Control Register
46        FFFFC6           DPCR      EQU     $FFFFC6                           ; DSP PCI Control Register
47        FFFFC5           DCTR      EQU     $FFFFC5                           ; DSP Control Register
48     
49                         ; Port E is the Synchronous Communications Interface (SCI) port
50        FFFF9F           PCRE      EQU     $FFFF9F                           ; Port Control Register
51        FFFF9E           PRRE      EQU     $FFFF9E                           ; Port Direction Register
52        FFFF9D           PDRE      EQU     $FFFF9D                           ; Port Data Register
53     
54                         ; Various PCI register bit equates
55        000001           STRQ      EQU     1                                 ; Slave transmit data request (DSR)
56        000002           SRRQ      EQU     2                                 ; Slave receive data request (DSR)
57        000017           HACT      EQU     23                                ; Host active, low true (DSR)
58        000001           MTRQ      EQU     1                                 ; Set whem master transmitter is not full (DPSR)
59        000004           MARQ      EQU     4                                 ; Master address request (DPSR)
60        00000A           TRTY      EQU     10                                ; PCI Target Retry (DPSR)
61        000000           HCIE      EQU     0                                 ; Host command interrupt enable (DCTR)
62     
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 2



63                         ; DPCR bit definitions
64        00000E           CLRT      EQU     14                                ; Clear the master transmitter DTXM
65        000012           MACE      EQU     18                                ; Master access counter enable
66        000015           IAE       EQU     21                                ; Insert Address Enable
67     
68                         ; Addresses of ESSI port
69        FFFFBC           TX00      EQU     $FFFFBC                           ; Transmit Data Register 0
70        FFFFB7           SSISR0    EQU     $FFFFB7                           ; Status Register
71        FFFFB6           CRB0      EQU     $FFFFB6                           ; Control Register B
72        FFFFB5           CRA0      EQU     $FFFFB5                           ; Control Register A
73     
74                         ; SSI Control Register A Bit Flags
75        000006           TDE       EQU     6                                 ; Set when transmitter data register is empty
76     
77                         ; Miscellaneous addresses
78        FFFFFF           RDFIFO    EQU     $FFFFFF                           ; Read the FIFO for incoming fiber optic data
79        FFFF8F           TCSR0     EQU     $FFFF8F                           ; Triple timer control and status register 0
80        FFFF8B           TCSR1     EQU     $FFFF8B                           ; Triple timer control and status register 1
81        FFFF87           TCSR2     EQU     $FFFF87                           ; Triple timer control and status register 2
82     
83                         ; Phase Locked Loop initialization
84        750012           PLL_INIT  EQU     $750012                           ; PLL = 33 MHz x 19 / 8 = 78.4 MHz
85     
86                         ; Port C is Enhanced Synchronous Serial Port 0
87        FFFFBF           PCRC      EQU     $FFFFBF                           ; Port C Control Register
88        FFFFBE           PRRC      EQU     $FFFFBE                           ; Port C Data direction Register
89        FFFFBD           PDRC      EQU     $FFFFBD                           ; Port C GPIO Data Register
90     
91                         ; Port D is Enhanced Synchronous Serial Port 1
92        FFFFAF           PCRD      EQU     $FFFFAF                           ; Port D Control Register
93        FFFFAE           PRRD      EQU     $FFFFAE                           ; Port D Data direction Register
94        FFFFAD           PDRD      EQU     $FFFFAD                           ; Port D GPIO Data Register
95     
96                         ; Bit number definitions of GPIO pins on Port D
97        000000           EF        EQU     0                                 ; FIFO Empty flag, low true
98        000001           HF        EQU     1                                 ; FIFO Half Full flag, low true
99     
100                        ; STATUS bit definition
101       000000           ODD       EQU     0                                 ; Set if odd number of pixels are in the image
102       000001           DWNLD     EQU     1                                 ; Set if downloading, so skip over special
103    
104                        ; Special address for two words for the DSP to bootstrap code from the EEPROM
105                                  IF      @SCP("HOST","ROM")                ; Boot from ROM on power-on
112                                  ENDIF
113    
114                                  IF      @SCP("HOST","HOST")               ; Download via host computer
115       P:000000 P:000000                   ORG     P:0,P:0
116       P:000000 P:000000                   DC      END_ADR-INIT                      ; Number of boot words
117       P:000001 P:000001                   DC      INIT                              ; Starting address
118       P:000000 P:000000                   ORG     P:0,P:0
119       P:000000 P:000000 0C00B2  INIT      JMP     <START
120       P:000001 P:000001 000000            NOP
121                                           ENDIF
122    
123                                           IF      @SCP("HOST","ONCE")               ; Download via ONCE debugger
127                                           ENDIF
128    
129                                 ; Vectored interrupt table, addresses at the beginning are reserved
130       P:000002 P:000002                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0       ; $02-$0f Reserved
131       P:000010 P:000010                   DC      0,0                               ; $11 - IRQA* = FIFO EF*
132       P:000012 P:000012                   DC      0,0                               ; $13 - IRQB* = FIFO HF*
133       P:000014 P:000014 0BF080            JSR     CLEAN_UP_PCI                      ; $15 - Software reset switch
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 3



                            000206
134       P:000016 P:000016                   DC      0,0,0,0,0,0,0,0,0,0,0,0           ; Reserved for DMA and Timer
135       P:000022 P:000022                   DC      0,0,0,0,0,0,0,0,0,0,0,0           ;   interrupts
136       P:00002E P:00002E 0BF080            JSR     DOWNLOAD_PCI_DSP_CODE             ; $2F
                            000045
137    
138                                 ; Now we're at P:$30, where some unused vector addresses are located
139    
140                                 ; This is ROM only code that is only executed once on power-up when the
141                                 ;   ROM code is downloaded. It is skipped over on OnCE or PCI downloads.
142                                 ; Initialize the PLL - phase locked loop
143                                 INIT_PCI
144       P:000030 P:000030 08F4BD            MOVEP             #PLL_INIT,X:PCTL        ; Initialize PLL
                            750012
145       P:000032 P:000032 000000            NOP
146    
147                                 ; Program the PCI self-configuration registers
148       P:000033 P:000033 240000            MOVE              #0,X0
149       P:000034 P:000034 08F485            MOVEP             #$500000,X:DCTR         ; Set self-configuration mode
                            500000
150       P:000036 P:000036 0604A0            REP     #4
151       P:000037 P:000037 08C408            MOVEP             X0,X:DPAR               ; Dummy writes to configuration space
152       P:000038 P:000038 08F487            MOVEP             #>$0000,X:DPMC          ; Subsystem ID
                            000000
153       P:00003A P:00003A 08F488            MOVEP             #>$0000,X:DPAR          ; Subsystem Vendor ID
                            000000
154    
155                                 ; PCI Personal reset
156       P:00003C P:00003C 08C405            MOVEP             X0,X:DCTR               ; Personal software reset
157       P:00003D P:00003D 000000            NOP
158       P:00003E P:00003E 000000            NOP
159       P:00003F P:00003F 0A89B7            JSET    #HACT,X:DSR,*                     ; Test for personal reset completion
                            00003F
160       P:000041 P:000041 07F084            MOVE              P:(*+3),X0              ; Trick to write "JMP <START" to P:0
                            000044
161       P:000043 P:000043 070004            MOVE              X0,P:(0)
162       P:000044 P:000044 0C00B2            JMP     <START
163    
164                                 DOWNLOAD_PCI_DSP_CODE
165       P:000045 P:000045 0A8615            BCLR    #IAE,X:DPCR                       ; Do not insert PCI address with data
166       P:000046 P:000046 0A8982  DNL0      JCLR    #SRRQ,X:DSR,*                     ; Wait for a receiver word
                            000046
167       P:000048 P:000048 084E0B            MOVEP             X:DRXR,A                ; Read it
168       P:000049 P:000049 0140C5            CMP     #$555AAA,A                        ; Check for sanity header word
                            555AAA
169       P:00004B P:00004B 0E2046            JNE     <DNL0
170       P:00004C P:00004C 044EBA            MOVE              OMR,A
171       P:00004D P:00004D 0140C6            AND     #$FFFFF0,A
                            FFFFF0
172       P:00004F P:00004F 014C82            OR      #$00000C,A
173       P:000050 P:000050 000000            NOP
174       P:000051 P:000051 04CEBA            MOVE              A,OMR                   ; Set boot mode to $C = PCI
175       P:000052 P:000052 0AF080            JMP     $FF0000                           ; Jump to boot code internal to DSP
                            FF0000
176    
177       P:000054 P:000054                   DC      0,0,0,0,0,0,0,0,0,0,0,0           ; Filler
178       P:000060 P:000060                   DC      0,0                               ; $60 - PCI Transaction Termination
179       P:000062 P:000062                   DC      0,0,0,0,0,0,0,0,0                 ; $62-$71 Reserved PCI
180       P:00006B P:00006B                   DC      0,0,0,0,0,0,0,0,0
181    
182                                 ; These interrupts are non-maskable, called from the host with $80xx
183       P:000074 P:000074 0BF080            JSR     READ_NUMBER_OF_PIXELS_READ        ; $8075
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 4



                            0001D6
184       P:000076 P:000076 0BF080            JSR     CLEAN_UP_PCI                      ; $8077
                            000206
185       P:000078 P:000078 0BF080            JSR     ABORT_READOUT                     ; $8079
                            0001F3
186       P:00007A P:00007A 0BF080            JSR     BOOT_EEPROM                       ; $807B
                            000185
187       P:00007C P:00007C                   DC      0,0,0,0                           ; Available
188    
189                                 ; These vector interrupts are masked at IPL = 1
190       P:000080 P:000080 0BF080            JSR     READ_REPLY_HEADER                 ; $81
                            00034A
191       P:000082 P:000082 0BF080            JSR     READ_REPLY_VALUE                  ; $83
                            000347
192       P:000084 P:000084 0BF080            JSR     CLEAR_HOST_FLAG                   ; $85
                            00034C
193       P:000086 P:000086 0BF080            JSR     RESET_CONTROLLER                  ; $87
                            0001DC
194       P:000088 P:000088 0BF080            JSR     READ_IMAGE                        ; $89
                            000210
195       P:00008A P:00008A                   DC      0,0                               ; Available
196       P:00008C P:00008C 0BF080            JSR     WRITE_BASE_PCI_ADDRESS            ; $8D
                            0001DD
197    
198       P:00008E P:00008E                   DC      0,0,0,0                           ; Available
199       P:000092 P:000092                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0
200       P:0000A0 P:0000A0                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
201    
202                                 ; New manual command for Version 1.6
203       P:0000B0 P:0000B0 0BF080            JSR     WRITE_COMMAND                     ; $B1
                            000190
204    
205       P:0000B2 P:0000B2 08F487  START     MOVEP             #>$00001,X:DPMC         ; 32-bit PCI <-> 24-bit DSP data
                            000001
206       P:0000B4 P:0000B4 0A8534            BSET    #20,X:DCTR                        ; HI32 mode = 1 => PCI
207       P:0000B5 P:0000B5 0A8515            BCLR    #21,X:DCTR
208       P:0000B6 P:0000B6 0A8516            BCLR    #22,X:DCTR
209       P:0000B7 P:0000B7 000000            NOP
210       P:0000B8 P:0000B8 0A8AAC            JSET    #12,X:DPSR,*                      ; Host data transfer not in progress
                            0000B8
211       P:0000BA P:0000BA 000000            NOP
212       P:0000BB P:0000BB 0A8632            BSET    #MACE,X:DPCR                      ; Master access counter enable
213       P:0000BC P:0000BC 000000            NOP                                       ; End of PCI programming
214    
215                                 ; Set operation mode register OMR to normal expanded
216       P:0000BD P:0000BD 0500BA            MOVEC             #$0000,OMR              ; Operating Mode Register = Normal Expanded
217       P:0000BE P:0000BE 0500BB            MOVEC             #0,SP                   ; Reset the Stack Pointer SP
218    
219                                 ; Move the table of constants from P: space to X: space
220       P:0000BF P:0000BF 61F400            MOVE              #CONSTANTS_TBL_START,R1 ; Start of table of constants
                            0003D8
221       P:0000C1 P:0000C1 300200            MOVE              #2,R0                   ; Leave X:0 for STATUS
222       P:0000C2 P:0000C2 060F80            DO      #CONSTANTS_TBL_LENGTH,L_WRITE
                            0000C5
223       P:0000C4 P:0000C4 07D984            MOVE              P:(R1)+,X0
224       P:0000C5 P:0000C5 445800            MOVE              X0,X:(R0)+              ; Write the constants to X:
225                                 L_WRITE
226    
227                                 ; Program the serial port ESSI0 = Port C for serial transmission to
228                                 ;   the timing board
229       P:0000C6 P:0000C6 07F43F            MOVEP             #>0,X:PCRC              ; Software reset of ESSI0
                            000000
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 5



230       P:0000C8 P:0000C8 07F435            MOVEP             #$000809,X:CRA0         ; Divide 78.4 MHz by 20 to get 3.92 MHz
                            000809
231                                                                                     ; DC0-CD4 = 0 for non-network operation
232                                                                                     ; WL0-WL2 = ALC = 0 for 2-bit data words
233                                                                                     ; SSC1 = 0 for SC1 not used
234       P:0000CA P:0000CA 07F436            MOVEP             #$010120,X:CRB0         ; SCKD = 1 for internally generated clock
                            010120
235                                                                                     ; SHFD = 0 for MSB shifted first
236                                                                                     ; CKP = 0 for rising clock edge transitions
237                                                                                     ; TE0 = 1 to enable transmitter #0
238                                                                                     ; MOD = 0 for normal, non-networked mode
239                                                                                     ; FSL1 = 1, FSL0 = 0 for on-demand transmit
240       P:0000CC P:0000CC 07F43F            MOVEP             #%101000,X:PCRC         ; Control Register (0 for GPIO, 1 for ESSI)
                            000028
241                                                                                     ; Set SCK0 = P3, STD0 = P5 to ESSI0
242       P:0000CE P:0000CE 07F43E            MOVEP             #%010111,X:PRRC         ; Data Direction Register (0 for In, 1 for O
ut)
                            000017
243       P:0000D0 P:0000D0 07F43D            MOVEP             #%000101,X:PDRC         ; Data Register - ROM/FIFO* = 0, SC02 = 0,
                            000005
244                                                                                     ;   AUX1 = 0, AUX2 = AUX3 = 1
245    
246                                 ; Conversion from software bits to schematic labels for Port C and D
247                                 ;       PC0 = SC00 = AUX3               PD0 = SC10 = EF*
248                                 ;       PC1 = SC01 = ROM/FIFO*          PD1 = SC11 = HF*
249                                 ;       PC2 = SC02 = AUX2               PD2 = SC12 = RS*
250                                 ;       PC3 = SCK0 = Serial clock       PD3 = SCK1 = FSYNC*
251                                 ;       PC4 = SRD0 = AUX1               PD4 = SRD1 = MODE
252                                 ;       PC5 = STD0 = Serial data        PD5 = STD1 = WRFIFO*
253    
254                                 ; Program the serial port ESSI1 = Port D for general purpose I/O (GPIO)
255       P:0000D2 P:0000D2 07F42F            MOVEP             #%000000,X:PCRD         ; Control Register (0 for GPIO, 1 for ESSI)
                            000000
256       P:0000D4 P:0000D4 07F42E            MOVEP             #%010100,X:PRRD         ; Data Direction Register (0 for In, 1 for O
ut)
                            000014
257       P:0000D6 P:0000D6 07F42D            MOVEP             #%010000,X:PDRD         ; Data Register - Pulse RS* low, MODE = 1
                            000010
258       P:0000D8 P:0000D8 060AA0            REP     #10
259       P:0000D9 P:0000D9 000000            NOP
260       P:0000DA P:0000DA 07F42D            MOVEP             #%010100,X:PDRD
                            000014
261    
262                                 ; Program the SCI port to benign values
263       P:0000DC P:0000DC 07F41F            MOVEP             #%000,X:PCRE            ; Port Control Register = GPIO
                            000000
264       P:0000DE P:0000DE 07F41E            MOVEP             #%110,X:PRRE            ; Port Direction Register (0 = Input)
                            000006
265       P:0000E0 P:0000E0 07F41D            MOVEP             #%110,X:PDRE            ; Port Data Register
                            000006
266                                 ;       PE0 = RXD
267                                 ;       PE1 = TXD
268                                 ;       PE2 = SCLK
269    
270                                 ; Program the triple timer to assert TCI0 as a GPIO output = 1
271       P:0000E2 P:0000E2 07F40F            MOVEP             #$2800,X:TCSR0
                            002800
272       P:0000E4 P:0000E4 07F40B            MOVEP             #$2800,X:TCSR1
                            002800
273       P:0000E6 P:0000E6 07F407            MOVEP             #$2800,X:TCSR2
                            002800
274    
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 6



275                                 ; Program the AA1 pin to read the FIFO memory for incoming timing board data
276       P:0000E8 P:0000E8 08F4B8            MOVEP             #$FFFC21,X:AAR1         ; Y = $FFF000 to $FFFFFF asserts AA1 low tru
e
                            FFFC21
277    
278                                 ; Program the DRAM memory access and addressing
279       P:0000EA P:0000EA 08F4BB            MOVEP             #$000020,X:BCR          ; Bus Control Register
                            000020
280       P:0000EC P:0000EC 08F4BA            MOVEP             #$893A05,X:DCR          ; DRAM Control Register
                            893A05
281       P:0000EE P:0000EE 08F4B7            MOVEP             #$000122,X:AAR2         ; Y: $000000 to $7FFFFF asserts AA2
                            000122
282       P:0000F0 P:0000F0 08F4B9            MOVEP             #$800122,X:AAR0         ; Y: $800000 to $FFFFFF asserts AA0
                            800122
283       P:0000F2 P:0000F2 08F4B6            MOVEP             #$000112,X:AAR3         ; X: $000000 to $7FFFFF asserts AA3
                            000112
284    
285                                 ; Clear all PCI error conditions
286       P:0000F4 P:0000F4 084E0A            MOVEP             X:DPSR,A
287       P:0000F5 P:0000F5 0140C2            OR      #$1FE,A
                            0001FE
288       P:0000F7 P:0000F7 000000            NOP
289       P:0000F8 P:0000F8 08CE0A            MOVEP             A,X:DPSR
290    
291                                 ; Establish interrupt priority levels IPL
292       P:0000F9 P:0000F9 08F4BF            MOVEP             #$0001C0,X:IPRC         ; IRQC priority IPL = 2 (reset switch, edge)
                            0001C0
293                                                                                     ; IRQB priority IPL = 2 or 0
294                                                                                     ;     (FIFO half full - HF*, level)
295       P:0000FB P:0000FB 08F4BE            MOVEP             #>2,X:IPRP              ; Enable PCI Host interrupts, IPL = 1
                            000002
296       P:0000FD P:0000FD 0A8520            BSET    #HCIE,X:DCTR                      ; Enable host command interrupts
297       P:0000FE P:0000FE 0500B9            MOVE              #0,SR                   ; Don't mask any interrupts
298    
299                                 ; Initialize the fiber optic serial transmitter to zero
300       P:0000FF P:0000FF 01B786            JCLR    #TDE,X:SSISR0,*
                            0000FF
301       P:000101 P:000101 07F43C            MOVEP             #$000000,X:TX00
                            000000
302    
303                                 ; Clear out the PCI receiver and transmitter FIFOs
304       P:000103 P:000103 0A862E            BSET    #CLRT,X:DPCR                      ; Clear the master transmitter
305       P:000104 P:000104 0A86AE            JSET    #CLRT,X:DPCR,*                    ; Wait for the clearing to be complete
                            000104
306       P:000106 P:000106 0A8982  CLR0      JCLR    #SRRQ,X:DSR,CLR1                  ; Wait for the receiver to be empty
                            00010B
307       P:000108 P:000108 08440B            MOVEP             X:DRXR,X0               ; Read receiver to empty it
308       P:000109 P:000109 000000            NOP
309       P:00010A P:00010A 0C0106            JMP     <CLR0
310                                 CLR1
311    
312                                 ; Repy = DONE host flags
313       P:00010B P:00010B 448600            MOVE              X:<FLAG_DONE,X0         ; Flag = 1 => Normal execution
314       P:00010C P:00010C 441D00            MOVE              X0,X:<HOST_FLAG
315       P:00010D P:00010D 0D0170            JSR     <FO_WRITE_HOST_FLAG
316    
317                                 ; ********************************************************************
318                                 ;
319                                 ;                       REGISTER  USAGE
320                                 ;
321                                 ;       X0, X1, Y0, Y1, A and B are used freely in READ_IMAGE. Interrups
322                                 ;               during readout will clobber these registers, as a result
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 7



323                                 ;               of which only catastrophic commands such as ABORT_READOUT
324                                 ;               and BOOT_EEPROM are allowed during readout.
325                                 ;
326                                 ;       X0, X1 and A are used for all interrupt handling routines, such
327                                 ;               as CLEAR_HOST-FLAGS, command processing and so on.
328                                 ;
329                                 ;       Y0, Y1 and B are used for all fiber optic processing routines,
330                                 ;               which are not in interrupt service routines.
331                                 ;
332                                 ; *********************************************************************
333    
334    
335                                 ; ************  Start of command interpreting code  ******************
336    
337                                 ; Test for fiber optic data on the FIFO. Discard the header for now
338    
339                                 ; Check for the header $AC in the first byte = Y0. Wait a little while and
340                                 ;  clear the FIFO if its not $AC - there was probably noise on the line.
341                                 ; We assume only two word replies here - Header = (S,D,#words)  Reply
342    
343       P:00010E P:00010E 01AD80  GET_FO    JCLR    #EF,X:PDRD,GET_FO                 ; Test for new fiber optic data
                            00010E
344       P:000110 P:000110 0D037D            JSR     <RD_FO_TIMEOUT                    ; Move the FIFO reply into A1
345       P:000111 P:000111 0E817B            JCS     <FO_ERR
346    
347                                 ; Check the header bytes for self-consistency
348       P:000112 P:000112 21A600            MOVE              B1,Y0
349       P:000113 P:000113 57F400            MOVE              #$FCFCF8,B              ; Test for S.LE.3 and D.LE.3 and N.LE.7
                            FCFCF8
350       P:000115 P:000115 20005E            AND     Y0,B
351       P:000116 P:000116 0E217B            JNE     <FO_ERR                           ; Test failed
352       P:000117 P:000117 57F400            MOVE              #$030300,B              ; Test for either S.NE.0 or D.NE.0
                            030300
353       P:000119 P:000119 20005E            AND     Y0,B
354       P:00011A P:00011A 0EA17B            JEQ     <FO_ERR                           ; Test failed
355       P:00011B P:00011B 57F400            MOVE              #>7,B
                            000007
356       P:00011D P:00011D 20005E            AND     Y0,B                              ; Extract NWORDS, must be >= 2
357       P:00011E P:00011E 01418D            CMP     #1,B
358       P:00011F P:00011F 0EF17B            JLE     <FO_ERR
359       P:000120 P:000120 20CF00            MOVE              Y0,B
360       P:000121 P:000121 0C1891            EXTRACTU #$008020,B,B                     ; Extract bits 15-8 = destination byte
                            008020
361       P:000123 P:000123 000000            NOP
362       P:000124 P:000124 511E00            MOVE              B0,X:<FO_DEST
363    
364                                 ; Read the reply or command from the fiber optics FIFO
365       P:000125 P:000125 0D037D            JSR     <RD_FO_TIMEOUT                    ; Move the FIFO reply into A1
366       P:000126 P:000126 0E817B            JCS     <FO_ERR
367       P:000127 P:000127 0A00A1            JSET    #DWNLD,X:<STATUS,RPLY             ; If downloading to the controller
                            00014B
368       P:000129 P:000129 551F00            MOVE              B1,X:<FO_CMD
369    
370                                 ; Check for commands from the controller to the PCI board, FO_DEST = 1
371       P:00012A P:00012A 579E00            MOVE              X:<FO_DEST,B
372       P:00012B P:00012B 01418D            CMP     #1,B
373       P:00012C P:00012C 0E213B            JNE     <HOSTCMD
374       P:00012D P:00012D 579F00            MOVE              X:<FO_CMD,B
375       P:00012E P:00012E 0140CD            CMP     #'RDA',B                          ; Read the image
                            524441
376       P:000130 P:000130 0EA210            JEQ     <READ_IMAGE
377       P:000131 P:000131 0140CD            CMP     #'IIA',B
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 8



                            494941
378       P:000133 P:000133 0EA1E9            JEQ     <INITIALIZE_NUMBER_OF_PIXELS      ; IPXLS = 0
379       P:000134 P:000134 0140CD            CMP     #'RDI',B
                            524449
380       P:000136 P:000136 0EA160            JEQ     <READING_IMAGE                    ; Controller is reading an image
381       P:000137 P:000137 0140CD            CMP     #'RDO',B
                            52444F
382       P:000139 P:000139 0EA16B            JEQ     <READING_IMAGE_OFF                ; Controller no longer reading an image
383       P:00013A P:00013A 0C010E            JMP     <GET_FO                           ; Not on the list -> just ignore it
384    
385                                 ; Check if the command or reply is for the host. If not just ignore it.
386       P:00013B P:00013B 579E00  HOSTCMD   MOVE              X:<FO_DEST,B
387       P:00013C P:00013C 01408D            CMP     #0,B
388       P:00013D P:00013D 0E210E            JNE     <GET_FO
389       P:00013E P:00013E 579F00            MOVE              X:<FO_CMD,B
390       P:00013F P:00013F 0140CD            CMP     #'DON',B
                            444F4E
391       P:000141 P:000141 0EA150            JEQ     <CONTROLLER_DONE                  ; Normal DONE reply
392       P:000142 P:000142 0140CD            CMP     #'ERR',B
                            455252
393       P:000144 P:000144 0EA154            JEQ     <CONTROLLER_ERROR                 ; Error reply
394       P:000145 P:000145 0140CD            CMP     #'BSY',B
                            425359
395       P:000147 P:000147 0EA15C            JEQ     <CONTROLLER_BUSY                  ; Controller is busy executing a command
396       P:000148 P:000148 0140CD            CMP     #'SYR',B
                            535952
397       P:00014A P:00014A 0EA158            JEQ     <CONTROLLER_RESET                 ; Controller system reset
398    
399                                 ; The controller reply is none of the above so return it as a reply
400       P:00014B P:00014B 551C00  RPLY      MOVE              B1,X:<REPLY             ; Report value
401       P:00014C P:00014C 468700            MOVE              X:<FLAG_REPLY,Y0        ; Flag = 2 => Reply with a value
402       P:00014D P:00014D 461D00            MOVE              Y0,X:<HOST_FLAG
403       P:00014E P:00014E 0D0170            JSR     <FO_WRITE_HOST_FLAG
404       P:00014F P:00014F 0C010E            JMP     <GET_FO
405    
406                                 CONTROLLER_DONE
407       P:000150 P:000150 468600            MOVE              X:<FLAG_DONE,Y0         ; Flag = 1 => Normal execution
408       P:000151 P:000151 461D00            MOVE              Y0,X:<HOST_FLAG
409       P:000152 P:000152 0D0170            JSR     <FO_WRITE_HOST_FLAG
410       P:000153 P:000153 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
411    
412                                 CONTROLLER_ERROR
413       P:000154 P:000154 468800            MOVE              X:<FLAG_ERR,Y0          ; Flag = 3 => controller error
414       P:000155 P:000155 461D00            MOVE              Y0,X:<HOST_FLAG
415       P:000156 P:000156 0D0170            JSR     <FO_WRITE_HOST_FLAG
416       P:000157 P:000157 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
417    
418                                 CONTROLLER_RESET
419       P:000158 P:000158 468900            MOVE              X:<FLAG_SYR,Y0          ; Flag = 4 => controller reset
420       P:000159 P:000159 461D00            MOVE              Y0,X:<HOST_FLAG
421       P:00015A P:00015A 0D0170            JSR     <FO_WRITE_HOST_FLAG
422       P:00015B P:00015B 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
423    
424                                 CONTROLLER_BUSY
425       P:00015C P:00015C 468B00            MOVE              X:<FLAG_BUSY,Y0         ; Flag = 6 => controller busy
426       P:00015D P:00015D 461D00            MOVE              Y0,X:<HOST_FLAG
427       P:00015E P:00015E 0D0170            JSR     <FO_WRITE_HOST_FLAG
428       P:00015F P:00015F 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
429    
430                                 ; A special handshaking here ensures that the host computer has read the 'DON'
431                                 ;   reply to the start_exposure command before the reading_image state is
432                                 ;   set in the host flags. Reading_image occurs only after a start_exposure
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 9



433                                 READING_IMAGE
434       P:000160 P:000160 579D00            MOVE              X:<HOST_FLAG,B          ; Retrieve current host flag value
435       P:000161 P:000161 448A00            MOVE              X:<FLAG_RDI,X0
436       P:000162 P:000162 20004D            CMP     X0,B                              ; If we're already in read_image
437       P:000163 P:000163 0EA10E            JEQ     <GET_FO                           ;   mode then do nothing
438       P:000164 P:000164 20000B            TST     B                                 ; Wait for flag to be cleared, which
439       P:000165 P:000165 0E2160            JNE     <READING_IMAGE                    ;  the host does when it gets the DONE
440    
441       P:000166 P:000166 0A8500            BCLR    #HCIE,X:DCTR                      ; Disable host command interrupts
442       P:000167 P:000167 468A00            MOVE              X:<FLAG_RDI,Y0
443       P:000168 P:000168 461D00            MOVE              Y0,X:<HOST_FLAG
444       P:000169 P:000169 0D0170            JSR     <FO_WRITE_HOST_FLAG               ; Set Host Flag to "reading out"
445       P:00016A P:00016A 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
446    
447                                 READING_IMAGE_OFF                                   ; Controller is no longer reading out
448       P:00016B P:00016B 468500            MOVE              X:<FLAG_ZERO,Y0
449       P:00016C P:00016C 461D00            MOVE              Y0,X:<HOST_FLAG
450       P:00016D P:00016D 0D0170            JSR     <FO_WRITE_HOST_FLAG
451       P:00016E P:00016E 0A8520            BSET    #HCIE,X:DCTR                      ; Enable host command interrupts
452       P:00016F P:00016F 0C010E            JMP     <GET_FO                           ; Keep looping for fiber optic commands
453    
454                                 ; Write X:<HOST_FLAG to the DCTR flag bits 5,4,3, as a subroutine
455                                 FO_WRITE_HOST_FLAG
456       P:000170 P:000170 57F000            MOVE              X:DCTR,B
                            FFFFC5
457       P:000172 P:000172 469D00            MOVE              X:<HOST_FLAG,Y0
458       P:000173 P:000173 0140CE            AND     #$FFFFC7,B                        ; Clear bits 5,4,3
                            FFFFC7
459       P:000175 P:000175 000000            NOP
460       P:000176 P:000176 20005A            OR      Y0,B                              ; Set flags appropriately
461       P:000177 P:000177 000000            NOP
462       P:000178 P:000178 577000            MOVE              B,X:DCTR
                            FFFFC5
463       P:00017A P:00017A 00000C            RTS
464    
465                                 ; There was an erroneous word on the fiber optic line -> clear the FIFO
466       P:00017B P:00017B 07F42D  FO_ERR    MOVEP             #%010000,X:PDRD         ; Clear FIFO RESET* for 2 milliseconds
                            000010
467       P:00017D P:00017D 46F400            MOVE              #200000,Y0
                            030D40
468       P:00017F P:00017F 06C600            DO      Y0,*+3
                            000181
469       P:000181 P:000181 000000            NOP
470       P:000182 P:000182 07F42D            MOVEP             #%010100,X:PDRD         ; Data Register - Set RS* high
                            000014
471       P:000184 P:000184 0C010E            JMP     <GET_FO
472    
473                                 ; **************  Boot from byte-wide on-board EEPROM  *******************
474    
475                                 BOOT_EEPROM
476       P:000185 P:000185 08F4BB            MOVEP             #$0002A0,X:BCR          ; Bus Control Register for slow EEPROM
                            0002A0
477       P:000187 P:000187 013D21            BSET    #1,X:PDRC                         ; ROM/FIFO* = 1 to select ROM
478       P:000188 P:000188 044EBA            MOVE              OMR,A
479       P:000189 P:000189 0140C6            AND     #$FFFFF0,A
                            FFFFF0
480       P:00018B P:00018B 014982            OR      #$000009,A                        ; Boot mode = $9 = byte-wide EEPROM
481       P:00018C P:00018C 000000            NOP
482       P:00018D P:00018D 04CEBA            MOVE              A,OMR
483       P:00018E P:00018E 0AF080            JMP     $FF0000                           ; Jump to boot code internal to DSP
                            FF0000
484    
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 10



485                                 ; ***************  Command processing  ****************
486    
487                                 WRITE_COMMAND
488       P:000190 P:000190 0A8982            JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            000333
489       P:000192 P:000192 084E0B            MOVEP             X:DRXR,A                ; Get the header
490       P:000193 P:000193 000000            NOP                                       ; Pipeline restriction
491       P:000194 P:000194 543000            MOVE              A1,X:<HEADER
492    
493                                 ; Check the header bytes for self-consistency
494       P:000195 P:000195 218400            MOVE              A1,X0
495       P:000196 P:000196 56F400            MOVE              #$FCFCF8,A              ; Test for S.LE.3 and D.LE.3 and N.LE.7
                            FCFCF8
496       P:000198 P:000198 200046            AND     X0,A
497       P:000199 P:000199 0E2333            JNE     <ERROR                            ; Test failed
498       P:00019A P:00019A 56F400            MOVE              #$030300,A              ; Test for either S.NE.0 or D.NE.0
                            030300
499       P:00019C P:00019C 200046            AND     X0,A
500       P:00019D P:00019D 0EA333            JEQ     <ERROR                            ; Test failed
501       P:00019E P:00019E 56F400            MOVE              #>7,A
                            000007
502       P:0001A0 P:0001A0 200046            AND     X0,A                              ; Extract NUM_ARG, must be >= 0
503       P:0001A1 P:0001A1 000000            NOP                                       ; Pipeline restriction
504       P:0001A2 P:0001A2 014284            SUB     #2,A
505       P:0001A3 P:0001A3 0E9333            JLT     <ERROR                            ; Number of arguments >= 0
506       P:0001A4 P:0001A4 543500            MOVE              A1,X:<NUM_ARG           ; Store number of arguments in command
507       P:0001A5 P:0001A5 014685            CMP     #6,A                              ; Number of arguemnts <= 6
508       P:0001A6 P:0001A6 0E7333            JGT     <ERROR
509    
510                                 ; Get the DESTINATION number (1 = PCI, 2 = timing, 3 = utility)
511       P:0001A7 P:0001A7 208E00            MOVE              X0,A                    ; Still the header
512       P:0001A8 P:0001A8 0C1ED0            LSR     #8,A
513       P:0001A9 P:0001A9 0140C6            AND     #>3,A                             ; Extract just three bits of
                            000003
514       P:0001AB P:0001AB 543400            MOVE              A1,X:<DESTINATION       ;   the destination byte
515       P:0001AC P:0001AC 0EA333            JEQ     <ERROR                            ; Destination of zero = host not allowed
516       P:0001AD P:0001AD 014185            CMP     #1,A                              ; Destination byte for PCI board
517       P:0001AE P:0001AE 0EA1BC            JEQ     <PCI
518    
519                                 ; Write the controller command and its arguments to the fiber optics
520       P:0001AF P:0001AF 56B000            MOVE              X:<HEADER,A
521       P:0001B0 P:0001B0 0BF080            JSR     XMT_WRD                           ; Write the word to the fiber optics
                            00035C
522       P:0001B2 P:0001B2 0A8982            JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            000333
523       P:0001B4 P:0001B4 084E0B            MOVEP             X:DRXR,A                ; Write the command
524       P:0001B5 P:0001B5 0D035C            JSR     <XMT_WRD                          ; Write the command to the fiber optics
525       P:0001B6 P:0001B6 063500            DO      X:<NUM_ARG,L_ARGS1                ; Do loop won't execute if NUM_ARG = 0
                            0001BA
526       P:0001B8 P:0001B8 084E0B            MOVEP             X:DRXR,A                ; Get the arguments
527       P:0001B9 P:0001B9 0D035C            JSR     <XMT_WRD                          ; Write the argument to the fiber optics
528       P:0001BA P:0001BA 000000            NOP                                       ; DO loop restriction
529       P:0001BB P:0001BB 000004  L_ARGS1   RTI                                       ; The controller will generate the reply
530    
531                                 ; Since it's a PCI command store the command and its arguments in X: memory
532       P:0001BC P:0001BC 0A8982  PCI       JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            000333
533       P:0001BE P:0001BE 08708B            MOVEP             X:DRXR,X:COMMAND        ; Get the command
                            000031
534       P:0001C0 P:0001C0 56B500            MOVE              X:<NUM_ARG,A            ; Get number of arguments in command
535       P:0001C1 P:0001C1 60F400            MOVE              #ARG1,R0                ; Starting address of argument list
                            000032
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 11



536       P:0001C3 P:0001C3 06CE00            DO      A,L_ARGS2                         ; DO loop won't execute if A = 0
                            0001C7
537       P:0001C5 P:0001C5 0A8982            JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            000333
538       P:0001C7 P:0001C7 08588B            MOVEP             X:DRXR,X:(R0)+          ; Get arguments
539                                 L_ARGS2
540    
541                                 ; Process a PCI board non-vector command
542                                 PCI_COMMAND
543       P:0001C8 P:0001C8 56B100            MOVE              X:<COMMAND,A            ; Get the command
544       P:0001C9 P:0001C9 0140C5            CMP     #'TRM',A                          ; Is it the test DRAM command?
                            54524D
545       P:0001CB P:0001CB 0EA39D            JEQ     <TEST_DRAM
546       P:0001CC P:0001CC 0140C5            CMP     #'TDL',A                          ; Is it the test data link command?
                            54444C
547       P:0001CE P:0001CE 0EA2CF            JEQ     <TEST_DATA_LINK
548       P:0001CF P:0001CF 0140C5            CMP     #'RDM',A
                            52444D
549       P:0001D1 P:0001D1 0EA2D1            JEQ     <READ_MEMORY                      ; Is it the read memory command?
550       P:0001D2 P:0001D2 0140C5            CMP     #'WRM',A
                            57524D
551       P:0001D4 P:0001D4 0EA2FC            JEQ     <WRITE_MEMORY                     ; Is it the write memory command?
552       P:0001D5 P:0001D5 0C0333            JMP     <ERROR                            ; Its not a recognized command
553    
554                                 ; ********************  Vector commands  *******************
555    
556                                 READ_NUMBER_OF_PIXELS_READ                          ; Write the reply to the DTXS FIFO
557       P:0001D6 P:0001D6 08F08D            MOVEP             X:R_PXLS_0,X:DTXS       ; DSP-to-host slave transmit
                            000017
558       P:0001D8 P:0001D8 000000            NOP
559       P:0001D9 P:0001D9 08F08D            MOVEP             X:R_PXLS_1,X:DTXS       ; DSP-to-host slave transmit
                            000016
560       P:0001DB P:0001DB 000004            RTI
561    
562                                 ; Reset controller is not implemented in Gen I controllers, so this just
563                                 ;  returns a "SYR" reply indicating 'successful' command completion
564                                 RESET_CONTROLLER
565       P:0001DC P:0001DC 0C0336            JMP     <SYR                              ; Reply to host, return from interrupt
566    
567                                 ; ****************  Exposure and readout commands  ****************
568    
569                                 WRITE_BASE_PCI_ADDRESS
570       P:0001DD P:0001DD 0A8982            JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            000333
571       P:0001DF P:0001DF 08480B            MOVEP             X:DRXR,A0
572       P:0001E0 P:0001E0 0A8982            JCLR    #SRRQ,X:DSR,ERROR                 ; Error if receiver FIFO has no data
                            000333
573       P:0001E2 P:0001E2 08440B            MOVEP             X:DRXR,X0               ; Get most significant word
574       P:0001E3 P:0001E3 0C1940            INSERT  #$010010,X0,A
                            010010
575       P:0001E5 P:0001E5 000000            NOP
576       P:0001E6 P:0001E6 501900            MOVE              A0,X:<BASE_ADDR_0       ; BASE_ADDR is 8 + 24 bits
577       P:0001E7 P:0001E7 541800            MOVE              A1,X:<BASE_ADDR_1
578       P:0001E8 P:0001E8 0C032C            JMP     <FINISH                           ; Write 'DON' reply
579    
580                                 ; Write the base PCI image address to the PCI address
581                                 INITIALIZE_NUMBER_OF_PIXELS
582       P:0001E9 P:0001E9 200013            CLR     A
583       P:0001EA P:0001EA 000000            NOP
584       P:0001EB P:0001EB 541600            MOVE              A1,X:<R_PXLS_1          ; Up counter of number of pixels read
585       P:0001EC P:0001EC 501700            MOVE              A0,X:<R_PXLS_0
586    
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 12



587       P:0001ED P:0001ED 509900            MOVE              X:<BASE_ADDR_0,A0       ; BASE_ADDR is 2 x 16-bits
588       P:0001EE P:0001EE 549800            MOVE              X:<BASE_ADDR_1,A1
589       P:0001EF P:0001EF 000000            NOP
590       P:0001F0 P:0001F0 501B00            MOVE              A0,X:<PCI_ADDR_0        ; PCI_ADDR is 8 + 24 bits
591       P:0001F1 P:0001F1 541A00            MOVE              A1,X:<PCI_ADDR_1
592    
593       P:0001F2 P:0001F2 0C0150            JMP     <CONTROLLER_DONE                  ; Repy = DONE host flags
594    
595                                 ; Send an abort readout command to the controller to stop image transmission
596                                 ABORT_READOUT
597       P:0001F3 P:0001F3 448600            MOVE              X:<FLAG_DONE,X0
598       P:0001F4 P:0001F4 441D00            MOVE              X0,X:<HOST_FLAG
599       P:0001F5 P:0001F5 0D0170            JSR     <FO_WRITE_HOST_FLAG
600    
601       P:0001F6 P:0001F6 568E00            MOVE              X:<C000202,A
602       P:0001F7 P:0001F7 0D035C            JSR     <XMT_WRD                          ; Timing board header word
603       P:0001F8 P:0001F8 56F400            MOVE              #'ABR',A
                            414252
604       P:0001FA P:0001FA 0D035C            JSR     <XMT_WRD                          ; Abort Readout
605    
606                                 ; Ensure that image data is no longer being received from the controller
607       P:0001FB P:0001FB 01AD80  ABR0      JCLR    #EF,X:PDRD,ABR2                   ; Test for incoming FIFO data
                            000201
608       P:0001FD P:0001FD 09443F  ABR1      MOVEP             Y:RDFIFO,X0             ; Read the FIFO until its empty
609       P:0001FE P:0001FE 000000            NOP
610       P:0001FF P:0001FF 01ADA0            JSET    #EF,X:PDRD,ABR1
                            0001FD
611       P:000201 P:000201 066089  ABR2      DO      #2400,ABR3                        ; Wait for about 30 microsec in case
                            000203
612       P:000203 P:000203 000000            NOP                                       ;   FIFO data is still arriving
613       P:000204 P:000204 01ADA0  ABR3      JSET    #EF,X:PDRD,ABR1                   ; Keep emptying if more data arrived
                            0001FD
614    
615                                 ; Clean up the PCI board from wherever it was executing
616                                 CLEAN_UP_PCI
617       P:000206 P:000206 08F4BF            MOVEP             #$0001C0,X:IPRC         ; Disable HF* FIFO interrupt
                            0001C0
618       P:000208 P:000208 0A8520            BSET    #HCIE,X:DCTR                      ; Enable host command interrupts
619       P:000209 P:000209 0501BB            MOVEC             #1,SP                   ; Point stack pointer to the top
620       P:00020A P:00020A 05F43D            MOVEC             #$000200,SSL            ; SR = zero except for interrupts
                            000200
621       P:00020C P:00020C 0500BB            MOVEC             #0,SP                   ; Writing to SSH preincrements the SP
622       P:00020D P:00020D 05B2BC            MOVEC             #START,SSH              ; Set PC to for full initialization
623       P:00020E P:00020E 000000            NOP
624       P:00020F P:00020F 000004            RTI
625    
626                                 ; *************************************************************************
627                                 ;  There are several address register assignements in the Scatter/Gather
628                                 ;    routine that should not be disturbed
629                                 ;
630                                 ;       R1 - DRAM address of pixel being scaterred
631                                 ;       R5 - DRAM address of pixel being gathered
632                                 ;       R0, R3, R6 and R7 are not used in the Scatter/Gather routine
633                                 ;
634                                 ; *************************************************************************
635    
636                                 ; Read the image - change the serial receiver to expect 16-bit (image) data
637                                 READ_IMAGE
638       P:000210 P:000210 0A8500            BCLR    #HCIE,X:DCTR                      ; Disable host command interrupts
639       P:000211 P:000211 448A00            MOVE              X:<FLAG_RDI,X0
640       P:000212 P:000212 441D00            MOVE              X0,X:<HOST_FLAG
641       P:000213 P:000213 0D0170            JSR     <FO_WRITE_HOST_FLAG               ; Set HCTR bits to "reading out"
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 13



642       P:000214 P:000214 084E0A            MOVEP             X:DPSR,A                ; Clear all PCI error conditions
643       P:000215 P:000215 0140C2            OR      #$1FE,A
                            0001FE
644       P:000217 P:000217 000000            NOP
645       P:000218 P:000218 08CE0A            MOVEP             A,X:DPSR
646       P:000219 P:000219 0A862E            BSET    #CLRT,X:DPCR                      ; Clear the master transmitter FIFO
647       P:00021A P:00021A 0A86AE            JSET    #CLRT,X:DPCR,*                    ; Wait for the clearing to be complete
                            00021A
648    
649                                 ; Compute the number of pixels to read from the controller
650       P:00021C P:00021C 0D037D            JSR     <RD_FO_TIMEOUT                    ; Read number of columns
651       P:00021D P:00021D 0E817B            JCS     <FO_ERR
652       P:00021E P:00021E 21A500            MOVE              B1,X1
653       P:00021F P:00021F 0D037D            JSR     <RD_FO_TIMEOUT                    ; Read number of rows
654       P:000220 P:000220 0E817B            JCS     <FO_ERR
655       P:000221 P:000221 21A700            MOVE              B1,Y1                   ; Number of rows to read is in Y1
656       P:000222 P:000222 2000F0            MPY     X1,Y1,A
657       P:000223 P:000223 200022            ASR     A                                 ; Correct for 0 in LS bit after MPY
658       P:000224 P:000224 20001B            CLR     B
659       P:000225 P:000225 541200            MOVE              A1,X:<NPXLS_1           ; NPXLS set by controller
660       P:000226 P:000226 501300            MOVE              A0,X:<NPXLS_0
661       P:000227 P:000227 551400            MOVE              B1,X:<IPXLS_1           ; IPXLS = 0
662       P:000228 P:000228 511500            MOVE              B0,X:<IPXLS_0
663    
664                                 ; Get the current PCI address into the accumulator B
665       P:000229 P:000229 519B00            MOVE              X:<PCI_ADDR_0,B0        ; B will contain the current PCI address
666       P:00022A P:00022A 559A00            MOVE              X:<PCI_ADDR_1,B1
667    
668                                 ; There are three separate stages of writing the image to the PCI bus
669                                 ;       a. Write complete 512 pixel FIFO half full blocks
670                                 ;       b. Write the pixels left over from the last complete FIFO block
671                                 ;       c. Write one pixel if the image has an odd number of pixels
672    
673    
674                                 ; Compute the number of pixel pairs from the FIFO --> PCI bus
675       P:00022B P:00022B 448C00  L_FIFO    MOVE              X:<C256,X0              ; 1/2 the FIFO depth
676       P:00022C P:00022C 250000            MOVE              #0,X1
677       P:00022D P:00022D 200013            CLR     A
678       P:00022E P:00022E 549200            MOVE              X:<NPXLS_1,A1           ; Number of pixels to write to PCI
679       P:00022F P:00022F 509300            MOVE              X:<NPXLS_0,A0
680       P:000230 P:000230 479400            MOVE              X:<IPXLS_1,Y1           ; Compare it to image size
681       P:000231 P:000231 469500            MOVE              X:<IPXLS_0,Y0
682       P:000232 P:000232 000000            NOP
683       P:000233 P:000233 200034            SUB     Y,A                               ; If (Image size - Ipxls)  <= 512
684       P:000234 P:000234 000000            NOP                                       ;   we're at the end of the image
685       P:000235 P:000235 200024            SUB     X,A
686       P:000236 P:000236 0EF267            JLE     <WRITE_LAST_LITTLE_BIT_OF_IMAGE
687    
688                                 ; (a) Write complete 256 pixel (1/2 FIFO) image blocks to the PCI bus
689       P:000237 P:000237 468400            MOVE              X:<FOUR,Y0              ; Number of bytes per PCI write
690       P:000238 P:000238 270000            MOVE              #0,Y1
691                                 WR_IMAGE
692       P:000239 P:000239 01ADA1            JSET    #HF,X:PDRD,*                      ; Wait for FIFO to be half full + 1
                            000239
693       P:00023B P:00023B 000000            NOP
694       P:00023C P:00023C 000000            NOP
695       P:00023D P:00023D 01ADA1            JSET    #HF,X:PDRD,WR_IMAGE               ; Protection against metastability
                            000239
696       P:00023F P:00023F 068080            DO      #128,WR_BLK1
                            00025C
697       P:000241 P:000241 0C1890            EXTRACTU #$010010,B,A                     ; Get D31-16 bits only. FC = 0 (32-bit)
                            010010
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 14



698       P:000243 P:000243 000000            NOP
699       P:000244 P:000244 08C807            MOVEP             A0,X:DPMC               ; DSP master control register
700       P:000245 P:000245 000000            NOP                                       ; FC = 0 -> 32-bit PCI writes
701       P:000246 P:000246 0C1890            EXTRACTU #$010000,B,A
                            010000
702       P:000248 P:000248 000000            NOP
703       P:000249 P:000249 210C00            MOVE              A0,A1
704       P:00024A P:00024A 0140C2            OR      #$070000,A                        ; A1 gets written to DPAR register
                            070000
705       P:00024C P:00024C 218400            MOVE              A1,X0
706       P:00024D P:00024D 0D02B4            JSR     <WR_PIX
707       P:00024E P:00024E 0D02B4            JSR     <WR_PIX
708       P:00024F P:00024F 08C408  AGAIN1    MOVEP             X0,X:DPAR               ; Write to PCI bus
709       P:000250 P:000250 000000            NOP                                       ; Pipeline delay
710       P:000251 P:000251 000000            NOP                                       ; Pipeline delay
711    
712       P:000252 P:000252 0A8A84            JCLR    #MARQ,X:DPSR,*                    ; Bit is clear if PCI still in progress
                            000252
713       P:000254 P:000254 0A8AAE            JSET    #14,X:DPSR,WR_OK1                 ; MDT bit
                            00025B
714       P:000256 P:000256 0A8A8A            JCLR    #TRTY,X:DPSR,END_WR               ; Error if its not a retry
                            0002AC
715       P:000258 P:000258 08F48A            MOVEP             #$0400,X:DPSR           ; Clear bit 10 = target retry bit
                            000400
716       P:00025A P:00025A 0C024F            JMP     <AGAIN1
717    
718       P:00025B P:00025B 200038  WR_OK1    ADD     Y,B                               ; Increment PCI address
719       P:00025C P:00025C 000000            NOP
720                                 WR_BLK1
721    
722                                 ; Re-calculate and store the PCI address where image data is being written to
723       P:00025D P:00025D 448C00            MOVE              X:<C256,X0              ; 1/2 the FIFO depth
724       P:00025E P:00025E 250000            MOVE              #0,X1
725       P:00025F P:00025F 509500            MOVE              X:<IPXLS_0,A0           ; Number of pixels to write to PCI
726       P:000260 P:000260 549400            MOVE              X:<IPXLS_1,A1
727       P:000261 P:000261 200020            ADD     X,A
728       P:000262 P:000262 000000            NOP
729       P:000263 P:000263 501500            MOVE              A0,X:<IPXLS_0           ; Number of pixels to write to PCI
730       P:000264 P:000264 541400            MOVE              A1,X:<IPXLS_1
731       P:000265 P:000265 0D02C1            JSR     <C_RPXLS                          ; Calculate number of pixels read
732       P:000266 P:000266 0C022B            JMP     <L_FIFO                           ; Go process the next 1/2 FIFO
733    
734                                 ; (b) Write the pixels left over
735                                 WRITE_LAST_LITTLE_BIT_OF_IMAGE
736       P:000267 P:000267 0A0000            BCLR    #ODD,X:<STATUS
737       P:000268 P:000268 200020            ADD     X,A
738       P:000269 P:000269 000000            NOP
739       P:00026A P:00026A 200022            ASR     A                                 ; Two pixels written per loop
740       P:00026B P:00026B 0E026D            JCC     *+2
741       P:00026C P:00026C 0A0020            BSET    #ODD,X:<STATUS                    ; ODD = 1 if carry bit is set
742       P:00026D P:00026D 468400            MOVE              X:<FOUR,Y0              ; Number of bytes per PCI write
743       P:00026E P:00026E 270000            MOVE              #0,Y1
744    
745       P:00026F P:00026F 06C800            DO      A0,WR_BLK2
                            00028C
746       P:000271 P:000271 0C1890            EXTRACTU #$010010,B,A                     ; Get D31-16 bits only. FC = 0 (32-bit)
                            010010
747       P:000273 P:000273 000000            NOP
748       P:000274 P:000274 08C807            MOVEP             A0,X:DPMC               ; DSP master control register
749       P:000275 P:000275 000000            NOP                                       ; FC = 0 -> 32-bit PCI writes
750       P:000276 P:000276 0C1890            EXTRACTU #$010000,B,A
                            010000
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 15



751       P:000278 P:000278 000000            NOP
752       P:000279 P:000279 210C00            MOVE              A0,A1
753       P:00027A P:00027A 0140C2            OR      #$070000,A                        ; A1 gets written to DPAR register
                            070000
754       P:00027C P:00027C 218400            MOVE              A1,X0
755       P:00027D P:00027D 0D02B4            JSR     <WR_PIX
756       P:00027E P:00027E 0D02B4            JSR     <WR_PIX
757       P:00027F P:00027F 08C408  AGAIN2    MOVEP             X0,X:DPAR               ; Write to PCI bus
758       P:000280 P:000280 000000            NOP                                       ; Pipeline delay
759       P:000281 P:000281 000000            NOP                                       ; Pipeline delay
760    
761       P:000282 P:000282 0A8A84            JCLR    #MARQ,X:DPSR,*                    ; Bit is clear if PCI still in progress
                            000282
762       P:000284 P:000284 0A8AAE            JSET    #14,X:DPSR,WR_OK2                 ; MDT bit
                            00028B
763       P:000286 P:000286 0A8A8A            JCLR    #TRTY,X:DPSR,END_WR               ; Bit is set if its a retry
                            0002AC
764       P:000288 P:000288 08F48A            MOVEP             #$0400,X:DPSR           ; Clear bit 10 = target retry bit
                            000400
765       P:00028A P:00028A 0C027F            JMP     <AGAIN2
766    
767       P:00028B P:00028B 200038  WR_OK2    ADD     Y,B                               ; Increment PCI address
768       P:00028C P:00028C 000000            NOP
769                                 WR_BLK2
770    
771                                 ; (c) Write the very last pixel if there is an odd number of pixels in the image
772       P:00028D P:00028D 0A0080            JCLR    #ODD,X:STATUS,END_WR
                            0002AC
773       P:00028F P:00028F 0C1890            EXTRACTU #$010010,B,A                     ; Get D31-16 bits only. FC = 0 (32-bit)
                            010010
774       P:000291 P:000291 000000            NOP
775       P:000292 P:000292 0AC876            BSET    #22,A0                            ; FC mode = 1
776       P:000293 P:000293 000000            NOP
777       P:000294 P:000294 08C807            MOVEP             A0,X:DPMC               ; DSP master control register
778       P:000295 P:000295 000000            NOP
779       P:000296 P:000296 0C1890            EXTRACTU #$010000,B,A
                            010000
780       P:000298 P:000298 000000            NOP
781       P:000299 P:000299 210C00            MOVE              A0,A1
782       P:00029A P:00029A 0140C2            OR      #$C70000,A                        ; Write 16 LS bits only
                            C70000
783       P:00029C P:00029C 218400            MOVE              A1,X0
784       P:00029D P:00029D 0140C8            ADD     #>2,B                             ; Increment PCI address
                            000002
785       P:00029F P:00029F 0D02B4            JSR     <WR_PIX
786       P:0002A0 P:0002A0 08C408  AGAIN3    MOVEP             X0,X:DPAR               ; Write to PCI bus
787       P:0002A1 P:0002A1 000000            NOP                                       ; Pipeline delay
788       P:0002A2 P:0002A2 000000            NOP                                       ; Pipeline delay
789    
790       P:0002A3 P:0002A3 0A8A84            JCLR    #MARQ,X:DPSR,*                    ; Bit is clear if PCI still in progress
                            0002A3
791       P:0002A5 P:0002A5 0A8AAE            JSET    #14,X:DPSR,END_WR                 ; MDT bit
                            0002AC
792       P:0002A7 P:0002A7 0A8A8A            JCLR    #TRTY,X:DPSR,END_WR               ; Bit is set if its a retry
                            0002AC
793       P:0002A9 P:0002A9 08F48A            MOVEP             #$0400,X:DPSR           ; Clear bit 10 = target retry bit
                            000400
794       P:0002AB P:0002AB 0C02A0            JMP     <AGAIN3
795    
796                                 ; Calculate and store the PCI address where image data is being written to
797       P:0002AC P:0002AC 0D02C1  END_WR    JSR     <C_RPXLS                          ; Calculate number of pixels read
798       P:0002AD P:0002AD 511B00            MOVE              B0,X:<PCI_ADDR_0        ; Update PCI Address
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 16



799       P:0002AE P:0002AE 551A00            MOVE              B1,X:<PCI_ADDR_1
800    
801       P:0002AF P:0002AF 448600            MOVE              X:<FLAG_DONE,X0
802       P:0002B0 P:0002B0 441D00            MOVE              X0,X:<HOST_FLAG
803       P:0002B1 P:0002B1 0D0170            JSR     <FO_WRITE_HOST_FLAG               ; Clear Host Flag to 'DONE'
804       P:0002B2 P:0002B2 0A8520            BSET    #HCIE,X:DCTR                      ; Enable host command interrupts
805       P:0002B3 P:0002B3 0C010E            JMP     <GET_FO                           ; We're all done, go process FO input
806    
807                                 ; Core routine for writing 24-bit fiber optic pixels to 16-bit PCI bus register
808       P:0002B4 P:0002B4 01AD80  WR_PIX    JCLR    #EF,X:PDRD,*
                            0002B4
809       P:0002B6 P:0002B6 09453F            MOVEP             Y:RDFIFO,X1             ; Read D15-D08
810       P:0002B7 P:0002B7 01AD80            JCLR    #EF,X:PDRD,*
                            0002B7
811       P:0002B9 P:0002B9 09483F            MOVEP             Y:RDFIFO,A0             ; Read D08-D00
812       P:0002BA P:0002BA 0C1880            EXTRACTU #$008008,A,A
                            008008
813       P:0002BC P:0002BC 0C1960            INSERT  #$008008,X1,A
                            008008
814       P:0002BE P:0002BE 000000            NOP
815       P:0002BF P:0002BF 08C80C            MOVEP             A0,X:DTXM
816       P:0002C0 P:0002C0 00000C            RTS
817    
818                                 ; R_PXLS is the number of pixels read out since the last IIA command
819       P:0002C1 P:0002C1 449900  C_RPXLS   MOVE              X:<BASE_ADDR_0,X0       ; BASE_ADDR is 2 x 16-bits
820       P:0002C2 P:0002C2 459800            MOVE              X:<BASE_ADDR_1,X1
821       P:0002C3 P:0002C3 200013            CLR     A
822       P:0002C4 P:0002C4 212800            MOVE              B0,A0                   ; B is current PCI address
823       P:0002C5 P:0002C5 21AC00            MOVE              B1,A1
824       P:0002C6 P:0002C6 200024            SUB     X,A                               ; Current PCI address - BASE address
825       P:0002C7 P:0002C7 200022            ASR     A                                 ; /2 => convert byte address to pixel
826       P:0002C8 P:0002C8 000000            NOP
827    
828       P:0002C9 P:0002C9 501700            MOVE              A0,X:<R_PXLS_0          ; R_PXLS is 2 x 16 bits, number of
829       P:0002CA P:0002CA 0C1880            EXTRACTU #$010010,A,A                     ;   image pixels read so far
                            010010
830       P:0002CC P:0002CC 000000            NOP
831       P:0002CD P:0002CD 501600            MOVE              A0,X:<R_PXLS_1
832       P:0002CE P:0002CE 00000C            RTS
833    
834                                 ; ***** Test Data Link, Read Memory and Write Memory Commands ******
835    
836                                 ; Test the data link by echoing back ARG1
837                                 TEST_DATA_LINK
838       P:0002CF P:0002CF 44B200            MOVE              X:<ARG1,X0
839       P:0002D0 P:0002D0 0C032F            JMP     <FINISH1
840    
841                                 ; Read from PCI memory. The address is masked to 16 bits, so only
842                                 ;   the bottom 64k words of DRAM will be accessed.
843                                 READ_MEMORY
844       P:0002D1 P:0002D1 56B200            MOVE              X:<ARG1,A               ; Get the address in an accumulator
845       P:0002D2 P:0002D2 0140C6            AND     #$FFFF,A                          ; Mask off only 16 address bits
                            00FFFF
846       P:0002D4 P:0002D4 219000            MOVE              A1,R0                   ; Get the address in an address register
847       P:0002D5 P:0002D5 56B200            MOVE              X:<ARG1,A               ; Get the address in an accumulator
848       P:0002D6 P:0002D6 000000            NOP
849       P:0002D7 P:0002D7 0ACE14            JCLR    #20,A,RDX                         ; Test address bit for Program memory
                            0002DB
850       P:0002D9 P:0002D9 07E084            MOVE              P:(R0),X0               ; Read from Program Memory
851       P:0002DA P:0002DA 0C032F            JMP     <FINISH1                          ; Send out a header with the value
852       P:0002DB P:0002DB 0ACE15  RDX       JCLR    #21,A,RDY                         ; Test address bit for X: memory
                            0002DF
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 17



853       P:0002DD P:0002DD 44E000            MOVE              X:(R0),X0               ; Write to X data memory
854       P:0002DE P:0002DE 0C032F            JMP     <FINISH1                          ; Send out a header with the value
855       P:0002DF P:0002DF 0ACE16  RDY       JCLR    #22,A,RDR                         ; Test address bit for Y: memory
                            0002E3
856       P:0002E1 P:0002E1 4CE000            MOVE                          Y:(R0),X0   ; Read from Y data memory
857       P:0002E2 P:0002E2 0C032F            JMP     <FINISH1                          ; Send out a header with the value
858       P:0002E3 P:0002E3 0ACE17  RDR       JCLR    #23,A,ERROR                       ; Test address bit for read from EEPROM memo
ry
                            000333
859    
860                                 ; Read the word from the PCI board EEPROM
861       P:0002E5 P:0002E5 013D21            BSET    #1,X:PDRC                         ; ROM/FIFO* = 1 to select ROM
862       P:0002E6 P:0002E6 08F4B8            MOVEP             #$008C29,X:AAR1         ; P: = $008000 to $008777 asserts AA1 low tr
ue
                            008C29
863       P:0002E8 P:0002E8 08F4BB            MOVEP             #$0002A0,X:BCR          ; Bus Control Register for slow EEPROM
                            0002A0
864       P:0002EA P:0002EA 458300            MOVE              X:<THREE,X1             ; Convert to word address to a byte address
865       P:0002EB P:0002EB 220400            MOVE              R0,X0                   ; Get 16-bit address in a data register
866       P:0002EC P:0002EC 2000A0            MPY     X1,X0,A                           ; Multiply
867       P:0002ED P:0002ED 200022            ASR     A                                 ; Eliminate zero fill of fractional multiply
868       P:0002EE P:0002EE 211000            MOVE              A0,R0                   ; Need to address memory
869       P:0002EF P:0002EF 0AD06F            BSET    #15,R0                            ; Set bit so its in EEPROM space
870       P:0002F0 P:0002F0 060380            DO      #3,L1RDR
                            0002F4
871       P:0002F2 P:0002F2 07D88A            MOVE              P:(R0)+,A2              ; Read each ROM byte
872       P:0002F3 P:0002F3 0C1C10            ASR     #8,A,A                            ; Move right into A1
873       P:0002F4 P:0002F4 000000            NOP
874                                 L1RDR
875       P:0002F5 P:0002F5 218400            MOVE              A1,X0                   ; Prepare for FINISH1
876       P:0002F6 P:0002F6 013D01            BCLR    #1,X:PDRC                         ; ROM/FIFO* = 0 to select FIFO
877       P:0002F7 P:0002F7 08F4B8            MOVEP             #$FFFC21,X:AAR1         ; Restore FIFO addressing
                            FFFC21
878       P:0002F9 P:0002F9 08F4BB            MOVEP             #$000020,X:BCR          ; Restore fast FIFO access
                            000020
879       P:0002FB P:0002FB 0C032F            JMP     <FINISH1
880    
881                                 ; Program WRMEM - write to PCI memory, reply = DONE host flags. The address is
882                                 ;  masked to 16 bits, so only the bottom 64k words of DRAM will be accessed.
883                                 WRITE_MEMORY
884       P:0002FC P:0002FC 56B200            MOVE              X:<ARG1,A               ; Get the address in an accumulator
885       P:0002FD P:0002FD 0140C6            AND     #$FFFF,A                          ; Mask off only 16 address bits
                            00FFFF
886       P:0002FF P:0002FF 219000            MOVE              A1,R0                   ; Get the address in an address register
887       P:000300 P:000300 56B200            MOVE              X:<ARG1,A               ; Get the address in an accumulator
888       P:000301 P:000301 44B300            MOVE              X:<ARG2,X0              ; Get the data to be written
889       P:000302 P:000302 0ACE14            JCLR    #20,A,WRX                         ; Test address bit for Program memory
                            000306
890       P:000304 P:000304 076084            MOVE              X0,P:(R0)               ; Write to Program memory
891       P:000305 P:000305 0C032C            JMP     <FINISH
892       P:000306 P:000306 0ACE15  WRX       JCLR    #21,A,WRY                         ; Test address bit for X: memory
                            00030A
893       P:000308 P:000308 446000            MOVE              X0,X:(R0)               ; Write to X: memory
894       P:000309 P:000309 0C032C            JMP     <FINISH
895       P:00030A P:00030A 0ACE16  WRY       JCLR    #22,A,WRR                         ; Test address bit for Y: memory
                            00030E
896       P:00030C P:00030C 4C6000            MOVE                          X0,Y:(R0)   ; Write to Y: memory
897       P:00030D P:00030D 0C032C            JMP     <FINISH
898       P:00030E P:00030E 0ACE17  WRR       JCLR    #23,A,ERROR                       ; Test address bit for write to EEPROM
                            000333
899    
900                                 ; Write the word to the on-board PCI EEPROM
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 18



901       P:000310 P:000310 013D21            BSET    #1,X:PDRC                         ; ROM/FIFO* = 1 to select ROM
902       P:000311 P:000311 08F4B8            MOVEP             #$008C29,X:AAR1         ; P: = $008000 to $008777 asserts AA1 low tr
ue
                            008C29
903       P:000313 P:000313 08F4BB            MOVEP             #$0002A0,X:BCR          ; Bus Control Register for slow EEPROM
                            0002A0
904       P:000315 P:000315 458300            MOVE              X:<THREE,X1             ; Convert to word address to a byte address
905       P:000316 P:000316 220400            MOVE              R0,X0                   ; Get 16-bit address in a data register
906       P:000317 P:000317 2000A0            MPY     X1,X0,A                           ; Multiply
907       P:000318 P:000318 200022            ASR     A                                 ; Eliminate zero fill of fractional multiply
908       P:000319 P:000319 211000            MOVE              A0,R0                   ; Need to address memory
909       P:00031A P:00031A 0AD06F            BSET    #15,R0                            ; Set bit so its in EEPROM space
910       P:00031B P:00031B 56B300            MOVE              X:<ARG2,A               ; Get the data to be written, again
911       P:00031C P:00031C 060380            DO      #3,L1WRR                          ; Loop over three bytes of the word
                            000325
912       P:00031E P:00031E 07588C            MOVE              A1,P:(R0)+              ; Write each EEPROM byte
913       P:00031F P:00031F 0C1C10            ASR     #8,A,A                            ; Move right one byte
914       P:000320 P:000320 44F400            MOVE              #400000,X0
                            061A80
915       P:000322 P:000322 06C400            DO      X0,L2WRR                          ; Delay by 5 millisec for EEPROM write
                            000324
916       P:000324 P:000324 000000            NOP
917                                 L2WRR
918       P:000325 P:000325 000000            NOP                                       ; DO loop nesting restriction
919                                 L1WRR
920       P:000326 P:000326 013D01            BCLR    #1,X:PDRC                         ; ROM/FIFO* = 0 to select FIFO
921       P:000327 P:000327 08F4B8            MOVEP             #$FFFC21,X:AAR1         ; Restore FIFO addressing
                            FFFC21
922       P:000329 P:000329 08F4BB            MOVEP             #$000020,X:BCR          ; Restore fast FIFO access
                            000020
923       P:00032B P:00032B 0C032C            JMP     <FINISH
924    
925                                 ;  ***** Subroutines for generating replies to command execution ******
926                                 ; Return from the interrupt with a reply = DONE host flags
927       P:00032C P:00032C 448600  FINISH    MOVE              X:<FLAG_DONE,X0         ; Flag = 1 => Normal execution
928       P:00032D P:00032D 441D00            MOVE              X0,X:<HOST_FLAG
929       P:00032E P:00032E 0C033C            JMP     <RTI_WRITE_HOST_FLAG
930    
931                                 ; Return from the interrupt with value in (X1,X0)
932       P:00032F P:00032F 441C00  FINISH1   MOVE              X0,X:<REPLY             ; Report value
933       P:000330 P:000330 448700            MOVE              X:<FLAG_REPLY,X0        ; Flag = 2 => Reply with a value
934       P:000331 P:000331 441D00            MOVE              X0,X:<HOST_FLAG
935       P:000332 P:000332 0C033C            JMP     <RTI_WRITE_HOST_FLAG
936    
937                                 ; Routine for returning from the interrupt on an error
938       P:000333 P:000333 448800  ERROR     MOVE              X:<FLAG_ERR,X0          ; Flag = 3 => Error value
939       P:000334 P:000334 441D00            MOVE              X0,X:<HOST_FLAG
940       P:000335 P:000335 0C033C            JMP     <RTI_WRITE_HOST_FLAG
941    
942                                 ; Routine for returning from the interrupt with a system reset
943       P:000336 P:000336 448900  SYR       MOVE              X:<FLAG_SYR,X0          ; Flag = 4 => System reset
944       P:000337 P:000337 441D00            MOVE              X0,X:<HOST_FLAG
945       P:000338 P:000338 0C033C            JMP     <RTI_WRITE_HOST_FLAG
946    
947                                 ; Routine for returning a BUSY status from the controller
948       P:000339 P:000339 448B00  BUSY      MOVE              X:<FLAG_BUSY,X0         ; Flag = 6 => Controller is busy
949       P:00033A P:00033A 441D00            MOVE              X0,X:<HOST_FLAG
950       P:00033B P:00033B 0C033C            JMP     <RTI_WRITE_HOST_FLAG
951    
952                                 ; Write X:<HOST_FLAG to the DCTR flag bits 5,4,3, as an interrupt
953                                 RTI_WRITE_HOST_FLAG
954       P:00033C P:00033C 56F000            MOVE              X:DCTR,A
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 19



                            FFFFC5
955       P:00033E P:00033E 449D00            MOVE              X:<HOST_FLAG,X0
956       P:00033F P:00033F 0140C6            AND     #$FFFFC7,A                        ; Clear bits 5,4,3
                            FFFFC7
957       P:000341 P:000341 000000            NOP
958       P:000342 P:000342 200042            OR      X0,A                              ; Set flags appropriately
959       P:000343 P:000343 000000            NOP
960       P:000344 P:000344 567000            MOVE              A,X:DCTR
                            FFFFC5
961       P:000346 P:000346 000004            RTI
962    
963                                 ; Put the reply value into the transmitter FIFO
964                                 READ_REPLY_VALUE
965       P:000347 P:000347 08F08D            MOVEP             X:REPLY,X:DTXS          ; DSP-to-host slave transmit
                            00001C
966       P:000349 P:000349 000004            RTI
967    
968                                 READ_REPLY_HEADER
969       P:00034A P:00034A 44B000            MOVE              X:<HEADER,X0
970       P:00034B P:00034B 0C032F            JMP     <FINISH1
971    
972                                 ; Clear the reply flags and receiver FIFO after a successful reply transaction,
973                                 ;   but leave the Read Image flags set if the controller is reading out.
974                                 CLEAR_HOST_FLAG
975       P:00034C P:00034C 448500            MOVE              X:<FLAG_ZERO,X0
976       P:00034D P:00034D 441D00            MOVE              X0,X:<HOST_FLAG
977       P:00034E P:00034E 44F400            MOVE              #$FFFFC7,X0
                            FFFFC7
978       P:000350 P:000350 56F000            MOVE              X:DCTR,A
                            FFFFC5
979       P:000352 P:000352 200046            AND     X0,A
980       P:000353 P:000353 000000            NOP
981       P:000354 P:000354 547000            MOVE              A1,X:DCTR
                            FFFFC5
982    
983       P:000356 P:000356 0A8982  CLR_RCV   JCLR    #SRRQ,X:DSR,CLR_RTS               ; Wait for the receiver to be empty
                            00035B
984       P:000358 P:000358 08440B            MOVEP             X:DRXR,X0               ; Read receiver to empty it
985       P:000359 P:000359 000000            NOP                                       ; Wait for flag to change
986       P:00035A P:00035A 0C0356            JMP     <CLR_RCV
987                                 CLR_RTS
988       P:00035B P:00035B 000004            RTI
989    
990                                 ; *************  Miscellaneous subroutines used everywhere  *************
991    
992                                 ; Transmit contents of Accumulator A1 to the timing board
993       P:00035C P:00035C 567000  XMT_WRD   MOVE              A,X:SV_A
                            000011
994       P:00035E P:00035E 01B786            JCLR    #TDE,X:SSISR0,*
                            00035E
995       P:000360 P:000360 07F43C            MOVEP             #$000000,X:TX00
                            000000
996       P:000362 P:000362 0D037B            JSR     <XMT_DLY
997       P:000363 P:000363 01B786            JCLR    #TDE,X:SSISR0,*                   ; Start bit
                            000363
998       P:000365 P:000365 07F43C            MOVEP             #$010000,X:TX00
                            010000
999       P:000367 P:000367 0D037B            JSR     <XMT_DLY
1000      P:000368 P:000368 01B786            JCLR    #TDE,X:SSISR0,*
                            000368
1001      P:00036A P:00036A 060380            DO      #3,L_XMIT
                            000370
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 20



1002      P:00036C P:00036C 01B786            JCLR    #TDE,X:SSISR0,*                   ; Three data bytes
                            00036C
1003      P:00036E P:00036E 04CCDC            MOVEP             A1,X:TX00
1004      P:00036F P:00036F 0D037B            JSR     <XMT_DLY
1005      P:000370 P:000370 0C1E90            LSL     #8,A
1006                                L_XMIT
1007      P:000371 P:000371 01B786            JCLR    #TDE,X:SSISR0,*                   ; Zeroes to bring TX00 low
                            000371
1008      P:000373 P:000373 07F43C            MOVEP             #$000000,X:TX00
                            000000
1009      P:000375 P:000375 0D037B            JSR     <XMT_DLY
1010      P:000376 P:000376 56F000            MOVE              X:SV_A,A
                            000011
1011      P:000378 P:000378 06A0AF            REP     #4000                             ; Delay because Gen I timing board
1012      P:000379 P:000379 000000            NOP                                       ;   needs time between serial words
1013      P:00037A P:00037A 00000C            RTS
1014   
1015                                ; Short delay for reliability
1016      P:00037B P:00037B 000000  XMT_DLY   NOP
1017      P:00037C P:00037C 00000C            RTS
1018   
1019                                ; Read one word of the fiber optic FIFO into B1 with a timeout
1020                                RD_FO_TIMEOUT
1021      P:00037D P:00037D 46F400            MOVE              #1000000,Y0             ; 13 millisecond timeout
                            0F4240
1022      P:00037F P:00037F 06C600            DO      Y0,LP_TIM
                            000389
1023      P:000381 P:000381 01AD80            JCLR    #EF,X:PDRD,NOT_YET                ; Test for new fiber optic data
                            000389
1024      P:000383 P:000383 000000            NOP
1025      P:000384 P:000384 000000            NOP
1026      P:000385 P:000385 01AD80            JCLR    #EF,X:PDRD,NOT_YET                ; For metastability, check it twice
                            000389
1027      P:000387 P:000387 00008C            ENDDO
1028      P:000388 P:000388 0C038E            JMP     <RD_FIFO                          ; Go read the FIFO word
1029      P:000389 P:000389 000000  NOT_YET   NOP
1030      P:00038A P:00038A 000000  LP_TIM    NOP
1031      P:00038B P:00038B 0AF960            BSET    #0,SR                             ; Timeout reached, error return
1032      P:00038C P:00038C 000000            NOP
1033      P:00038D P:00038D 00000C            RTS
1034   
1035                                ; Read one word from the fiber optics FIFO and put it in A1
1036      P:00038E P:00038E 09463F  RD_FIFO   MOVEP             Y:RDFIFO,Y0             ; Read D23-D08
1037      P:00038F P:00038F 20001B            CLR     B
1038      P:000390 P:000390 0632A0            REP     #50                               ; Wait for the next FIFO word
1039      P:000391 P:000391 000000            NOP
1040      P:000392 P:000392 09493F            MOVEP             Y:RDFIFO,B0             ; Read D07-D00
1041      P:000393 P:000393 0C1C91            ASR     #8,B,B                            ; Shift D07-D00 into LS bits
1042      P:000394 P:000394 0C1951            INSERT  #$010008,Y0,B                     ; Move D23-D08 into A0
                            010008
1043      P:000396 P:000396 000000            NOP
1044      P:000397 P:000397 212F00            MOVE              B0,B                    ; Move it from B0 to B1
1045      P:000398 P:000398 000000            NOP
1046      P:000399 P:000399 000000            NOP
1047      P:00039A P:00039A 0AF940            BCLR    #0,SR                             ; Clear carry bit => no error
1048      P:00039B P:00039B 000000            NOP
1049      P:00039C P:00039C 00000C            RTS
1050   
1051                                ; ************************  Test on board DRAM  ***********************
1052                                ; Test Y: memory mapped to AA0 and AA2 from $000000 to $FFFFFF (16 megapixels)
1053                                ; DRAM definitions
1054   
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 21



1055                                TEST_DRAM
1056   
1057                                ; Test Y: memory mapped to AA0 and AA2 from $000000 to $FFFFFF (16 megapixels)
1058      P:00039D P:00039D 200013            CLR     A
1059      P:00039E P:00039E 000000            NOP
1060      P:00039F P:00039F 21D000            MOVE              A,R0
1061      P:0003A0 P:0003A0 26FF00            MOVE              #$FF0000,Y0             ; Y:$000000 to Y:$FEFFFF
1062      P:0003A1 P:0003A1 06C600            DO      Y0,L_WRITE_RAM0
                            0003A5
1063      P:0003A3 P:0003A3 5C5800            MOVE                          A1,Y:(R0)+
1064      P:0003A4 P:0003A4 014180            ADD     #1,A
1065      P:0003A5 P:0003A5 000000            NOP
1066                                L_WRITE_RAM0
1067   
1068      P:0003A6 P:0003A6 200013            CLR     A
1069      P:0003A7 P:0003A7 000000            NOP
1070      P:0003A8 P:0003A8 21D000            MOVE              A,R0
1071      P:0003A9 P:0003A9 26FF00            MOVE              #$FF0000,Y0
1072      P:0003AA P:0003AA 06C600            DO      Y0,L_CHECK_RAM0
                            0003B2
1073      P:0003AC P:0003AC 4CD800            MOVE                          Y:(R0)+,X0
1074      P:0003AD P:0003AD 0C1FF8            CMPU    X0,A
1075      P:0003AE P:0003AE 0EA3B1            JEQ     <L_RAM4
1076      P:0003AF P:0003AF 00008C            ENDDO
1077      P:0003B0 P:0003B0 0C03CC            JMP     <ERROR_Y
1078      P:0003B1 P:0003B1 014180  L_RAM4    ADD     #1,A
1079      P:0003B2 P:0003B2 000000            NOP
1080                                L_CHECK_RAM0
1081   
1082                                ; Test X: memory mapped to AA3 from $1000 to $7FFFFF (8 megapixels)
1083      P:0003B3 P:0003B3 200013            CLR     A
1084      P:0003B4 P:0003B4 60F400            MOVE              #$1000,R0               ; Skip over internal X: memory
                            001000
1085      P:0003B6 P:0003B6 46F400            MOVE              #$7FF000,Y0             ; X:$001000 to X:$7FFFFF
                            7FF000
1086      P:0003B8 P:0003B8 06C600            DO      Y0,L_WRITE_RAM3
                            0003BC
1087      P:0003BA P:0003BA 565800            MOVE              A,X:(R0)+
1088      P:0003BB P:0003BB 014180            ADD     #1,A
1089      P:0003BC P:0003BC 000000            NOP
1090                                L_WRITE_RAM3
1091   
1092      P:0003BD P:0003BD 200013            CLR     A
1093      P:0003BE P:0003BE 60F400            MOVE              #$1000,R0
                            001000
1094      P:0003C0 P:0003C0 46F400            MOVE              #$7FF000,Y0
                            7FF000
1095      P:0003C2 P:0003C2 06C600            DO      Y0,L_CHECK_RAM3
                            0003CA
1096      P:0003C4 P:0003C4 44D800            MOVE              X:(R0)+,X0
1097      P:0003C5 P:0003C5 0C1FF8            CMPU    X0,A
1098      P:0003C6 P:0003C6 0EA3C9            JEQ     <L_RAM5
1099      P:0003C7 P:0003C7 00008C            ENDDO
1100      P:0003C8 P:0003C8 0C03D1            JMP     <ERROR_X
1101      P:0003C9 P:0003C9 014180  L_RAM5    ADD     #1,A
1102      P:0003CA P:0003CA 000000            NOP
1103                                L_CHECK_RAM3
1104      P:0003CB P:0003CB 0C032C            JMP     <FINISH
1105   
1106      P:0003CC P:0003CC 44F400  ERROR_Y   MOVE              #'__Y',X0
                            5F5F59
1107      P:0003CE P:0003CE 440F00            MOVE              X0,X:<TRM_MEM
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 22



1108      P:0003CF P:0003CF 601000            MOVE              R0,X:<TRM_ADR
1109      P:0003D0 P:0003D0 0C0333            JMP     <ERROR
1110      P:0003D1 P:0003D1 44F400  ERROR_X   MOVE              #'__X',X0
                            5F5F58
1111      P:0003D3 P:0003D3 440F00            MOVE              X0,X:<TRM_MEM
1112      P:0003D4 P:0003D4 601000            MOVE              R0,X:<TRM_ADR
1113      P:0003D5 P:0003D5 0C0333            JMP     <ERROR
1114   
1115                                ;  ****************  Setup memory tables in X: space ********************
1116   
1117                                ; Define the address in P: space where the table of constants begins
1118   
1119      X:000000 P:0003D6                   ORG     X:VAR_TBL,P:
1120   
1121                                ; Parameters
1122      X:000000 P:0003D6         STATUS    DC      0                                 ; Execution status bits
1123      X:000001 P:0003D7                   DC      0                                 ; Reserved
1124   
1125                                          IF      @SCP("HOST","HOST")               ; Download via host computer
1126                                 CONSTANTS_TBL_START
1127      0003D8                              EQU     @LCV(L)
1128                                          ENDIF
1129   
1130                                          IF      @SCP("HOST","ROM")                ; Boot ROM code
1132                                          ENDIF
1133   
1134                                          IF      @SCP("HOST","ONCE")               ; Download via ONCE debugger
1136                                          ENDIF
1137   
1138                                ; Parameter table in P: space to be copied into X: space during
1139                                ;   initialization, and must be copied from ROM in the boot process
1140      X:000002 P:0003D8         ONE       DC      1                                 ; One
1141      X:000003 P:0003D9         THREE     DC      3                                 ; Three
1142      X:000004 P:0003DA         FOUR      DC      4                                 ; Four
1143   
1144                                ; Host flags are bits 5,4,3 of the HSTR
1145      X:000005 P:0003DB         FLAG_ZERO DC      0                                 ; Flag = 0 => command executing
1146      X:000006 P:0003DC         FLAG_DONE DC      $000008                           ; Flag = 1 => DONE
1147      X:000007 P:0003DD         FLAG_REPLY DC     $000010                           ; Flag = 2 => reply value available
1148      X:000008 P:0003DE         FLAG_ERR  DC      $000018                           ; Flag = 3 => error
1149      X:000009 P:0003DF         FLAG_SYR  DC      $000020                           ; Flag = 4 => controller reset
1150      X:00000A P:0003E0         FLAG_RDI  DC      $000028                           ; Flag = 5 => reading out image
1151      X:00000B P:0003E1         FLAG_BUSY DC      $000030                           ; Flag = 6 => controller is busy
1152      X:00000C P:0003E2         C256      DC      256                               ; 1/2 the FIFO size
1153      X:00000D P:0003E3         C00FF00   DC      $00FF00
1154      X:00000E P:0003E4         C000202   DC      $000202                           ; Timing board header
1155      X:00000F P:0003E5         TRM_MEM   DC      0                                 ; Test DRAM, memory type of failure
1156      X:000010 P:0003E6         TRM_ADR   DC      0                                 ; Test DRAM, address of failure
1157   
1158                                ; Tack the length of the variable table onto the length of code to be booted
1159                                 CONSTANTS_TBL_LENGTH
1160      00000F                              EQU     @CVS(P,*-ONE)                     ; Length of variable table
1161   
1162                                ; Ending address of program so its length can be calculated for bootstrapping
1163                                ; The constants defined after this are NOT initialized, so need not be
1164                                ;    downloaded.
1165   
1166      0003E7                    END_ADR   EQU     @LCV(L)                           ; End address of P: code written to ROM
1167   
1168                                ; Miscellaneous variables
1169      X:000011 P:0003E7         SV_A      DC      0                                 ; Place for saving accumulator A
1170      X:000012 P:0003E8         NPXLS_1   DC      0                                 ; # of pxls in current READ_IMAGE call, MS b
Motorola DSP56300 Assembler  Version 6.3.4   04-03-17  19:20:36  pci1boot.asm  Page 23



yte
1171      X:000013 P:0003E9         NPXLS_0   DC      0                                 ; # of pxls in current READ_IMAGE, LS 24-bit
s
1172      X:000014 P:0003EA         IPXLS_1   DC      0                                 ; Down pixel counter in READ_IMAGE, MS byte
1173      X:000015 P:0003EB         IPXLS_0   DC      0                                 ; Down pixel counter in READ_IMAGE, 24-bits
1174      X:000016 P:0003EC         R_PXLS_1  DC      0                                 ; Up Counter of # of pixels read, MS 16-bits
1175      X:000017 P:0003ED         R_PXLS_0  DC      0                                 ; Up Counter of # of pixels read, LS 16-bits
1176                                 BASE_ADDR_1
1177      X:000018 P:0003EE                   DC      0                                 ; Starting PCI address of image, MS byte
1178                                 BASE_ADDR_0
1179      X:000019 P:0003EF                   DC      0                                 ; Starting PCI address of image, LS 24-bits
1180      X:00001A P:0003F0         PCI_ADDR_1 DC     0                                 ; Current PCI address of image, MS byte
1181      X:00001B P:0003F1         PCI_ADDR_0 DC     0                                 ; Current PCI address of image, LS 24-bits
1182      X:00001C P:0003F2         REPLY     DC      0                                 ; Reply value
1183      X:00001D P:0003F3         HOST_FLAG DC      0                                 ; Value of host flags written to X:DCTR
1184      X:00001E P:0003F4         FO_DEST   DC      0                                 ; Whether host or PCI board receives command
1185      X:00001F P:0003F5         FO_CMD    DC      0                                 ; Fiber optic command or reply
1186   
1187                                ; Check that the parameter table is not too big
1188                                          IF      @CVS(N,*)>=ARG_TBL
1190                                          ENDIF
1191   
1192      X:000030 P:0003F6                   ORG     X:ARG_TBL,P:
1193   
1194                                ; Table that contains the header, command and its arguments
1195      X:000030 P:0003F6         HEADER    DC      0                                 ; (Source, Destination, Number of words)
1196      X:000031 P:0003F7         COMMAND   DC      0                                 ; Manual command
1197      X:000032 P:0003F8         ARG1      DC      0                                 ; First command argument
1198      X:000033 P:0003F9         ARG2      DC      0                                 ; Second command argument
1199                                 DESTINATION
1200      X:000034 P:0003FA                   DC      0                                 ; Derived from header
1201      X:000035 P:0003FB         NUM_ARG   DC      0                                 ; Derived from header
1202   
1203                                ; End of program
1204                                          END

0    Errors
0    Warnings


