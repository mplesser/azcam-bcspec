Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 1



1                          ; ARC22.asm
2      
3                          ; This file is used to generate DSP code for the 250 MHz fiber optic
4                          ; ARC22 timing board using a DSP56303 as its main processor.
5      
6                          ; This version is for 90Prime with ARC47 boards.
7                          ; 07Jan11 last change MPL for 90Prime (slow idle pclock)
8      
9                                    PAGE    132                               ; Printronix page width - 132 columns
10     
11                         ; *** include header,  boot code, and board configuration files ***
12                                   INCLUDE "ARC22_hdr.asm"
13                                COMMENT *
14     
15                         timhdr.asm for ARC22 timing code
16     
17                         This is a header file that is shared between the fiber optic timing board
18                         boot and application code files for Rev. 5 = 250 MHz timing boards
19     
20                         Utility board support version
21     
22                         Last change 29Oct06 MPL
23     
24                                 *
25     
26                                   PAGE    132                               ; Printronix page width - 132 columns
27     
28                         ; Various addressing control registers
29        FFFFFB           BCR       EQU     $FFFFFB                           ; Bus Control Register
30        FFFFF9           AAR0      EQU     $FFFFF9                           ; Address Attribute Register, channel 0
31        FFFFF8           AAR1      EQU     $FFFFF8                           ; Address Attribute Register, channel 1
32        FFFFF7           AAR2      EQU     $FFFFF7                           ; Address Attribute Register, channel 2
33        FFFFF6           AAR3      EQU     $FFFFF6                           ; Address Attribute Register, channel 3
34        FFFFFD           PCTL      EQU     $FFFFFD                           ; PLL control register
35        FFFFFE           IPRP      EQU     $FFFFFE                           ; Interrupt Priority register - Peripheral
36        FFFFFF           IPRC      EQU     $FFFFFF                           ; Interrupt Priority register - Core
37     
38                         ; Port E is the Synchronous Communications Interface (SCI) port
39        FFFF9F           PCRE      EQU     $FFFF9F                           ; Port Control Register
40        FFFF9E           PRRE      EQU     $FFFF9E                           ; Port Direction Register
41        FFFF9D           PDRE      EQU     $FFFF9D                           ; Port Data Register
42        FFFF9C           SCR       EQU     $FFFF9C                           ; SCI Control Register
43        FFFF9B           SCCR      EQU     $FFFF9B                           ; SCI Clock Control Register
44     
45        FFFF9A           SRXH      EQU     $FFFF9A                           ; SCI Receive Data Register, High byte
46        FFFF99           SRXM      EQU     $FFFF99                           ; SCI Receive Data Register, Middle byte
47        FFFF98           SRXL      EQU     $FFFF98                           ; SCI Receive Data Register, Low byte
48     
49        FFFF97           STXH      EQU     $FFFF97                           ; SCI Transmit Data register, High byte
50        FFFF96           STXM      EQU     $FFFF96                           ; SCI Transmit Data register, Middle byte
51        FFFF95           STXL      EQU     $FFFF95                           ; SCI Transmit Data register, Low byte
52     
53        FFFF94           STXA      EQU     $FFFF94                           ; SCI Transmit Address Register
54        FFFF93           SSR       EQU     $FFFF93                           ; SCI Status Register
55     
56        000009           SCITE     EQU     9                                 ; X:SCR bit set to enable the SCI transmitter
57        000008           SCIRE     EQU     8                                 ; X:SCR bit set to enable the SCI receiver
58        000000           TRNE      EQU     0                                 ; This is set in X:SSR when the transmitter
59                                                                             ;  shift and data registers are both empty
60        000001           TDRE      EQU     1                                 ; This is set in X:SSR when the transmitter
61                                                                             ;  data register is empty
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_hdr.asm  Page 2



62        000002           RDRF      EQU     2                                 ; X:SSR bit set when receiver register is full
63        00000F           SELSCI    EQU     15                                ; 1 for SCI to backplane, 0 to front connector
64     
65     
66                         ; ESSI Flags
67        000006           TDE       EQU     6                                 ; Set when transmitter data register is empty
68        000007           RDF       EQU     7                                 ; Set when receiver is full of data
69        000010           TE        EQU     16                                ; Transmitter enable
70     
71                         ; Phase Locked Loop initialization
72        050003           PLL_INIT  EQU     $050003                           ; PLL = 25 MHz x 2 = 100 MHz
73     
74                         ; Port B general purpose I/O
75        FFFFC4           HPCR      EQU     $FFFFC4                           ; Control register (bits 1-6 cleared for GPIO)
76        FFFFC9           HDR       EQU     $FFFFC9                           ; Data register
77        FFFFC8           HDDR      EQU     $FFFFC8                           ; Data Direction Register bits (=1 for output)
78     
79                         ; Port C is Enhanced Synchronous Serial Port 0 = ESSI0
80        FFFFBF           PCRC      EQU     $FFFFBF                           ; Port C Control Register
81        FFFFBE           PRRC      EQU     $FFFFBE                           ; Port C Data direction Register
82        FFFFBD           PDRC      EQU     $FFFFBD                           ; Port C GPIO Data Register
83        FFFFBC           TX00      EQU     $FFFFBC                           ; Transmit Data Register #0
84        FFFFB8           RX0       EQU     $FFFFB8                           ; Receive data register
85        FFFFB7           SSISR0    EQU     $FFFFB7                           ; Status Register
86        FFFFB6           CRB0      EQU     $FFFFB6                           ; Control Register B
87        FFFFB5           CRA0      EQU     $FFFFB5                           ; Control Register A
88     
89                         ; Port D is Enhanced Synchronous Serial Port 1 = ESSI1
90        FFFFAF           PCRD      EQU     $FFFFAF                           ; Port D Control Register
91        FFFFAE           PRRD      EQU     $FFFFAE                           ; Port D Data direction Register
92        FFFFAD           PDRD      EQU     $FFFFAD                           ; Port D GPIO Data Register
93        FFFFAC           TX10      EQU     $FFFFAC                           ; Transmit Data Register 0
94        FFFFA7           SSISR1    EQU     $FFFFA7                           ; Status Register
95        FFFFA6           CRB1      EQU     $FFFFA6                           ; Control Register B
96        FFFFA5           CRA1      EQU     $FFFFA5                           ; Control Register A
97     
98                         ; Timer module addresses
99        FFFF8F           TCSR0     EQU     $FFFF8F                           ; Timer control and status register
100       FFFF8E           TLR0      EQU     $FFFF8E                           ; Timer load register = 0
101       FFFF8D           TCPR0     EQU     $FFFF8D                           ; Timer compare register = exposure time
102       FFFF8C           TCR0      EQU     $FFFF8C                           ; Timer count register = elapsed time
103       FFFF83           TPLR      EQU     $FFFF83                           ; Timer prescaler load register => milliseconds
104       FFFF82           TPCR      EQU     $FFFF82                           ; Timer prescaler count register
105       000000           TIM_BIT   EQU     0                                 ; Set to enable the timer
106       000009           TRM       EQU     9                                 ; Set to enable the timer preloading
107       000015           TCF       EQU     21                                ; Set when timer counter = compare register
108    
109                        ; Board specific addresses and constants
110       FFFFF1           RDFO      EQU     $FFFFF1                           ; Read incoming fiber optic data byte
111       FFFFF2           WRFO      EQU     $FFFFF2                           ; Write fiber optic data replies
112       FFFFF3           WRSS      EQU     $FFFFF3                           ; Write switch state
113       FFFFF5           WRLATCH   EQU     $FFFFF5                           ; Write to a latch
114       010000           RDAD      EQU     $010000                           ; Read A/D values into the DSP
115       000009           EF        EQU     9                                 ; Serial receiver empty flag
116    
117                        ; DSP port A bit equates
118       000000           PWROK     EQU     0                                 ; Power control board says power is OK
119       000001           LED1      EQU     1                                 ; Control one of two LEDs
120       000002           LVEN      EQU     2                                 ; Low voltage power enable
121       000003           HVEN      EQU     3                                 ; High voltage power enable
122       00000E           SSFHF     EQU     14                                ; Switch state FIFO half full flag
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_hdr.asm  Page 3



123    
124                        ; Port D equate
125       000001           SSFEF     EQU     1                                 ; Switch state FIFO empty flag
126    
127                        ; Other equates
128       000002           WRENA     EQU     2                                 ; Enable writing to the EEPROM
129    
130                        ; Latch U12 bit equates
131       000000           CDAC      EQU     0                                 ; Clear the analog board DACs
132       000002           ENCK      EQU     2                                 ; Enable the clock outputs
133       000004           SHUTTER   EQU     4                                 ; Control the shutter
134       000005           TIM_U_RST EQU     5                                 ; Reset the utility board
135    
136                        ; Software status bits, defined at X:<STATUS = X:0
137       000000           ST_RCV    EQU     0                                 ; Set to indicate word is from SCI = utility board
138       000002           IDLMODE   EQU     2                                 ; Set if need to idle after readout
139       000003           ST_SHUT   EQU     3                                 ; Set to indicate shutter is closed, clear for open
140       000004           ST_RDC    EQU     4                                 ; Set if executing 'RDC' command - reading out
141       000005           SPLIT_S   EQU     5                                 ; Set if split serial
142       000006           SPLIT_P   EQU     6                                 ; Set if split parallel
143       000007           MPPMODE   EQU     7                                 ; Set if parallels are in MPP mode - MPL
144       000008           NOT_CLR   EQU     8                                 ; Set if not to clear CCD before exposure
145       00000A           TST_IMG   EQU     10                                ; Set if controller is to generate a test image
146       00000B           SHUT      EQU     11                                ; Set if opening shutter at beginning of exposure
147       00000C           ST_DITH   EQU     12                                ; Set if to dither during exposure
148       00000D           NOREAD    EQU     13                                ; Set if not to call RDCCD after expose MPL
149    
150                        ; Address for the table containing the incoming SCI words
151       000400           SCI_TABLE EQU     $400
152                                  INCLUDE "ARC22_boot.asm"
153                               COMMENT *
154    
155                        This file is used to generate boot DSP code for the 250 MHz fiber optic timing board
156                        using a DSP56303 as its main processor.
157    
158                        Added utility board support Dec. 2002
159                        Integration Dither OFF Aug., 2012
160                                *
161    
162                                  PAGE    132                               ; Printronix page width - 132 columns
163    
164                        ; Special address for two words for the DSP to bootstrap code from the EEPROM
165                                  IF      @SCP("HOST","ROM")
172                                  ENDIF
173    
174                                  IF      @SCP("HOST","HOST")
175       P:000000 P:000000                   ORG     P:0,P:0
176       P:000000 P:000000 0C018E            JMP     <INIT
177       P:000001 P:000001 000000            NOP
178                                           ENDIF
179    
180                                 ;  This ISR receives serial words a byte at a time over the asynchronous
181                                 ;    serial link (SCI) and squashes them into a single 24-bit word
182       P:000002 P:000002 602400  SCI_RCV   MOVE              R0,X:<SAVE_R0           ; Save R0
183       P:000003 P:000003 052139            MOVEC             SR,X:<SAVE_SR           ; Save Status Register
184       P:000004 P:000004 60A700            MOVE              X:<SCI_R0,R0            ; Restore R0 = pointer to SCI receive regist
er
185       P:000005 P:000005 542300            MOVE              A1,X:<SAVE_A1           ; Save A1
186       P:000006 P:000006 452200            MOVE              X1,X:<SAVE_X1           ; Save X1
187       P:000007 P:000007 54A600            MOVE              X:<SCI_A1,A1            ; Get SRX value of accumulator contents
188       P:000008 P:000008 45E000            MOVE              X:(R0),X1               ; Get the SCI byte
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 4



189       P:000009 P:000009 0AD041            BCLR    #1,R0                             ; Test for the address being $FFF6 = last by
te
190       P:00000A P:00000A 000000            NOP
191       P:00000B P:00000B 000000            NOP
192       P:00000C P:00000C 000000            NOP
193       P:00000D P:00000D 205862            OR      X1,A      (R0)+                   ; Add the byte into the 24-bit word
194       P:00000E P:00000E 0E0013            JCC     <MID_BYT                          ; Not the last byte => only restore register
s
195       P:00000F P:00000F 545C00  END_BYT   MOVE              A1,X:(R4)+              ; Put the 24-bit word into the SCI buffer
196       P:000010 P:000010 60F400            MOVE              #SRXL,R0                ; Re-establish first address of SCI interfac
e
                            FFFF98
197       P:000012 P:000012 2C0000            MOVE              #0,A1                   ; For zeroing out SCI_A1
198       P:000013 P:000013 602700  MID_BYT   MOVE              R0,X:<SCI_R0            ; Save the SCI receiver address
199       P:000014 P:000014 542600            MOVE              A1,X:<SCI_A1            ; Save A1 for next interrupt
200       P:000015 P:000015 05A139            MOVEC             X:<SAVE_SR,SR           ; Restore Status Register
201       P:000016 P:000016 54A300            MOVE              X:<SAVE_A1,A1           ; Restore A1
202       P:000017 P:000017 45A200            MOVE              X:<SAVE_X1,X1           ; Restore X1
203       P:000018 P:000018 60A400            MOVE              X:<SAVE_R0,R0           ; Restore R0
204       P:000019 P:000019 000004            RTI                                       ; Return from interrupt service
205    
206                                 ; Clear error condition and interrupt on SCI receiver
207       P:00001A P:00001A 077013  CLR_ERR   MOVEP             X:SSR,X:RCV_ERR         ; Read SCI status register
                            000025
208       P:00001C P:00001C 077018            MOVEP             X:SRXL,X:RCV_ERR        ; This clears any error
                            000025
209       P:00001E P:00001E 000004            RTI
210    
211       P:00001F P:00001F                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
212       P:000030 P:000030                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
213       P:000040 P:000040                   DC      0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
214    
215                                 ; Tune the table so the following instruction is at P:$50 exactly.
216       P:000050 P:000050 0D0002            JSR     SCI_RCV                           ; SCI receive data interrupt
217       P:000051 P:000051 000000            NOP
218       P:000052 P:000052 0D001A            JSR     CLR_ERR                           ; SCI receive error interrupt
219       P:000053 P:000053 000000            NOP
220    
221                                 ; *******************  Command Processing  ******************
222    
223                                 ; Read the header and check it for self-consistency
224       P:000054 P:000054 609F00  START     MOVE              X:<IDL_ADR,R0
225       P:000055 P:000055 018FA0            JSET    #TIM_BIT,X:TCSR0,CHK_TIM          ; MPL If exposing go check the timer
                            000372
226                                 ;       JSET    #ST_RDC,X:<STATUS,CONTINUE_READING
227       P:000057 P:000057 0AE080            JMP     (R0)
228    
229       P:000058 P:000058 330700  TST_RCV   MOVE              #<COM_BUF,R3
230       P:000059 P:000059 0D00A3            JSR     <GET_RCV
231       P:00005A P:00005A 0E0059            JCC     *-1
232    
233                                 ; Check the header and read all the remaining words in the command
234       P:00005B P:00005B 0C00FD  PRC_RCV   JMP     <CHK_HDR                          ; Update HEADER and NWORDS
235       P:00005C P:00005C 578600  PR_RCV    MOVE              X:<NWORDS,B             ; Read this many words total in the command
236       P:00005D P:00005D 000000            NOP
237       P:00005E P:00005E 01418C            SUB     #1,B                              ; We've already read the header
238       P:00005F P:00005F 000000            NOP
239       P:000060 P:000060 06CF00            DO      B,RD_COM
                            000068
240       P:000062 P:000062 205B00            MOVE              (R3)+                   ; Increment past what's been read already
241       P:000063 P:000063 0B0080  GET_WRD   JSCLR   #ST_RCV,X:STATUS,CHK_FO
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 5



                            0000A7
242       P:000065 P:000065 0B00A0            JSSET   #ST_RCV,X:STATUS,CHK_SCI
                            0000D3
243       P:000067 P:000067 0E0063            JCC     <GET_WRD
244       P:000068 P:000068 000000            NOP
245       P:000069 P:000069 330700  RD_COM    MOVE              #<COM_BUF,R3            ; Restore R3 = beginning of the command
246    
247                                 ; Is this command for the timing board?
248       P:00006A P:00006A 448500            MOVE              X:<HEADER,X0
249       P:00006B P:00006B 579B00            MOVE              X:<DMASK,B
250       P:00006C P:00006C 459A4E            AND     X0,B      X:<TIM_DRB,X1           ; Extract destination byte
251       P:00006D P:00006D 20006D            CMP     X1,B                              ; Does header = timing board number?
252       P:00006E P:00006E 0EA07E            JEQ     <COMMAND                          ; Yes, process it here
253       P:00006F P:00006F 0E909B            JLT     <FO_XMT                           ; Send it to fiber optic transmitter
254    
255                                 ; Transmit the command to the utility board over the SCI port
256       P:000070 P:000070 060600            DO      X:<NWORDS,DON_XMT                 ; Transmit NWORDS
                            00007C
257       P:000072 P:000072 60F400            MOVE              #STXL,R0                ; SCI first byte address
                            FFFF95
258       P:000074 P:000074 44DB00            MOVE              X:(R3)+,X0              ; Get the 24-bit word to transmit
259       P:000075 P:000075 060380            DO      #3,SCI_SPT
                            00007B
260       P:000077 P:000077 019381            JCLR    #TDRE,X:SSR,*                     ; Continue ONLY if SCI XMT is empty
                            000077
261       P:000079 P:000079 445800            MOVE              X0,X:(R0)+              ; Write to SCI, byte pointer + 1
262       P:00007A P:00007A 000000            NOP                                       ; Delay for the status flag to be set
263       P:00007B P:00007B 000000            NOP
264                                 SCI_SPT
265       P:00007C P:00007C 000000            NOP
266                                 DON_XMT
267       P:00007D P:00007D 0C0054            JMP     <START
268    
269                                 ; Process the receiver entry - is it in the command table ?
270       P:00007E P:00007E 0203DF  COMMAND   MOVE              X:(R3+1),B              ; Get the command
271       P:00007F P:00007F 205B00            MOVE              (R3)+
272       P:000080 P:000080 205B00            MOVE              (R3)+                   ; Point R3 to the first argument
273       P:000081 P:000081 302800            MOVE              #<COM_TBL,R0            ; Get the command table starting address
274       P:000082 P:000082 061E80            DO      #NUM_COM,END_COM                  ; Loop over the command table
                            000089
275       P:000084 P:000084 47D800            MOVE              X:(R0)+,Y1              ; Get the command table entry
276       P:000085 P:000085 62E07D            CMP     Y1,B      X:(R0),R2               ; Does receiver = table entries address?
277       P:000086 P:000086 0E2089            JNE     <NOT_COM                          ; No, keep looping
278       P:000087 P:000087 00008C            ENDDO                                     ; Restore the DO loop system registers
279       P:000088 P:000088 0AE280            JMP     (R2)                              ; Jump execution to the command
280       P:000089 P:000089 205800  NOT_COM   MOVE              (R0)+                   ; Increment the register past the table addr
ess
281                                 END_COM
282       P:00008A P:00008A 0C008B            JMP     <ERROR                            ; The command is not in the table
283    
284                                 ; It's not in the command table - send an error message
285       P:00008B P:00008B 479D00  ERROR     MOVE              X:<ERR,Y1               ; Send the message - there was an error
286       P:00008C P:00008C 0C008E            JMP     <FINISH1                          ; This protects against unknown commands
287    
288                                 ; Send a reply packet - header and reply
289       P:00008D P:00008D 479800  FINISH    MOVE              X:<DONE,Y1              ; Send 'DON' as the reply
290       P:00008E P:00008E 578500  FINISH1   MOVE              X:<HEADER,B             ; Get header of incoming command
291       P:00008F P:00008F 469C00            MOVE              X:<SMASK,Y0             ; This was the source byte, and is to
292       P:000090 P:000090 330700            MOVE              #<COM_BUF,R3            ;     become the destination byte
293       P:000091 P:000091 46935E            AND     Y0,B      X:<TWO,Y0
294       P:000092 P:000092 0C1ED1            LSR     #8,B                              ; Shift right eight bytes, add it to the
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 6



295       P:000093 P:000093 460600            MOVE              Y0,X:<NWORDS            ;     header, and put 2 as the number
296       P:000094 P:000094 469958            ADD     Y0,B      X:<SBRD,Y0              ;     of words in the string
297       P:000095 P:000095 200058            ADD     Y0,B                              ; Add source board's header, set Y1 for abov
e
298       P:000096 P:000096 000000            NOP
299       P:000097 P:000097 575B00            MOVE              B,X:(R3)+               ; Put the new header on the transmitter stac
k
300       P:000098 P:000098 475B00            MOVE              Y1,X:(R3)+              ; Put the argument on the transmitter stack
301       P:000099 P:000099 570500            MOVE              B,X:<HEADER
302       P:00009A P:00009A 0C0069            JMP     <RD_COM                           ; Decide where to send the reply, and do it
303    
304                                 ; Transmit words to the host computer over the fiber optics link
305       P:00009B P:00009B 63F400  FO_XMT    MOVE              #COM_BUF,R3
                            000007
306       P:00009D P:00009D 060600            DO      X:<NWORDS,DON_FFO                 ; Transmit all the words in the command
                            0000A1
307       P:00009F P:00009F 57DB00            MOVE              X:(R3)+,B
308       P:0000A0 P:0000A0 0D00E9            JSR     <XMT_WRD
309       P:0000A1 P:0000A1 000000            NOP
310       P:0000A2 P:0000A2 0C0054  DON_FFO   JMP     <START
311    
312                                 ; Check for commands from the fiber optic FIFO and the utility board (SCI)
313       P:0000A3 P:0000A3 0D00A7  GET_RCV   JSR     <CHK_FO                           ; Check for fiber optic command from FIFO
314       P:0000A4 P:0000A4 0E80A6            JCS     <RCV_RTS                          ; If there's a command, check the header
315       P:0000A5 P:0000A5 0D00D3            JSR     <CHK_SCI                          ; Check for an SCI command
316       P:0000A6 P:0000A6 00000C  RCV_RTS   RTS
317    
318                                 ; Because of FIFO metastability require that EF be stable for two tests
319       P:0000A7 P:0000A7 0A8989  CHK_FO    JCLR    #EF,X:HDR,TST2                    ; EF = Low,  Low  => CLR SR, return
                            0000AA
320       P:0000A9 P:0000A9 0C00AD            JMP     <TST3                             ;      High, Low  => try again
321       P:0000AA P:0000AA 0A8989  TST2      JCLR    #EF,X:HDR,CLR_CC                  ;      Low,  High => try again
                            0000CF
322       P:0000AC P:0000AC 0C00A7            JMP     <CHK_FO                           ;      High, High => read FIFO
323       P:0000AD P:0000AD 0A8989  TST3      JCLR    #EF,X:HDR,CHK_FO
                            0000A7
324    
325       P:0000AF P:0000AF 08F4BB            MOVEP             #$028FE2,X:BCR          ; Slow down RDFO access
                            028FE2
326       P:0000B1 P:0000B1 000000            NOP
327       P:0000B2 P:0000B2 000000            NOP
328       P:0000B3 P:0000B3 5FF000            MOVE                          Y:RDFO,B
                            FFFFF1
329       P:0000B5 P:0000B5 2B0000            MOVE              #0,B2
330       P:0000B6 P:0000B6 0140CE            AND     #$FF,B
                            0000FF
331       P:0000B8 P:0000B8 0140CD            CMP     #>$AC,B                           ; It must be $AC to be a valid word
                            0000AC
332       P:0000BA P:0000BA 0E20CF            JNE     <CLR_CC
333       P:0000BB P:0000BB 4EF000            MOVE                          Y:RDFO,Y0   ; Read the MS byte
                            FFFFF1
334       P:0000BD P:0000BD 0C1951            INSERT  #$008010,Y0,B
                            008010
335       P:0000BF P:0000BF 4EF000            MOVE                          Y:RDFO,Y0   ; Read the middle byte
                            FFFFF1
336       P:0000C1 P:0000C1 0C1951            INSERT  #$008008,Y0,B
                            008008
337       P:0000C3 P:0000C3 4EF000            MOVE                          Y:RDFO,Y0   ; Read the LS byte
                            FFFFF1
338       P:0000C5 P:0000C5 0C1951            INSERT  #$008000,Y0,B
                            008000
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 7



339       P:0000C7 P:0000C7 000000            NOP
340       P:0000C8 P:0000C8 516300            MOVE              B0,X:(R3)               ; Put the word into COM_BUF
341       P:0000C9 P:0000C9 0A0000            BCLR    #ST_RCV,X:<STATUS                 ; Its a command from the host computer
342       P:0000CA P:0000CA 000000  SET_CC    NOP
343       P:0000CB P:0000CB 0AF960            BSET    #0,SR                             ; Valid word => SR carry bit = 1
344       P:0000CC P:0000CC 08F4BB            MOVEP             #$028FE1,X:BCR          ; Restore RDFO access
                            028FE1
345       P:0000CE P:0000CE 00000C            RTS
346       P:0000CF P:0000CF 0AF940  CLR_CC    BCLR    #0,SR                             ; Not valid word => SR carry bit = 0
347       P:0000D0 P:0000D0 08F4BB            MOVEP             #$028FE1,X:BCR          ; Restore RDFO access
                            028FE1
348       P:0000D2 P:0000D2 00000C            RTS
349    
350                                 ; Test the SCI (= synchronous communications interface) for new words
351       P:0000D3 P:0000D3 44F000  CHK_SCI   MOVE              X:(SCI_TABLE+33),X0
                            000421
352       P:0000D5 P:0000D5 228E00            MOVE              R4,A
353       P:0000D6 P:0000D6 209000            MOVE              X0,R0
354       P:0000D7 P:0000D7 200045            CMP     X0,A
355       P:0000D8 P:0000D8 0EA0CF            JEQ     <CLR_CC                           ; There is no new SCI word
356       P:0000D9 P:0000D9 44D800            MOVE              X:(R0)+,X0
357       P:0000DA P:0000DA 446300            MOVE              X0,X:(R3)
358       P:0000DB P:0000DB 220E00            MOVE              R0,A
359       P:0000DC P:0000DC 0140C5            CMP     #(SCI_TABLE+32),A                 ; Wrap it around the circular
                            000420
360       P:0000DE P:0000DE 0EA0E2            JEQ     <INIT_PROCESSED_SCI               ;   buffer boundary
361       P:0000DF P:0000DF 547000            MOVE              A1,X:(SCI_TABLE+33)
                            000421
362       P:0000E1 P:0000E1 0C00E7            JMP     <SCI_END
363                                 INIT_PROCESSED_SCI
364       P:0000E2 P:0000E2 56F400            MOVE              #SCI_TABLE,A
                            000400
365       P:0000E4 P:0000E4 000000            NOP
366       P:0000E5 P:0000E5 567000            MOVE              A,X:(SCI_TABLE+33)
                            000421
367       P:0000E7 P:0000E7 0A0020  SCI_END   BSET    #ST_RCV,X:<STATUS                 ; Its a utility board (SCI) word
368       P:0000E8 P:0000E8 0C00CA            JMP     <SET_CC
369    
370                                 ; Transmit the word in B1 to the host computer over the fiber optic data link
371                                 XMT_WRD
372       P:0000E9 P:0000E9 08F4BB            MOVEP             #$028FE2,X:BCR          ; Slow down RDFO access
                            028FE2
373       P:0000EB P:0000EB 60F400            MOVE              #FO_HDR+1,R0
                            000002
374       P:0000ED P:0000ED 060380            DO      #3,XMT_WRD1
                            0000F1
375       P:0000EF P:0000EF 0C1D91            ASL     #8,B,B
376       P:0000F0 P:0000F0 000000            NOP
377       P:0000F1 P:0000F1 535800            MOVE              B2,X:(R0)+
378                                 XMT_WRD1
379       P:0000F2 P:0000F2 60F400            MOVE              #FO_HDR,R0
                            000001
380       P:0000F4 P:0000F4 61F400            MOVE              #WRFO,R1
                            FFFFF2
381       P:0000F6 P:0000F6 060480            DO      #4,XMT_WRD2
                            0000F9
382       P:0000F8 P:0000F8 46D800            MOVE              X:(R0)+,Y0              ; Should be MOVEP  X:(R0)+,Y:WRFO
383       P:0000F9 P:0000F9 4E6100            MOVE                          Y0,Y:(R1)
384                                 XMT_WRD2
385       P:0000FA P:0000FA 08F4BB            MOVEP             #$028FE1,X:BCR          ; Restore RDFO access
                            028FE1
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 8



386       P:0000FC P:0000FC 00000C            RTS
387    
388                                 ; Check the command or reply header in X:(R3) for self-consistency
389       P:0000FD P:0000FD 46E300  CHK_HDR   MOVE              X:(R3),Y0
390       P:0000FE P:0000FE 579600            MOVE              X:<MASK1,B              ; Test for S.LE.3 and D.LE.3 and N.LE.7
391       P:0000FF P:0000FF 20005E            AND     Y0,B
392       P:000100 P:000100 0E208B            JNE     <ERROR                            ; Test failed
393       P:000101 P:000101 579700            MOVE              X:<MASK2,B              ; Test for either S.NE.0 or D.NE.0
394       P:000102 P:000102 20005E            AND     Y0,B
395       P:000103 P:000103 0EA08B            JEQ     <ERROR                            ; Test failed
396       P:000104 P:000104 579500            MOVE              X:<SEVEN,B
397       P:000105 P:000105 20005E            AND     Y0,B                              ; Extract NWORDS, must be > 0
398       P:000106 P:000106 0EA08B            JEQ     <ERROR
399       P:000107 P:000107 44E300            MOVE              X:(R3),X0
400       P:000108 P:000108 440500            MOVE              X0,X:<HEADER            ; Its a correct header
401       P:000109 P:000109 550600            MOVE              B1,X:<NWORDS            ; Number of words in the command
402       P:00010A P:00010A 0C005C            JMP     <PR_RCV
403    
404                                 ;  *****************  Boot Commands  *******************
405    
406                                 ; Test Data Link - simply return value received after 'TDL'
407       P:00010B P:00010B 47DB00  TDL       MOVE              X:(R3)+,Y1              ; Get the data value
408       P:00010C P:00010C 0C008E            JMP     <FINISH1                          ; Return from executing TDL command
409    
410                                 ; Read DSP or EEPROM memory ('RDM' address): read memory, reply with value
411       P:00010D P:00010D 47DB00  RDMEM     MOVE              X:(R3)+,Y1
412       P:00010E P:00010E 20EF00            MOVE              Y1,B
413       P:00010F P:00010F 0140CE            AND     #$0FFFFF,B                        ; Bits 23-20 need to be zeroed
                            0FFFFF
414       P:000111 P:000111 21B000            MOVE              B1,R0                   ; Need the address in an address register
415       P:000112 P:000112 20EF00            MOVE              Y1,B
416       P:000113 P:000113 000000            NOP
417       P:000114 P:000114 0ACF14            JCLR    #20,B,RDX                         ; Test address bit for Program memory
                            000118
418       P:000116 P:000116 07E087            MOVE              P:(R0),Y1               ; Read from Program Memory
419       P:000117 P:000117 0C008E            JMP     <FINISH1                          ; Send out a header with the value
420       P:000118 P:000118 0ACF15  RDX       JCLR    #21,B,RDY                         ; Test address bit for X: memory
                            00011C
421       P:00011A P:00011A 47E000            MOVE              X:(R0),Y1               ; Write to X data memory
422       P:00011B P:00011B 0C008E            JMP     <FINISH1                          ; Send out a header with the value
423       P:00011C P:00011C 0ACF16  RDY       JCLR    #22,B,RDR                         ; Test address bit for Y: memory
                            000120
424       P:00011E P:00011E 4FE000            MOVE                          Y:(R0),Y1   ; Read from Y data memory
425       P:00011F P:00011F 0C008E            JMP     <FINISH1                          ; Send out a header with the value
426       P:000120 P:000120 0ACF17  RDR       JCLR    #23,B,ERROR                       ; Test address bit for read from EEPROM memo
ry
                            00008B
427       P:000122 P:000122 479400            MOVE              X:<THREE,Y1             ; Convert to word address to a byte address
428       P:000123 P:000123 220600            MOVE              R0,Y0                   ; Get 16-bit address in a data register
429       P:000124 P:000124 2000B8            MPY     Y0,Y1,B                           ; Multiply
430       P:000125 P:000125 20002A            ASR     B                                 ; Eliminate zero fill of fractional multiply
431       P:000126 P:000126 213000            MOVE              B0,R0                   ; Need to address memory
432       P:000127 P:000127 0AD06F            BSET    #15,R0                            ; Set bit so its in EEPROM space
433       P:000128 P:000128 0D0176            JSR     <RD_WORD                          ; Read word from EEPROM
434       P:000129 P:000129 21A700            MOVE              B1,Y1                   ; FINISH1 transmits Y1 as its reply
435       P:00012A P:00012A 0C008E            JMP     <FINISH1
436    
437                                 ; Program WRMEM ('WRM' address datum): write to memory, reply 'DON'.
438       P:00012B P:00012B 47DB00  WRMEM     MOVE              X:(R3)+,Y1              ; Get the address to be written to
439       P:00012C P:00012C 20EF00            MOVE              Y1,B
440       P:00012D P:00012D 0140CE            AND     #$0FFFFF,B                        ; Bits 23-20 need to be zeroed
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 9



                            0FFFFF
441       P:00012F P:00012F 21B000            MOVE              B1,R0                   ; Need the address in an address register
442       P:000130 P:000130 20EF00            MOVE              Y1,B
443       P:000131 P:000131 46DB00            MOVE              X:(R3)+,Y0              ; Get datum into Y0 so MOVE works easily
444       P:000132 P:000132 0ACF14            JCLR    #20,B,WRX                         ; Test address bit for Program memory
                            000136
445       P:000134 P:000134 076086            MOVE              Y0,P:(R0)               ; Write to Program memory
446       P:000135 P:000135 0C008D            JMP     <FINISH
447       P:000136 P:000136 0ACF15  WRX       JCLR    #21,B,WRY                         ; Test address bit for X: memory
                            00013A
448       P:000138 P:000138 466000            MOVE              Y0,X:(R0)               ; Write to X: memory
449       P:000139 P:000139 0C008D            JMP     <FINISH
450       P:00013A P:00013A 0ACF16  WRY       JCLR    #22,B,WRR                         ; Test address bit for Y: memory
                            00013E
451       P:00013C P:00013C 4E6000            MOVE                          Y0,Y:(R0)   ; Write to Y: memory
452       P:00013D P:00013D 0C008D            JMP     <FINISH
453       P:00013E P:00013E 0ACF17  WRR       JCLR    #23,B,ERROR                       ; Test address bit for write to EEPROM
                            00008B
454       P:000140 P:000140 013D02            BCLR    #WRENA,X:PDRC                     ; WR_ENA* = 0 to enable EEPROM writing
455       P:000141 P:000141 460E00            MOVE              Y0,X:<SV_A1             ; Save the datum to be written
456       P:000142 P:000142 479400            MOVE              X:<THREE,Y1             ; Convert word address to a byte address
457       P:000143 P:000143 220600            MOVE              R0,Y0                   ; Get 16-bit address in a data register
458       P:000144 P:000144 2000B8            MPY     Y1,Y0,B                           ; Multiply
459       P:000145 P:000145 20002A            ASR     B                                 ; Eliminate zero fill of fractional multiply
460       P:000146 P:000146 213000            MOVE              B0,R0                   ; Need to address memory
461       P:000147 P:000147 0AD06F            BSET    #15,R0                            ; Set bit so its in EEPROM space
462       P:000148 P:000148 558E00            MOVE              X:<SV_A1,B1             ; Get the datum to be written
463       P:000149 P:000149 060380            DO      #3,L1WRR                          ; Loop over three bytes of the word
                            000152
464       P:00014B P:00014B 07588D            MOVE              B1,P:(R0)+              ; Write each EEPROM byte
465       P:00014C P:00014C 0C1C91            ASR     #8,B,B
466       P:00014D P:00014D 469E00            MOVE              X:<C100K,Y0             ; Move right one byte, enter delay = 1 msec
467       P:00014E P:00014E 06C600            DO      Y0,L2WRR                          ; Delay by 12 milliseconds for EEPROM write
                            000151
468       P:000150 P:000150 060CA0            REP     #12                               ; Assume 100 MHz DSP56303
469       P:000151 P:000151 000000            NOP
470                                 L2WRR
471       P:000152 P:000152 000000            NOP                                       ; DO loop nesting restriction
472                                 L1WRR
473       P:000153 P:000153 013D22            BSET    #WRENA,X:PDRC                     ; WR_ENA* = 1 to disable EEPROM writing
474       P:000154 P:000154 0C008D            JMP     <FINISH
475    
476                                 ; Load application code from P: memory into its proper locations
477       P:000155 P:000155 47DB00  LDAPPL    MOVE              X:(R3)+,Y1              ; Application number, not used yet
478       P:000156 P:000156 0D0158            JSR     <LOAD_APPLICATION
479       P:000157 P:000157 0C008D            JMP     <FINISH
480    
481                                 LOAD_APPLICATION
482       P:000158 P:000158 60F400            MOVE              #$8000,R0               ; Starting EEPROM address
                            008000
483       P:00015A P:00015A 0D0176            JSR     <RD_WORD                          ; Number of words in boot code
484       P:00015B P:00015B 21A600            MOVE              B1,Y0
485       P:00015C P:00015C 479400            MOVE              X:<THREE,Y1
486       P:00015D P:00015D 2000B8            MPY     Y0,Y1,B
487       P:00015E P:00015E 20002A            ASR     B
488       P:00015F P:00015F 213000            MOVE              B0,R0                   ; EEPROM address of start of P: application
489       P:000160 P:000160 0AD06F            BSET    #15,R0                            ; To access EEPROM
490       P:000161 P:000161 0D0176            JSR     <RD_WORD                          ; Read number of words in application P:
491       P:000162 P:000162 61F400            MOVE              #(X_BOOT_START+1),R1    ; End of boot P: code that needs keeping
                            000226
492       P:000164 P:000164 06CD00            DO      B1,RD_APPL_P
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 10



                            000167
493       P:000166 P:000166 0D0176            JSR     <RD_WORD
494       P:000167 P:000167 07598D            MOVE              B1,P:(R1)+
495                                 RD_APPL_P
496       P:000168 P:000168 0D0176            JSR     <RD_WORD                          ; Read number of words in application X:
497       P:000169 P:000169 61F400            MOVE              #END_COMMAND_TABLE,R1
                            000036
498       P:00016B P:00016B 06CD00            DO      B1,RD_APPL_X
                            00016E
499       P:00016D P:00016D 0D0176            JSR     <RD_WORD
500       P:00016E P:00016E 555900            MOVE              B1,X:(R1)+
501                                 RD_APPL_X
502       P:00016F P:00016F 0D0176            JSR     <RD_WORD                          ; Read number of words in application Y:
503       P:000170 P:000170 310100            MOVE              #1,R1                   ; There is no Y: memory in the boot code
504       P:000171 P:000171 06CD00            DO      B1,RD_APPL_Y
                            000174
505       P:000173 P:000173 0D0176            JSR     <RD_WORD
506       P:000174 P:000174 5D5900            MOVE                          B1,Y:(R1)+
507                                 RD_APPL_Y
508       P:000175 P:000175 00000C            RTS
509    
510                                 ; Read one word from EEPROM location R0 into accumulator B1
511       P:000176 P:000176 060380  RD_WORD   DO      #3,L_RDBYTE
                            000179
512       P:000178 P:000178 07D88B            MOVE              P:(R0)+,B2
513       P:000179 P:000179 0C1C91            ASR     #8,B,B
514                                 L_RDBYTE
515       P:00017A P:00017A 00000C            RTS
516    
517                                 ; Come to here on a 'STP' command so 'DON' can be sent
518                                 STOP_IDLE_CLOCKING
519       P:00017B P:00017B 305800            MOVE              #<TST_RCV,R0            ; Execution address when idle => when not
520       P:00017C P:00017C 601F00            MOVE              R0,X:<IDL_ADR           ;   processing commands or reading out
521       P:00017D P:00017D 0A0002            BCLR    #IDLMODE,X:<STATUS                ; Don't idle after readout
522       P:00017E P:00017E 0C008D            JMP     <FINISH
523    
524                                 ; Routines executed after the DSP boots and initializes
525       P:00017F P:00017F 305800  STARTUP   MOVE              #<TST_RCV,R0            ; Execution address when idle => when not
526       P:000180 P:000180 601F00            MOVE              R0,X:<IDL_ADR           ;   processing commands or reading out
527       P:000181 P:000181 44F400            MOVE              #50000,X0               ; Delay by 500 milliseconds
                            00C350
528       P:000183 P:000183 06C400            DO      X0,L_DELAY
                            000186
529       P:000185 P:000185 06E8A3            REP     #1000
530       P:000186 P:000186 000000            NOP
531                                 L_DELAY
532       P:000187 P:000187 57F400            MOVE              #$020002,B              ; Normal reply after booting is 'SYR'
                            020002
533       P:000189 P:000189 0D00E9            JSR     <XMT_WRD
534       P:00018A P:00018A 57F400            MOVE              #'SYR',B
                            535952
535       P:00018C P:00018C 0D00E9            JSR     <XMT_WRD
536    
537       P:00018D P:00018D 0C0054            JMP     <START                            ; Start normal command processing
538    
539                                 ; *******************  DSP  INITIALIZATION  CODE  **********************
540                                 ; This code initializes the DSP right after booting, and is overwritten
541                                 ;   by application code
542       P:00018E P:00018E 08F4BD  INIT      MOVEP             #PLL_INIT,X:PCTL        ; Initialize PLL to 100 MHz
                            050003
543       P:000190 P:000190 000000            NOP
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 11



544    
545                                 ; Set operation mode register OMR to normal expanded
546       P:000191 P:000191 0500BA            MOVEC             #$0000,OMR              ; Operating Mode Register = Normal Expanded
547       P:000192 P:000192 0500BB            MOVEC             #0,SP                   ; Reset the Stack Pointer SP
548    
549                                 ; Program the AA = address attribute pins
550       P:000193 P:000193 08F4B9            MOVEP             #$FFFC21,X:AAR0         ; Y = $FFF000 to $FFFFFF asserts commands
                            FFFC21
551       P:000195 P:000195 08F4B8            MOVEP             #$008909,X:AAR1         ; P = $008000 to $00FFFF accesses the EEPROM
                            008909
552       P:000197 P:000197 08F4B7            MOVEP             #$010C11,X:AAR2         ; X = $010000 to $010FFF reads A/D values
                            010C11
553       P:000199 P:000199 08F4B6            MOVEP             #$080621,X:AAR3         ; Y = $080000 to $0BFFFF R/W from SRAM
                            080621
554    
555                                 ; Program the DRAM memory access and addressing
556       P:00019B P:00019B 08F4BB            MOVEP             #$028FE1,X:BCR          ; Bus Control Register
                            028FE1
557    
558                                 ; Program the Host port B for parallel I/O
559       P:00019D P:00019D 08F484            MOVEP             #>1,X:HPCR              ; All pins enabled as GPIO
                            000001
560       P:00019F P:00019F 08F489            MOVEP             #$810C,X:HDR
                            00810C
561       P:0001A1 P:0001A1 08F488            MOVEP             #$B10E,X:HDDR           ; Data Direction Register
                            00B10E
562                                                                                     ;  (1 for Output, 0 for Input)
563    
564                                 ; Port B conversion from software bits to schematic labels
565                                 ;       PB0 = PWROK             PB08 = PRSFIFO*
566                                 ;       PB1 = LED1              PB09 = EF*
567                                 ;       PB2 = LVEN              PB10 = EXT-IN0
568                                 ;       PB3 = HVEN              PB11 = EXT-IN1
569                                 ;       PB4 = STATUS0           PB12 = EXT-OUT0
570                                 ;       PB5 = STATUS1           PB13 = EXT-OUT1
571                                 ;       PB6 = STATUS2           PB14 = SSFHF*
572                                 ;       PB7 = STATUS3           PB15 = SELSCI
573    
574                                 ; Program the serial port ESSI0 = Port C for serial communication with
575                                 ;   the utility board
576       P:0001A3 P:0001A3 07F43F            MOVEP             #>0,X:PCRC              ; Software reset of ESSI0
                            000000
577       P:0001A5 P:0001A5 07F435            MOVEP             #$180809,X:CRA0         ; Divide 100 MHz by 20 to get 5.0 MHz
                            180809
578                                                                                     ; DC[4:0] = 0 for non-network operation
579                                                                                     ; WL0-WL2 = 3 for 24-bit data words
580                                                                                     ; SSC1 = 0 for SC1 not used
581       P:0001A7 P:0001A7 07F436            MOVEP             #$020020,X:CRB0         ; SCKD = 1 for internally generated clock
                            020020
582                                                                                     ; SCD2 = 0 so frame sync SC2 is an output
583                                                                                     ; SHFD = 0 for MSB shifted first
584                                                                                     ; FSL = 0, frame sync length not used
585                                                                                     ; CKP = 0 for rising clock edge transitions
586                                                                                     ; SYN = 0 for asynchronous
587                                                                                     ; TE0 = 1 to enable transmitter #0
588                                                                                     ; MOD = 0 for normal, non-networked mode
589                                                                                     ; TE0 = 0 to NOT enable transmitter #0 yet
590                                                                                     ; RE = 1 to enable receiver
591       P:0001A9 P:0001A9 07F43F            MOVEP             #%111001,X:PCRC         ; Control Register (0 for GPIO, 1 for ESSI)
                            000039
592       P:0001AB P:0001AB 07F43E            MOVEP             #%000110,X:PRRC         ; Data Direction Register (0 for In, 1 for O
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 12



ut)
                            000006
593       P:0001AD P:0001AD 07F43D            MOVEP             #%000100,X:PDRC         ; Data Register - WR_ENA* = 1
                            000004
594    
595                                 ; Port C version = Analog boards
596                                 ;       MOVEP   #$000809,X:CRA0 ; Divide 100 MHz by 20 to get 5.0 MHz
597                                 ;       MOVEP   #$000030,X:CRB0 ; SCKD = 1 for internally generated clock
598                                 ;       MOVEP   #%100000,X:PCRC ; Control Register (0 for GPIO, 1 for ESSI)
599                                 ;       MOVEP   #%000100,X:PRRC ; Data Direction Register (0 for In, 1 for Out)
600                                 ;       MOVEP   #%000000,X:PDRC ; Data Register: 'not used' = 0 outputs
601    
602       P:0001AF P:0001AF 07F43C            MOVEP             #0,X:TX00               ; Initialize the transmitter to zero
                            000000
603       P:0001B1 P:0001B1 000000            NOP
604       P:0001B2 P:0001B2 000000            NOP
605       P:0001B3 P:0001B3 013630            BSET    #TE,X:CRB0                        ; Enable the SSI transmitter
606    
607                                 ; Conversion from software bits to schematic labels for Port C
608                                 ;       PC0 = SC00 = UTL-T-SCK
609                                 ;       PC1 = SC01 = 2_XMT = SYNC on prototype
610                                 ;       PC2 = SC02 = WR_ENA*
611                                 ;       PC3 = SCK0 = TIM-U-SCK
612                                 ;       PC4 = SRD0 = UTL-T-STD
613                                 ;       PC5 = STD0 = TIM-U-STD
614    
615                                 ; Program the serial port ESSI1 = Port D for serial transmission to
616                                 ;   the analog boards and two parallel I/O input pins
617       P:0001B4 P:0001B4 07F42F            MOVEP             #>0,X:PCRD              ; Software reset of ESSI0
                            000000
618       P:0001B6 P:0001B6 07F425            MOVEP             #$000809,X:CRA1         ; Divide 100 MHz by 20 to get 5.0 MHz
                            000809
619                                                                                     ; DC[4:0] = 0
620                                                                                     ; WL[2:0] = ALC = 0 for 8-bit data words
621                                                                                     ; SSC1 = 0 for SC1 not used
622       P:0001B8 P:0001B8 07F426            MOVEP             #$000030,X:CRB1         ; SCKD = 1 for internally generated clock
                            000030
623                                                                                     ; SCD2 = 1 so frame sync SC2 is an output
624                                                                                     ; SHFD = 0 for MSB shifted first
625                                                                                     ; CKP = 0 for rising clock edge transitions
626                                                                                     ; TE0 = 0 to NOT enable transmitter #0 yet
627                                                                                     ; MOD = 0 so its not networked mode
628       P:0001BA P:0001BA 07F42F            MOVEP             #%100000,X:PCRD         ; Control Register (0 for GPIO, 1 for ESSI)
                            000020
629                                                                                     ; PD3 = SCK1, PD5 = STD1 for ESSI
630       P:0001BC P:0001BC 07F42E            MOVEP             #%000100,X:PRRD         ; Data Direction Register (0 for In, 1 for O
ut)
                            000004
631       P:0001BE P:0001BE 07F42D            MOVEP             #%000100,X:PDRD         ; Data Register: 'not used' = 0 outputs
                            000004
632       P:0001C0 P:0001C0 07F42C            MOVEP             #0,X:TX10               ; Initialize the transmitter to zero
                            000000
633       P:0001C2 P:0001C2 000000            NOP
634       P:0001C3 P:0001C3 000000            NOP
635       P:0001C4 P:0001C4 012630            BSET    #TE,X:CRB1                        ; Enable the SSI transmitter
636    
637                                 ; Conversion from software bits to schematic labels for Port D
638                                 ; PD0 = SC10 = 2_XMT_? input
639                                 ; PD1 = SC11 = SSFEF* input
640                                 ; PD2 = SC12 = PWR_EN
641                                 ; PD3 = SCK1 = TIM-A-SCK
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 13



642                                 ; PD4 = SRD1 = PWRRST
643                                 ; PD5 = STD1 = TIM-A-STD
644    
645                                 ; Program the SCI port to communicate with the utility board
646       P:0001C5 P:0001C5 07F41C            MOVEP             #$0B04,X:SCR            ; SCI programming: 11-bit asynchronous
                            000B04
647                                                                                     ;   protocol (1 start, 8 data, 1 even parity
,
648                                                                                     ;   1 stop); LSB before MSB; enable receiver
649                                                                                     ;   and its interrupts; transmitter interrup
ts
650                                                                                     ;   disabled.
651       P:0001C7 P:0001C7 07F41B            MOVEP             #$0003,X:SCCR           ; SCI clock: utility board data rate =
                            000003
652                                                                                     ;   (390,625 kbits/sec); internal clock.
653       P:0001C9 P:0001C9 07F41F            MOVEP             #%011,X:PCRE            ; Port Control Register = RXD, TXD enabled
                            000003
654       P:0001CB P:0001CB 07F41E            MOVEP             #%000,X:PRRE            ; Port Direction Register (0 = Input)
                            000000
655    
656                                 ;       PE0 = RXD
657                                 ;       PE1 = TXD
658                                 ;       PE2 = SCLK
659    
660                                 ; Program one of the three timers as an exposure timer
661       P:0001CD P:0001CD 07F403            MOVEP             #$C34F,X:TPLR           ; Prescaler to generate millisecond timer,
                            00C34F
662                                                                                     ;  counting from the system clock / 2 = 50 M
Hz
663       P:0001CF P:0001CF 07F40F            MOVEP             #$208200,X:TCSR0        ; Clear timer complete bit and enable presca
ler
                            208200
664       P:0001D1 P:0001D1 07F40E            MOVEP             #0,X:TLR0               ; Timer load register
                            000000
665    
666                                 ; Enable interrupts for the SCI port only
667       P:0001D3 P:0001D3 08F4BF            MOVEP             #$000000,X:IPRC         ; No interrupts allowed
                            000000
668       P:0001D5 P:0001D5 08F4BE            MOVEP             #>$80,X:IPRP            ; Enable SCI interrupt only, IPR = 1
                            000080
669       P:0001D7 P:0001D7 00FCB8            ANDI    #$FC,MR                           ; Unmask all interrupt levels
670    
671                                 ; Initialize the fiber optic serial receiver circuitry
672       P:0001D8 P:0001D8 061480            DO      #20,L_FO_INIT
                            0001DD
673       P:0001DA P:0001DA 5FF000            MOVE                          Y:RDFO,B
                            FFFFF1
674       P:0001DC P:0001DC 0605A0            REP     #5
675       P:0001DD P:0001DD 000000            NOP
676                                 L_FO_INIT
677    
678                                 ; Pulse PRSFIFO* low to revive the CMDRST* instruction and reset the FIFO
679       P:0001DE P:0001DE 44F400            MOVE              #1000000,X0             ; Delay by 10 milliseconds
                            0F4240
680       P:0001E0 P:0001E0 06C400            DO      X0,*+3
                            0001E2
681       P:0001E2 P:0001E2 000000            NOP
682       P:0001E3 P:0001E3 0A8908            BCLR    #8,X:HDR
683       P:0001E4 P:0001E4 0614A0            REP     #20
684       P:0001E5 P:0001E5 000000            NOP
685       P:0001E6 P:0001E6 0A8928            BSET    #8,X:HDR
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 14



686    
687                                 ; Reset the utility board
688       P:0001E7 P:0001E7 0A0F05            BCLR    #5,X:<LATCH
689       P:0001E8 P:0001E8 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Clear reset utility board bit
                            00000F
690       P:0001EA P:0001EA 06C8A0            REP     #200                              ; Delay by RESET* low time
691       P:0001EB P:0001EB 000000            NOP
692       P:0001EC P:0001EC 0A0F25            BSET    #5,X:<LATCH
693       P:0001ED P:0001ED 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Clear reset utility board bit
                            00000F
694       P:0001EF P:0001EF 56F400            MOVE              #200000,A               ; Delay 2 msec for utility boot
                            030D40
695       P:0001F1 P:0001F1 06CE00            DO      A,*+3
                            0001F3
696       P:0001F3 P:0001F3 000000            NOP
697    
698                                 ; Put all the analog switch inputs to low so they draw minimum current
699       P:0001F4 P:0001F4 012F23            BSET    #3,X:PCRD                         ; Turn the serial clock on
700       P:0001F5 P:0001F5 56F400            MOVE              #$0C3000,A              ; Value of integrate speed and gain switches
                            0C3000
701       P:0001F7 P:0001F7 20001B            CLR     B
702       P:0001F8 P:0001F8 241000            MOVE              #$100000,X0             ; Increment over board numbers for DAC write
s
703       P:0001F9 P:0001F9 45F400            MOVE              #$001000,X1             ; Increment over board numbers for WRSS writ
es
                            001000
704       P:0001FB P:0001FB 060F80            DO      #15,L_ANALOG                      ; Fifteen video processor boards maximum
                            000203
705       P:0001FD P:0001FD 0D020A            JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
706       P:0001FE P:0001FE 200040            ADD     X0,A
707       P:0001FF P:0001FF 5F7000            MOVE                          B,Y:WRSS    ; This is for the fast analog switches
                            FFFFF3
708       P:000201 P:000201 0620A3            REP     #800                              ; Delay for the serial data transmission
709       P:000202 P:000202 000000            NOP
710       P:000203 P:000203 200068            ADD     X1,B                              ; Increment the video and clock driver numbe
rs
711                                 L_ANALOG
712       P:000204 P:000204 0A0F00            BCLR    #CDAC,X:<LATCH                    ; Enable clearing of DACs
713       P:000205 P:000205 0A0F02            BCLR    #ENCK,X:<LATCH                    ; Disable clock and DAC output switches
714       P:000206 P:000206 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Execute these two operations
                            00000F
715       P:000208 P:000208 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
716       P:000209 P:000209 0C021E            JMP     <SKIP
717    
718                                 ; Transmit contents of accumulator A1 over the synchronous serial transmitter
719                                 XMIT_A_WORD
720       P:00020A P:00020A 547000            MOVE              A1,X:SV_A1
                            00000E
721       P:00020C P:00020C 01A786            JCLR    #TDE,X:SSISR1,*                   ; Start bit
                            00020C
722       P:00020E P:00020E 07F42C            MOVEP             #$010000,X:TX10
                            010000
723       P:000210 P:000210 060380            DO      #3,L_XMIT
                            000216
724       P:000212 P:000212 01A786            JCLR    #TDE,X:SSISR1,*                   ; Three data bytes
                            000212
725       P:000214 P:000214 04CCCC            MOVEP             A1,X:TX10
726       P:000215 P:000215 0C1E90            LSL     #8,A
727       P:000216 P:000216 000000            NOP
728                                 L_XMIT
729       P:000217 P:000217 01A786            JCLR    #TDE,X:SSISR1,*                   ; Zeroes to bring transmitter low
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 15



                            000217
730       P:000219 P:000219 07F42C            MOVEP             #0,X:TX10
                            000000
731       P:00021B P:00021B 54F000            MOVE              X:SV_A1,A1
                            00000E
732       P:00021D P:00021D 00000C            RTS
733    
734                                 SKIP
735    
736                                 ; Set up the circular SCI buffer, 32 words in size
737       P:00021E P:00021E 64F400            MOVE              #SCI_TABLE,R4
                            000400
738       P:000220 P:000220 051FA4            MOVE              #31,M4
739       P:000221 P:000221 647000            MOVE              R4,X:(SCI_TABLE+33)
                            000421
740    
741                                           IF      @SCP("HOST","ROM")
749                                           ENDIF
750    
751       P:000223 P:000223 44F400            MOVE              #>$AC,X0
                            0000AC
752       P:000225 P:000225 440100            MOVE              X0,X:<FO_HDR
753    
754       P:000226 P:000226 0C017F            JMP     <STARTUP
755    
756                                 ;  ****************  X: Memory tables  ********************
757    
758                                 ; Define the address in P: space where the table of constants begins
759    
760                                  X_BOOT_START
761       000225                              EQU     @LCV(L)-2
762    
763                                           IF      @SCP("HOST","ROM")
765                                           ENDIF
766                                           IF      @SCP("HOST","HOST")
767       X:000000 X:000000                   ORG     X:0,X:0
768                                           ENDIF
769    
770                                 ; Special storage area - initialization constants and scratch space
771                                 ;STATUS DC      $1064                   ; Controller status bits
772       X:000000 X:000000         STATUS    DC      $64                               ; Controller status bits ST_DITH OFF
773    
774       000001                    FO_HDR    EQU     STATUS+1                          ; Fiber optic write bytes
775       000005                    HEADER    EQU     FO_HDR+4                          ; Command header
776       000006                    NWORDS    EQU     HEADER+1                          ; Number of words in the command
777       000007                    COM_BUF   EQU     NWORDS+1                          ; Command buffer
778       00000E                    SV_A1     EQU     COM_BUF+7                         ; Save accumulator A1
779    
780                                           IF      @SCP("HOST","ROM")
785                                           ENDIF
786    
787                                           IF      @SCP("HOST","HOST")
788       X:00000F X:00000F                   ORG     X:$F,X:$F
789                                           ENDIF
790    
791                                 ; Parameter table in P: space to be copied into X: space during
792                                 ;   initialization, and is copied from ROM by the DSP boot
793       X:00000F X:00000F         LATCH     DC      $7A                               ; Starting value in latch chip U25
794                                  EXPOSURE_TIME
795       X:000010 X:000010                   DC      0                                 ; Exposure time in milliseconds
796                                  ELAPSED_TIME
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC22_boot.asm  Page 16



797       X:000011 X:000011                   DC      0                                 ; Time elapsed so far in the exposure
798       X:000012 X:000012         ONE       DC      1                                 ; One
799       X:000013 X:000013         TWO       DC      2                                 ; Two
800       X:000014 X:000014         THREE     DC      3                                 ; Three
801       X:000015 X:000015         SEVEN     DC      7                                 ; Seven
802       X:000016 X:000016         MASK1     DC      $FCFCF8                           ; Mask for checking header
803       X:000017 X:000017         MASK2     DC      $030300                           ; Mask for checking header
804       X:000018 X:000018         DONE      DC      'DON'                             ; Standard reply
805       X:000019 X:000019         SBRD      DC      $020000                           ; Source Identification number
806       X:00001A X:00001A         TIM_DRB   DC      $000200                           ; Destination = timing board number
807       X:00001B X:00001B         DMASK     DC      $00FF00                           ; Mask to get destination board number
808       X:00001C X:00001C         SMASK     DC      $FF0000                           ; Mask to get source board number
809       X:00001D X:00001D         ERR       DC      'ERR'                             ; An error occurred
810       X:00001E X:00001E         C100K     DC      100000                            ; Delay for WRROM = 1 millisec
811       X:00001F X:00001F         IDL_ADR   DC      TST_RCV                           ; Address of idling routine
812       X:000020 X:000020         EXP_ADR   DC      0                                 ; Jump to this address during exposures
813    
814                                 ; Places for saving register values
815       X:000021 X:000021         SAVE_SR   DC      0                                 ; Status Register
816       X:000022 X:000022         SAVE_X1   DC      0
817       X:000023 X:000023         SAVE_A1   DC      0
818       X:000024 X:000024         SAVE_R0   DC      0
819       X:000025 X:000025         RCV_ERR   DC      0
820       X:000026 X:000026         SCI_A1    DC      0                                 ; Contents of accumulator A1 in RCV ISR
821       X:000027 X:000027         SCI_R0    DC      SRXL
822    
823                                 ; Command table
824       000028                    COM_TBL_R EQU     @LCV(R)
825       X:000028 X:000028         COM_TBL   DC      'TDL',TDL                         ; Test Data Link
826       X:00002A X:00002A                   DC      'RDM',RDMEM                       ; Read from DSP or EEPROM memory
827       X:00002C X:00002C                   DC      'WRM',WRMEM                       ; Write to DSP memory
828       X:00002E X:00002E                   DC      'LDA',LDAPPL                      ; Load application from EEPROM to DSP
829       X:000030 X:000030                   DC      'STP',STOP_IDLE_CLOCKING
830       X:000032 X:000032                   DC      'DON',START                       ; Nothing special
831       X:000034 X:000034                   DC      'ERR',START                       ; Nothing special
832    
833                                  END_COMMAND_TABLE
834       000036                              EQU     @LCV(R)
835    
836                                 ; The table at SCI_TABLE is for words received from the utility board, written by
837                                 ;   the interrupt service routine SCI_RCV. Note that it is 32 words long,
838                                 ;   hard coded, and the 33rd location contains the pointer to words that have
839                                 ;   been processed by moving them from the SCI_TABLE to the COM_BUF.
840    
841                                           IF      @SCP("HOST","ROM")
843                                           ENDIF
844    
845       000036                    END_ADR   EQU     @LCV(L)                           ; End address of P: code written to ROM
846    
847                                           INCLUDE "SystemConfig.asm"
848                                 ; SystemConfig.asm - defines the system configurations for an ARC controller
849                                 ; Use 'null.asm' for boards which are not installed
850    
851                                           DEFINE  TIMBRD    'tim3.asm'              ; timing board (not used yet)
852    
853                                           DEFINE  VIDDEFS   'ARC47_defs.asm'        ; video board defs
854                                           DEFINE  VIDBRD0   'ARC47_dacs_brd0.asm'   ; video board 0
855                                           DEFINE  VIDBRD1   'ARC47_dacs_brd1.asm'   ; video board 1
856                                           DEFINE  VIDBRD2   'ARC47_dacs_brd2.asm'   ; video board 2
857                                           DEFINE  VIDBRD3   'ARC47_dacs_brd3.asm'   ; video board 3
858    
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\SystemConfig.asm  Page 17



859                                           DEFINE  CLKBRD0   'ARC32_dacs.asm'        ; clock board 0
860                                           DEFINE  CLKBRD1   'null.asm'              ; clock board 1
861    
862                                           DEFINE  SBNCODE   'ARC47_ARC32_sbn.asm'   ; video&clock SBN command
863    
864                                           DEFINE  CLKPINOUT '90PrimeClockPins.asm'  ; clock board pinout
865    
866                                           DEFINE  POWERCODE 'ARC47_power.asm'       ; power related code
867    
868                                           DEFINE  UTILBRD   'null.asm'              ; utility board
869    
870    
871       P:000227 P:000227                   ORG     P:,P:
872    
873                                 ; Put number of words of application in P: for loading application from EEPROM
874       P:000227 P:000227                   DC      TIMBOOT_X_MEMORY-@LCV(L)-1
875    
876                                 ; *******************************************************************
877                                 ; Shift and read CCD
878                                 RDCCD
879       P:000228 P:000228 0A0024            BSET    #ST_RDC,X:<STATUS                 ; Set status to reading out
880       P:000229 P:000229 0D03EB            JSR     <PCI_READ_IMAGE                   ; Get the PCI board reading the image
881    
882       P:00022A P:00022A 0A00AA            JSET    #TST_IMG,X:STATUS,SYNTHETIC_IMAGE ; jump for fake image
                            0003B8
883    
884       P:00022C P:00022C 68A500            MOVE                          Y:<AFPXFER0,R0 ; frame transfer
885       P:00022D P:00022D 0D03FB            JSR     <CLOCK
886       P:00022E P:00022E 301500            MOVE              #<FRAMET,R0
887       P:00022F P:00022F 0D0285            JSR     <PQSKIP
888       P:000230 P:000230 0E8054            JCS     <START
889    
890       P:000231 P:000231 300E00            MOVE              #<NPPRESKIP,R0          ; skip to underscan
891       P:000232 P:000232 0D0279            JSR     <PSKIP
892       P:000233 P:000233 0E8054            JCS     <START
893       P:000234 P:000234 68A600            MOVE                          Y:<AFPXFER2,R0
894       P:000235 P:000235 0D03FB            JSR     <CLOCK
895       P:000236 P:000236 300700            MOVE              #<NSCLEAR,R0
896       P:000237 P:000237 0D029D            JSR     <FSSKIP
897    
898       P:000238 P:000238 300F00            MOVE              #<NPUNDERSCAN,R0        ; read underscan
899       P:000239 P:000239 0D0252            JSR     <PDATA
900       P:00023A P:00023A 0E8054            JCS     <START
901    
902       P:00023B P:00023B 68A500            MOVE                          Y:<AFPXFER0,R0 ; skip to ROI
903       P:00023C P:00023C 0D03FB            JSR     <CLOCK
904       P:00023D P:00023D 301000            MOVE              #<NPSKIP,R0
905       P:00023E P:00023E 0D0279            JSR     <PSKIP
906       P:00023F P:00023F 0E8054            JCS     <START
907       P:000240 P:000240 68A600            MOVE                          Y:<AFPXFER2,R0
908       P:000241 P:000241 0D03FB            JSR     <CLOCK
909       P:000242 P:000242 300700            MOVE              #<NSCLEAR,R0
910       P:000243 P:000243 0D029D            JSR     <FSSKIP
911    
912       P:000244 P:000244 300200            MOVE              #<NPDATA,R0             ; read ROI
913       P:000245 P:000245 0D0252            JSR     <PDATA
914       P:000246 P:000246 0E8054            JCS     <START
915    
916                                 ;       MOVE  #<NPOVERSCAN,A            ; test parallel overscan
917                                 ;       TST     A
918                                 ;       JLE     <RDC_END
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 18



919    
920                                 ;       MOVE    Y:<AFPXFER0,R0          ; skip to overscan
921                                 ;       JSR     <CLOCK
922                                 ;       MOVE  #<NPPOSTSKIP,R0
923                                 ;       JSR   <PSKIP
924                                 ;       JCS     <START
925                                 ;       MOVE    Y:<AFPXFER2,R0
926                                 ;       JSR     <CLOCK
927                                 ;       MOVE  #<NSCLEAR,R0
928                                 ;       JSR     <FSSKIP
929    
930                                 ;       MOVE  #<NPOVERSCAN,R0           ; read parallel overscan
931                                 ;       JSR   <PDATA
932                                 ;       JCS     <START
933    
934                                 RDC_END
935       P:000247 P:000247 0A0082            JCLR    #IDLMODE,X:<STATUS,NO_IDL         ; Don't idle after readout
                            00024D
936       P:000249 P:000249 60F400            MOVE              #IDLE,R0
                            0002F7
937       P:00024B P:00024B 601F00            MOVE              R0,X:<IDL_ADR
938       P:00024C P:00024C 0C024F            JMP     <RDC_E
939                                 NO_IDL
940       P:00024D P:00024D 305800            MOVE              #<TST_RCV,R0
941       P:00024E P:00024E 601F00            MOVE              R0,X:<IDL_ADR
942                                 RDC_E
943       P:00024F P:00024F 0D03F8            JSR     <WAIT_TO_FINISH_CLOCKING
944       P:000250 P:000250 0A0004            BCLR    #ST_RDC,X:<STATUS                 ; Set status to not reading out
945    
946       P:000251 P:000251 0C0054            JMP     <START                            ; DONE flag set by PCI when finished
947    
948                                 ; *******************************************************************
949                                 PDATA
950       P:000252 P:000252 0D02C8            JSR     <CNPAMPS                          ; compensate for split register
951       P:000253 P:000253 0EF26B            JLE     <PDATA0
952       P:000254 P:000254 06CE00            DO      A,PDATA0                          ; loop through # of binned rows into each se
rial register
                            00026A
953       P:000256 P:000256 300400            MOVE              #<NPBIN,R0              ; shift NPBIN rows into serial register
954       P:000257 P:000257 0D026C            JSR     <PDSKIP
955       P:000258 P:000258 0E025B            JCC     <PDATA1
956       P:000259 P:000259 00008C            ENDDO
957       P:00025A P:00025A 0C026B            JMP     <PDATA0
958                                 PDATA1
959       P:00025B P:00025B 300900            MOVE              #<NSPRESKIP,R0          ; skip to serial underscan
960       P:00025C P:00025C 0D02A5            JSR     <SSKIP
961       P:00025D P:00025D 300A00            MOVE              #<NSUNDERSCAN,R0        ; read underscan
962       P:00025E P:00025E 0D02AF            JSR     <SDATA
963       P:00025F P:00025F 300B00            MOVE              #<NSSKIP,R0             ; skip to ROI
964       P:000260 P:000260 0D02A5            JSR     <SSKIP
965       P:000261 P:000261 300100            MOVE              #<NSDATA,R0             ; read ROI
966       P:000262 P:000262 0D02AF            JSR     <SDATA
967       P:000263 P:000263 300C00            MOVE              #<NSPOSTSKIP,R0         ; skip to serial overscan
968       P:000264 P:000264 0D02A5            JSR     <SSKIP
969       P:000265 P:000265 300D00            MOVE              #<NSOVERSCAN,R0         ; read overscan
970       P:000266 P:000266 0D02AF            JSR     <SDATA
971       P:000267 P:000267 0AF940            BCLR    #0,SR                             ; set CC
972       P:000268 P:000268 000000            NOP
973       P:000269 P:000269 000000            NOP
974       P:00026A P:00026A 000000            NOP
975                                 PDATA0
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 19



976       P:00026B P:00026B 00000C            RTS
977    
978                                 ; *******************************************************************
979                                 PDSKIP
980       P:00026C P:00026C 5EE000            MOVE                          Y:(R0),A    ; shift data lines into serial reg
981       P:00026D P:00026D 200003            TST     A
982       P:00026E P:00026E 0EF278            JLE     <PDSKIP0
983       P:00026F P:00026F 066040            DO      Y:(R0),PDSKIP0
                            000277
984       P:000271 P:000271 68A800            MOVE                          Y:<APDXFER,R0
985       P:000272 P:000272 0D02D2            JSR     <PCLOCK
986       P:000273 P:000273 0D00A3            JSR     <GET_RCV
987       P:000274 P:000274 0E0277            JCC     <PDSKIP1
988       P:000275 P:000275 00008C            ENDDO
989       P:000276 P:000276 000000            NOP
990                                 PDSKIP1
991       P:000277 P:000277 000000            NOP
992                                 PDSKIP0
993       P:000278 P:000278 00000C            RTS
994    
995                                 ; *******************************************************************
996                                 PSKIP
997       P:000279 P:000279 0D02C8            JSR     <CNPAMPS
998       P:00027A P:00027A 0EF284            JLE     <PSKIP0
999       P:00027B P:00027B 06CE00            DO      A,PSKIP0
                            000283
1000      P:00027D P:00027D 68A700            MOVE                          Y:<APXFER,R0
1001      P:00027E P:00027E 0D02D2            JSR     <PCLOCK
1002      P:00027F P:00027F 0D00A3            JSR     <GET_RCV
1003      P:000280 P:000280 0E0283            JCC     <PSKIP1
1004      P:000281 P:000281 00008C            ENDDO
1005      P:000282 P:000282 000000            NOP
1006                                PSKIP1
1007      P:000283 P:000283 000000            NOP
1008                                PSKIP0
1009      P:000284 P:000284 00000C            RTS
1010   
1011                                ; *******************************************************************
1012                                PQSKIP
1013      P:000285 P:000285 0D02C8            JSR     <CNPAMPS
1014      P:000286 P:000286 0EF290            JLE     <PQSKIP0
1015      P:000287 P:000287 06CE00            DO      A,PQSKIP0
                            00028F
1016      P:000289 P:000289 68A900            MOVE                          Y:<APQXFER,R0
1017      P:00028A P:00028A 0D02D2            JSR     <PCLOCK
1018      P:00028B P:00028B 0D00A3            JSR     <GET_RCV
1019      P:00028C P:00028C 0E028F            JCC     <PQSKIP1
1020      P:00028D P:00028D 00008C            ENDDO
1021      P:00028E P:00028E 000000            NOP
1022                                PQSKIP1
1023      P:00028F P:00028F 000000            NOP
1024                                PQSKIP0
1025      P:000290 P:000290 00000C            RTS
1026   
1027                                ; *******************************************************************
1028                                RSKIP
1029      P:000291 P:000291 0D02C8            JSR     <CNPAMPS
1030      P:000292 P:000292 0EF29C            JLE     <RSKIP0
1031      P:000293 P:000293 06CE00            DO      A,RSKIP0
                            00029B
1032      P:000295 P:000295 68AA00            MOVE                          Y:<ARXFER,R0
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 20



1033      P:000296 P:000296 0D02D2            JSR     <PCLOCK
1034      P:000297 P:000297 0D00A3            JSR     <GET_RCV
1035      P:000298 P:000298 0E029B            JCC     <RSKIP1
1036      P:000299 P:000299 00008C            ENDDO
1037      P:00029A P:00029A 000000            NOP
1038                                RSKIP1
1039      P:00029B P:00029B 000000            NOP
1040                                RSKIP0
1041      P:00029C P:00029C 00000C            RTS
1042   
1043                                ; *******************************************************************
1044                                FSSKIP
1045      P:00029D P:00029D 0D02C2            JSR     <CNSAMPS
1046      P:00029E P:00029E 0EF2A4            JLE     <FSSKIP0
1047      P:00029F P:00029F 06CE00            DO      A,FSSKIP0
                            0002A3
1048      P:0002A1 P:0002A1 68AB00            MOVE                          Y:<AFSXFER,R0
1049      P:0002A2 P:0002A2 0D03FB            JSR     <CLOCK
1050      P:0002A3 P:0002A3 000000            NOP
1051                                FSSKIP0
1052      P:0002A4 P:0002A4 00000C            RTS
1053   
1054                                ; *******************************************************************
1055                                SSKIP
1056      P:0002A5 P:0002A5 0D02C2            JSR     <CNSAMPS
1057      P:0002A6 P:0002A6 0EF2AE            JLE     <SSKIP0
1058      P:0002A7 P:0002A7 06CE00            DO      A,SSKIP0
                            0002AD
1059      P:0002A9 P:0002A9 68AC00            MOVE                          Y:<ASXFER0,R0
1060      P:0002AA P:0002AA 0D03FB            JSR     <CLOCK
1061      P:0002AB P:0002AB 68AE00            MOVE                          Y:<ASXFER2,R0
1062      P:0002AC P:0002AC 0D03FB            JSR     <CLOCK
1063      P:0002AD P:0002AD 000000            NOP
1064                                SSKIP0
1065      P:0002AE P:0002AE 00000C            RTS
1066   
1067                                ; *******************************************************************
1068                                SDATA
1069      P:0002AF P:0002AF 0D02C2            JSR     <CNSAMPS
1070      P:0002B0 P:0002B0 0EF2C1            JLE     <SDATA0
1071      P:0002B1 P:0002B1 06CE00            DO      A,SDATA0
                            0002C0
1072      P:0002B3 P:0002B3 68AC00            MOVE                          Y:<ASXFER0,R0
1073      P:0002B4 P:0002B4 0D03FB            JSR     <CLOCK
1074      P:0002B5 P:0002B5 449200            MOVE              X:<ONE,X0               ; Get bin-1
1075      P:0002B6 P:0002B6 5E8300            MOVE                          Y:<NSBIN,A
1076      P:0002B7 P:0002B7 200044            SUB     X0,A
1077      P:0002B8 P:0002B8 0EF2BE            JLE     <SDATA1
1078      P:0002B9 P:0002B9 06CE00            DO      A,SDATA1
                            0002BD
1079      P:0002BB P:0002BB 68AD00            MOVE                          Y:<ASXFER1,R0
1080      P:0002BC P:0002BC 0D03FB            JSR     <CLOCK
1081      P:0002BD P:0002BD 000000            NOP
1082                                SDATA1
1083      P:0002BE P:0002BE 68AF00            MOVE                          Y:<ASXFER2D,R0
1084      P:0002BF P:0002BF 0D03FB            JSR     <CLOCK
1085                                SDATA0T
1086      P:0002C0 P:0002C0 000000            NOP
1087                                SDATA0
1088      P:0002C1 P:0002C1 00000C            RTS
1089   
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 21



1090                                ; *******************************************************************
1091                                ; Compensate count for split serial
1092      P:0002C2 P:0002C2 5EE000  CNSAMPS   MOVE                          Y:(R0),A    ; get num pixels to read
1093      P:0002C3 P:0002C3 0A05C0            JCLR    #0,Y:<NSAMPS,CNSSHIFTLL           ; split register?
                            0002C6
1094      P:0002C5 P:0002C5 200022            ASR     A                                 ; yes, divide by 2
1095      P:0002C6 P:0002C6 200003  CNSSHIFTLL TST    A
1096      P:0002C7 P:0002C7 00000C            RTS
1097   
1098                                ; *******************************************************************
1099                                ; Compensate count for split parallel
1100      P:0002C8 P:0002C8 5EE000  CNPAMPS   MOVE                          Y:(R0),A    ; get num rows to shift
1101      P:0002C9 P:0002C9 0A06C0            JCLR    #0,Y:<NPAMPS,CNPSHIFTLL           ; split parallels?
                            0002CC
1102      P:0002CB P:0002CB 200022            ASR     A                                 ; yes, divide by 2
1103      P:0002CC P:0002CC 200003  CNPSHIFTLL TST    A
1104      P:0002CD P:0002CD 000000            NOP                                       ; MPL for Gen3
1105      P:0002CE P:0002CE 000000            NOP                                       ; MPL for Gen3
1106      P:0002CF P:0002CF 0AF940            BCLR    #0,SR                             ; clear carry
1107      P:0002D0 P:0002D0 000000            NOP                                       ; MPL for Gen3
1108      P:0002D1 P:0002D1 00000C            RTS
1109   
1110                                ; *******************************************************************
1111                                ; slow clock for parallel shifts - Gen3 version
1112                                PCLOCK
1113      P:0002D2 P:0002D2 0A898E            JCLR    #SSFHF,X:HDR,*                    ; Only write to FIFO if < half full
                            0002D2
1114      P:0002D4 P:0002D4 000000            NOP
1115      P:0002D5 P:0002D5 0A898E            JCLR    #SSFHF,X:HDR,PCLOCK               ; Guard against metastability
                            0002D2
1116      P:0002D7 P:0002D7 4CD800            MOVE                          Y:(R0)+,X0  ; # of waveform entries
1117      P:0002D8 P:0002D8 06C400            DO      X0,PCLK1                          ; Repeat X0 times
                            0002DE
1118      P:0002DA P:0002DA 5ED800            MOVE                          Y:(R0)+,A   ; get waveform
1119      P:0002DB P:0002DB 062040            DO      Y:<PMULT,PCLK2
                            0002DD
1120      P:0002DD P:0002DD 09CE33            MOVEP             A,Y:WRSS                ; 30 nsec write the waveform to the SS
1121      P:0002DE P:0002DE 000000  PCLK2     NOP
1122      P:0002DF P:0002DF 000000  PCLK1     NOP
1123      P:0002E0 P:0002E0 00000C            RTS                                       ; Return from subroutine
1124   
1125                                ; *******************************************************************
1126      P:0002E1 P:0002E1 0D02E3  CLEAR     JSR     <CLR_CCD                          ; clear CCD, executed as a command
1127      P:0002E2 P:0002E2 0C008D            JMP     <FINISH
1128   
1129                                ; *******************************************************************
1130                                CLR_CCD
1131      P:0002E3 P:0002E3 68A500            MOVE                          Y:<AFPXFER0,R0 ; prep for fast flush
1132      P:0002E4 P:0002E4 0D03FB            JSR     <CLOCK
1133      P:0002E5 P:0002E5 300800            MOVE              #<NPCLEAR,R0            ; shift all rows
1134      P:0002E6 P:0002E6 0D0285            JSR     <PQSKIP
1135      P:0002E7 P:0002E7 68A600            MOVE                          Y:<AFPXFER2,R0 ; set clocks on clear exit
1136      P:0002E8 P:0002E8 0D03FB            JSR     <CLOCK
1137      P:0002E9 P:0002E9 300700            MOVE              #<NSCLEAR,R0            ; flush serial register
1138      P:0002EA P:0002EA 0D029D            JSR     <FSSKIP
1139      P:0002EB P:0002EB 00000C            RTS
1140   
1141                                ; *******************************************************************
1142                                FOR_PSHIFT
1143      P:0002EC P:0002EC 301300            MOVE              #<NPXSHIFT,R0           ; forward shift rows
1144      P:0002ED P:0002ED 0D0279            JSR     <PSKIP
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 22



1145      P:0002EE P:0002EE 0C008D            JMP     <FINISH
1146   
1147                                ; *******************************************************************
1148                                REV_PSHIFT
1149      P:0002EF P:0002EF 301300            MOVE              #<NPXSHIFT,R0           ; reverse shift rows
1150      P:0002F0 P:0002F0 0D0291            JSR     <RSKIP
1151      P:0002F1 P:0002F1 0C008D            JMP     <FINISH
1152   
1153                                ; *******************************************************************
1154                                ; Set software to IDLE mode
1155                                START_IDLE_CLOCKING
1156      P:0002F2 P:0002F2 60F400            MOVE              #IDLE,R0                ; Exercise clocks when idling
                            0002F7
1157      P:0002F4 P:0002F4 601F00            MOVE              R0,X:<IDL_ADR
1158      P:0002F5 P:0002F5 0A0022            BSET    #IDLMODE,X:<STATUS                ; Idle after readout
1159      P:0002F6 P:0002F6 0C008D            JMP     <FINISH                           ; Need to send header and 'DON'
1160   
1161                                ; Keep the CCD idling when not reading out - MPL modified for AzCam
1162      P:0002F7 P:0002F7 060740  IDLE      DO      Y:<NSCLEAR,IDL1                   ; Loop over number of pixels per line
                            000300
1163      P:0002F9 P:0002F9 68AB00            MOVE                          Y:<AFSXFER,R0 ; Serial transfer on pixel
1164      P:0002FA P:0002FA 0D03FB            JSR     <CLOCK                            ; Go to it
1165      P:0002FB P:0002FB 330700            MOVE              #COM_BUF,R3
1166      P:0002FC P:0002FC 0D00A3            JSR     <GET_RCV                          ; Check for FO or SSI commands
1167      P:0002FD P:0002FD 0E0300            JCC     <NO_COM                           ; Continue IDLE if no commands received
1168      P:0002FE P:0002FE 00008C            ENDDO
1169      P:0002FF P:0002FF 0C005B            JMP     <PRC_RCV                          ; Go process header and command
1170      P:000300 P:000300 000000  NO_COM    NOP
1171                                IDL1
1172      P:000301 P:000301 68A900            MOVE                          Y:<APQXFER,R0 ; Address of parallel clocking waveform
1173                                ;       JSR     <CLOCK                  ; Go clock out the CCD charge
1174      P:000302 P:000302 0D02D2            JSR     <PCLOCK                           ; Go clock out the CCD charge
1175      P:000303 P:000303 0C02F7            JMP     <IDLE
1176   
1177                                ; *******************************************************************
1178   
1179                                ; Misc routines
1180   
1181                                ; POWER_OFF
1182                                ; POWER_ON
1183                                ; SET_BIASES
1184                                ; CLR_SWS
1185                                ; CLEAR_SWITCHES_AND_DACS
1186                                ; OPEN_SHUTTER
1187                                ; CLOSE_SHUTTER
1188                                ; OSHUT
1189                                ; CSHUT
1190                                ; EXPOSE
1191                                ; START_EXPOSURE
1192                                ; SET_EXPOSURE_TIME
1193                                ; READ_EXPOSURE_TIME
1194                                ; PAUSE_EXPOSURE
1195                                ; RESUME_EXPOSURE
1196                                ; ABORT_ALL
1197                                ; SYNTHETIC_IMAGE
1198                                ; XMT_PIX
1199                                ; READ_AD
1200                                ; PCI_READ_IMAGE
1201                                ; WAIT_TO_FINISH_CLOCKING
1202                                ; CLOCK
1203                                ; PAL_DLY
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 23



1204                                ; READ_CONTROLLER_CONFIGURATION
1205                                ; ST_GAIN
1206                                ; SET_DC
1207                                ; SET_BIAS_NUMBER
1208                                ;
1209   
1210                                          INCLUDE "ARC47_power.asm"
1211                                ; ARC45_power.asm
1212                                ; ARC45 power related code
1213   
1214                                ; *******************************************************************
1215                                POWER_OFF
1216      P:000304 P:000304 0D033F            JSR     <CLEAR_SWITCHES_AND_DACS          ; Clear switches and DACs
1217      P:000305 P:000305 0A8922            BSET    #LVEN,X:HDR
1218      P:000306 P:000306 0A8923            BSET    #HVEN,X:HDR
1219      P:000307 P:000307 0C008D            JMP     <FINISH
1220   
1221                                ; *******************************************************************
1222                                ; Execute the power-on cycle, as a command
1223                                POWER_ON
1224      P:000308 P:000308 0D033F            JSR     <CLEAR_SWITCHES_AND_DACS          ; Clear switches and DACs
1225   
1226                                ; Turn on the low voltages (+/- 6.5V, +/- 16.5V) and delay
1227      P:000309 P:000309 0A8902            BCLR    #LVEN,X:HDR                       ; Set these signals to DSP outputs
1228      P:00030A P:00030A 44F400            MOVE              #2000000,X0
                            1E8480
1229      P:00030C P:00030C 06C400            DO      X0,*+3                            ; Wait 20 millisec for settling
                            00030E
1230      P:00030E P:00030E 000000            NOP
1231   
1232                                ; Turn on the high +36 volt power line and delay
1233      P:00030F P:00030F 0A8903            BCLR    #HVEN,X:HDR                       ; HVEN = Low => Turn on +36V
1234      P:000310 P:000310 44F400            MOVE              #2000000,X0
                            1E8480
1235      P:000312 P:000312 06C400            DO      X0,*+3                            ; Wait 20 millisec for settling
                            000314
1236      P:000314 P:000314 000000            NOP
1237   
1238      P:000315 P:000315 0A8980            JCLR    #PWROK,X:HDR,PWR_ERR              ; Test if the power turned on properly
                            000320
1239      P:000317 P:000317 0D0325            JSR     <SET_BIASES                       ; Turn on the DC bias supplies
1240   
1241                                ; Turn the ARC-47 DACs on
1242                                ;       BSET    #3,X:PCRD               ; Turn on the serial clock
1243                                ;       JSR     <PAL_DLY                ; Delay for all this to happen
1244                                ;       MOVE    #$0C0004,A              ; Turn ON the DACs on all ARC-48s
1245                                ;       MOVE    #$100000,X0             ; Increment over board numbers
1246                                ;       DO      #8,L_ON                 ; 8 video processor boards
1247                                ;       JSR     <XMIT_A_WORD            ; Transmit A to TIM-A-STD
1248                                ;       ADD     X0,A
1249                                ;       JSR     <PAL_DLY                ; Delay for all this to happen
1250                                ;       NOP
1251                                ;L_ON
1252      P:000318 P:000318 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1253   
1254      P:000319 P:000319 60F400            MOVE              #IDLE,R0                ; Put controller in IDLE state
                            0002F7
1255      P:00031B P:00031B 601F00            MOVE              R0,X:<IDL_ADR
1256      P:00031C P:00031C 44F400            MOVE              #$1064,X0
                            001064
1257      P:00031E P:00031E 440000            MOVE              X0,X:<STATUS
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_power.asm  Page 24



1258      P:00031F P:00031F 0C008D            JMP     <FINISH
1259   
1260                                ; The power failed to turn on because of an error on the power control board
1261      P:000320 P:000320 0A8922  PWR_ERR   BSET    #LVEN,X:HDR                       ; Turn off the low voltage emable line
1262      P:000321 P:000321 0A8923            BSET    #HVEN,X:HDR                       ; Turn off the high voltage emable line
1263      P:000322 P:000322 0C008B            JMP     <ERROR
1264   
1265                                ; *******************************************************************
1266                                SET_BIAS_VOLTAGES
1267      P:000323 P:000323 0D0325            JSR     <SET_BIASES
1268      P:000324 P:000324 0C008D            JMP     <FINISH
1269   
1270                                ; Set all the DC bias voltages and video processor offset values, reading
1271                                ;   them from the 'DACS' table
1272                                SET_BIASES
1273      P:000325 P:000325 012F23            BSET    #3,X:PCRD                         ; Turn on the serial clock
1274      P:000326 P:000326 0A0F01            BCLR    #1,X:<LATCH                       ; Separate updates of clock driver
1275      P:000327 P:000327 0A0F20            BSET    #CDAC,X:<LATCH                    ; Disable clearing of DACs
1276      P:000328 P:000328 0A0F22            BSET    #ENCK,X:<LATCH                    ; Enable clock and DAC output switches
1277      P:000329 P:000329 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Write it to the hardware
                            00000F
1278      P:00032B P:00032B 0D0406            JSR     <PAL_DLY                          ; Delay for all this to happen
1279   
1280                                ; Read DAC values from a table, and write them to the DACs
1281      P:00032C P:00032C 60F400            MOVE              #DACS,R0                ; Get starting address of DAC values
                            000031
1282      P:00032E P:00032E 000000            NOP
1283      P:00032F P:00032F 000000            NOP
1284      P:000330 P:000330 000000            NOP
1285      P:000331 P:000331 065840            DO      Y:(R0)+,L_DAC                     ; Repeat Y:(R0)+ times
                            000335
1286      P:000333 P:000333 5ED800            MOVE                          Y:(R0)+,A   ; Read the table entry
1287      P:000334 P:000334 0D020A            JSR     <XMIT_A_WORD                      ; Transmit it to TIM-A-STD
1288      P:000335 P:000335 000000            NOP
1289                                L_DAC
1290   
1291                                ; Let the DAC voltages all ramp up before exiting
1292      P:000336 P:000336 44F400            MOVE              #400000,X0
                            061A80
1293      P:000338 P:000338 06C400            DO      X0,*+3                            ; 4 millisec delay
                            00033A
1294      P:00033A P:00033A 000000            NOP
1295      P:00033B P:00033B 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1296      P:00033C P:00033C 00000C            RTS
1297   
1298                                ; *******************************************************************
1299      P:00033D P:00033D 0D033F  CLR_SWS   JSR     <CLEAR_SWITCHES_AND_DACS          ; Clear switches and DACs
1300      P:00033E P:00033E 0C008D            JMP     <FINISH
1301   
1302                                CLEAR_SWITCHES_AND_DACS
1303      P:00033F P:00033F 0A0F00            BCLR    #CDAC,X:<LATCH                    ; Clear all the DACs
1304      P:000340 P:000340 0A0F02            BCLR    #ENCK,X:<LATCH                    ; Disable all the output switches
1305      P:000341 P:000341 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Write it to the hardware
                            00000F
1306      P:000343 P:000343 012F23            BSET    #3,X:PCRD                         ; Turn the serial clock on
1307      P:000344 P:000344 56F400            MOVE              #$0C3000,A              ; Value of integrate speed and gain switches
                            0C3000
1308      P:000346 P:000346 20001B            CLR     B
1309      P:000347 P:000347 241000            MOVE              #$100000,X0             ; Increment over board numbers for DAC write
s
1310      P:000348 P:000348 45F400            MOVE              #$001000,X1             ; Increment over board numbers for WRSS writ
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_power.asm  Page 25



es
                            001000
1311      P:00034A P:00034A 060F80            DO      #15,L_VIDEO                       ; Fifteen video processor boards maximum
                            000351
1312      P:00034C P:00034C 0D020A            JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
1313      P:00034D P:00034D 200040            ADD     X0,A
1314      P:00034E P:00034E 5F7000            MOVE                          B,Y:WRSS
                            FFFFF3
1315      P:000350 P:000350 0D0406            JSR     <PAL_DLY                          ; Delay for the serial data transmission
1316      P:000351 P:000351 200068            ADD     X1,B
1317                                L_VIDEO
1318      P:000352 P:000352 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1319      P:000353 P:000353 00000C            RTS
1320   
1321   
1322                                ; *******************************************************************
1323                                ; Open the shutter by setting the backplane bit TIM-LATCH0
1324                                ; reversed for ITL prober
1325      P:000354 P:000354 0A0023  OSHUT     BSET    #ST_SHUT,X:<STATUS                ; Set status bit to mean shutter open
1326      P:000355 P:000355 0A0F24            BSET    #SHUTTER,X:<LATCH                 ; Clear hardware shutter bit to open
1327                                ;       BCLR    #SHUTTER,X:<LATCH       ; Clear hardware shutter bit to open 90prime
1328      P:000356 P:000356 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Write it to the hardware
                            00000F
1329      P:000358 P:000358 00000C            RTS
1330   
1331                                ; *******************************************************************
1332                                ; Close the shutter by clearing the backplane bit TIM-LATCH0
1333                                ; reversed for ITL prober
1334      P:000359 P:000359 0A0003  CSHUT     BCLR    #ST_SHUT,X:<STATUS                ; Clear status to mean shutter closed
1335      P:00035A P:00035A 0A0F04            BCLR    #SHUTTER,X:<LATCH                 ; Set hardware shutter bit to close
1336                                ;       BSET    #SHUTTER,X:<LATCH       ; Set hardware shutter bit to close 90prime
1337      P:00035B P:00035B 09F0B5            MOVEP             X:LATCH,Y:WRLATCH       ; Write it to the hardware
                            00000F
1338      P:00035D P:00035D 00000C            RTS
1339   
1340                                ; *******************************************************************
1341                                ; Open the shutter from the timing board, executed as a command
1342                                OPEN_SHUTTER
1343      P:00035E P:00035E 0D0354            JSR     <OSHUT
1344      P:00035F P:00035F 0C008D            JMP     <FINISH
1345   
1346                                ; *******************************************************************
1347                                ; Close the shutter from the timing board, executed as a command
1348                                CLOSE_SHUTTER
1349      P:000360 P:000360 0D0359            JSR     <CSHUT
1350      P:000361 P:000361 0C008D            JMP     <FINISH
1351   
1352                                ; *******************************************************************
1353                                ; Start the exposure timer and monitor its progress
1354      P:000362 P:000362 579000  EXPOSE    MOVE              X:<EXPOSURE_TIME,B
1355      P:000363 P:000363 20000B            TST     B                                 ; Special test for zero exposure time
1356      P:000364 P:000364 0EA374            JEQ     <END_EXP                          ; Don't even start an exposure
1357      P:000365 P:000365 01418C            SUB     #1,B                              ; Timer counts from X:TCPR0+1 to zero
1358      P:000366 P:000366 010F20            BSET    #TIM_BIT,X:TCSR0                  ; Enable the timer #0
1359      P:000367 P:000367 577000            MOVE              B,X:TCPR0
                            FFFF8D
1360      P:000369 P:000369 330700  CHK_RCV   MOVE              #COM_BUF,R3             ; The beginning of the command buffer
1361      P:00036A P:00036A 0A8989            JCLR    #EF,X:HDR,EXP1                    ; Simple test for fast execution
                            00036E
1362      P:00036C P:00036C 0D00A3            JSR     <GET_RCV                          ; Check for an incoming command
1363      P:00036D P:00036D 0E805B            JCS     <PRC_RCV                          ; If command is received, go check it
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 26



1364      P:00036E P:00036E 0A008C  EXP1      JCLR    #ST_DITH,X:STATUS,CHK_TIM
                            000372
1365      P:000370 P:000370 68AB00            MOVE                          Y:<AFSXFER,R0
1366      P:000371 P:000371 0D03FB            JSR     <CLOCK
1367      P:000372 P:000372 018F95  CHK_TIM   JCLR    #TCF,X:TCSR0,CHK_RCV              ; Wait for timer to equal compare value
                            000369
1368      P:000374 P:000374 010F00  END_EXP   BCLR    #TIM_BIT,X:TCSR0                  ; Disable the timer
1369      P:000375 P:000375 0AE780            JMP     (R7)                              ; This contains the return address
1370   
1371                                ; *******************************************************************
1372                                ; Start the exposure, operate the shutter, and initiate CCD readout
1373                                START_EXPOSURE
1374      P:000376 P:000376 57F400            MOVE              #$020102,B
                            020102
1375      P:000378 P:000378 0D00E9            JSR     <XMT_WRD
1376      P:000379 P:000379 57F400            MOVE              #'IIA',B                ; responds to host with DON
                            494941
1377      P:00037B P:00037B 0D00E9            JSR     <XMT_WRD                          ;  indicating exposure started
1378   
1379      P:00037C P:00037C 305800            MOVE              #<TST_RCV,R0            ; Process commands, don't idle,
1380      P:00037D P:00037D 601F00            MOVE              R0,X:<IDL_ADR           ;  during the exposure
1381      P:00037E P:00037E 0A008B            JCLR    #SHUT,X:STATUS,L_SEX0
                            000381
1382      P:000380 P:000380 0D0354            JSR     <OSHUT                            ; Open the shutter if needed
1383      P:000381 P:000381 67F400  L_SEX0    MOVE              #L_SEX1,R7              ; Return address at end of exposure
                            000384
1384      P:000383 P:000383 0C0362            JMP     <EXPOSE                           ; Delay for specified exposure time
1385                                L_SEX1
1386      P:000384 P:000384 0A008B            JCLR    #SHUT,X:STATUS,S_DEL0
                            000391
1387      P:000386 P:000386 0D0359            JSR     <CSHUT                            ; Close the shutter if necessary
1388   
1389                                ; shutter delay
1390      P:000387 P:000387 5E9900            MOVE                          Y:<SH_DEL,A
1391      P:000388 P:000388 200003            TST     A
1392      P:000389 P:000389 0EF391            JLE     <S_DEL0
1393      P:00038A P:00038A 449E00            MOVE              X:<C100K,X0             ; assume 100 MHz DSP
1394      P:00038B P:00038B 06CE00            DO      A,S_DEL0                          ; Delay by Y:SH_DEL milliseconds
                            000390
1395      P:00038D P:00038D 06C400            DO      X0,S_DEL1
                            00038F
1396      P:00038F P:00038F 000000            NOP
1397      P:000390 P:000390 000000  S_DEL1    NOP
1398      P:000391 P:000391 000000  S_DEL0    NOP
1399   
1400      P:000392 P:000392 0C0054            JMP     <START                            ; finish
1401   
1402                                ; *******************************************************************
1403                                ; Set the desired exposure time
1404                                SET_EXPOSURE_TIME
1405      P:000393 P:000393 46DB00            MOVE              X:(R3)+,Y0
1406      P:000394 P:000394 461000            MOVE              Y0,X:EXPOSURE_TIME
1407      P:000395 P:000395 07F00D            MOVEP             X:EXPOSURE_TIME,X:TCPR0
                            000010
1408      P:000397 P:000397 0C008D            JMP     <FINISH
1409   
1410                                ; *******************************************************************
1411                                ; Read the time remaining until the exposure ends
1412                                READ_EXPOSURE_TIME
1413      P:000398 P:000398 47F000            MOVE              X:TCR0,Y1               ; Read elapsed exposure time
                            FFFF8C
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 27



1414      P:00039A P:00039A 0C008E            JMP     <FINISH1
1415   
1416                                ; *******************************************************************
1417                                ; Pause the exposure - close the shutter, and stop the timer
1418                                PAUSE_EXPOSURE
1419      P:00039B P:00039B 010F00            BCLR    #TIM_BIT,X:TCSR0                  ; Disable the DSP exposure timer
1420      P:00039C P:00039C 0D0359            JSR     <CSHUT                            ; Close the shutter
1421      P:00039D P:00039D 0C008D            JMP     <FINISH
1422   
1423                                ; *******************************************************************
1424                                ; Resume the exposure - open the shutter if needed and restart the timer
1425                                RESUME_EXPOSURE
1426      P:00039E P:00039E 010F20            BSET    #TIM_BIT,X:TCSR0                  ; Re-enable the DSP exposure timer
1427      P:00039F P:00039F 0A008B            JCLR    #SHUT,X:STATUS,L_RES
                            0003A2
1428      P:0003A1 P:0003A1 0D0354            JSR     <OSHUT                            ; Open the shutter ir necessary
1429      P:0003A2 P:0003A2 0C008D  L_RES     JMP     <FINISH
1430   
1431                                ; *******************************************************************
1432                                ; Special ending after abort command to send a 'DON' to the host computer
1433                                ABORT_ALL
1434      P:0003A3 P:0003A3 010F00            BCLR    #TIM_BIT,X:TCSR0                  ; Disable the DSP exposure timer
1435      P:0003A4 P:0003A4 0D0359            JSR     <CSHUT                            ; Close the shutter
1436      P:0003A5 P:0003A5 44F400            MOVE              #100000,X0
                            0186A0
1437      P:0003A7 P:0003A7 06C400            DO      X0,L_WAIT0                        ; Wait one millisecond to delimit
                            0003A9
1438      P:0003A9 P:0003A9 000000            NOP                                       ;   image data and the 'DON' reply
1439                                L_WAIT0
1440      P:0003AA P:0003AA 0A0082            JCLR    #IDLMODE,X:<STATUS,NO_IDL2        ; Don't idle after readout
                            0003B0
1441      P:0003AC P:0003AC 60F400            MOVE              #IDLE,R0
                            0002F7
1442      P:0003AE P:0003AE 601F00            MOVE              R0,X:<IDL_ADR
1443      P:0003AF P:0003AF 0C03B2            JMP     <RDC_E2
1444      P:0003B0 P:0003B0 305800  NO_IDL2   MOVE              #<TST_RCV,R0
1445      P:0003B1 P:0003B1 601F00            MOVE              R0,X:<IDL_ADR
1446      P:0003B2 P:0003B2 0D03F8  RDC_E2    JSR     <WAIT_TO_FINISH_CLOCKING
1447      P:0003B3 P:0003B3 0A0004            BCLR    #ST_RDC,X:<STATUS                 ; Set status to not reading out
1448   
1449      P:0003B4 P:0003B4 44F400            MOVE              #$000202,X0             ; Send 'DON' to the host computer
                            000202
1450      P:0003B6 P:0003B6 440500            MOVE              X0,X:<HEADER
1451      P:0003B7 P:0003B7 0C008D            JMP     <FINISH
1452   
1453                                ; *******************************************************************
1454                                ; Generate a synthetic image by simply incrementing the pixel counts
1455                                SYNTHETIC_IMAGE
1456      P:0003B8 P:0003B8 200013            CLR     A
1457                                ;       DO      Y:<NPR,LPR_TST          ; Loop over each line readout
1458                                ;       DO      Y:<NSR,LSR_TST          ; Loop over number of pixels per line
1459      P:0003B9 P:0003B9 061C40            DO      Y:<NPIMAGE,LPR_TST                ; Loop over each line readout
                            0003C4
1460      P:0003BB P:0003BB 061B40            DO      Y:<NSIMAGE,LSR_TST                ; Loop over number of pixels per line
                            0003C3
1461      P:0003BD P:0003BD 0614A0            REP     #20                               ; #20 => 1.0 microsec per pixel
1462      P:0003BE P:0003BE 000000            NOP
1463      P:0003BF P:0003BF 014180            ADD     #1,A                              ; Pixel data = Pixel data + 1
1464      P:0003C0 P:0003C0 000000            NOP
1465      P:0003C1 P:0003C1 21CF00            MOVE              A,B
1466      P:0003C2 P:0003C2 0D03C6            JSR     <XMT_PIX                          ;  transmit them
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 28



1467      P:0003C3 P:0003C3 000000            NOP
1468                                LSR_TST
1469      P:0003C4 P:0003C4 000000            NOP
1470                                LPR_TST
1471      P:0003C5 P:0003C5 0C0247            JMP     <RDC_END                          ; Normal exit
1472   
1473                                ; *******************************************************************
1474                                ; Transmit the 16-bit pixel datum in B1 to the host computer
1475      P:0003C6 P:0003C6 0C1DA1  XMT_PIX   ASL     #16,B,B
1476      P:0003C7 P:0003C7 000000            NOP
1477      P:0003C8 P:0003C8 216500            MOVE              B2,X1
1478      P:0003C9 P:0003C9 0C1D91            ASL     #8,B,B
1479      P:0003CA P:0003CA 000000            NOP
1480      P:0003CB P:0003CB 216400            MOVE              B2,X0
1481      P:0003CC P:0003CC 000000            NOP
1482      P:0003CD P:0003CD 09C532            MOVEP             X1,Y:WRFO
1483      P:0003CE P:0003CE 09C432            MOVEP             X0,Y:WRFO
1484      P:0003CF P:0003CF 00000C            RTS
1485   
1486                                ; *******************************************************************
1487                                ; Test the hardware to read A/D values directly into the DSP instead
1488                                ;   of using the SXMIT option, A/Ds #2 and 3.
1489      P:0003D0 P:0003D0 57F000  READ_AD   MOVE              X:(RDAD+2),B
                            010002
1490      P:0003D2 P:0003D2 0C1DA1            ASL     #16,B,B
1491      P:0003D3 P:0003D3 000000            NOP
1492      P:0003D4 P:0003D4 216500            MOVE              B2,X1
1493      P:0003D5 P:0003D5 0C1D91            ASL     #8,B,B
1494      P:0003D6 P:0003D6 000000            NOP
1495      P:0003D7 P:0003D7 216400            MOVE              B2,X0
1496      P:0003D8 P:0003D8 000000            NOP
1497      P:0003D9 P:0003D9 09C532            MOVEP             X1,Y:WRFO
1498      P:0003DA P:0003DA 09C432            MOVEP             X0,Y:WRFO
1499      P:0003DB P:0003DB 060AA0            REP     #10
1500      P:0003DC P:0003DC 000000            NOP
1501      P:0003DD P:0003DD 57F000            MOVE              X:(RDAD+3),B
                            010003
1502      P:0003DF P:0003DF 0C1DA1            ASL     #16,B,B
1503      P:0003E0 P:0003E0 000000            NOP
1504      P:0003E1 P:0003E1 216500            MOVE              B2,X1
1505      P:0003E2 P:0003E2 0C1D91            ASL     #8,B,B
1506      P:0003E3 P:0003E3 000000            NOP
1507      P:0003E4 P:0003E4 216400            MOVE              B2,X0
1508      P:0003E5 P:0003E5 000000            NOP
1509      P:0003E6 P:0003E6 09C532            MOVEP             X1,Y:WRFO
1510      P:0003E7 P:0003E7 09C432            MOVEP             X0,Y:WRFO
1511      P:0003E8 P:0003E8 060AA0            REP     #10
1512      P:0003E9 P:0003E9 000000            NOP
1513      P:0003EA P:0003EA 00000C            RTS
1514   
1515                                ; *******************************************************************
1516                                ; Alert the PCI interface board that images are coming soon
1517                                PCI_READ_IMAGE
1518      P:0003EB P:0003EB 57F400            MOVE              #$020104,B              ; Send header word to the FO transmitter
                            020104
1519      P:0003ED P:0003ED 0D00E9            JSR     <XMT_WRD
1520      P:0003EE P:0003EE 57F400            MOVE              #'RDA',B
                            524441
1521      P:0003F0 P:0003F0 0D00E9            JSR     <XMT_WRD
1522                                ;       MOVE    Y:NSR,B                 ; Number of columns to read
1523      P:0003F1 P:0003F1 5FF000            MOVE                          Y:NSIMAGE,B ; Number of columns to read
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 29



                            00001B
1524      P:0003F3 P:0003F3 0D00E9            JSR     <XMT_WRD
1525                                ;       MOVE    Y:NPR,B                 ; Number of rows to read
1526      P:0003F4 P:0003F4 5FF000            MOVE                          Y:NPIMAGE,B ; Number of columns to read
                            00001C
1527      P:0003F6 P:0003F6 0D00E9            JSR     <XMT_WRD
1528      P:0003F7 P:0003F7 00000C            RTS
1529   
1530                                ; *******************************************************************
1531                                ; Wait for the clocking to be complete before proceeding
1532                                WAIT_TO_FINISH_CLOCKING
1533      P:0003F8 P:0003F8 01ADA1            JSET    #SSFEF,X:PDRD,*                   ; Wait for the SS FIFO to be empty
                            0003F8
1534      P:0003FA P:0003FA 00000C            RTS
1535   
1536                                ; *******************************************************************
1537                                ; This MOVEP instruction executes in 30 nanosec, 20 nanosec for the MOVEP,
1538                                ;   and 10 nanosec for the wait state that is required for SRAM writes and
1539                                ;   FIFO setup times. It looks reliable, so will be used for now.
1540   
1541                                ; Core subroutine for clocking out CCD charge
1542                                CLOCK
1543      P:0003FB P:0003FB 0A898E            JCLR    #SSFHF,X:HDR,*                    ; Only write to FIFO if < half full
                            0003FB
1544      P:0003FD P:0003FD 000000            NOP
1545      P:0003FE P:0003FE 0A898E            JCLR    #SSFHF,X:HDR,CLOCK                ; Guard against metastability
                            0003FB
1546      P:000400 P:000400 4CD800            MOVE                          Y:(R0)+,X0  ; # of waveform entries
1547      P:000401 P:000401 06C400            DO      X0,CLK1                           ; Repeat X0 times
                            000403
1548      P:000403 P:000403 09D8F3            MOVEP             Y:(R0)+,Y:WRSS          ; 30 nsec Write the waveform to the SS
1549                                CLK1
1550      P:000404 P:000404 000000            NOP
1551      P:000405 P:000405 00000C            RTS                                       ; Return from subroutine
1552   
1553                                ; *******************************************************************
1554                                ; Work on later !!!
1555                                ; This will execute in 20 nanosec, 10 nanosec for the MOVE and 10 nanosec
1556                                ;   the one wait state that is required for SRAM writes and FIFO setup times.
1557                                ;   However, the assembler gives a WARNING about pipeline problems if its
1558                                ;   put in a DO loop. This problem needs to be resolved later, and in the
1559                                ;   meantime I'll be using the MOVEP instruction.
1560   
1561                                ;       MOVE    #$FFFF03,R6             ; Write switch states, X:(R6)
1562                                ;       MOVE    Y:(R0)+,A  A,X:(R6)
1563   
1564                                ; Delay for serial writes to the PALs and DACs by 8 microsec
1565      P:000406 P:000406 062083  PAL_DLY   DO      #800,DLY                          ; Wait 8 usec for serial data transmission
                            000408
1566      P:000408 P:000408 000000            NOP
1567      P:000409 P:000409 000000  DLY       NOP
1568      P:00040A P:00040A 00000C            RTS
1569   
1570                                ; *******************************************************************
1571                                ; Let the host computer read the controller configuration
1572                                READ_CONTROLLER_CONFIGURATION
1573      P:00040B P:00040B 4F9A00            MOVE                          Y:<CONFIG,Y1 ; Just transmit the configuration
1574      P:00040C P:00040C 0C008E            JMP     <FINISH1
1575   
1576                                ; *******************************************************************
1577                                ; Set the video processor boards in DC-coupled diagnostic mode or not
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 30



1578                                ; Command syntax is  SDC #      # = 0 for normal operation
1579                                ;                               # = 1 for DC coupled diagnostic mode
1580      P:00040D P:00040D 012F23  SET_DC    BSET    #3,X:PCRD                         ; Turn the serial clock on
1581      P:00040E P:00040E 44DB00            MOVE              X:(R3)+,X0
1582      P:00040F P:00040F 0AC420            JSET    #0,X0,SDC_1
                            000414
1583      P:000411 P:000411 0A174A            BCLR    #10,Y:<GAIN
1584      P:000412 P:000412 0A174B            BCLR    #11,Y:<GAIN
1585      P:000413 P:000413 0C0416            JMP     <SDC_A
1586      P:000414 P:000414 0A176A  SDC_1     BSET    #10,Y:<GAIN
1587      P:000415 P:000415 0A176B            BSET    #11,Y:<GAIN
1588      P:000416 P:000416 241000  SDC_A     MOVE              #$100000,X0             ; Increment value
1589      P:000417 P:000417 060F80            DO      #15,SDC_LOOP
                            00041C
1590      P:000419 P:000419 5E9700            MOVE                          Y:<GAIN,A
1591      P:00041A P:00041A 0D020A            JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
1592      P:00041B P:00041B 0D0406            JSR     <PAL_DLY                          ; Wait for SSI and PAL to be empty
1593      P:00041C P:00041C 200048            ADD     X0,B                              ; Increment the video processor board number
1594                                SDC_LOOP
1595      P:00041D P:00041D 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1596      P:00041E P:00041E 0C008D            JMP     <FINISH
1597   
1598                                ; include SBN command
1599                                          INCLUDE "ARC47_ARC32_sbn.asm"
1600                                ; ARC47_ARC32_sbn.asm
1601                                ; 02Apr10
1602   
1603                                ; ST_GAIN
1604                                ; SET_BIAS_NUMBER
1605                                ; SET_VIDEO_OFFSET
1606                                ; SET_MUX
1607   
1608                                ; Set the video processor gain:   SGN  #GAIN  (0 TO 15)
1609      P:00041F P:00041F 56DB00  ST_GAIN   MOVE              X:(R3)+,A               ; Gain value
1610      P:000420 P:000420 240D00            MOVE              #$0D0000,X0
1611      P:000421 P:000421 200042            OR      X0,A                              ; Gain from 0 to $F
1612      P:000422 P:000422 0D020A            JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
1613      P:000423 P:000423 0C008D            JMP     <FINISH
1614   
1615                                ; Set a particular DAC numbers, for setting DC bias voltages, clock driver
1616                                ;   voltages and video processor offset
1617                                ;
1618                                ; SBN  #BOARD  ['CLK' or 'VID']  #DAC  voltage
1619                                ;
1620                                ;                               #BOARD is from 0 to 15
1621                                ;                               #DAC number
1622                                ;                               #voltage is from 0 to 4095
1623                                SET_BIAS_NUMBER                                     ; Set bias number
1624      P:000424 P:000424 012F23            BSET    #3,X:PCRD                         ; Turn on the serial clock
1625   
1626      P:000425 P:000425 56DB00            MOVE              X:(R3)+,A               ; First argument is board number, 0 to 15
1627      P:000426 P:000426 0614A0            REP     #20
1628      P:000427 P:000427 200033            LSL     A
1629      P:000428 P:000428 000000            NOP
1630      P:000429 P:000429 21C400            MOVE              A,X0                    ; Board number is in bits #23-20
1631      P:00042A P:00042A 208500            MOVE              X0,X1                   ; MPL save board number for CLK
1632      P:00042B P:00042B 56DB00            MOVE              X:(R3)+,A               ; Second argument is 'VID' or 'CLK'
1633      P:00042C P:00042C 46F400            MOVE              #'VID',Y0
                            564944
1634      P:00042E P:00042E 200055            CMP     Y0,A
1635      P:00042F P:00042F 0EA46E            JEQ     <VID_SBN                          ; go to video board
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_ARC32_sbn.asm  Page 31



1636      P:000430 P:000430 46F400            MOVE              #'CLK',Y0
                            434C4B
1637      P:000432 P:000432 200055            CMP     Y0,A
1638      P:000433 P:000433 0E246B            JNE     <ERR_SBN
1639   
1640                                ; **********************************************
1641                                ; clock board SBN from ARC, does not seem to work with ARC48
1642                                ;       MOVE    X:(R3)+,A       ; Third argument is DAC number
1643                                ;       REP     #14
1644                                ;       LSL     A
1645                                ;       OR      X0,A
1646                                ;       NOP
1647                                ;       MOVE    A,X0
1648                                ;
1649                                ;       MOVE    X:(R3)+,A       ; Fourth argument is voltage value, 0 to $fff
1650                                ;       MOVE    #$000FFF,Y0     ; Mask off just 12 bits to be sure
1651                                ;       AND     Y0,A
1652                                ;       OR      X0,A
1653                                ;       JSR     <XMIT_A_WORD    ; Transmit A to TIM-A-STD
1654                                ;       JSR     <PAL_DLY        ; Wait for the number to be sent
1655                                ;       BCLR    #3,X:PCRD       ; Turn off the serial clock
1656                                ;       JMP     <FINISH
1657                                ; **********************************************
1658   
1659                                ; MPL - below is for ARC32 clock board with ARC47 video (from older ARC45 code)
1660   
1661                                ; For ARC32 do some trickiness to set the chip select and address bits
1662      P:000434 P:000434 56DB00            MOVE              X:(R3)+,A               ; Third argument is DAC number
1663      P:000435 P:000435 000000            NOP
1664      P:000436 P:000436 218F00            MOVE              A1,B
1665      P:000437 P:000437 060EA0            REP     #14
1666      P:000438 P:000438 200033            LSL     A
1667      P:000439 P:000439 240E00            MOVE              #$0E0000,X0
1668      P:00043A P:00043A 200046            AND     X0,A
1669      P:00043B P:00043B 44F400            MOVE              #>7,X0
                            000007
1670      P:00043D P:00043D 20004E            AND     X0,B                              ; Get 3 least significant bits of clock #
1671      P:00043E P:00043E 01408D            CMP     #0,B
1672      P:00043F P:00043F 0E2442            JNE     <CLK_1
1673      P:000440 P:000440 0ACE68            BSET    #8,A
1674      P:000441 P:000441 0C045D            JMP     <BD_SET
1675      P:000442 P:000442 01418D  CLK_1     CMP     #1,B
1676      P:000443 P:000443 0E2446            JNE     <CLK_2
1677      P:000444 P:000444 0ACE69            BSET    #9,A
1678      P:000445 P:000445 0C045D            JMP     <BD_SET
1679      P:000446 P:000446 01428D  CLK_2     CMP     #2,B
1680      P:000447 P:000447 0E244A            JNE     <CLK_3
1681      P:000448 P:000448 0ACE6A            BSET    #10,A
1682      P:000449 P:000449 0C045D            JMP     <BD_SET
1683      P:00044A P:00044A 01438D  CLK_3     CMP     #3,B
1684      P:00044B P:00044B 0E244E            JNE     <CLK_4
1685      P:00044C P:00044C 0ACE6B            BSET    #11,A
1686      P:00044D P:00044D 0C045D            JMP     <BD_SET
1687      P:00044E P:00044E 01448D  CLK_4     CMP     #4,B
1688      P:00044F P:00044F 0E2452            JNE     <CLK_5
1689      P:000450 P:000450 0ACE6D            BSET    #13,A
1690      P:000451 P:000451 0C045D            JMP     <BD_SET
1691      P:000452 P:000452 01458D  CLK_5     CMP     #5,B
1692      P:000453 P:000453 0E2456            JNE     <CLK_6
1693      P:000454 P:000454 0ACE6E            BSET    #14,A
1694      P:000455 P:000455 0C045D            JMP     <BD_SET
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_ARC32_sbn.asm  Page 32



1695      P:000456 P:000456 01468D  CLK_6     CMP     #6,B
1696      P:000457 P:000457 0E245A            JNE     <CLK_7
1697      P:000458 P:000458 0ACE6F            BSET    #15,A
1698      P:000459 P:000459 0C045D            JMP     <BD_SET
1699      P:00045A P:00045A 01478D  CLK_7     CMP     #7,B
1700      P:00045B P:00045B 0E245D            JNE     <BD_SET
1701      P:00045C P:00045C 0ACE70            BSET    #16,A
1702   
1703      P:00045D P:00045D 200062  BD_SET    OR      X1,A                              ; Add on the board number
1704      P:00045E P:00045E 000000            NOP
1705      P:00045F P:00045F 21C400            MOVE              A,X0
1706      P:000460 P:000460 56DB00            MOVE              X:(R3)+,A               ; Fourth argument is voltage value, 0 to $ff
f
1707      P:000461 P:000461 0604A0            REP     #4
1708      P:000462 P:000462 200023            LSR     A                                 ; Convert 12 bits to 8 bits for ARC32
1709      P:000463 P:000463 46F400            MOVE              #>$FF,Y0                ; Mask off just 8 bits
                            0000FF
1710      P:000465 P:000465 200056            AND     Y0,A
1711      P:000466 P:000466 200042            OR      X0,A
1712      P:000467 P:000467 0D020A            JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
1713      P:000468 P:000468 0D0406            JSR     <PAL_DLY                          ; Wait for the number to be sent
1714      P:000469 P:000469 012F03            BCLR    #3,X:PCRD                         ; Turn the serial clock off
1715      P:00046A P:00046A 0C008D            JMP     <FINISH
1716   
1717      P:00046B P:00046B 56DB00  ERR_SBN   MOVE              X:(R3)+,A               ; Read and discard the fourth argument
1718      P:00046C P:00046C 012F03            BCLR    #3,X:PCRD                         ; Turn off the serial clock
1719      P:00046D P:00046D 0C008B            JMP     <ERROR
1720   
1721                                ; ARC47 values below
1722   
1723      P:00046E P:00046E 56DB00  VID_SBN   MOVE              X:(R3)+,A               ; Third argument is DAC number
1724      P:00046F P:00046F 014085            CMP     #0,A
1725      P:000470 P:000470 0E2474            JNE     <CMP1V
1726      P:000471 P:000471 2E0E00            MOVE              #$0E0000,A              ; Magic number for channel #0, Vod0
1727      P:000472 P:000472 200042            OR      X0,A
1728      P:000473 P:000473 0C0508            JMP     <SVO_XMT
1729      P:000474 P:000474 014185  CMP1V     CMP     #1,A
1730      P:000475 P:000475 0E247A            JNE     <CMP2V
1731      P:000476 P:000476 56F400            MOVE              #$0E0004,A              ; Magic number for channel #1, Vrd0
                            0E0004
1732      P:000478 P:000478 200042            OR      X0,A
1733      P:000479 P:000479 0C0508            JMP     <SVO_XMT
1734      P:00047A P:00047A 014285  CMP2V     CMP     #2,A
1735      P:00047B P:00047B 0E2480            JNE     <CMP3V
1736      P:00047C P:00047C 56F400            MOVE              #$0E0008,A              ; Magic number for channel #2, Vog0
                            0E0008
1737      P:00047E P:00047E 200042            OR      X0,A
1738      P:00047F P:00047F 0C0508            JMP     <SVO_XMT
1739      P:000480 P:000480 014385  CMP3V     CMP     #3,A
1740      P:000481 P:000481 0E2486            JNE     <CMP4V
1741      P:000482 P:000482 56F400            MOVE              #$0E000C,A              ; Magic number for channel #3, Vrsv0
                            0E000C
1742      P:000484 P:000484 200042            OR      X0,A
1743      P:000485 P:000485 0C0508            JMP     <SVO_XMT
1744   
1745      P:000486 P:000486 014485  CMP4V     CMP     #4,A
1746      P:000487 P:000487 0E248C            JNE     <CMP5V
1747      P:000488 P:000488 56F400            MOVE              #$0E0001,A              ; Magic number for channel #4, Vod1
                            0E0001
1748      P:00048A P:00048A 200042            OR      X0,A
1749      P:00048B P:00048B 0C0508            JMP     <SVO_XMT
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_ARC32_sbn.asm  Page 33



1750      P:00048C P:00048C 014585  CMP5V     CMP     #5,A
1751      P:00048D P:00048D 0E2492            JNE     <CMP6V
1752      P:00048E P:00048E 56F400            MOVE              #$0E0005,A              ; Magic number for channel #5, Vrd1
                            0E0005
1753      P:000490 P:000490 200042            OR      X0,A
1754      P:000491 P:000491 0C0508            JMP     <SVO_XMT
1755      P:000492 P:000492 014685  CMP6V     CMP     #6,A
1756      P:000493 P:000493 0E2498            JNE     <CMP7V
1757      P:000494 P:000494 56F400            MOVE              #$0E0009,A              ; Magic number for channel #6, Vog1
                            0E0009
1758      P:000496 P:000496 200042            OR      X0,A
1759      P:000497 P:000497 0C0508            JMP     <SVO_XMT
1760      P:000498 P:000498 014785  CMP7V     CMP     #7,A
1761      P:000499 P:000499 0E249E            JNE     <CMP8V
1762      P:00049A P:00049A 56F400            MOVE              #$0E000D,A              ; Magic number for channel #7, Vrsv1
                            0E000D
1763      P:00049C P:00049C 200042            OR      X0,A
1764      P:00049D P:00049D 0C0508            JMP     <SVO_XMT
1765   
1766      P:00049E P:00049E 014885  CMP8V     CMP     #8,A
1767      P:00049F P:00049F 0E24A4            JNE     <CMP9V
1768      P:0004A0 P:0004A0 56F400            MOVE              #$0E0002,A              ; Magic number for channel #8, Vod2
                            0E0002
1769      P:0004A2 P:0004A2 200042            OR      X0,A
1770      P:0004A3 P:0004A3 0C0508            JMP     <SVO_XMT
1771      P:0004A4 P:0004A4 014985  CMP9V     CMP     #9,A
1772      P:0004A5 P:0004A5 0E24AA            JNE     <CMP10V
1773      P:0004A6 P:0004A6 56F400            MOVE              #$0E0006,A              ; Magic number for channel #9, Vrd2
                            0E0006
1774      P:0004A8 P:0004A8 200042            OR      X0,A
1775      P:0004A9 P:0004A9 0C0508            JMP     <SVO_XMT
1776      P:0004AA P:0004AA 014A85  CMP10V    CMP     #10,A
1777      P:0004AB P:0004AB 0E24B0            JNE     <CMP11V
1778      P:0004AC P:0004AC 56F400            MOVE              #$0E000A,A              ; Magic number for channel #10, Vog2
                            0E000A
1779      P:0004AE P:0004AE 200042            OR      X0,A
1780      P:0004AF P:0004AF 0C0508            JMP     <SVO_XMT
1781      P:0004B0 P:0004B0 014B85  CMP11V    CMP     #11,A
1782      P:0004B1 P:0004B1 0E24B6            JNE     <CMP12V
1783      P:0004B2 P:0004B2 56F400            MOVE              #$0E000E,A              ; Magic number for channel #11, Vrsv2
                            0E000E
1784      P:0004B4 P:0004B4 200042            OR      X0,A
1785      P:0004B5 P:0004B5 0C0508            JMP     <SVO_XMT
1786   
1787      P:0004B6 P:0004B6 014C85  CMP12V    CMP     #12,A
1788      P:0004B7 P:0004B7 0E24BC            JNE     <CMP13V
1789      P:0004B8 P:0004B8 56F400            MOVE              #$0E0003,A              ; Magic number for channel #12, Vod3
                            0E0003
1790      P:0004BA P:0004BA 200042            OR      X0,A
1791      P:0004BB P:0004BB 0C0508            JMP     <SVO_XMT
1792      P:0004BC P:0004BC 014D85  CMP13V    CMP     #13,A
1793      P:0004BD P:0004BD 0E24C2            JNE     <CMP14V
1794      P:0004BE P:0004BE 56F400            MOVE              #$0E0007,A              ; Magic number for channel #13, Vrd3
                            0E0007
1795      P:0004C0 P:0004C0 200042            OR      X0,A
1796      P:0004C1 P:0004C1 0C0508            JMP     <SVO_XMT
1797      P:0004C2 P:0004C2 014E85  CMP14V    CMP     #14,A
1798      P:0004C3 P:0004C3 0E24C8            JNE     <CMP15V
1799      P:0004C4 P:0004C4 56F400            MOVE              #$0E000B,A              ; Magic number for channel #14, Vog3
                            0E000B
1800      P:0004C6 P:0004C6 200042            OR      X0,A
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_ARC32_sbn.asm  Page 34



1801      P:0004C7 P:0004C7 0C0508            JMP     <SVO_XMT
1802      P:0004C8 P:0004C8 014F85  CMP15V    CMP     #15,A
1803      P:0004C9 P:0004C9 0E24CE            JNE     <CMP16V
1804      P:0004CA P:0004CA 56F400            MOVE              #$0E000F,A              ; Magic number for channel #15, Vrsv3
                            0E000F
1805      P:0004CC P:0004CC 200042            OR      X0,A
1806      P:0004CD P:0004CD 0C0508            JMP     <SVO_XMT
1807   
1808      P:0004CE P:0004CE 015085  CMP16V    CMP     #16,A
1809      P:0004CF P:0004CF 0E24D4            JNE     <CMP17V
1810      P:0004D0 P:0004D0 56F400            MOVE              #$0E0010,A              ; Magic number for channel #16, Vod4
                            0E0010
1811      P:0004D2 P:0004D2 200042            OR      X0,A
1812      P:0004D3 P:0004D3 0C0508            JMP     <SVO_XMT
1813      P:0004D4 P:0004D4 015185  CMP17V    CMP     #17,A
1814      P:0004D5 P:0004D5 0E24DA            JNE     <CMP18V
1815      P:0004D6 P:0004D6 56F400            MOVE              #$0E0011,A              ; Magic number for channel #17, Vrd4
                            0E0011
1816      P:0004D8 P:0004D8 200042            OR      X0,A
1817      P:0004D9 P:0004D9 0C0508            JMP     <SVO_XMT
1818      P:0004DA P:0004DA 015285  CMP18V    CMP     #18,A
1819      P:0004DB P:0004DB 0E24E0            JNE     <CMP19V
1820      P:0004DC P:0004DC 56F400            MOVE              #$0E0012,A              ; Magic number for channel #18, Vog4
                            0E0012
1821      P:0004DE P:0004DE 200042            OR      X0,A
1822      P:0004DF P:0004DF 0C0508            JMP     <SVO_XMT
1823      P:0004E0 P:0004E0 015385  CMP19V    CMP     #19,A
1824      P:0004E1 P:0004E1 0E251B            JNE     <ERR_SV2
1825      P:0004E2 P:0004E2 56F400            MOVE              #$0E0013,A              ; Magic number for channel #19, Vrsv4
                            0E0013
1826      P:0004E4 P:0004E4 200042            OR      X0,A
1827      P:0004E5 P:0004E5 0C0508            JMP     <SVO_XMT
1828   
1829   
1830                                ; Set the video offset for the ARC-47 4-channel CCD video board
1831                                ; SVO  Board  DAC  voltage      Board number is from 0 to 15
1832                                ;                               DAC number from 0 to 7
1833                                ;                               voltage number is from 0 to 16,383 (14 bits)
1834   
1835                                SET_VIDEO_OFFSET
1836      P:0004E6 P:0004E6 012F23            BSET    #3,X:PCRD                         ; Turn on the serial clock
1837      P:0004E7 P:0004E7 56DB00            MOVE              X:(R3)+,A               ; First argument is board number, 0 to 15
1838      P:0004E8 P:0004E8 200003            TST     A
1839      P:0004E9 P:0004E9 0E9517            JLT     <ERR_SV1
1840      P:0004EA P:0004EA 014F85            CMP     #15,A
1841      P:0004EB P:0004EB 0E7517            JGT     <ERR_SV1
1842      P:0004EC P:0004EC 0614A0            REP     #20
1843      P:0004ED P:0004ED 200033            LSL     A
1844      P:0004EE P:0004EE 000000            NOP
1845      P:0004EF P:0004EF 21C400            MOVE              A,X0                    ; Board number is in bits #23-20
1846      P:0004F0 P:0004F0 56DB00            MOVE              X:(R3)+,A               ; Second argument is the video channel numbe
r
1847      P:0004F1 P:0004F1 014085            CMP     #0,A
1848      P:0004F2 P:0004F2 0E24F7            JNE     <CMP1
1849      P:0004F3 P:0004F3 56F400            MOVE              #$0E0014,A              ; Magic number for channel #0
                            0E0014
1850      P:0004F5 P:0004F5 200042            OR      X0,A
1851      P:0004F6 P:0004F6 0C0508            JMP     <SVO_XMT
1852      P:0004F7 P:0004F7 014185  CMP1      CMP     #1,A
1853      P:0004F8 P:0004F8 0E24FD            JNE     <CMP2
1854      P:0004F9 P:0004F9 56F400            MOVE              #$0E0015,A              ; Magic number for channel #1
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_ARC32_sbn.asm  Page 35



                            0E0015
1855      P:0004FB P:0004FB 200042            OR      X0,A
1856      P:0004FC P:0004FC 0C0508            JMP     <SVO_XMT
1857      P:0004FD P:0004FD 014285  CMP2      CMP     #2,A
1858      P:0004FE P:0004FE 0E2503            JNE     <CMP3
1859      P:0004FF P:0004FF 56F400            MOVE              #$0E0016,A              ; Magic number for channel #2
                            0E0016
1860      P:000501 P:000501 200042            OR      X0,A
1861      P:000502 P:000502 0C0508            JMP     <SVO_XMT
1862      P:000503 P:000503 014385  CMP3      CMP     #3,A
1863      P:000504 P:000504 0E251B            JNE     <ERR_SV2
1864      P:000505 P:000505 56F400            MOVE              #$0E0017,A              ; Magic number for channel #3
                            0E0017
1865      P:000507 P:000507 200042            OR      X0,A
1866   
1867      P:000508 P:000508 0D020A  SVO_XMT   JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
1868      P:000509 P:000509 0D0406            JSR     <PAL_DLY                          ; Wait for the number to be sent
1869      P:00050A P:00050A 56DB00            MOVE              X:(R3)+,A               ; Forth argument is the DAC voltage number
1870      P:00050B P:00050B 200003            TST     A
1871      P:00050C P:00050C 0E951E            JLT     <ERR_SV3                          ; Voltage number needs to be positive
1872      P:00050D P:00050D 0140C5            CMP     #$3FFF,A                          ; Voltage number needs to be 14 bits
                            003FFF
1873      P:00050F P:00050F 0E751E            JGT     <ERR_SV3
1874      P:000510 P:000510 200042            OR      X0,A
1875      P:000511 P:000511 0140C2            OR      #$0FC000,A
                            0FC000
1876      P:000513 P:000513 0D020A            JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
1877      P:000514 P:000514 0D0406            JSR     <PAL_DLY
1878      P:000515 P:000515 012F03            BCLR    #3,X:PCRD                         ; Turn off the serial clock
1879      P:000516 P:000516 0C008D            JMP     <FINISH
1880      P:000517 P:000517 012F03  ERR_SV1   BCLR    #3,X:PCRD                         ; Turn off the serial clock
1881      P:000518 P:000518 56DB00            MOVE              X:(R3)+,A
1882      P:000519 P:000519 56DB00            MOVE              X:(R3)+,A
1883      P:00051A P:00051A 0C008B            JMP     <ERROR
1884      P:00051B P:00051B 012F03  ERR_SV2   BCLR    #3,X:PCRD                         ; Turn off the serial clock
1885      P:00051C P:00051C 56DB00            MOVE              X:(R3)+,A
1886      P:00051D P:00051D 0C008B            JMP     <ERROR
1887      P:00051E P:00051E 012F03  ERR_SV3   BCLR    #3,X:PCRD                         ; Turn off the serial clock
1888      P:00051F P:00051F 0C008B            JMP     <ERROR
1889   
1890                                ; Specify the MUX value to be output on the clock driver board
1891                                ; Command syntax is  SMX  #clock_driver_board #MUX1 #MUX2
1892                                ;                               #clock_driver_board from 0 to 15
1893                                ;                               #MUX1, #MUX2 from 0 to 23
1894   
1895      P:000520 P:000520 56DB00  SET_MUX   MOVE              X:(R3)+,A               ; Clock driver board number
1896      P:000521 P:000521 0614A0            REP     #20
1897      P:000522 P:000522 200033            LSL     A
1898      P:000523 P:000523 44F400            MOVE              #$003000,X0
                            003000
1899      P:000525 P:000525 200042            OR      X0,A
1900      P:000526 P:000526 000000            NOP
1901      P:000527 P:000527 21C500            MOVE              A,X1                    ; Move here for storage
1902   
1903                                ; Get the first MUX number
1904      P:000528 P:000528 56DB00            MOVE              X:(R3)+,A               ; Get the first MUX number
1905      P:000529 P:000529 0AF0A9            JLT     ERR_SM1
                            00056C
1906      P:00052B P:00052B 44F400            MOVE              #>24,X0                 ; Check for argument less than 32
                            000018
1907      P:00052D P:00052D 200045            CMP     X0,A
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_ARC32_sbn.asm  Page 36



1908      P:00052E P:00052E 0AF0A1            JGE     ERR_SM1
                            00056C
1909      P:000530 P:000530 21CF00            MOVE              A,B
1910      P:000531 P:000531 44F400            MOVE              #>7,X0
                            000007
1911      P:000533 P:000533 20004E            AND     X0,B
1912      P:000534 P:000534 44F400            MOVE              #>$18,X0
                            000018
1913      P:000536 P:000536 200046            AND     X0,A
1914      P:000537 P:000537 0E253A            JNE     <SMX_1                            ; Test for 0 <= MUX number <= 7
1915      P:000538 P:000538 0ACD63            BSET    #3,B1
1916      P:000539 P:000539 0C0545            JMP     <SMX_A
1917      P:00053A P:00053A 44F400  SMX_1     MOVE              #>$08,X0
                            000008
1918      P:00053C P:00053C 200045            CMP     X0,A                              ; Test for 8 <= MUX number <= 15
1919      P:00053D P:00053D 0E2540            JNE     <SMX_2
1920      P:00053E P:00053E 0ACD64            BSET    #4,B1
1921      P:00053F P:00053F 0C0545            JMP     <SMX_A
1922      P:000540 P:000540 44F400  SMX_2     MOVE              #>$10,X0
                            000010
1923      P:000542 P:000542 200045            CMP     X0,A                              ; Test for 16 <= MUX number <= 23
1924      P:000543 P:000543 0E256C            JNE     <ERR_SM1
1925      P:000544 P:000544 0ACD65            BSET    #5,B1
1926      P:000545 P:000545 20006A  SMX_A     OR      X1,B1                             ; Add prefix to MUX numbers
1927      P:000546 P:000546 000000            NOP
1928      P:000547 P:000547 21A700            MOVE              B1,Y1
1929   
1930                                ; Add on the second MUX number
1931      P:000548 P:000548 56DB00            MOVE              X:(R3)+,A               ; Get the next MUX number
1932      P:000549 P:000549 0E908B            JLT     <ERROR
1933      P:00054A P:00054A 44F400            MOVE              #>24,X0                 ; Check for argument less than 32
                            000018
1934      P:00054C P:00054C 200045            CMP     X0,A
1935      P:00054D P:00054D 0E108B            JGE     <ERROR
1936      P:00054E P:00054E 0606A0            REP     #6
1937      P:00054F P:00054F 200033            LSL     A
1938      P:000550 P:000550 000000            NOP
1939      P:000551 P:000551 21CF00            MOVE              A,B
1940      P:000552 P:000552 44F400            MOVE              #$1C0,X0
                            0001C0
1941      P:000554 P:000554 20004E            AND     X0,B
1942      P:000555 P:000555 44F400            MOVE              #>$600,X0
                            000600
1943      P:000557 P:000557 200046            AND     X0,A
1944      P:000558 P:000558 0E255B            JNE     <SMX_3                            ; Test for 0 <= MUX number <= 7
1945      P:000559 P:000559 0ACD69            BSET    #9,B1
1946      P:00055A P:00055A 0C0566            JMP     <SMX_B
1947      P:00055B P:00055B 44F400  SMX_3     MOVE              #>$200,X0
                            000200
1948      P:00055D P:00055D 200045            CMP     X0,A                              ; Test for 8 <= MUX number <= 15
1949      P:00055E P:00055E 0E2561            JNE     <SMX_4
1950      P:00055F P:00055F 0ACD6A            BSET    #10,B1
1951      P:000560 P:000560 0C0566            JMP     <SMX_B
1952      P:000561 P:000561 44F400  SMX_4     MOVE              #>$400,X0
                            000400
1953      P:000563 P:000563 200045            CMP     X0,A                              ; Test for 16 <= MUX number <= 23
1954      P:000564 P:000564 0E208B            JNE     <ERROR
1955      P:000565 P:000565 0ACD6B            BSET    #11,B1
1956      P:000566 P:000566 200078  SMX_B     ADD     Y1,B                              ; Add prefix to MUX numbers
1957      P:000567 P:000567 000000            NOP
1958      P:000568 P:000568 21AE00            MOVE              B1,A
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_ARC32_sbn.asm  Page 37



1959      P:000569 P:000569 0D020A            JSR     <XMIT_A_WORD                      ; Transmit A to TIM-A-STD
1960      P:00056A P:00056A 0D0406            JSR     <PAL_DLY                          ; Delay for all this to happen
1961      P:00056B P:00056B 0C008D            JMP     <FINISH
1962      P:00056C P:00056C 56DB00  ERR_SM1   MOVE              X:(R3)+,A
1963      P:00056D P:00056D 0C008B            JMP     <ERROR
1964   
1965   
1966   
1967   
1968   
1969   
1970   
1971   
1972                                 TIMBOOT_X_MEMORY
1973      00056E                              EQU     @LCV(L)
1974   
1975                                ;  ****************  Setup memory tables in X: space ********************
1976   
1977                                ; Define the address in P: space where the table of constants begins
1978   
1979                                          IF      @SCP("HOST","HOST")
1980      X:000036 X:000036                   ORG     X:END_COMMAND_TABLE,X:END_COMMAND_TABLE
1981                                          ENDIF
1982   
1983                                          IF      @SCP("HOST","ROM")
1985                                          ENDIF
1986   
1987                                ; Application commands
1988      X:000036 X:000036                   DC      'PON',POWER_ON
1989      X:000038 X:000038                   DC      'POF',POWER_OFF
1990      X:00003A X:00003A                   DC      'SBV',SET_BIAS_VOLTAGES
1991      X:00003C X:00003C                   DC      'IDL',START_IDLE_CLOCKING
1992      X:00003E X:00003E                   DC      'OSH',OPEN_SHUTTER
1993      X:000040 X:000040                   DC      'CSH',CLOSE_SHUTTER
1994      X:000042 X:000042                   DC      'RDC',RDCCD
1995      X:000044 X:000044                   DC      'CLR',CLEAR
1996   
1997                                ; Exposure and readout control routines
1998      X:000046 X:000046                   DC      'SET',SET_EXPOSURE_TIME
1999      X:000048 X:000048                   DC      'RET',READ_EXPOSURE_TIME
2000      X:00004A X:00004A                   DC      'SEX',START_EXPOSURE
2001      X:00004C X:00004C                   DC      'PEX',PAUSE_EXPOSURE
2002      X:00004E X:00004E                   DC      'REX',RESUME_EXPOSURE
2003      X:000050 X:000050                   DC      'AEX',ABORT_ALL
2004      X:000052 X:000052                   DC      'ABR',ABORT_ALL                   ; MPL temporary
2005      X:000054 X:000054                   DC      'FPX',FOR_PSHIFT
2006      X:000056 X:000056                   DC      'RPX',REV_PSHIFT
2007   
2008                                ; Support routines
2009      X:000058 X:000058                   DC      'SGN',ST_GAIN
2010      X:00005A X:00005A                   DC      'SDC',SET_DC
2011      X:00005C X:00005C                   DC      'SBN',SET_BIAS_NUMBER
2012      X:00005E X:00005E                   DC      'SMX',SET_MUX
2013      X:000060 X:000060                   DC      'CSW',CLR_SWS
2014      X:000062 X:000062                   DC      'RCC',READ_CONTROLLER_CONFIGURATION
2015   
2016                                 END_APPLICATON_COMMAND_TABLE
2017      000064                              EQU     @LCV(L)
2018   
2019                                          IF      @SCP("HOST","HOST")
2020      00001E                    NUM_COM   EQU     (@LCV(R)-COM_TBL_R)/2             ; Number of boot + application commands
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 38



2021      000372                    EXPOSING  EQU     CHK_TIM                           ; Address if exposing
2022                                          ENDIF
2023   
2024                                          IF      @SCP("HOST","ROM")
2026                                          ENDIF
2027   
2028                                ; Now let's go for the timing waveform tables
2029                                          IF      @SCP("HOST","HOST")
2030      Y:000000 Y:000000                   ORG     Y:0,Y:0
2031                                          ENDIF
2032   
2033                                ; *** include waveform header info ***
2034      000001                    GENCNT    EQU     1                                 ; clock tables index
2035      000000                    VIDEO     EQU     $000000                           ; Video processor board (all are addressed t
ogether)
2036      002000                    CLK2      EQU     $002000                           ; Clock driver board select = board 2 low ba
nk
2037      003000                    CLK3      EQU     $003000                           ; Clock driver board select = board 2 high b
ank
2038      200000                    CLKV      EQU     $200000                           ; Clock driver board DAC voltage selection a
ddress (ARC32)
2039   
2040                                ; for ARC-47 (same as ARC48)
2041                                 VIDEO_CONFIG
2042      0C000C                              EQU     $0C000C                           ; WARP = DAC_OUT = ON; H16B, Reset FIFOs
2043      000000                    VID0      EQU     $000000                           ; Address of the first ARC-47 video board
2044      100000                    VID1      EQU     $100000                           ; Address of the second ARC-47 video board
2045      200000                    VID2      EQU     $200000                           ; Address of the second ARC-47 video board
2046      300000                    VID3      EQU     $300000                           ; Address of the second ARC-47 video board
2047      0E0000                    DAC_ADDR  EQU     $0E0000                           ; DAC Channel Address
2048      0F4000                    DAC_RegM  EQU     $0F4000                           ; DAC m Register
2049      0F8000                    DAC_RegC  EQU     $0F8000                           ; DAC c Register
2050      0FC000                    DAC_RegD  EQU     $0FC000                           ; DAC X1 Register
2051      000000                    VIDEO_DACS EQU    $000000                           ; Address of DACs on the video board
2052      000800                    CLK_ZERO  EQU     $000800                           ; Zero volts on clock driver line
2053   
2054                                ; *** include waveform table ***
2055                                          INCLUDE "90PrimeOne.asm"
2056                                ; 90PrimeOne.asm
2057                                ; STA2900 waveform code for 90Prime controller with 4 ARC47 video boards + ARC32 clock
2058                                ; 25Aug15 last change MPL
2059   
2060                                ; long delays needed for measured capacitance
2061   
2062                                ; *** timing (40 - 5080 ns) ***
2063      000118                    SERDEL    EQU     280                               ; S clock delay  - 280 (critical)
2064      0000F0                    RSTDEL    EQU     240                               ; RG clock delay - 320
2065      000050                    VIDDEL    EQU     80                                ; VP delay       -  80
2066   
2067      001388                    PARDEL    EQU     5000                              ; P clock delay
2068      000014                    PARMULT   EQU     20                                ;
2069   
2070      0007D0                    SAMPLE    EQU     2000                              ; sample time  was 2000
2071   
2072                                ; Gain g = 0 to 14, Gain = 1.00 to 4.75 in steps of 0.25
2073      000001                    VGAIN     EQU     1
2074   
2075                                ; Speed $10 to $F0 time constant (first nib)
2076      0000F0                    VSPEED    EQU     $f0
2077   
2078                                ; *** video offsets ***
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  90PrimeOne.asm  Page 39



2079                                ; ARC47 video offsets - 0 to $3fff video offset value
2080                                ; about 1 DN/count
2081   
2082      002710                    OFFSET    EQU     10000
2083                                          INCLUDE "offsets.asm"
2084                                ; *** video offsets ***
2085      00097F                    OFFSET0   EQU     2431
2086      0008A7                    OFFSET1   EQU     2215
2087      000B9E                    OFFSET2   EQU     2974
2088      00098B                    OFFSET3   EQU     2443
2089      000000                    OFFSET4   EQU     0
2090      000000                    OFFSET5   EQU     0
2091      000000                    OFFSET6   EQU     0
2092      000000                    OFFSET7   EQU     0
2093      000000                    OFFSET8   EQU     0
2094      000000                    OFFSET9   EQU     0
2095      000000                    OFFSET10  EQU     0
2096      000000                    OFFSET11  EQU     0
2097      000000                    OFFSET12  EQU     0
2098      000000                    OFFSET13  EQU     0
2099      000000                    OFFSET14  EQU     0
2100      000000                    OFFSET15  EQU     0
2101   
2102                                ; Default values:
2103                                ;OFFSET0    EQU      0
2104                                ;OFFSET1    EQU      0
2105                                ;OFFSET2    EQU      0
2106                                ;OFFSET3    EQU      0
2107   
2108                                ; *** bias voltages ***
2109      2.500000E+001             VOD       EQU     25.0                              ; Output Drain 24.0
2110      1.450000E+001             VRD       EQU     14.5                              ; Reset Drain  trails when > 15   14.8
2111      0.000000E+000             VOG       EQU     0.0                               ; Output Gate
2112      2.000000E+000             VRSV      EQU     2.0                               ; RTN lower more gain 2.0
2113      2.000000E+001             VSCP      EQU     20.0                              ; SCP 20
2114   
2115                                ; *** clock voltages ***
2116      8.000000E+000             RG_HI     EQU     8.0                               ; Reset Gate    8,-2
2117      -2.000000E+000            RG_LO     EQU     -2.0
2118   
2119      4.000000E+000             S_HI      EQU     +4.0                              ; Serial clocks 4,-6
2120      -6.000000E+000            S_LO      EQU     -6.0                              ; important for CCD1 fat "cols"
2121   
2122      4.000000E+000             SW_HI     EQU     +4.0                              ; Summing Well +-4
2123      -4.000000E+000            SW_LO     EQU     -4.0
2124   
2125      2.000000E+000             P1HI      EQU     +2.0                              ; 10789  2
2126      -8.000000E+000            P1LO      EQU     -8.0                              ;       -8
2127   
2128      1.000000E+000             P2HI      EQU     +1.0                              ; 10747  1
2129      -8.000000E+000            P2LO      EQU     -8.0                              ;       -8
2130   
2131      1.000000E+000             P3HI      EQU     +1.0                              ; 10317  1
2132      -7.000000E+000            P3LO      EQU     -7.0                              ;       -8
2133   
2134      1.000000E+000             P4HI      EQU     +1.0                              ; 10764  1
2135      -8.000000E+000            P4LO      EQU     -8.0                              ;       -8
2136   
2137                                ; *** aliases ***
2138      2.000000E+001             VSCP1     EQU     VSCP
2139      2.000000E+001             VSCP2     EQU     VSCP
2140      2.000000E+001             VSCP3     EQU     VSCP
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  90PrimeOne.asm  Page 40



2141      2.000000E+001             VSCP4     EQU     VSCP
2142   
2143                                ;                                        CHANNEL
2144      2.500000E+001             VOD1      EQU     VOD                               ; im4  - data[0]
2145      2.500000E+001             VOD2      EQU     VOD                               ; im3  - data[1]
2146      2.500000E+001             VOD3      EQU     VOD                               ; im2  - data[2]
2147      2.500000E+001             VOD4      EQU     VOD                               ; im1  - data[3]
2148   
2149      2.500000E+001             VOD5      EQU     VOD                               ; im8  - data[4]
2150      2.550000E+001             VOD6      EQU     VOD+0.5                           ; im7  - data[5]
2151      2.600000E+001             VOD7      EQU     VOD+1.0                           ; im6  - data[6] new, was 0.5
2152      2.500000E+001             VOD8      EQU     VOD                               ; im5  - data[7]
2153   
2154      2.500000E+001             VOD9      EQU     VOD                               ; im9  - data[8]
2155      2.500000E+001             VOD10     EQU     VOD                               ; im10 - data[9]
2156      2.500000E+001             VOD11     EQU     VOD                               ; im11 - data[10]
2157      2.500000E+001             VOD12     EQU     VOD                               ; im12 - data[12]
2158   
2159      2.500000E+001             VOD13     EQU     VOD                               ; im13 - data[12]
2160      2.500000E+001             VOD14     EQU     VOD                               ; im14 - data[13]
2161      2.600000E+001             VOD15     EQU     VOD+1                             ; im15 - data[14] new 03aug15
2162      2.500000E+001             VOD16     EQU     VOD                               ; im16 - data[15] bad
2163   
2164      -2.000000E+000            VOG1      EQU     -2.0                              ; was -2 this device
2165      0.000000E+000             VOG2      EQU     VOG
2166      0.000000E+000             VOG3      EQU     VOG
2167      0.000000E+000             VOG4      EQU     VOG
2168   
2169      0.000000E+000             VOG5      EQU     VOG
2170      0.000000E+000             VOG6      EQU     VOG
2171      0.000000E+000             VOG7      EQU     VOG
2172      -5.000000E-001            VOG8      EQU     -0.5
2173   
2174      0.000000E+000             VOG9      EQU     VOG
2175      0.000000E+000             VOG10     EQU     VOG
2176      0.000000E+000             VOG11     EQU     VOG
2177      0.000000E+000             VOG12     EQU     VOG
2178   
2179      0.000000E+000             VOG13     EQU     VOG
2180      0.000000E+000             VOG14     EQU     VOG
2181      1.500000E+000             VOG15     EQU     1.5                               ; new 03aug15
2182      -5.000000E-001            VOG16     EQU     -0.5                              ; new
2183   
2184      1.450000E+001             VRD1      EQU     VRD
2185      1.450000E+001             VRD2      EQU     VRD
2186      1.450000E+001             VRD3      EQU     VRD
2187      1.450000E+001             VRD4      EQU     VRD
2188      1.450000E+001             VRD5      EQU     VRD
2189      1.450000E+001             VRD6      EQU     VRD
2190      1.450000E+001             VRD7      EQU     VRD
2191      1.450000E+001             VRD8      EQU     VRD
2192      1.450000E+001             VRD9      EQU     VRD
2193      1.450000E+001             VRD10     EQU     VRD
2194      1.450000E+001             VRD11     EQU     VRD
2195      1.450000E+001             VRD12     EQU     VRD
2196      1.450000E+001             VRD13     EQU     VRD
2197      1.450000E+001             VRD14     EQU     VRD
2198      1.450000E+001             VRD15     EQU     VRD
2199      1.450000E+001             VRD16     EQU     VRD
2200   
2201      2.000000E+000             VRSV1     EQU     VRSV
2202      2.000000E+000             VRSV2     EQU     VRSV
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  90PrimeOne.asm  Page 41



2203      2.000000E+000             VRSV3     EQU     VRSV
2204      2.000000E+000             VRSV4     EQU     VRSV
2205   
2206      2.000000E+000             VRSV5     EQU     VRSV
2207      2.000000E+000             VRSV6     EQU     VRSV
2208      2.000000E+000             VRSV7     EQU     VRSV
2209      2.000000E+000             VRSV8     EQU     VRSV
2210   
2211      2.000000E+000             VRSV9     EQU     VRSV
2212      2.000000E+000             VRSV10    EQU     VRSV
2213      2.000000E+000             VRSV11    EQU     VRSV
2214      2.000000E+000             VRSV12    EQU     VRSV
2215   
2216      2.000000E+000             VRSV13    EQU     VRSV
2217      2.000000E+000             VRSV14    EQU     VRSV
2218      2.000000E+000             VRSV15    EQU     VRSV
2219      2.000000E+000             VRSV16    EQU     VRSV
2220   
2221                                ; clocks
2222      8.000000E+000             RG1_HI    EQU     RG_HI
2223      -2.000000E+000            RG1_LO    EQU     RG_LO
2224      8.000000E+000             RG2_HI    EQU     RG_HI
2225      -2.000000E+000            RG2_LO    EQU     RG_LO
2226      8.000000E+000             RG3_HI    EQU     RG_HI
2227      -2.000000E+000            RG3_LO    EQU     RG_LO
2228      8.000000E+000             RG4_HI    EQU     RG_HI
2229      -2.000000E+000            RG4_LO    EQU     RG_LO
2230   
2231      4.000000E+000             SWL_HI    EQU     SW_HI
2232      -4.000000E+000            SWL_LO    EQU     SW_LO
2233      4.000000E+000             SWR_HI    EQU     SW_HI
2234      -4.000000E+000            SWR_LO    EQU     SW_LO
2235   
2236      4.000000E+000             S1_HI     EQU     S_HI
2237      -6.000000E+000            S1_LO     EQU     S_LO
2238      4.000000E+000             S2_HI     EQU     S_HI
2239      -6.000000E+000            S2_LO     EQU     S_LO
2240      4.000000E+000             S3_HI     EQU     S_HI
2241      -6.000000E+000            S3_LO     EQU     S_LO
2242   
2243      2.000000E+000             P11_HI    EQU     P1HI
2244      -8.000000E+000            P11_LO    EQU     P1LO
2245      2.000000E+000             P21_HI    EQU     P1HI
2246      -8.000000E+000            P21_LO    EQU     P1LO
2247      2.000000E+000             P31_HI    EQU     P1HI
2248      -8.000000E+000            P31_LO    EQU     P1LO
2249   
2250      1.000000E+000             P12_HI    EQU     P2HI
2251      -8.000000E+000            P12_LO    EQU     P2LO
2252      1.000000E+000             P22_HI    EQU     P2HI
2253      -8.000000E+000            P22_LO    EQU     P2LO
2254      1.000000E+000             P32_HI    EQU     P2HI
2255      -8.000000E+000            P32_LO    EQU     P2LO
2256   
2257      1.000000E+000             P13_HI    EQU     P3HI
2258      -7.000000E+000            P13_LO    EQU     P3LO
2259      1.000000E+000             P23_HI    EQU     P3HI
2260      -7.000000E+000            P23_LO    EQU     P3LO
2261      1.000000E+000             P33_HI    EQU     P3HI
2262      -7.000000E+000            P33_LO    EQU     P3LO
2263   
2264      1.000000E+000             P14_HI    EQU     P4HI
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  90PrimeOne.asm  Page 42



2265      -8.000000E+000            P14_LO    EQU     P4LO
2266      1.000000E+000             P24_HI    EQU     P4HI
2267      -8.000000E+000            P24_LO    EQU     P4LO
2268      1.000000E+000             P34_HI    EQU     P4HI
2269      -8.000000E+000            P34_LO    EQU     P4LO
2270   
2271                                ; *** configurations ****
2272   
2273                                          DEFINE  CHANNELS  '0123'
2274                                          DEFINE  CLOCKING  'clocking.asm'
2275   
2276                                ; *** DSP Y memory parameter table ***
2277                                ; Values in this block start at Y:0 and are overwritten by AzCam
2278                                ; All values are unbinned pixels unless noted.
2279   
2280      Y:000000 Y:000000         CAMSTAT   DC      0                                 ; not used
2281      Y:000001 Y:000001         NSDATA    DC      1                                 ; number BINNED serial columns in ROI
2282      Y:000002 Y:000002         NPDATA    DC      1                                 ; number of BINNED parallel rows in ROI
2283      Y:000003 Y:000003         NSBIN     DC      1                                 ; Serial binning parameter (>= 1)
2284      Y:000004 Y:000004         NPBIN     DC      1                                 ; Parallel binning parameter (>= 1)
2285   
2286      Y:000005 Y:000005         NSAMPS    DC      0                                 ; 0 => 1 amp, 1 => split serials
2287      Y:000006 Y:000006         NPAMPS    DC      0                                 ; 0 => 1 amp, 1 => split parallels
2288      Y:000007 Y:000007         NSCLEAR   DC      1                                 ; number of columns to clear during flush
2289      Y:000008 Y:000008         NPCLEAR   DC      1                                 ; number of rows to clear during flush
2290   
2291      Y:000009 Y:000009         NSPRESKIP DC      0                                 ; number of cols to skip before underscan
2292                                 NSUNDERSCAN
2293      Y:00000A Y:00000A                   DC      0                                 ; number of BINNED columns in underscan
2294      Y:00000B Y:00000B         NSSKIP    DC      0                                 ; number of cols to skip between underscan a
nd data
2295      Y:00000C Y:00000C         NSPOSTSKIP DC     0                                 ; number of cols to skip between data and ov
erscan
2296      Y:00000D Y:00000D         NSOVERSCAN DC     0                                 ; number of BINNED columns in overscan
2297   
2298      Y:00000E Y:00000E         NPPRESKIP DC      0                                 ; number of rows to skip before underscan
2299                                 NPUNDERSCAN
2300      Y:00000F Y:00000F                   DC      0                                 ; number of BINNED rows in underscan
2301      Y:000010 Y:000010         NPSKIP    DC      0                                 ; number of rows to skip between underscan a
nd data
2302      Y:000011 Y:000011         NPPOSTSKIP DC     0                                 ; number of rows to skip between data and ov
erscan
2303      Y:000012 Y:000012         NPOVERSCAN DC     0                                 ; number of BINNED rows in overscan
2304   
2305      Y:000013 Y:000013         NPXSHIFT  DC      0                                 ; number of rows to parallel shift
2306      Y:000014 Y:000014         TESTDATA  DC      0                                 ; 0 => normal, 1 => send incremented fake da
ta
2307      Y:000015 Y:000015         FRAMET    DC      0                                 ; number of storage rows for frame transfer 
shift
2308      Y:000016 Y:000016         PREFLASH  DC      0                                 ; not used
2309      Y:000017 Y:000017         GAIN      DC      0                                 ; Video proc gain and integrator speed store
d here
2310      Y:000018 Y:000018         TST_DAT   DC      0                                 ; Place for synthetic test image pixel data
2311      Y:000019 Y:000019         SH_DEL    DC      1500                              ; Delay (msecs) between shutter closing and 
image readout
2312      Y:00001A Y:00001A         CONFIG    DC      0                                 ; Controller configuration - was CC
2313      Y:00001B Y:00001B         NSIMAGE   DC      1                                 ; total number of columns in image
2314      Y:00001C Y:00001C         NPIMAGE   DC      1                                 ; total number of rows in image
2315      Y:00001D Y:00001D         PAD3      DC      0                                 ; unused
2316      Y:00001E Y:00001E         PAD4      DC      0                                 ; unused
2317      Y:00001F Y:00001F         IDLEONE   DC      2                                 ; lines to shift in IDLE (really 1)
2318   
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\TIM3.asm  Page 43



2319                                ; Values in this block start at Y:20 and are overwritten if waveform table
2320                                ; is downloaded
2321      Y:000020 Y:000020         PMULT     DC      PARMULT                           ; parallel clock multiplier
2322      Y:000021 Y:000021         ACLEAR0   DC      TNOP                              ; Clear prologue - NOT USED
2323      Y:000022 Y:000022         ACLEAR2   DC      TNOP                              ; Clear epilogue - NOT USED
2324      Y:000023 Y:000023         AREAD0    DC      TNOP                              ; Read prologue - NOT USED
2325      Y:000024 Y:000024         AREAD8    DC      TNOP                              ; Read epilogue - NOT USED
2326      Y:000025 Y:000025         AFPXFER0  DC      FPXFER0                           ; Fast parallel transfer prologue
2327      Y:000026 Y:000026         AFPXFER2  DC      FPXFER2                           ; Fast parallel transfer epilogue
2328      Y:000027 Y:000027         APXFER    DC      PXFER                             ; Parallel transfer - storage only
2329      Y:000028 Y:000028         APDXFER   DC      PXFER                             ; Parallel transfer (data) - storage only
2330      Y:000029 Y:000029         APQXFER   DC      PQXFER                            ; Parallel transfer - storage and image
2331      Y:00002A Y:00002A         ARXFER    DC      RXFER                             ; Reverse parallel transfer (for focus)
2332      Y:00002B Y:00002B         AFSXFER   DC      FSXFER                            ; Fast serial transfer
2333      Y:00002C Y:00002C         ASXFER0   DC      SXFER0                            ; Serial transfer prologue
2334      Y:00002D Y:00002D         ASXFER1   DC      SXFER1                            ; Serial transfer ( * colbin-1 )
2335      Y:00002E Y:00002E         ASXFER2   DC      SXFER2                            ; Serial transfer epilogue - no data
2336      Y:00002F Y:00002F         ASXFER2D  DC      SXFER2D                           ; Serial transfer epilogue - data
2337      Y:000030 Y:000030         ADACS     DC      DACS
2338   
2339                                ; *** clock boards pins and states***
2340                                          INCLUDE "90PrimeClockPins.asm"
2341                                ; 90Primeclockpins.asm
2342   
2343                                ; low bank
2344      000000                    P11L      EQU     0                                 ;       CLK0    Pin 1
2345      000001                    P11H      EQU     1                                 ;       CLK0
2346      000000                    P21L      EQU     0                                 ;       CLK1    Pin 2
2347      000002                    P21H      EQU     2                                 ;       CLK1
2348      000000                    P31L      EQU     0                                 ;       CLK2    Pin 3
2349      000004                    P31H      EQU     4                                 ;       CLK2
2350      000000                    P12L      EQU     0                                 ;       CLK3    Pin 4
2351      000008                    P12H      EQU     8                                 ;       CLK3
2352      000000                    P22L      EQU     0                                 ;       CLK4    Pin 5
2353      000010                    P22H      EQU     $10                               ;       CLK4
2354      000000                    P32L      EQU     0                                 ;       CLK5    Pin 6
2355      000020                    P32H      EQU     $20                               ;       CLK5
2356      000000                    P13L      EQU     0                                 ;       CLK6    Pin 7
2357      000040                    P13H      EQU     $40                               ;       CLK6
2358      000000                    P23L      EQU     0                                 ;       CLK7    Pin 8
2359      000080                    P23H      EQU     $80                               ;       CLK7
2360      000000                    P33L      EQU     0                                 ;       CLK8    Pin 9
2361      000100                    P33H      EQU     $100                              ;       CLK8
2362      000000                    P14L      EQU     0                                 ;       CLK9    Pin 10
2363      000200                    P14H      EQU     $200                              ;       CLK9
2364      000000                    P24L      EQU     0                                 ;       CLK10   Pin 11
2365      000400                    P24H      EQU     $400                              ;       CLK10
2366      000000                    P34L      EQU     0                                 ;       CLK11   Pin 12
2367      000800                    P34H      EQU     $800                              ;       CLK11
2368   
2369                                ; high bank
2370      000000                    S1L       EQU     0                                 ;       CLK12   Pin 13
2371      000001                    S1H       EQU     $1                                ;       CLK12
2372      000000                    S2L       EQU     0                                 ;       CLK13   Pin 14
2373      000002                    S2H       EQU     $2                                ;       CLK13
2374      000000                    S3L       EQU     0                                 ;       CLK14   Pin 15
2375      000004                    S3H       EQU     $4                                ;       CLK14
2376      000000                    Z0LL      EQU     0                                 ;       CLK15   Pin 16
2377      000008                    Z0HH      EQU     $8                                ;       CLK15
2378      000000                    Z1LL      EQU     0                                 ;       CLK16   Pin 17
2379      000010                    Z1HH      EQU     $10                               ;       CLK16
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\90PrimeClockPins.asm  Page 44



2380      000000                    SWLL      EQU     0                                 ;       CLK17   Pin 18
2381      000020                    SWLH      EQU     $20                               ;       CLK17
2382      000000                    SWRL      EQU     0                                 ;       CLK18   Pin 19
2383      000040                    SWRH      EQU     $40                               ;       CLK18
2384      000000                    Z2L       EQU     0                                 ;       CLK19   Pin 33
2385      000080                    Z2H       EQU     $80                               ;       CLK19
2386      000000                    RG1L      EQU     0                                 ;       CLK20   Pin 34
2387      000100                    RG1H      EQU     $100                              ;       CLK20
2388      000000                    RG2L      EQU     0                                 ;       CLK21   Pin 35
2389      000200                    RG2H      EQU     $200                              ;       CLK21
2390      000000                    RG3L      EQU     0                                 ;       CLK22   Pin 36
2391      000400                    RG3H      EQU     $400                              ;       CLK22
2392      000000                    RG4L      EQU     0                                 ;       CLK23   Pin 37
2393      000800                    RG4H      EQU     $800                              ;       CLK23
2394   
2395                                ; *** video definitions ***
2396                                          INCLUDE "ARC47_defs.asm"
2397                                ; ARC47_defs.asm
2398                                ; 02Sep10 last change MPL
2399   
2400                                ; *** define SXMIT based on selected channels ***
2401                                ; ARC47 ADC conversion codes
2402                                ;$00F000        BRD#0 A/D#0
2403                                ;$00F041        BRD#0 A/D#1
2404                                ;$00F082        BRD#0 A/D#2
2405                                ;$00F0C3        BRD#0 A/D#3
2406                                ;$00F104        BRD#0 A/D#4
2407                                ;$00F145        BRD#0 A/D#5
2408                                ;$00F186        BRD#0 A/D#6
2409                                ;$00F1C7        BRD#0 A/D#7
2410                                ;$00F208        BRD#1 A/D#0
2411                                ;$00F249        BRD#1 A/D#1
2412                                ;$00F28A        BRD#1 A/D#2
2413                                ;$00F2CB        BRD#1 A/D#3
2414                                ;$00F30C        BRD#1 A/D#4
2415                                ;$00F34D        BRD#1 A/D#5
2416                                ;$00F38E        BRD#1 A/D#6
2417                                ;$00F3CF        BRD#1 A/D#7
2418                                ;$00F1C0        BRD#0 A/D#0-#7
2419                                ;$00F3C8        BRD#1 A/D#0-#7
2420                                ;$00F3C0        BRD#0-#1 A/D#0-#7
2421   
2422                                          IF      @SCP("0123","8A")
2424                                          ENDIF
2425                                          IF      @SCP("0123","8B")
2427                                          ENDIF
2428                                          IF      @SCP("0123","16")
2430                                          ENDIF
2431                                          IF      @SCP("0123","32")
2433                                          ENDIF
2434                                          IF      @SCP("0123","0")
2436                                          ENDIF
2437                                          IF      @SCP("0123","1")
2439                                          ENDIF
2440                                          IF      @SCP("0123","2")
2442                                          ENDIF
2443                                          IF      @SCP("0123","3")
2445                                          ENDIF
2446                                          IF      @SCP("0123","01")
2448                                          ENDIF
2449                                          IF      @SCP("0123","23")
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_defs.asm  Page 45



2451                                          ENDIF
2452                                          IF      @SCP("0123","0123")
2453      00F0C0                    SXMIT     EQU     $00F0C0
2454                                          ENDIF
2455   
2456                                ; timing
2457      060000                    S_DELAY   EQU     @CVI((SERDEL-40)/40)<<16
2458      050000                    R_DELAY   EQU     @CVI((RSTDEL-40)/40)<<16
2459      010000                    V_DELAY   EQU     @CVI((VIDDEL-40)/40)<<16
2460      7C0000                    P_DELAY   EQU     @CVI((PARDEL-40)/40)<<16
2461      310000                    DWELL     EQU     @CVI((SAMPLE-40)/40)<<16
2462   
2463                                ; ARC47 gain : $0D000g, g = 0 to %1111, Gain = 1.00 to 4.75 in steps of 0.25
2464                                ; 0     1.00             8      3.00
2465                                ; 1     1.25             9      3.25
2466                                ; 2     1.50            10      3.75
2467                                ; 3     1.75            11      4.00
2468                                ; 4     2.00            12      4.25
2469                                ; 5     2.25            13      4.50
2470                                ; 6     2.50            14      4.75
2471                                ; 7     2.75            15      forbidden?
2472   
2473                                ; voltage to DN
2474   
2475      3.045000E+001             VOD_MAX   EQU     30.45
2476      1.990000E+001             VRD_MAX   EQU     19.90
2477      8.700000E+000             VOG_MAX   EQU     8.70
2478      8.700000E+000             VRSV_MAX  EQU     8.70
2479   
2480      00348A                    DAC_VOD1  EQU     @CVI((VOD1/VOD_MAX)*16384-1)      ; Unipolar
2481      002EA1                    DAC_VRD1  EQU     @CVI((VRD1/VRD_MAX)*16384-1)      ; Unipolar
2482      0018A3                    DAC_VOG1  EQU     @CVI(((VOG1+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2483      00275A                    DAC_VRSV1 EQU     @CVI(((VRSV1+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2484   
2485      00348A                    DAC_VOD2  EQU     @CVI((VOD2/VOD_MAX)*16384-1)      ; Unipolar
2486      002EA1                    DAC_VRD2  EQU     @CVI((VRD2/VRD_MAX)*16384-1)      ; Unipolar
2487      001FFF                    DAC_VOG2  EQU     @CVI(((VOG2+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2488      00275A                    DAC_VRSV2 EQU     @CVI(((VRSV2+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2489   
2490      00348A                    DAC_VOD3  EQU     @CVI((VOD3/VOD_MAX)*16384-1)      ; Unipolar
2491      002EA1                    DAC_VRD3  EQU     @CVI((VRD3/VRD_MAX)*16384-1)      ; Unipolar
2492      001FFF                    DAC_VOG3  EQU     @CVI(((VOG3+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2493      00275A                    DAC_VRSV3 EQU     @CVI(((VRSV3+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2494   
2495      00348A                    DAC_VOD4  EQU     @CVI((VOD4/VOD_MAX)*16384-1)      ; Unipolar
2496      002EA1                    DAC_VRD4  EQU     @CVI((VRD4/VRD_MAX)*16384-1)      ; Unipolar
2497      001FFF                    DAC_VOG4  EQU     @CVI(((VOG4+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2498      00275A                    DAC_VRSV4 EQU     @CVI(((VRSV4+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2499   
2500      00348A                    DAC_VOD5  EQU     @CVI((VOD5/VOD_MAX)*16384-1)      ; Unipolar
2501      002EA1                    DAC_VRD5  EQU     @CVI((VRD5/VRD_MAX)*16384-1)      ; Unipolar
2502      001FFF                    DAC_VOG5  EQU     @CVI(((VOG5+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2503      00275A                    DAC_VRSV5 EQU     @CVI(((VRSV5+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2504   
2505      003597                    DAC_VOD6  EQU     @CVI((VOD6/VOD_MAX)*16384-1)      ; Unipolar
2506      002EA1                    DAC_VRD6  EQU     @CVI((VRD6/VRD_MAX)*16384-1)      ; Unipolar
2507      001FFF                    DAC_VOG6  EQU     @CVI(((VOG6+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2508      00275A                    DAC_VRSV6 EQU     @CVI(((VRSV6+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2509   
2510      0036A4                    DAC_VOD7  EQU     @CVI((VOD7/VOD_MAX)*16384-1)      ; Unipolar
2511      002EA1                    DAC_VRD7  EQU     @CVI((VRD7/VRD_MAX)*16384-1)      ; Unipolar
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_defs.asm  Page 46



2512      001FFF                    DAC_VOG7  EQU     @CVI(((VOG7+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2513      00275A                    DAC_VRSV7 EQU     @CVI(((VRSV7+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2514   
2515      00348A                    DAC_VOD8  EQU     @CVI((VOD8/VOD_MAX)*16384-1)      ; Unipolar
2516      002EA1                    DAC_VRD8  EQU     @CVI((VRD8/VRD_MAX)*16384-1)      ; Unipolar
2517      001E28                    DAC_VOG8  EQU     @CVI(((VOG8+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2518      00275A                    DAC_VRSV8 EQU     @CVI(((VRSV8+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2519   
2520      00348A                    DAC_VOD9  EQU     @CVI((VOD9/VOD_MAX)*16384-1)      ; Unipolar
2521      002EA1                    DAC_VRD9  EQU     @CVI((VRD9/VRD_MAX)*16384-1)      ; Unipolar
2522      001FFF                    DAC_VOG9  EQU     @CVI(((VOG9+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2523      00275A                    DAC_VRSV9 EQU     @CVI(((VRSV9+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2524   
2525      00348A                    DAC_VOD10 EQU     @CVI((VOD10/VOD_MAX)*16384-1)     ; Unipolar
2526      002EA1                    DAC_VRD10 EQU     @CVI((VRD10/VRD_MAX)*16384-1)     ; Unipolar
2527      001FFF                    DAC_VOG10 EQU     @CVI(((VOG10+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2528      00275A                    DAC_VRSV10 EQU    @CVI(((VRSV10+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2529   
2530      00348A                    DAC_VOD11 EQU     @CVI((VOD11/VOD_MAX)*16384-1)     ; Unipolar
2531      002EA1                    DAC_VRD11 EQU     @CVI((VRD11/VRD_MAX)*16384-1)     ; Unipolar
2532      001FFF                    DAC_VOG11 EQU     @CVI(((VOG11+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2533      00275A                    DAC_VRSV11 EQU    @CVI(((VRSV11+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2534   
2535      00348A                    DAC_VOD12 EQU     @CVI((VOD12/VOD_MAX)*16384-1)     ; Unipolar
2536      002EA1                    DAC_VRD12 EQU     @CVI((VRD12/VRD_MAX)*16384-1)     ; Unipolar
2537      001FFF                    DAC_VOG12 EQU     @CVI(((VOG12+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2538      00275A                    DAC_VRSV12 EQU    @CVI(((VRSV12+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2539   
2540      00348A                    DAC_VOD13 EQU     @CVI((VOD13/VOD_MAX)*16384-1)     ; Unipolar
2541      002EA1                    DAC_VRD13 EQU     @CVI((VRD13/VRD_MAX)*16384-1)     ; Unipolar
2542      001FFF                    DAC_VOG13 EQU     @CVI(((VOG13+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2543      00275A                    DAC_VRSV13 EQU    @CVI(((VRSV13+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2544   
2545      00348A                    DAC_VOD14 EQU     @CVI((VOD14/VOD_MAX)*16384-1)     ; Unipolar
2546      002EA1                    DAC_VRD14 EQU     @CVI((VRD14/VRD_MAX)*16384-1)     ; Unipolar
2547      001FFF                    DAC_VOG14 EQU     @CVI(((VOG14+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2548      00275A                    DAC_VRSV14 EQU    @CVI(((VRSV14+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2549   
2550      0036A4                    DAC_VOD15 EQU     @CVI((VOD15/VOD_MAX)*16384-1)     ; Unipolar
2551      002EA1                    DAC_VRD15 EQU     @CVI((VRD15/VRD_MAX)*16384-1)     ; Unipolar
2552      002583                    DAC_VOG15 EQU     @CVI(((VOG15+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2553      00275A                    DAC_VRSV15 EQU    @CVI(((VRSV15+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2554   
2555      00348A                    DAC_VOD16 EQU     @CVI((VOD16/VOD_MAX)*16384-1)     ; Unipolar
2556      002EA1                    DAC_VRD16 EQU     @CVI((VRD16/VRD_MAX)*16384-1)     ; Unipolar
2557      001E28                    DAC_VOG16 EQU     @CVI(((VOG16+VOG_MAX)/VOG_MAX)*8192-1) ; Bipolar
2558      00275A                    DAC_VRSV16 EQU    @CVI(((VRSV16+VRSV_MAX)/VRSV_MAX)*8192-1) ; Bipolar
2559   
2560      002A08                    DAC_VSCP1 EQU     @CVI((VSCP1/VOD_MAX)*16384-1)     ; Unipolar
2561      002A08                    DAC_VSCP2 EQU     @CVI((VSCP2/VOD_MAX)*16384-1)     ; Unipolar
2562      002A08                    DAC_VSCP3 EQU     @CVI((VSCP3/VOD_MAX)*16384-1)     ; Unipolar
2563      002A08                    DAC_VSCP4 EQU     @CVI((VSCP4/VOD_MAX)*16384-1)     ; Unipolar
2564   
2565   
2566                                ; *** DACS table for video and clock boards ***
2567      Y:000031 Y:000031         DACS      DC      EDACS-DACS-1
2568                                          INCLUDE "ARC47_dacs_brd0.asm"
2569                                ; ARC47_dacs_brd0.asm
2570                                ; ARC47 4 channel video board DACS table
2571                                ; first installed board
2572                                ; 04Sep13 last change MPL
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_dacs_brd0.asm  Page 47



2573   
2574                                ; Commands for the ARC-47 video board
2575      Y:000032 Y:000032                   DC      VID0+$0C0004                      ; Normal Image data D17-D2
2576   
2577                                ; Gain : $0D000g, g = 0 to %1111, Gain = 1.00 to 4.75 in steps of 0.25
2578      Y:000033 Y:000033                   DC      VID0+$0D0000+VGAIN                ; Left readout
2579      Y:000034 Y:000034                   DC      VID0+$0C0100+VSPEED               ; time constant
2580   
2581                                ; Initialize the ARC-47 DAC For DC_BIAS
2582      Y:000035 Y:000035                   DC      VID0+DAC_ADDR+$000000             ; Vod0,pin 52
2583      Y:000036 Y:000036                   DC      VID0+DAC_RegD+DAC_VOD1
2584      Y:000037 Y:000037                   DC      VID0+DAC_ADDR+$000004             ; Vrd0,pin 13
2585      Y:000038 Y:000038                   DC      VID0+DAC_RegD+DAC_VRD1
2586      Y:000039 Y:000039                   DC      VID0+DAC_ADDR+$000008             ; Vog0,pin 29
2587      Y:00003A Y:00003A                   DC      VID0+DAC_RegD+DAC_VOG1
2588      Y:00003B Y:00003B                   DC      VID0+DAC_ADDR+$00000C             ; Vabg,pin 5
2589      Y:00003C Y:00003C                   DC      VID0+DAC_RegD+DAC_VRSV1
2590   
2591      Y:00003D Y:00003D                   DC      VID0+DAC_ADDR+$000001             ; Vod1,pin 32
2592      Y:00003E Y:00003E                   DC      VID0+DAC_RegD+DAC_VOD2
2593      Y:00003F Y:00003F                   DC      VID0+DAC_ADDR+$000005             ; Vrd1,pin 55
2594      Y:000040 Y:000040                   DC      VID0+DAC_RegD+DAC_VRD2
2595      Y:000041 Y:000041                   DC      VID0+DAC_ADDR+$000009             ; Vog1,pin 8
2596      Y:000042 Y:000042                   DC      VID0+DAC_RegD+DAC_VOG2
2597      Y:000043 Y:000043                   DC      VID0+DAC_ADDR+$00000D             ; Vrsv1,pin 47
2598      Y:000044 Y:000044                   DC      VID0+DAC_RegD+DAC_VRSV2
2599   
2600      Y:000045 Y:000045                   DC      VID0+DAC_ADDR+$000002             ; Vod2,pin 11
2601      Y:000046 Y:000046                   DC      VID0+DAC_RegD+DAC_VOD3
2602      Y:000047 Y:000047                   DC      VID0+DAC_ADDR+$000006             ; Vrd2,pin 35
2603      Y:000048 Y:000048                   DC      VID0+DAC_RegD+DAC_VRD3
2604      Y:000049 Y:000049                   DC      VID0+DAC_ADDR+$00000A             ; Vog2,pin 50
2605      Y:00004A Y:00004A                   DC      VID0+DAC_RegD+DAC_VOG3
2606      Y:00004B Y:00004B                   DC      VID0+DAC_ADDR+$00000E             ; Vrsv2,pin 27
2607      Y:00004C Y:00004C                   DC      VID0+DAC_RegD+DAC_VRSV3
2608   
2609      Y:00004D Y:00004D                   DC      VID0+DAC_ADDR+$000003             ; Vod3,pin 53
2610      Y:00004E Y:00004E                   DC      VID0+DAC_RegD+DAC_VOD4
2611      Y:00004F Y:00004F                   DC      VID0+DAC_ADDR+$000007             ; Vrd3,pin 14
2612      Y:000050 Y:000050                   DC      VID0+DAC_RegD+DAC_VRD4
2613      Y:000051 Y:000051                   DC      VID0+DAC_ADDR+$00000B             ; Vog3,pin 30
2614      Y:000052 Y:000052                   DC      VID0+DAC_RegD+DAC_VOG4
2615      Y:000053 Y:000053                   DC      VID0+DAC_ADDR+$00000F             ; Vrsv3,pin 6
2616      Y:000054 Y:000054                   DC      VID0+DAC_RegD+DAC_VRSV4
2617   
2618      Y:000055 Y:000055                   DC      VID0+DAC_ADDR+$000010             ; Vod4,pin 33
2619      Y:000056 Y:000056                   DC      VID0+DAC_RegD+DAC_VSCP1
2620      Y:000057 Y:000057                   DC      VID0+DAC_ADDR+$000011             ; Vrd4,pin 56
2621      Y:000058 Y:000058                   DC      VID0+DAC_RegD+DAC_VRD4
2622      Y:000059 Y:000059                   DC      VID0+DAC_ADDR+$000012             ; Vog4,pin 9
2623      Y:00005A Y:00005A                   DC      VID0+DAC_RegD+DAC_VOG4
2624      Y:00005B Y:00005B                   DC      VID0+DAC_ADDR+$000013             ; Vrsv4,pin 48
2625      Y:00005C Y:00005C                   DC      VID0+DAC_RegD+DAC_VRSV4
2626   
2627                                ; Initialize the ARC-47 DAC For Video Offsets
2628      Y:00005D Y:00005D                   DC      VID0+DAC_ADDR+$000014
2629      Y:00005E Y:00005E                   DC      VID0+DAC_RegD+OFFSET+OFFSET0
2630      Y:00005F Y:00005F                   DC      VID0+DAC_ADDR+$000015
2631      Y:000060 Y:000060                   DC      VID0+DAC_RegD+OFFSET+OFFSET1
2632      Y:000061 Y:000061                   DC      VID0+DAC_ADDR+$000016
2633      Y:000062 Y:000062                   DC      VID0+DAC_RegD+OFFSET+OFFSET2
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_dacs_brd0.asm  Page 48



2634      Y:000063 Y:000063                   DC      VID0+DAC_ADDR+$000017
2635      Y:000064 Y:000064                   DC      VID0+DAC_RegD+OFFSET+OFFSET3
2636   
2637                                ; end of ARC47_dacs_brd0.asm
2638                                          INCLUDE "ARC47_dacs_brd1.asm"
2639                                ; ARC47_dacs_brd1.asm
2640                                ; ARC47 4 channel video board DACS table
2641                                ; second installed board
2642                                ; 04Sep13 last change MPL
2643   
2644                                ; Commands for the ARC-47 video board
2645      Y:000065 Y:000065                   DC      VID1+$0C0004                      ; Normal Image data D17-D2
2646   
2647                                ; Gain : $0D000g, g = 0 to %1111, Gain = 1.00 to 4.75 in steps of 0.25
2648      Y:000066 Y:000066                   DC      VID1+$0D0000+VGAIN
2649      Y:000067 Y:000067                   DC      VID1+$0C0100+VSPEED               ; time constant
2650   
2651                                ; Initialize the ARC-47 DAC For DC_BIAS
2652      Y:000068 Y:000068                   DC      VID1+DAC_ADDR+$000000             ; Vod0,pin 52
2653      Y:000069 Y:000069                   DC      VID1+DAC_RegD+DAC_VOD5
2654      Y:00006A Y:00006A                   DC      VID1+DAC_ADDR+$000004             ; Vrd0,pin 13
2655      Y:00006B Y:00006B                   DC      VID1+DAC_RegD+DAC_VRD5
2656      Y:00006C Y:00006C                   DC      VID1+DAC_ADDR+$000008             ; Vog0,pin 29
2657      Y:00006D Y:00006D                   DC      VID1+DAC_RegD+DAC_VOG5
2658      Y:00006E Y:00006E                   DC      VID1+DAC_ADDR+$00000C             ; Vabg,pin 5
2659      Y:00006F Y:00006F                   DC      VID1+DAC_RegD+DAC_VRSV5
2660   
2661      Y:000070 Y:000070                   DC      VID1+DAC_ADDR+$000001             ; Vod1,pin 32
2662      Y:000071 Y:000071                   DC      VID1+DAC_RegD+DAC_VOD6
2663      Y:000072 Y:000072                   DC      VID1+DAC_ADDR+$000005             ; Vrd1,pin 55
2664      Y:000073 Y:000073                   DC      VID1+DAC_RegD+DAC_VRD6
2665      Y:000074 Y:000074                   DC      VID1+DAC_ADDR+$000009             ; Vog1,pin 8
2666      Y:000075 Y:000075                   DC      VID1+DAC_RegD+DAC_VOG6
2667      Y:000076 Y:000076                   DC      VID1+DAC_ADDR+$00000D             ; Vrsv1,pin 47
2668      Y:000077 Y:000077                   DC      VID1+DAC_RegD+DAC_VRSV6
2669   
2670      Y:000078 Y:000078                   DC      VID1+DAC_ADDR+$000002             ; Vod2,pin 11
2671      Y:000079 Y:000079                   DC      VID1+DAC_RegD+DAC_VOD7
2672      Y:00007A Y:00007A                   DC      VID1+DAC_ADDR+$000006             ; Vrd2,pin 35
2673      Y:00007B Y:00007B                   DC      VID1+DAC_RegD+DAC_VRD7
2674      Y:00007C Y:00007C                   DC      VID1+DAC_ADDR+$00000A             ; Vog2,pin 50
2675      Y:00007D Y:00007D                   DC      VID1+DAC_RegD+DAC_VOG7
2676      Y:00007E Y:00007E                   DC      VID1+DAC_ADDR+$00000E             ; Vrsv2,pin 27
2677      Y:00007F Y:00007F                   DC      VID1+DAC_RegD+DAC_VRSV7
2678   
2679      Y:000080 Y:000080                   DC      VID1+DAC_ADDR+$000003             ; Vod3,pin 53
2680      Y:000081 Y:000081                   DC      VID1+DAC_RegD+DAC_VOD8
2681      Y:000082 Y:000082                   DC      VID1+DAC_ADDR+$000007             ; Vrd3,pin 14
2682      Y:000083 Y:000083                   DC      VID1+DAC_RegD+DAC_VRD8
2683      Y:000084 Y:000084                   DC      VID1+DAC_ADDR+$00000B             ; Vog3,pin 30
2684      Y:000085 Y:000085                   DC      VID1+DAC_RegD+DAC_VOG8
2685      Y:000086 Y:000086                   DC      VID1+DAC_ADDR+$00000F             ; Vrsv3,pin 6
2686      Y:000087 Y:000087                   DC      VID1+DAC_RegD+DAC_VRSV8
2687   
2688      Y:000088 Y:000088                   DC      VID1+DAC_ADDR+$000010             ; Vod4,pin 33
2689      Y:000089 Y:000089                   DC      VID1+DAC_RegD+DAC_VSCP2
2690      Y:00008A Y:00008A                   DC      VID1+DAC_ADDR+$000011             ; Vrd4,pin 56
2691      Y:00008B Y:00008B                   DC      VID1+DAC_RegD+DAC_VRD4
2692      Y:00008C Y:00008C                   DC      VID1+DAC_ADDR+$000012             ; Vog4,pin 9
2693      Y:00008D Y:00008D                   DC      VID1+DAC_RegD+DAC_VOG4
2694      Y:00008E Y:00008E                   DC      VID1+DAC_ADDR+$000013             ; Vrsv4,pin 48
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_dacs_brd1.asm  Page 49



2695      Y:00008F Y:00008F                   DC      VID1+DAC_RegD+DAC_VRSV4
2696   
2697                                ; Initialize the ARC-47 DAC For Video Offsets
2698      Y:000090 Y:000090                   DC      VID1+DAC_ADDR+$000014
2699      Y:000091 Y:000091                   DC      VID1+DAC_RegD+OFFSET+OFFSET4
2700      Y:000092 Y:000092                   DC      VID1+DAC_ADDR+$000015
2701      Y:000093 Y:000093                   DC      VID1+DAC_RegD+OFFSET+OFFSET5
2702      Y:000094 Y:000094                   DC      VID1+DAC_ADDR+$000016
2703      Y:000095 Y:000095                   DC      VID1+DAC_RegD+OFFSET+OFFSET6
2704      Y:000096 Y:000096                   DC      VID1+DAC_ADDR+$000017
2705      Y:000097 Y:000097                   DC      VID1+DAC_RegD+OFFSET+OFFSET7
2706   
2707                                ; end of ARC47_dacs_brd1.asm
2708                                          INCLUDE "ARC47_dacs_brd2.asm"
2709                                ; ARC47_dacs_brd3.asm
2710                                ; ARC47 4 channel video board DACS table
2711                                ; third installed board
2712                                ; 04Sep13 last change MPL
2713   
2714                                ; Commands for the ARC-47 video board
2715      Y:000098 Y:000098                   DC      VID2+$0C0004                      ; Normal Image data D17-D2
2716   
2717                                ; Gain : $0D000g, g = 0 to %1111, Gain = 1.00 to 4.75 in steps of 0.25
2718      Y:000099 Y:000099                   DC      VID2+$0D0000+VGAIN                ; Left readout
2719      Y:00009A Y:00009A                   DC      VID2+$0C0100+VSPEED               ; time constant
2720   
2721                                ; Initialize the ARC-47 DAC For DC_BIAS
2722      Y:00009B Y:00009B                   DC      VID2+DAC_ADDR+$000000             ; Vod0,pin 52
2723      Y:00009C Y:00009C                   DC      VID2+DAC_RegD+DAC_VOD9
2724      Y:00009D Y:00009D                   DC      VID2+DAC_ADDR+$000004             ; Vrd0,pin 13
2725      Y:00009E Y:00009E                   DC      VID2+DAC_RegD+DAC_VRD9
2726      Y:00009F Y:00009F                   DC      VID2+DAC_ADDR+$000008             ; Vog0,pin 29
2727      Y:0000A0 Y:0000A0                   DC      VID2+DAC_RegD+DAC_VOG9
2728      Y:0000A1 Y:0000A1                   DC      VID2+DAC_ADDR+$00000C             ; Vabg,pin 5
2729      Y:0000A2 Y:0000A2                   DC      VID2+DAC_RegD+DAC_VRSV9
2730   
2731      Y:0000A3 Y:0000A3                   DC      VID2+DAC_ADDR+$000001             ; Vod1,pin 32
2732      Y:0000A4 Y:0000A4                   DC      VID2+DAC_RegD+DAC_VOD10
2733      Y:0000A5 Y:0000A5                   DC      VID2+DAC_ADDR+$000005             ; Vrd1,pin 55
2734      Y:0000A6 Y:0000A6                   DC      VID2+DAC_RegD+DAC_VRD10
2735      Y:0000A7 Y:0000A7                   DC      VID2+DAC_ADDR+$000009             ; Vog1,pin 8
2736      Y:0000A8 Y:0000A8                   DC      VID2+DAC_RegD+DAC_VOG10
2737      Y:0000A9 Y:0000A9                   DC      VID2+DAC_ADDR+$00000D             ; Vrsv1,pin 47
2738      Y:0000AA Y:0000AA                   DC      VID2+DAC_RegD+DAC_VRSV10
2739   
2740      Y:0000AB Y:0000AB                   DC      VID2+DAC_ADDR+$000002             ; Vod2,pin 11
2741      Y:0000AC Y:0000AC                   DC      VID2+DAC_RegD+DAC_VOD11
2742      Y:0000AD Y:0000AD                   DC      VID2+DAC_ADDR+$000006             ; Vrd2,pin 35
2743      Y:0000AE Y:0000AE                   DC      VID2+DAC_RegD+DAC_VRD11
2744      Y:0000AF Y:0000AF                   DC      VID2+DAC_ADDR+$00000A             ; Vog2,pin 50
2745      Y:0000B0 Y:0000B0                   DC      VID2+DAC_RegD+DAC_VOG11
2746      Y:0000B1 Y:0000B1                   DC      VID2+DAC_ADDR+$00000E             ; Vrsv2,pin 27
2747      Y:0000B2 Y:0000B2                   DC      VID2+DAC_RegD+DAC_VRSV11
2748   
2749      Y:0000B3 Y:0000B3                   DC      VID2+DAC_ADDR+$000003             ; Vod3,pin 53
2750      Y:0000B4 Y:0000B4                   DC      VID2+DAC_RegD+DAC_VOD12
2751      Y:0000B5 Y:0000B5                   DC      VID2+DAC_ADDR+$000007             ; Vrd3,pin 14
2752      Y:0000B6 Y:0000B6                   DC      VID2+DAC_RegD+DAC_VRD12
2753      Y:0000B7 Y:0000B7                   DC      VID2+DAC_ADDR+$00000B             ; Vog3,pin 30
2754      Y:0000B8 Y:0000B8                   DC      VID2+DAC_RegD+DAC_VOG12
2755      Y:0000B9 Y:0000B9                   DC      VID2+DAC_ADDR+$00000F             ; Vrsv3,pin 6
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_dacs_brd2.asm  Page 50



2756      Y:0000BA Y:0000BA                   DC      VID2+DAC_RegD+DAC_VRSV12
2757   
2758      Y:0000BB Y:0000BB                   DC      VID2+DAC_ADDR+$000010             ; Vod4,pin 33
2759      Y:0000BC Y:0000BC                   DC      VID2+DAC_RegD+DAC_VSCP3
2760      Y:0000BD Y:0000BD                   DC      VID2+DAC_ADDR+$000011             ; Vrd4,pin 56
2761      Y:0000BE Y:0000BE                   DC      VID2+DAC_RegD+DAC_VRD4
2762      Y:0000BF Y:0000BF                   DC      VID2+DAC_ADDR+$000012             ; Vog4,pin 9
2763      Y:0000C0 Y:0000C0                   DC      VID2+DAC_RegD+DAC_VOG4
2764      Y:0000C1 Y:0000C1                   DC      VID2+DAC_ADDR+$000013             ; Vrsv4,pin 48
2765      Y:0000C2 Y:0000C2                   DC      VID2+DAC_RegD+DAC_VRSV4
2766   
2767                                ; Initialize the ARC-47 DAC For Video Offsets
2768      Y:0000C3 Y:0000C3                   DC      VID2+DAC_ADDR+$000014
2769      Y:0000C4 Y:0000C4                   DC      VID2+DAC_RegD+OFFSET+OFFSET8
2770      Y:0000C5 Y:0000C5                   DC      VID2+DAC_ADDR+$000015
2771      Y:0000C6 Y:0000C6                   DC      VID2+DAC_RegD+OFFSET+OFFSET9
2772      Y:0000C7 Y:0000C7                   DC      VID2+DAC_ADDR+$000016
2773      Y:0000C8 Y:0000C8                   DC      VID2+DAC_RegD+OFFSET+OFFSET10
2774      Y:0000C9 Y:0000C9                   DC      VID2+DAC_ADDR+$000017
2775      Y:0000CA Y:0000CA                   DC      VID2+DAC_RegD+OFFSET+OFFSET11
2776   
2777                                ; end of ARC47_dacs_brd2.asm
2778                                          INCLUDE "ARC47_dacs_brd3.asm"
2779                                ; ARC47_dacs_brd3.asm
2780                                ; ARC47 4 channel video board DACS table
2781                                ; forth installed board
2782                                ; 04Sep13 last change MPL
2783   
2784                                ; Commands for the ARC-47 video board
2785      Y:0000CB Y:0000CB                   DC      VID3+$0C0004                      ; Normal Image data D17-D2
2786   
2787                                ; Gain : $0D000g, g = 0 to %1111, Gain = 1.00 to 4.75 in steps of 0.25
2788      Y:0000CC Y:0000CC                   DC      VID3+$0D0000+VGAIN                ; Left readout
2789      Y:0000CD Y:0000CD                   DC      VID3+$0C0100+VSPEED               ; time constant
2790   
2791                                ; Initialize the ARC-47 DAC For DC_BIAS
2792      Y:0000CE Y:0000CE                   DC      VID3+DAC_ADDR+$000000             ; Vod0,pin 52
2793      Y:0000CF Y:0000CF                   DC      VID3+DAC_RegD+DAC_VOD13
2794      Y:0000D0 Y:0000D0                   DC      VID3+DAC_ADDR+$000004             ; Vrd0,pin 13
2795      Y:0000D1 Y:0000D1                   DC      VID3+DAC_RegD+DAC_VRD13
2796      Y:0000D2 Y:0000D2                   DC      VID3+DAC_ADDR+$000008             ; Vog0,pin 29
2797      Y:0000D3 Y:0000D3                   DC      VID3+DAC_RegD+DAC_VOG13
2798      Y:0000D4 Y:0000D4                   DC      VID3+DAC_ADDR+$00000C             ; Vabg,pin 5
2799      Y:0000D5 Y:0000D5                   DC      VID3+DAC_RegD+DAC_VRSV13
2800   
2801      Y:0000D6 Y:0000D6                   DC      VID3+DAC_ADDR+$000001             ; Vod1,pin 32
2802      Y:0000D7 Y:0000D7                   DC      VID3+DAC_RegD+DAC_VOD14
2803      Y:0000D8 Y:0000D8                   DC      VID3+DAC_ADDR+$000005             ; Vrd1,pin 55
2804      Y:0000D9 Y:0000D9                   DC      VID3+DAC_RegD+DAC_VRD14
2805      Y:0000DA Y:0000DA                   DC      VID3+DAC_ADDR+$000009             ; Vog1,pin 8
2806      Y:0000DB Y:0000DB                   DC      VID3+DAC_RegD+DAC_VOG14
2807      Y:0000DC Y:0000DC                   DC      VID3+DAC_ADDR+$00000D             ; Vrsv1,pin 47
2808      Y:0000DD Y:0000DD                   DC      VID3+DAC_RegD+DAC_VRSV14
2809   
2810      Y:0000DE Y:0000DE                   DC      VID3+DAC_ADDR+$000002             ; Vod2,pin 11
2811      Y:0000DF Y:0000DF                   DC      VID3+DAC_RegD+DAC_VOD15
2812      Y:0000E0 Y:0000E0                   DC      VID3+DAC_ADDR+$000006             ; Vrd2,pin 35
2813      Y:0000E1 Y:0000E1                   DC      VID3+DAC_RegD+DAC_VRD15
2814      Y:0000E2 Y:0000E2                   DC      VID3+DAC_ADDR+$00000A             ; Vog2,pin 50
2815      Y:0000E3 Y:0000E3                   DC      VID3+DAC_RegD+DAC_VOG15
2816      Y:0000E4 Y:0000E4                   DC      VID3+DAC_ADDR+$00000E             ; Vrsv2,pin 27
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC47_dacs_brd3.asm  Page 51



2817      Y:0000E5 Y:0000E5                   DC      VID3+DAC_RegD+DAC_VRSV15
2818   
2819      Y:0000E6 Y:0000E6                   DC      VID3+DAC_ADDR+$000003             ; Vod3,pin 53
2820      Y:0000E7 Y:0000E7                   DC      VID3+DAC_RegD+DAC_VOD16
2821      Y:0000E8 Y:0000E8                   DC      VID3+DAC_ADDR+$000007             ; Vrd3,pin 14
2822      Y:0000E9 Y:0000E9                   DC      VID3+DAC_RegD+DAC_VRD16
2823      Y:0000EA Y:0000EA                   DC      VID3+DAC_ADDR+$00000B             ; Vog3,pin 30
2824      Y:0000EB Y:0000EB                   DC      VID3+DAC_RegD+DAC_VOG16
2825      Y:0000EC Y:0000EC                   DC      VID3+DAC_ADDR+$00000F             ; Vrsv3,pin 6
2826      Y:0000ED Y:0000ED                   DC      VID3+DAC_RegD+DAC_VRSV16
2827   
2828      Y:0000EE Y:0000EE                   DC      VID3+DAC_ADDR+$000010             ; Vod4,pin 33
2829      Y:0000EF Y:0000EF                   DC      VID3+DAC_RegD+DAC_VSCP4
2830      Y:0000F0 Y:0000F0                   DC      VID3+DAC_ADDR+$000011             ; Vrd4,pin 56
2831      Y:0000F1 Y:0000F1                   DC      VID3+DAC_RegD+DAC_VRD4
2832      Y:0000F2 Y:0000F2                   DC      VID3+DAC_ADDR+$000012             ; Vog4,pin 9
2833      Y:0000F3 Y:0000F3                   DC      VID3+DAC_RegD+DAC_VOG4
2834      Y:0000F4 Y:0000F4                   DC      VID3+DAC_ADDR+$000013             ; Vrsv4,pin 48
2835      Y:0000F5 Y:0000F5                   DC      VID3+DAC_RegD+DAC_VRSV4
2836   
2837                                ; Initialize the ARC-47 DAC For Video Offsets
2838      Y:0000F6 Y:0000F6                   DC      VID3+DAC_ADDR+$000014
2839      Y:0000F7 Y:0000F7                   DC      VID3+DAC_RegD+OFFSET+OFFSET12
2840      Y:0000F8 Y:0000F8                   DC      VID3+DAC_ADDR+$000015
2841      Y:0000F9 Y:0000F9                   DC      VID3+DAC_RegD+OFFSET+OFFSET13
2842      Y:0000FA Y:0000FA                   DC      VID3+DAC_ADDR+$000016
2843      Y:0000FB Y:0000FB                   DC      VID3+DAC_RegD+OFFSET+OFFSET14
2844      Y:0000FC Y:0000FC                   DC      VID3+DAC_ADDR+$000017
2845      Y:0000FD Y:0000FD                   DC      VID3+DAC_RegD+OFFSET+OFFSET15
2846   
2847                                ; end of ARC47_dacs_brd3.asm
2848                                          INCLUDE "ARC32_dacs.asm"
2849                                ; ARC32 clock board DACS table for 90Prime
2850                                ; 05Jan11 last change MPL
2851   
2852      1.240000E+001             VMAX      EQU     12.4
2853      0.000000E+000             ZERO      EQU     0.0
2854      200000                    CLKV2     EQU     $200000
2855      300000                    CLKV3     EQU     $300000
2856   
2857                                ; clock board #1 - addressed as board 2
2858                                ; bank 0
2859      Y:0000FE Y:0000FE                   DC      CLKV2+$0A0080                     ; DAC = unbuffered mode
2860   
2861      Y:0000FF Y:0000FF                   DC      CLKV2+$000100+@CVI((P11_HI+VMAX)/(2*VMAX)*255)
2862      Y:000100 Y:000100                   DC      CLKV2+$000200+@CVI((P11_LO+VMAX)/(2*VMAX)*255)
2863      Y:000101 Y:000101                   DC      CLKV2+$000400+@CVI((P21_HI+VMAX)/(2*VMAX)*255)
2864      Y:000102 Y:000102                   DC      CLKV2+$000800+@CVI((P21_LO+VMAX)/(2*VMAX)*255)
2865      Y:000103 Y:000103                   DC      CLKV2+$002000+@CVI((P31_HI+VMAX)/(2*VMAX)*255)
2866      Y:000104 Y:000104                   DC      CLKV2+$004000+@CVI((P31_LO+VMAX)/(2*VMAX)*255)
2867      Y:000105 Y:000105                   DC      CLKV2+$008000+@CVI((P12_HI+VMAX)/(2*VMAX)*255)
2868      Y:000106 Y:000106                   DC      CLKV2+$010000+@CVI((P12_LO+VMAX)/(2*VMAX)*255)
2869      Y:000107 Y:000107                   DC      CLKV2+$020100+@CVI((P22_HI+VMAX)/(2*VMAX)*255)
2870      Y:000108 Y:000108                   DC      CLKV2+$020200+@CVI((P22_LO+VMAX)/(2*VMAX)*255)
2871      Y:000109 Y:000109                   DC      CLKV2+$020400+@CVI((P32_HI+VMAX)/(2*VMAX)*255)
2872      Y:00010A Y:00010A                   DC      CLKV2+$020800+@CVI((P32_LO+VMAX)/(2*VMAX)*255)
2873      Y:00010B Y:00010B                   DC      CLKV2+$022000+@CVI((P13_HI+VMAX)/(2*VMAX)*255)
2874      Y:00010C Y:00010C                   DC      CLKV2+$024000+@CVI((P13_LO+VMAX)/(2*VMAX)*255)
2875      Y:00010D Y:00010D                   DC      CLKV2+$028000+@CVI((P23_HI+VMAX)/(2*VMAX)*255)
2876      Y:00010E Y:00010E                   DC      CLKV2+$030000+@CVI((P23_LO+VMAX)/(2*VMAX)*255)
2877      Y:00010F Y:00010F                   DC      CLKV2+$040100+@CVI((P33_HI+VMAX)/(2*VMAX)*255)
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  
C:\AzCam\systems\90prime\Hardware\Controller\dsptiming_90primeone\arc22timing\ARC32_dacs.asm  Page 52



2878      Y:000110 Y:000110                   DC      CLKV2+$040200+@CVI((P33_LO+VMAX)/(2*VMAX)*255)
2879      Y:000111 Y:000111                   DC      CLKV2+$040400+@CVI((P14_HI+VMAX)/(2*VMAX)*255)
2880      Y:000112 Y:000112                   DC      CLKV2+$040800+@CVI((P14_LO+VMAX)/(2*VMAX)*255)
2881      Y:000113 Y:000113                   DC      CLKV2+$042000+@CVI((P24_HI+VMAX)/(2*VMAX)*255)
2882      Y:000114 Y:000114                   DC      CLKV2+$044000+@CVI((P24_LO+VMAX)/(2*VMAX)*255)
2883      Y:000115 Y:000115                   DC      CLKV2+$048000+@CVI((P34_HI+VMAX)/(2*VMAX)*255)
2884      Y:000116 Y:000116                   DC      CLKV2+$050000+@CVI((P34_LO+VMAX)/(2*VMAX)*255)
2885   
2886                                ; bank 1
2887      Y:000117 Y:000117                   DC      CLKV2+$060100+@CVI((S1_HI+VMAX)/(2*VMAX)*255)
2888      Y:000118 Y:000118                   DC      CLKV2+$060200+@CVI((S1_LO+VMAX)/(2*VMAX)*255)
2889      Y:000119 Y:000119                   DC      CLKV2+$060400+@CVI((S2_HI+VMAX)/(2*VMAX)*255)
2890      Y:00011A Y:00011A                   DC      CLKV2+$060800+@CVI((S2_LO+VMAX)/(2*VMAX)*255)
2891      Y:00011B Y:00011B                   DC      CLKV2+$062000+@CVI((S3_HI+VMAX)/(2*VMAX)*255)
2892      Y:00011C Y:00011C                   DC      CLKV2+$064000+@CVI((S3_LO+VMAX)/(2*VMAX)*255)
2893      Y:00011D Y:00011D                   DC      CLKV2+$068000+@CVI((ZERO+VMAX)/(2*VMAX)*255)
2894      Y:00011E Y:00011E                   DC      CLKV2+$070000+@CVI((ZERO+VMAX)/(2*VMAX)*255)
2895      Y:00011F Y:00011F                   DC      CLKV2+$080100+@CVI((ZERO+VMAX)/(2*VMAX)*255)
2896      Y:000120 Y:000120                   DC      CLKV2+$080200+@CVI((ZERO+VMAX)/(2*VMAX)*255)
2897      Y:000121 Y:000121                   DC      CLKV2+$080400+@CVI((SWL_HI+VMAX)/(2*VMAX)*255)
2898      Y:000122 Y:000122                   DC      CLKV2+$080800+@CVI((SWL_LO+VMAX)/(2*VMAX)*255)
2899      Y:000123 Y:000123                   DC      CLKV2+$082000+@CVI((SWR_HI+VMAX)/(2*VMAX)*255)
2900      Y:000124 Y:000124                   DC      CLKV2+$084000+@CVI((SWR_LO+VMAX)/(2*VMAX)*255)
2901      Y:000125 Y:000125                   DC      CLKV2+$088000+@CVI((ZERO+VMAX)/(2*VMAX)*255)
2902      Y:000126 Y:000126                   DC      CLKV2+$090000+@CVI((ZERO+VMAX)/(2*VMAX)*255)
2903      Y:000127 Y:000127                   DC      CLKV2+$0A0100+@CVI((RG1_HI+VMAX)/(2*VMAX)*255)
2904      Y:000128 Y:000128                   DC      CLKV2+$0A0200+@CVI((RG1_LO+VMAX)/(2*VMAX)*255)
2905      Y:000129 Y:000129                   DC      CLKV2+$0A0400+@CVI((RG2_HI+VMAX)/(2*VMAX)*255)
2906      Y:00012A Y:00012A                   DC      CLKV2+$0A0800+@CVI((RG2_LO+VMAX)/(2*VMAX)*255)
2907      Y:00012B Y:00012B                   DC      CLKV2+$0A2000+@CVI((RG3_HI+VMAX)/(2*VMAX)*255)
2908      Y:00012C Y:00012C                   DC      CLKV2+$0A4000+@CVI((RG3_LO+VMAX)/(2*VMAX)*255)
2909      Y:00012D Y:00012D                   DC      CLKV2+$0A8000+@CVI((RG4_HI+VMAX)/(2*VMAX)*255)
2910      Y:00012E Y:00012E                   DC      CLKV2+$0B0000+@CVI((RG4_LO+VMAX)/(2*VMAX)*255)
2911   
2912                                          INCLUDE "null.asm"
2913                                EDACS
2914   
2915                                ; *** Timing NOP statement ***
2916      Y:00012F Y:00012F         TNOP      DC      ETNOP-TNOP-GENCNT
2917      Y:000130 Y:000130                   DC      $00E000
2918      Y:000131 Y:000131                   DC      $00E000
2919                                ETNOP
2920   
2921                                ; *** waveforms ***
2922                                          INCLUDE "clocking.asm"
2923                                ; STA2900A 90Prime clocking routines
2924                                ; 03Sep13 MPL
2925   
2926                                ; The direct controller serials operate the left serials
2927                                ; The right serials are swapped S1-S2 relative to the left
2928   
2929                                ; SW1 and SW3 are tied to SW (lefts)
2930                                ; SW2 and SW4 are tied to TG (rights)
2931   
2932                                ; Parallel P's are lower
2933                                ; Parallel Q's are upper
2934   
2935                                ; ***********************************************
2936                                ;                  parallel
2937                                ; ***********************************************
2938                                ; shift into s1+s2
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  clocking.asm  Page 53



2939   
2940                                ; wired as P1=Q2, P2=Q1, P3=Q3
2941   
2942      000249                    P1H       EQU     P11H+P12H+P13H+P14H
2943      000000                    P1L       EQU     P11L+P12L+P13L+P14L
2944      000492                    P2H       EQU     P21H+P22H+P23H+P24H
2945      000000                    P2L       EQU     P21L+P22L+P23L+P24L
2946      000924                    P3H       EQU     P31H+P32H+P33H+P34H
2947      000000                    P3L       EQU     P31L+P32L+P33L+P34L
2948   
2949                                ; forward P (lower), reverse Q (upper) - Normal operation
2950      Y:000132 Y:000132         PFOR      DC      EPFOR-PFOR-1
2951      Y:000133 Y:000133                   DC      VIDEO+%0011000                    ; Reset integ. and DC restore
2952      Y:000134 Y:000134                   DC      CLK2+P_DELAY+P1L+P2H+P3L
2953      Y:000135 Y:000135                   DC      CLK2+P_DELAY+P1L+P2H+P3H
2954      Y:000136 Y:000136                   DC      CLK2+P_DELAY+P1L+P2L+P3H
2955      Y:000137 Y:000137                   DC      CLK2+P_DELAY+P1H+P2L+P3H
2956      Y:000138 Y:000138                   DC      CLK2+P_DELAY+P1H+P2L+P3L
2957      Y:000139 Y:000139                   DC      CLK2+P_DELAY+P1H+P2H+P3L          ; last for center rows
2958                                EPFOR
2959   
2960                                ; reverse P (lower), forward Q (upper) - Reverse operation
2961      Y:00013A Y:00013A         PREV      DC      EPREV-PREV-1
2962      Y:00013B Y:00013B                   DC      VIDEO+%0011000                    ; Reset integ. and DC restore
2963      Y:00013C Y:00013C                   DC      CLK2+P_DELAY+P1H+P2L+P3L
2964      Y:00013D Y:00013D                   DC      CLK2+P_DELAY+P1H+P2L+P3H
2965      Y:00013E Y:00013E                   DC      CLK2+P_DELAY+P1L+P2L+P3H
2966      Y:00013F Y:00013F                   DC      CLK2+P_DELAY+P1L+P2H+P3H
2967      Y:000140 Y:000140                   DC      CLK2+P_DELAY+P1L+P2H+P3L
2968      Y:000141 Y:000141                   DC      CLK2+P_DELAY+P1H+P2H+P3L
2969                                EPREV
2970   
2971      000132                    PXFER     EQU     PFOR
2972      000132                    PQXFER    EQU     PXFER
2973      00013A                    RXFER     EQU     PREV
2974   
2975                                ; ***********************************************
2976                                ;                  Video
2977                                ; ***********************************************
2978   
2979                                ; ARC47:  |xfer|A/D|integ|polarity|not used|DC restore|rst| (1 => switch open)
2980                                ;      polarity reversed from RevD to RevE
2981   
2982                                LATCH     MACRO
2983 m                                        DC      VIDEO+%0011000                    ; Reset integ. and DC restore
2984 m                                        ENDM
2985   
2986                                INTNOISE  MACRO
2987 m                              ; CDS integrate on noise
2988 m                                        DC      VIDEO+$000000+%0011011            ; Stop resetting int
2989 m                                        DC      VIDEO+DWELL+%0001011              ; Integrate noise
2990 m                                        DC      VIDEO+$000000+%0011011            ; Stop int
2991 m                                        ENDM
2992   
2993                                INTSIGNAL MACRO
2994 m                              ; CDS integrate on signal
2995 m                                        DC      VIDEO+$020000+%0010011            ; change polarity
2996 m                                        DC      VIDEO+DWELL+%0000011              ; Integrate signal
2997 m                                        DC      VIDEO+$030000+%0010011            ; Stop integrate, ADC is sampling
2998 m                                        DC      VIDEO+$010000+%1110011            ; start A/D conversion
2999 m                                        DC      VIDEO+$000000+%0010010            ; End start A/D conv. pulse
3000 m                                        ENDM
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  clocking.asm  Page 54



3001   
3002                                ; ***********************************************
3003                                ;                  serial
3004                                ; ***********************************************
3005   
3006                                ; s2_123w for left
3007                                ; s1_213w for right
3008                                ; SW like S1
3009                                ; TG like S2
3010   
3011      000F00                    RGH       EQU     RG1H+RG2H+RG3H+RG4H
3012      000000                    RGL       EQU     RG1L+RG2L+RG3L+RG4L
3013   
3014      Y:000142 Y:000142         FPXFER0   DC      EFPXFER0-FPXFER0-1
3015      Y:000143 Y:000143                   DC      CLK3+S_DELAY+RGH+S1H+S2H+S3H+SWLH+SWRH
3016      Y:000144 Y:000144                   DC      CLK3+S_DELAY+RGH+S1H+S2H+S3H+SWLH+SWRH
3017                                EFPXFER0
3018   
3019      Y:000145 Y:000145         FPXFER2   DC      EFPXFER2-FPXFER2-1
3020      Y:000146 Y:000146                   DC      CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLL+SWRL
3021      Y:000147 Y:000147                   DC      CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLL+SWRL
3022                                EFPXFER2
3023   
3024      Y:000148 Y:000148         FSXFER    DC      EFSXFER-FSXFER-1
3025      Y:000149 Y:000149                   DC      CLK3+R_DELAY+RGH+S1L+S2H+S3L+SWLH+SWRH
3026      Y:00014A Y:00014A                   DC      CLK3+S_DELAY+RGL+S1L+S2H+S3H+SWLH+SWRH
3027      Y:00014B Y:00014B                   DC      CLK3+S_DELAY+RGL+S1L+S2L+S3H+SWLH+SWRH
3028      Y:00014C Y:00014C                   DC      CLK3+S_DELAY+RGL+S1H+S2L+S3H+SWLH+SWRH
3029      Y:00014D Y:00014D                   DC      CLK3+S_DELAY+RGL+S1H+S2L+S3L+SWLH+SWRH
3030      Y:00014E Y:00014E                   DC      CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLL+SWRL
3031                                EFSXFER
3032   
3033      Y:00014F Y:00014F         SXFER0    DC      ESXFER0-SXFER0-1
3034                                          LATCH
3036      Y:000151 Y:000151                   DC      CLK3+R_DELAY+RGH+S1H+S2H+S3L+SWLH+SWRH
3037      Y:000152 Y:000152                   DC      CLK3+S_DELAY+RGL+S1L+S2H+S3L+SWLH+SWRH
3038      Y:000153 Y:000153                   DC      VIDEO+$000000+%0011000            ; Reset integrator
3039      Y:000154 Y:000154                   DC      CLK3+S_DELAY+RGL+S1L+S2H+S3H+SWLH+SWRH
3040      Y:000155 Y:000155                   DC      CLK3+S_DELAY+RGL+S1L+S2L+S3H+SWLH+SWRH
3041      Y:000156 Y:000156                   DC      CLK3+S_DELAY+RGL+S1H+S2L+S3H+SWLH+SWRH
3042      Y:000157 Y:000157                   DC      CLK3+S_DELAY+RGL+S1H+S2L+S3L+SWLH+SWRH
3043      Y:000158 Y:000158                   DC      CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLH+SWRH
3044                                ESXFER0
3045   
3046      Y:000159 Y:000159         SXFER1    DC      ESXFER1-SXFER1-1
3047      Y:00015A Y:00015A                   DC      CLK3+S_DELAY+RGL+S1L+S2H+S3L+SWLH+SWRH
3048      Y:00015B Y:00015B                   DC      CLK3+S_DELAY+RGL+S1L+S2H+S3H+SWLH+SWRH
3049      Y:00015C Y:00015C                   DC      CLK3+S_DELAY+RGL+S1L+S2L+S3H+SWLH+SWRH
3050      Y:00015D Y:00015D                   DC      CLK3+S_DELAY+RGL+S1H+S2L+S3H+SWLH+SWRH
3051      Y:00015E Y:00015E                   DC      CLK3+S_DELAY+RGL+S1H+S2L+S3L+SWLH+SWRH
3052      Y:00015F Y:00015F                   DC      CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLH+SWRH
3053                                ESXFER1
3054   
3055      Y:000160 Y:000160         SXFER2    DC      ESXFER2-SXFER2-1
3056                                          INTNOISE
3061      Y:000164 Y:000164                   DC      CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLL+SWRL
3062                                          INTSIGNAL
3069                                ESXFER2
3070   
3071      Y:00016A Y:00016A         SXFER2D   DC      ESXFER2D-SXFER2D-1
3072      Y:00016B Y:00016B                   DC      SXMIT
3073                                          INTNOISE
Motorola DSP56300 Assembler  Version 6.3.4   15-10-06  15:23:00  clocking.asm  Page 55



3078      Y:00016F Y:00016F                   DC      CLK3+S_DELAY+RGL+S1H+S2H+S3L+SWLL+SWRL
3079                                          INTSIGNAL
3086                                ESXFER2D
3087   
3088                                 END_APPLICATON_Y_MEMORY
3089      000175                              EQU     @LCV(L)
3090   
3091                                          END

0    Errors
0    Warnings


