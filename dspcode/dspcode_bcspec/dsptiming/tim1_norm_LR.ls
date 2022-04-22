Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 1



1                               COMMENT *
2      
3                        This file is used to generate DSP code for the Gen 1 timing board.
4      
5                        -d 1 1  To generate code for downloading to DSP memory.
6                        -d 1 0  To generate code for writing to the EEPROM.
7      
8                        Modified for AzCam and PCI interface
9                        02Jan05 Last change MPL
10                               *
11     
12                                 PAGE    132                               ; page width - 132 columns
13     
14                       ; Define a section name so it doesn't conflict with other application programs
15                                 SECTION TIMAZCAM
16     
17                       ; These are also defined in "timboot.asm", so be sure they agree
18        000001         APL_NUM   EQU     1                                 ; Application number from 1 to 10
19        0000E8         APL_ADR   EQU     $E8                               ; P: memory location where application code begins
20        000118         APL_LEN   EQU     $200-APL_ADR                      ; Maximum length of application program
21        0000C0         COM_TBL   EQU     $C0                               ; Starting address of command table in X: memory
22     
23                       ;  Define other useful constants
24        000004         DACTIME   EQU     4                                 ; Time to load the DC bias DACs
25        0000FF         INV       EQU     255                               ; Because DAC's now invert
26     
27                       ;  Define various hardware selection codes
28        000000         CCD       EQU     $000000                           ; Select CCD clock drivers
29        010000         DELAY     EQU     $010000                           ; Delay time byte
30        00F000         VP        EQU     $00F000                           ; Video Processor timing instructions
31        00F100         LATCH     EQU     $00F100                           ; Addressable latch
32        00F200         PULSE2    EQU     $00F200                           ; Pulse 2
33        000C00         BIASSEL   EQU     $000C00                           ; Select bias voltage DAC to update
34        000D00         BIASDAT   EQU     $000D00                           ; Set bias voltage
35     
36                       ; Board status bits, defined at X:<STATUS = X:0
37        000004         ST_RDC    EQU     4                                 ; Set if executing 'RDC' command - reading out
38     
39                       ;**************************************************************************
40                       ;                                                                         *
41                       ;    Permanent address register assignments                               *
42                       ;        R1 - Address of SSI receiver contents                            *
43                       ;        R2 - Address of SCI receiver contents                            *
44                       ;        R3 - Pointer to current top of command buffer                    *
45                       ;        R4 - Pointer to processed contents of command buffer             *
46                       ;        R5 - Temporary register for processing SSI and SCI contents      *
47                       ;        R6 - CCD clock driver address for CCD #0 = $FFB0                 *
48                       ;                It is also the A/D address of analog board #0            *
49                       ;                                                                         *
50                       ;    Other registers                                                      *
51                       ;        R0, R7 - Temporary registers used all over the place.            *
52                       ;        R5 - Can be used as a temporary register but is circular,        *
53                       ;               modulo 32.                                                *
54                       ;**************************************************************************
55     
56                       ;  Specify execution and load addresses
57                                 IF      1
58        P:00E8 P:00E8                   ORG     P:APL_ADR,P:APL_ADR               ; Download address
59                                        ELSE
61                                        ENDIF
62     
63        P:00E8 P:00E8 0C010E  IDLE      JMP     <IDLE0
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 2



64     
65                              ; Set software to IDLE mode
66        P:00E9 P:00E9 0A0020  IDL       BSET    #IDLING,X:<STATUS
67        P:00EA P:00EA 0C0000            JMP     <FINISH                           ; Need to send header ID and 'DON'
68     
69                              ; Come to here on a 'STP' command so 'DON' can be sent
70        P:00EB P:00EB 0A0000  STP       BCLR    #IDLING,X:<STATUS
71        P:00EC P:00EC 0C0000            JMP     <FINISH
72     
73                              ;  Set bias voltages; assert LATCH6 to signal same
74        P:00ED P:00ED 68B000  SETBIAS   MOVE                          Y:<ADACS,R0
75        P:00EE P:00EE 0D01ED            JSR     <CLOCK
76        P:00EF P:00EF 0C0000            JMP     <FINISH                           ; Send 'DON' message, then RCV
77     
78                              ;HIGAIN  MOVE    Y:<HIGN,A
79        P:00F0 P:00F0 56F400  HIGAIN    MOVE              #$00F101,A
                        00F101
80        P:00F2 P:00F2 566600            MOVE              A,X:(R6)                ; Set LATCH bit 0 to high gain
81        P:00F3 P:00F3 0C0000            JMP     <FINISH                           ; Send 'DON' message, then RCV
82     
83                              ;LOWGAIN MOVE    Y:<LOGN,A
84        P:00F4 P:00F4 56F400  LOWGAIN   MOVE              #$00F100,A
                        00F100
85        P:00F6 P:00F6 566600            MOVE              A,X:(R6)                ; Set LATCH bit 0 to low gain
86        P:00F7 P:00F7 0C0000            JMP     <FINISH                           ; Send 'DON' message, then RCV
87     
88                              ;  Operate the shutter - Shutter commands are included here for
89                              ;     backwards compatability with systems that do not have a
90                              ;     utility board.
91                              ;OSHUT   MOVE    Y:<SHUT_O,A     ; Open the shutter
92        P:00F8 P:00F8 56F400  OSHUT     MOVE              #$00F102,A              ; Open the shutter
                        00F102
93        P:00FA P:00FA 566600            MOVE              A,X:(R6)
94        P:00FB P:00FB 0C0000            JMP     <FINISH
95     
96                              ;CSHUT   MOVE    Y:<SHUT_C,A     ; Close the shutter
97        P:00FC P:00FC 56F400  CSHUT     MOVE              #$00F103,A              ; Close the shutter
                        00F103
98        P:00FE P:00FE 566600            MOVE              A,X:(R6)
99        P:00FF P:00FF 0C0000            JMP     <FINISH
100    
101                             ; Reset and calibrate the A/D converter
102                             ;RAD    MOVE    Y:<RAD_K1,Y0    ; A/D reset low = active, delay
103       P:0100 P:0100 46F400  RAD       MOVE              #$FAF04C,Y0             ; A/D reset low = active, delay
                        FAF04C
104       P:0102 P:0102 466600            MOVE              Y0,X:(R6)
105                             ;        DO      Y:CDLY,DLY      ; Delay 1.5 seconds
106       P:0103 P:0103 065882            DO      #600,DLY2
                        000109
107       P:0105 P:0105 066480            DO      #100,DLY                          ; Delay 1.5 seconds
                        000108
108       P:0107 P:0107 466600            MOVE              Y0,X:(R6)               ; Activate 10 microsec hardware delay
109       P:0108 P:0108 466600            MOVE              Y0,X:(R6)               ; Just a nop so delay counter is activated
110                             DLY
111       P:0109 P:0109 000000            NOP
112                             DLY2
113                             ;       MOVE    Y:<RAD_K2,Y0    ; Raise reset
114       P:010A P:010A 46F400            MOVE              #$FAF04D,Y0             ; Raise reset
                        FAF04D
115       P:010C P:010C 466600            MOVE              Y0,X:(R6)
116       P:010D P:010D 0C0000            JMP     <FINISH                           ; Send 'DON' reply
117    
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 3



118                             ; Keep the CCD idling when not reading out
119                             IDLE0
120       P:010E P:010E 68A500            MOVE                          Y:<AFPXFER0,R0
121       P:010F P:010F 0D01ED            JSR     <CLOCK
122       P:0110 P:0110 301F00            MOVE              #<IDLEONE,R0
123       P:0111 P:0111 0D01A1            JSR     <PQSKIP
124       P:0112 P:0112 0E2000            JNE     <RCV_ID                           ; Go process header and command
125       P:0113 P:0113 68A600            MOVE                          Y:<AFPXFER2,R0
126       P:0114 P:0114 0D01ED            JSR     <CLOCK
127       P:0115 P:0115 300700            MOVE              #<NSCLEAR,R0
128       P:0116 P:0116 0D01BB            JSR     <FSSKIP
129    
130       P:0117 P:0117 0C010E            JMP     <IDLE0
131    
132                             ; Fast clear image before each exposure
133                             CLEAR
134       P:0118 P:0118 68A100            MOVE                          Y:<ACLEAR0,R0
135       P:0119 P:0119 0D01ED            JSR     <CLOCK
136       P:011A P:011A 68A500            MOVE                          Y:<AFPXFER0,R0
137       P:011B P:011B 0D01ED            JSR     <CLOCK
138       P:011C P:011C 300800            MOVE              #<NPCLEAR,R0
139       P:011D P:011D 0D01A1            JSR     <PQSKIP
140       P:011E P:011E 0E2000            JNE     <START
141       P:011F P:011F 68A600            MOVE                          Y:<AFPXFER2,R0
142       P:0120 P:0120 0D01ED            JSR     <CLOCK
143       P:0121 P:0121 300700            MOVE              #<NSCLEAR,R0
144       P:0122 P:0122 0D01BB            JSR     <FSSKIP
145       P:0123 P:0123 68A200            MOVE                          Y:<ACLEAR2,R0
146       P:0124 P:0124 0D01ED            JSR     <CLOCK
147    
148       P:0125 P:0125 0A0004            BCLR    #ST_RDC,X:<STATUS                 ; No longer reading out MPL
149       P:0126 P:0126 0A0000            BCLR    #IDLMODE,X:<STATUS
150       P:0127 P:0127 0A0080            JCLR    #IDLING,X:<STATUS,FINISH
                        000000
151    
152                             ; Insure that idling resumes after readout but not during the exposure
153       P:0129 P:0129 0A0020            BSET    #IDLMODE,X:<STATUS                ; Idle after readout
154       P:012A P:012A 0A0000            BCLR    #IDLING,X:<STATUS                 ; Don't idle during exposure
155       P:012B P:012B 0C0000            JMP     <FINISH
156    
157                             ; Reverse Vertical Shift
158                             ;RVXFER
159                             ;       MOVE    #<NPXSHIFT,R0
160                             ;       JSR     <RSKIP
161                             ;       JMP     <FINISH
162    
163                             ; Alert the PCI interface board that images are coming soon
164                             PCI_READ_IMAGE
165    
166                             ;MPL 08Nov05                            ; add RDI command
167       P:012C P:012C 44F400            MOVE              #$020102,X0             ; Send header word to the FO transmitter
                        020102
168       P:012E P:012E 0D013D            JSR     <XMT_FO
169       P:012F P:012F 44F400            MOVE              #'RDI',X0               ; set PCI card to reading out mode
                        524449
170       P:0131 P:0131 0D013D            JSR     <XMT_FO
171    
172       P:0132 P:0132 44F400            MOVE              #$020104,X0             ; Command to PCI board
                        020104
173       P:0134 P:0134 0D013D            JSR     <XMT_FO
174       P:0135 P:0135 44F400            MOVE              #'RDA',X0
                        524441
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 4



175       P:0137 P:0137 0D013D            JSR     <XMT_FO
176       P:0138 P:0138 4C9B00            MOVE                          Y:<NSIMAGE,X0 ; Number of columns to read
177       P:0139 P:0139 0D013D            JSR     <XMT_FO
178       P:013A P:013A 4C9C00            MOVE                          Y:<NPIMAGE,X0
179       P:013B P:013B 0D013D            JSR     <XMT_FO
180       P:013C P:013C 00000C            RTS
181                             ; Transmit data on fiber
182       P:013D P:013D 4C6600  XMT_FO    MOVE                          X0,Y:(R6)
183       P:013E P:013E 061EA0            REP     #30                               ; Delay a bit for the transmission
184       P:013F P:013F 000000            NOP
185       P:0140 P:0140 00000C            RTS
186    
187                             ;  *** readout code ***
188    
189       P:0141 P:0141 0A0024  RDCCD     BSET    #ST_RDC,X:<STATUS                 ; Set status to reading out
190       P:0142 P:0142 0D012C            JSR     <PCI_READ_IMAGE                   ; Wake up the PCI interface board
191    
192       P:0143 P:0143 68A500            MOVE                          Y:<AFPXFER0,R0
193       P:0144 P:0144 0D01ED            JSR     <CLOCK
194       P:0145 P:0145 301500            MOVE              #<FRAMET,R0
195       P:0146 P:0146 0D01A1            JSR     <PQSKIP
196       P:0147 P:0147 0E2000            JNE     <START
197    
198       P:0148 P:0148 300E00            MOVE              #<NPPRESKIP,R0
199       P:0149 P:0149 0D0194            JSR     <PSKIP
200       P:014A P:014A 0E2000            JNE     <START
201       P:014B P:014B 68A600            MOVE                          Y:<AFPXFER2,R0
202       P:014C P:014C 0D01ED            JSR     <CLOCK
203    
204       P:014D P:014D 300700            MOVE              #<NSCLEAR,R0
205       P:014E P:014E 0D01BB            JSR     <FSSKIP
206    
207       P:014F P:014F 300F00            MOVE              #<NPUNDERSCAN,R0
208       P:0150 P:0150 0D016E            JSR     <PDATA
209       P:0151 P:0151 0E2000            JNE     <START
210    
211       P:0152 P:0152 68A500            MOVE                          Y:<AFPXFER0,R0
212       P:0153 P:0153 0D01ED            JSR     <CLOCK
213       P:0154 P:0154 301000            MOVE              #<NPSKIP,R0
214       P:0155 P:0155 0D0194            JSR     <PSKIP
215       P:0156 P:0156 0E2000            JNE     <START
216       P:0157 P:0157 68A600            MOVE                          Y:<AFPXFER2,R0
217       P:0158 P:0158 0D01ED            JSR     <CLOCK
218    
219       P:0159 P:0159 300700            MOVE              #<NSCLEAR,R0
220       P:015A P:015A 0D01BB            JSR     <FSSKIP
221    
222       P:015B P:015B 300200            MOVE              #<NPDATA,R0             ; data
223       P:015C P:015C 0D016E            JSR     <PDATA
224       P:015D P:015D 0E2000            JNE     <START
225    
226       P:015E P:015E 68A500            MOVE                          Y:<AFPXFER0,R0
227       P:015F P:015F 0D01ED            JSR     <CLOCK
228       P:0160 P:0160 301100            MOVE              #<NPPOSTSKIP,R0
229       P:0161 P:0161 0D0194            JSR     <PSKIP
230       P:0162 P:0162 0E2000            JNE     <START
231       P:0163 P:0163 68A600            MOVE                          Y:<AFPXFER2,R0
232       P:0164 P:0164 0D01ED            JSR     <CLOCK
233    
234       P:0165 P:0165 300700            MOVE              #<NSCLEAR,R0
235       P:0166 P:0166 0D01BB            JSR     <FSSKIP
236    
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 5



237       P:0167 P:0167 301200            MOVE              #<NPOVERSCAN,R0
238       P:0168 P:0168 0D016E            JSR     <PDATA
239       P:0169 P:0169 0E2000            JNE     <START
240    
241       P:016A P:016A 0A0080            JCLR    #IDLMODE,X:<STATUS,START          ; Don't idle after readout
                        000000
242       P:016C P:016C 0A0020            BSET    #IDLING,X:<STATUS                 ; Idle after readout
243       P:016D P:016D 0C0000            JMP     <START                            ; Wait for a new command
244    
245                             PDATA
246       P:016E P:016E 5EE000            MOVE                          Y:(R0),A
247       P:016F P:016F 200003            TST     A
248       P:0170 P:0170 0EF185            JLE     <PDATA0
249       P:0171 P:0171 066040            DO      Y:(R0),PDATA0
                        000184
250       P:0173 P:0173 300400            MOVE              #<NPBIN,R0
251       P:0174 P:0174 0D0187            JSR     <PDSKIP
252       P:0175 P:0175 0EA178            JEQ     <PDATA1
253       P:0176 P:0176 00008C            ENDDO
254       P:0177 P:0177 0C0185            JMP     <PDATA0
255                             PDATA1
256       P:0178 P:0178 300900            MOVE              #<NSPRESKIP,R0
257       P:0179 P:0179 0D01C5            JSR     <SSKIP
258       P:017A P:017A 300A00            MOVE              #<NSUNDERSCAN,R0
259       P:017B P:017B 0D01D1            JSR     <SDATA
260       P:017C P:017C 300B00            MOVE              #<NSSKIP,R0
261       P:017D P:017D 0D01C5            JSR     <SSKIP
262       P:017E P:017E 300100            MOVE              #<NSDATA,R0
263       P:017F P:017F 0D01D1            JSR     <SDATA
264       P:0180 P:0180 300C00            MOVE              #<NSPOSTSKIP,R0
265       P:0181 P:0181 0D01C5            JSR     <SSKIP
266       P:0182 P:0182 300D00            MOVE              #<NSOVERSCAN,R0
267       P:0183 P:0183 0D01D1            JSR     <SDATA
268       P:0184 P:0184 200013            CLR     A                                 ; set CC
269                             PDATA0
270       P:0185 P:0185 000000            NOP
271       P:0186 P:0186 00000C            RTS
272    
273                             PDSKIP
274       P:0187 P:0187 5EE000            MOVE                          Y:(R0),A
275       P:0188 P:0188 200003            TST     A
276       P:0189 P:0189 0EF192            JLE     <PDSKIP0
277       P:018A P:018A 066040            DO      Y:(R0),PDSKIP0
                        000191
278       P:018C P:018C 68A800            MOVE                          Y:<APDXFER,R0
279       P:018D P:018D 0D01F4            JSR     <PCLOCK
280       P:018E P:018E 0D0000            JSR     <RCV_TST
281       P:018F P:018F 0EA191            JEQ     <PDSKIP1
282       P:0190 P:0190 00008C            ENDDO
283                             PDSKIP1
284       P:0191 P:0191 000000            NOP
285                             PDSKIP0
286       P:0192 P:0192 000000            NOP
287       P:0193 P:0193 00000C            RTS
288    
289                             PSKIP
290       P:0194 P:0194 5EE000            MOVE                          Y:(R0),A
291       P:0195 P:0195 200003            TST     A
292       P:0196 P:0196 0EF19F            JLE     <PSKIP0
293       P:0197 P:0197 066040            DO      Y:(R0),PSKIP0
                        00019E
294       P:0199 P:0199 68A700            MOVE                          Y:<APXFER,R0
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 6



295       P:019A P:019A 0D01F4            JSR     <PCLOCK
296       P:019B P:019B 0D0000            JSR     <RCV_TST
297       P:019C P:019C 0EA19E            JEQ     <PSKIP1
298       P:019D P:019D 00008C            ENDDO
299                             PSKIP1
300       P:019E P:019E 000000            NOP
301                             PSKIP0
302       P:019F P:019F 000000            NOP
303       P:01A0 P:01A0 00000C            RTS
304    
305                             PQSKIP
306       P:01A1 P:01A1 5EE000            MOVE                          Y:(R0),A
307       P:01A2 P:01A2 200003            TST     A
308       P:01A3 P:01A3 0EF1AC            JLE     <PQSKIP0
309       P:01A4 P:01A4 066040            DO      Y:(R0),PQSKIP0
                        0001AB
310       P:01A6 P:01A6 68A900            MOVE                          Y:<APQXFER,R0
311       P:01A7 P:01A7 0D01F4            JSR     <PCLOCK
312       P:01A8 P:01A8 0D0000            JSR     <RCV_TST
313       P:01A9 P:01A9 0EA1AB            JEQ     <PQSKIP1
314       P:01AA P:01AA 00008C            ENDDO
315                             PQSKIP1
316       P:01AB P:01AB 000000            NOP
317                             PQSKIP0
318       P:01AC P:01AC 000000            NOP
319       P:01AD P:01AD 00000C            RTS
320    
321                             RSKIP
322       P:01AE P:01AE 5EE000            MOVE                          Y:(R0),A
323       P:01AF P:01AF 200003            TST     A
324       P:01B0 P:01B0 0EF1B9            JLE     <RSKIP0
325       P:01B1 P:01B1 066040            DO      Y:(R0),RSKIP0
                        0001B8
326       P:01B3 P:01B3 68AA00            MOVE                          Y:<ARXFER,R0
327       P:01B4 P:01B4 0D01F4            JSR     <PCLOCK
328       P:01B5 P:01B5 0D0000            JSR     <RCV_TST
329       P:01B6 P:01B6 0EA1B8            JEQ     <RSKIP1
330       P:01B7 P:01B7 00008C            ENDDO
331                             RSKIP1
332       P:01B8 P:01B8 000000            NOP
333                             RSKIP0
334       P:01B9 P:01B9 000000            NOP
335       P:01BA P:01BA 00000C            RTS
336    
337                             FSSKIP
338       P:01BB P:01BB 5EE000            MOVE                          Y:(R0),A
339       P:01BC P:01BC 200003            TST     A
340       P:01BD P:01BD 0EF1C3            JLE     <FSSKIP0
341       P:01BE P:01BE 066040            DO      Y:(R0),FSSKIP0
                        0001C2
342       P:01C0 P:01C0 68AB00            MOVE                          Y:<AFSXFER,R0
343       P:01C1 P:01C1 0D01ED            JSR     <CLOCK
344       P:01C2 P:01C2 000000            NOP
345                             FSSKIP0
346       P:01C3 P:01C3 000000            NOP
347       P:01C4 P:01C4 00000C            RTS
348    
349                             SSKIP
350       P:01C5 P:01C5 5EE000            MOVE                          Y:(R0),A
351       P:01C6 P:01C6 200003            TST     A
352       P:01C7 P:01C7 0EF1CF            JLE     <SSKIP0
353       P:01C8 P:01C8 066040            DO      Y:(R0),SSKIP0
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 7



                        0001CE
354       P:01CA P:01CA 68AC00            MOVE                          Y:<ASXFER0,R0
355       P:01CB P:01CB 0D01ED            JSR     <CLOCK
356       P:01CC P:01CC 68AE00            MOVE                          Y:<ASXFER2,R0
357       P:01CD P:01CD 0D01ED            JSR     <CLOCK
358       P:01CE P:01CE 000000            NOP
359                             SSKIP0
360       P:01CF P:01CF 000000            NOP
361       P:01D0 P:01D0 00000C            RTS
362    
363                             SDATA
364       P:01D1 P:01D1 5EE000            MOVE                          Y:(R0),A
365       P:01D2 P:01D2 200003            TST     A
366       P:01D3 P:01D3 0EF1E5            JLE     <SDATA0
367       P:01D4 P:01D4 066040            DO      Y:(R0),SDATA0
                        0001E4
368       P:01D6 P:01D6 68AC00            MOVE                          Y:<ASXFER0,R0
369       P:01D7 P:01D7 0D01ED            JSR     <CLOCK
370       P:01D8 P:01D8 448000            MOVE              X:<ONE,X0               ; Get bin-1
371       P:01D9 P:01D9 5E8300            MOVE                          Y:<NSBIN,A  ;
372       P:01DA P:01DA 200044            SUB     X0,A                              ;
373       P:01DB P:01DB 0EF1E1            JLE     <SDATA1                           ;
374       P:01DC P:01DC 06CE00            DO      A,SDATA1
                        0001E0
375       P:01DE P:01DE 68AD00            MOVE                          Y:<ASXFER1,R0
376       P:01DF P:01DF 0D01ED            JSR     <CLOCK
377       P:01E0 P:01E0 000000            NOP
378                             SDATA1
379       P:01E1 P:01E1 68AF00            MOVE                          Y:<ASXFER2D,R0
380       P:01E2 P:01E2 0D01ED            JSR     <CLOCK
381                             ; Read pixel datum from the A/D and send it along the serial transmitter
382       P:01E3 P:01E3 56E600            MOVE              X:(R6),A                ; Get the A/D converter counts from #0 A/D
383       P:01E4 P:01E4 5E6600            MOVE                          A,Y:(R6)    ; Send them to the serial transmitter
384                             SDATA0
385       P:01E5 P:01E5 000000            NOP
386       P:01E6 P:01E6 00000C            RTS
387    
388                             ; *******************************************************************
389                             FOR_PSHIFT
390       P:01E7 P:01E7 301300            MOVE              #<NPXSHIFT,R0
391       P:01E8 P:01E8 0D0194            JSR     <PSKIP
392       P:01E9 P:01E9 0C0000            JMP     <FINISH
393    
394                             ; *******************************************************************
395                             REV_PSHIFT
396       P:01EA P:01EA 301300            MOVE              #<NPXSHIFT,R0
397       P:01EB P:01EB 0D01AE            JSR     <RSKIP
398       P:01EC P:01EC 0C0000            JMP     <FINISH
399    
400                             ; *******************************************************************
401                             ;  This is the core subroutine for clocking out CCD charge
402                             CLOCK
403       P:01ED P:01ED 4CD800            MOVE                          Y:(R0)+,X0  ; # of waveform entries
404       P:01EE P:01EE 5ED800            MOVE                          Y:(R0)+,A   ; Start the pipeline
405       P:01EF P:01EF 06C400            DO      X0,CLK1                           ; Repeat X0 times
                        0001F1
406       P:01F1 P:01F1 FA0600            MOVE              A,X:(R6)    Y:(R0)+,A   ; Send out the waveform
407                             CLK1
408       P:01F2 P:01F2 566600            MOVE              A,X:(R6)                ; Flush out the pipeline
409       P:01F3 P:01F3 00000C            RTS                                       ; Return from subroutine
410    
411                             ; *******************************************************************
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 8



412                             ;  Slow clock for parallel shifts
413       P:01F4 P:01F4 5ED800  PCLOCK    MOVE                          Y:(R0)+,A   ; # of waveform entries
414       P:01F5 P:01F5 448000            MOVE              X:<ONE,X0               ; Add 1 - no pipeline prime
415       P:01F6 P:01F6 200040            ADD     X0,A
416       P:01F7 P:01F7 06CE00            DO      A,PCLK1
                        0001FD
417       P:01F9 P:01F9 5ED800            MOVE                          Y:(R0)+,A   ; Get the waveform
418       P:01FA P:01FA 062040            DO      Y:<PMULT,PCLK2
                        0001FC
419       P:01FC P:01FC 566600            MOVE              A,X:(R6)                ; Send out the waveform
420                             PCLK2
421       P:01FD P:01FD 000000            NOP
422                             PCLK1
423       P:01FE P:01FE 00000C            RTS                                       ; Return from subroutine
424    
425                             ; Check for program overflow
426                                       IF      @CVS(N,*)>=$200
428                                       ENDIF                                     ;  will not overflow
429    
430                             ; *** Macros ***
431    
432                             INTNOISE  MACRO
433  m                                                                              ; integrate noise
434  m                                    DC      VP+002*DELAY+%00011001            ; Start A/D
435  m                                    DC      VP+000*DELAY+%00011101            ; Continue A/D
436  m                                    DC      VP+010*DELAY+%10010101            ; Integrator Reset, latch data
437  m                                    DC      VP+010*DELAY+%01010101            ; DC Restore
438  m                                    DC      VP+010*DELAY+%01011101            ; End of Integrator Reset
439  m                                    DC      VP+DWEL*DELAY+%01001101           ; Start Integrate
440  m                                    DC      VP+010*DELAY+%01011101            ; Stop Integrate
441  m                                    ENDM
442    
443                             INTSIGNAL MACRO
444  m                                                                              ; integrate signal
445  m                                    DC      VP+008*DELAY+%01111101            ; Change Polarity
446  m                                    DC      VP+DWEL*DELAY+%01101101           ; Start Integrate
447  m                                    DC      VP+004*DELAY+%01111101            ; Stop Integrate
448  m                                    DC      PULSE2                            ; Synchronize CK8
449  m                                    DC      VP+%00011111                      ; Start Coarse Sample, Etc.
450  m                                    ENDM
451    
452                             ; *** Data areas ***
453    
454                             ;  Command table
455                                       IF      1                                 ; Memory offsets for downloading code
456       X:00C0 X:00C0                   ORG     X:COM_TBL,X:COM_TBL
457                                       ELSE                                      ; Memory offsets for generating EEPROMs
459                                       ENDIF
460    
461       X:00C0 X:00C0                   DC      'IDL',IDL                         ; Put CCD in IDLE mode
462       X:00C2 X:00C2                   DC      'STP',STP                         ; Exit IDLE mode
463       X:00C4 X:00C4                   DC      'SBV',SETBIAS                     ; Set DC bias supply voltages
464       X:00C6 X:00C6                   DC      'RDC',RDCCD                       ; Begin CCD readout
465       X:00C8 X:00C8                   DC      'CLR',CLEAR                       ; Fast clear CCD
466       X:00CA X:00CA                   DC      'HGN',HIGAIN                      ; Set analog boards to high gain
467       X:00CC X:00CC                   DC      'LGN',LOWGAIN                     ; Set analog boards to low gain
468       X:00CE X:00CE                   DC      'OSH',OSHUT                       ; Open shutter
469       X:00D0 X:00D0                   DC      'CSH',CSHUT                       ; Close shutter
470       X:00D2 X:00D2                   DC      'RAD',RAD                         ; Reset A/D - self-calibration for 1.5 sec
471       X:00D4 X:00D4                   DC      'DON',START                       ; Nothing special
472       X:00D6 X:00D6                   DC      0,START
473       X:00D8 X:00D8                   DC      'TST',FINISH                      ; Test to see if we are loaded
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 9



474       X:00DA X:00DA                   DC      'FPX',FOR_PSHIFT                  ; Forward parallel shift
475       X:00DC X:00DC                   DC      'RPX',REV_PSHIFT                  ; Reverse parallel shift
476       X:00DE X:00DE                   DC      0,START
477    
478                                       IF      1
479       Y:0000 Y:0000                   ORG     Y:0,Y:0                           ; Download address
480                                       ELSE
482                                       ENDIF
483    
484                             ; *** include waveform tables and device specific parameters ***
485                                       INCLUDE "waveforms.asm"
486                             ; waveforms.asm for STA0510A BCSpec
487                             ; Gen1 controller
488                             ; 10Aug11 last change MPL
489    
490                             ; *** timing delays ***
491       001770                P_DELAY   EQU     6000                              ; parallel clock delay nsecs (min 50)
492       000064                S_DELAY   EQU     100                               ; S clock delay nsec (min 50)
493       001F40                DWELL     EQU     8000                              ; integration nsec (min 50)
494       000004                PARMULT   EQU     4                                 ; parallel delay multiplier
495    
496                             ; *** clock rails ***
497       6.000000E+000         RG_HI     EQU     +6.0                              ; Reset Gate
498       -0.000000E+000        RG_LO     EQU     -0.0
499       4.000000E+000         S_HI      EQU     +4.0                              ; Serial clocks
500       -4.000000E+000        S_LO      EQU     -4.0
501       3.000000E+000         SW_HI     EQU     +3.0                              ; Summing Well
502       -3.000000E+000        SW_LO     EQU     -3.0
503       0.000000E+000         P_HI      EQU     +0.0                              ; Parallel clock phases 1 & 2
504       -8.000000E+000        P_LO      EQU     -8.0                              ;
505       1.000000E+000         PMPP_HI   EQU     +1.0                              ; 0 phase
506       -6.500000E+000        PMPP_LO   EQU     -6.5                              ;
507       2.000000E+000         TG_HI     EQU     +2.0                              ; Transfer gate
508       -5.000000E+000        TG_LO     EQU     -5.0
509    
510                             ; *** bias voltages ***
511       2.400000E+001         VOD       EQU     +24.0                             ; Vod, originally 24
512       1.350000E+001         VRD       EQU     +13.5                             ; Vrd, originally 13.5
513       0.000000E+000         VOG       EQU     0.0                               ; Vog
514       0.000000E+000         VB5       EQU     0.0                               ; Bias5
515       0.000000E+000         VB6       EQU     0.0                               ; Bias6
516       0.000000E+000         VB7       EQU     0.0                               ; Bias7
517    
518                             ; *** video processor offset ***
519       2.800000E-001         VOFFSET   EQU     0.28                              ; larger reduces bias
520    
521                             ; *** clock rail aliases ***
522       4.000000E+000         S1_HI     EQU     S_HI
523       -4.000000E+000        S1_LO     EQU     S_LO
524       4.000000E+000         S2_HI     EQU     S_HI
525       -4.000000E+000        S2_LO     EQU     S_LO
526       4.000000E+000         S3_HI     EQU     S_HI
527       -4.000000E+000        S3_LO     EQU     S_LO
528    
529       0.000000E+000         P1_HI     EQU     P_HI
530       -8.000000E+000        P1_LO     EQU     P_LO
531       0.000000E+000         P2_HI     EQU     P_HI
532       -8.000000E+000        P2_LO     EQU     P_LO
533                                       IF      0
536                                       ELSE
537       0.000000E+000         P3_HI     EQU     P_HI
538       -8.000000E+000        P3_LO     EQU     P_LO
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  waveforms.asm  Page 10



539                                       ENDIF
540       0.000000E+000         Q1_HI     EQU     P_HI
541       -8.000000E+000        Q1_LO     EQU     P_LO
542       0.000000E+000         Q2_HI     EQU     P_HI
543       -8.000000E+000        Q2_LO     EQU     P_LO
544                                       IF      0
547                                       ELSE
548       0.000000E+000         Q3_HI     EQU     P_HI
549       -8.000000E+000        Q3_LO     EQU     P_LO
550                                       ENDIF
551    
552                             ; *** set waveforms for each amp below ***
553                             ; both serial registers are 3-2-1-w to active amp
554    
555                             ; ITL test lab in Kovar tub
556                             ; amp 3 U, 123t, 321w
557                             ; amp 1 L, 321t, 321w
558    
559                             ; 123t, 123w, not connected
560                             ; 321t, 123w, not connected
561    
562                                       DEFINE  SHIFTLR_PAR_NORM 'p_12_321t.asm'  ; BCSpec
563                                       DEFINE  SHIFTLR_PAR_MPP 'p_12_321t_mpp.asm'
564    
565                             ;       DEFINE  p_12_321t.asm   'p_12_123t.asm'
566                             ;       DEFINE  p_12_321t_mpp.asm               'p_12_123t_mpp.asm'
567    
568                                       DEFINE  SHIFTLR_SER 's_2_321w.asm'
569    
570    
571                             ; *** end of waveform.asm ***
572    
573                             ; these values are at Y:0 and are overwritten by AzCam
574       Y:0000 Y:0000         DUMMY     DC      0
575       Y:0001 Y:0001         NSDATA    DC      2048
576       Y:0002 Y:0002         NPDATA    DC      2048
577       Y:0003 Y:0003         NSBIN     DC      1
578       Y:0004 Y:0004         NPBIN     DC      1
579       Y:0005 Y:0005                   DC      0
580       Y:0006 Y:0006                   DC      0
581       Y:0007 Y:0007         NSCLEAR   DC      2134
582       Y:0008 Y:0008         NPCLEAR   DC      2048
583       Y:0009 Y:0009         NSPRESKIP DC      16
584                              NSUNDERSCAN
585       Y:000A Y:000A                   DC      0
586       Y:000B Y:000B         NSSKIP    DC      0
587       Y:000C Y:000C         NSPOSTSKIP DC     50
588       Y:000D Y:000D         NSOVERSCAN DC     20
589       Y:000E Y:000E         NPPRESKIP DC      0
590                              NPUNDERSCAN
591       Y:000F Y:000F                   DC      0
592       Y:0010 Y:0010         NPSKIP    DC      0
593       Y:0011 Y:0011         NPPOSTSKIP DC     0
594       Y:0012 Y:0012         NPOVERSCAN DC     0
595       Y:0013 Y:0013         NPXSHIFT  DC      0
596       Y:0014 Y:0014                   DC      0
597       Y:0015 Y:0015         FRAMET    DC      0
598       Y:0016 Y:0016         PREFLASH  DC      0
599       Y:0017 Y:0017                   DC      0
600       Y:0018 Y:0018                   DC      0
601       Y:0019 Y:0019                   DC      0
602       Y:001A Y:001A                   DC      0
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 11



603       Y:001B Y:001B         NSIMAGE   DC      0
604       Y:001C Y:001C         NPIMAGE   DC      0
605       Y:001D Y:001D                   DC      0
606       Y:001E Y:001E                   DC      0
607       Y:001F Y:001F         IDLEONE   DC      1
608    
609                             ; *** these values are at Y:20 and are addresses ***
610       Y:0020 Y:0020         PMULT     DC      PARMULT
611       Y:0021 Y:0021         ACLEAR0   DC      TNOP                              ; Prepare prologue (biases)
612       Y:0022 Y:0022         ACLEAR2   DC      TNOP                              ; Prepare epilogue
613       Y:0023 Y:0023         AREAD0    DC      TNOP                              ; not used
614       Y:0024 Y:0024         AREAD8    DC      TNOP                              ; not used
615       Y:0025 Y:0025         AFPXFER0  DC      TNOP                              ; Fast parallel transfer prologue
616       Y:0026 Y:0026         AFPXFER2  DC      TNOP                              ; Fast parallel transfer epilogue
617       Y:0027 Y:0027         APXFER    DC      PXFER                             ; Parallel transfer - storage only
618       Y:0028 Y:0028         APDXFER   DC      PXFER                             ; Parallel transfer (data) - storage only
619       Y:0029 Y:0029         APQXFER   DC      PQXFER                            ; Parallel transfer - storage and image
620       Y:002A Y:002A         ARXFER    DC      RXFER                             ; Reverse parallel transfer (for focus)
621       Y:002B Y:002B         AFSXFER   DC      FSXFER                            ; Fast serial transfer
622       Y:002C Y:002C         ASXFER0   DC      SXFER0                            ; Serial transfer prologue
623       Y:002D Y:002D         ASXFER1   DC      SXFER1                            ; Serial transfer ( * colbin-1 )
624       Y:002E Y:002E         ASXFER2   DC      SXFER2                            ; Serial transfer epilogue - no data
625       Y:002F Y:002F         ASXFER2D  DC      SXFER2                            ; Serial transfer epilogue - data
626       Y:0030 Y:0030         ADACS     DC      BIAS
627    
628                             ;  *** CCD clock select codes ***
629       000000                RG        EQU     $000000                           ; Reset gate -10-+16
630       000100                S1        EQU     $000100                           ; Serial clock phase 1 (-10:+10)
631       000200                S2        EQU     $000200                           ; Serial clock phase 2 (-10:+10)
632       000300                S3        EQU     $000300                           ; Serial clock phase 3 (-10:+10)
633       000400                SW        EQU     $000400                           ; Output Summing Well (-10:+10)
634       000500                P1        EQU     $000500                           ; Parallel clock phase 1 (-10:+10)
635       000600                P2        EQU     $000600                           ; Parallel clock phase 2 (-10:+10)
636       000700                P3        EQU     $000700                           ; Parallel clock phase 3 (-10:+10)
637       000800                TG        EQU     $000800                           ; Transfer gate (-10:+10)
638       000900                Q1        EQU     $000900                           ; Q1 (-10:+10)
639       000A00                Q2        EQU     $000A00                           ; Q2 (-10:+10)
640       000B00                Q3        EQU     $000B00                           ; Q3 (-10:+10)
641       0000FE                OFFSET    EQU     INV-1                             ; Video processor offset (-5:+5)
642       0000FD                OD        EQU     INV-2                             ; Output Drain (0:30)
643       0000FB                RD        EQU     INV-4                             ; Reset Drain (0:20)
644       0000F7                B3        EQU     INV-8                             ; B3 (0:30)
645       0000EF                OG        EQU     INV-16                            ; Output Gate (-5:+5)
646       0000DF                B5        EQU     INV-32                            ; B5 (-10:+10)
647       0000BF                B6        EQU     INV-64                            ; B6 (-10:+10)
648       00007F                B7        EQU     INV-128                           ; B7 (-10:+10)
649    
650                             ; *** change clock decimal voltages to counts ***
651       000063                RGH       EQU     RG+255-@CVI((RG_HI+10.0)/26.0*255)
652       00009D                RGL       EQU     RG+255-@CVI((RG_LO+10.0)/26.0*255)
653       00014D                S1H       EQU     S1+255-@CVI((S1_HI+10.0)/20.0*255)
654       0001B3                S1L       EQU     S1+255-@CVI((S1_LO+10.0)/20.0*255)
655       00024D                S2H       EQU     S2+255-@CVI((S2_HI+10.0)/20.0*255)
656       0002B3                S2L       EQU     S2+255-@CVI((S2_LO+10.0)/20.0*255)
657       00034D                S3H       EQU     S3+255-@CVI((S3_HI+10.0)/20.0*255)
658       0003B3                S3L       EQU     S3+255-@CVI((S3_LO+10.0)/20.0*255)
659       00045A                SWH       EQU     SW+255-@CVI((SW_HI+10.0)/20.0*255)
660       0004A6                SWL       EQU     SW+255-@CVI((SW_LO+10.0)/20.0*255)
661       000580                P1H       EQU     P1+255-@CVI((P1_HI+10.0)/20.0*255)
662       0005E6                P1L       EQU     P1+255-@CVI((P1_LO+10.0)/20.0*255)
663       000680                P2H       EQU     P2+255-@CVI((P2_HI+10.0)/20.0*255)
664       0006E6                P2L       EQU     P2+255-@CVI((P2_LO+10.0)/20.0*255)
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 12



665       000780                P3H       EQU     P3+255-@CVI((P3_HI+10.0)/20.0*255)
666       0007E6                P3L       EQU     P3+255-@CVI((P3_LO+10.0)/20.0*255)
667       000866                TGH       EQU     TG+255-@CVI((TG_HI+10.0)/20.0*255)
668       0008C0                TGL       EQU     TG+255-@CVI((TG_LO+10.0)/20.0*255)
669       000980                Q1H       EQU     Q1+255-@CVI((Q1_HI+10.0)/20.0*255)
670       0009E6                Q1L       EQU     Q1+255-@CVI((Q1_LO+10.0)/20.0*255)
671       000A80                Q2H       EQU     Q2+255-@CVI((Q2_HI+10.0)/20.0*255)
672       000AE6                Q2L       EQU     Q2+255-@CVI((Q2_LO+10.0)/20.0*255)
673       000B80                Q3H       EQU     Q3+255-@CVI((Q3_HI+10.0)/20.0*255)
674       000BE6                Q3L       EQU     Q3+255-@CVI((Q3_LO+10.0)/20.0*255)
675    
676                             ; *** change bias decimal voltages to counts ***
677       000086                VOFFD     EQU     @CVI((VOFFSET+5.0)/10.0*255)
678       0000E5                VODD      EQU     @CVI((VOD+00.0)/26.7*255)
679       0000B9                VRDD      EQU     @CVI((VRD+00.0)/18.6*255)
680       00007F                VOGD      EQU     @CVI((VOG+05.0)/10.0*255)
681       00007F                VB5D      EQU     @CVI((VB5+10.0)/20.0*255)
682       00007F                VB6D      EQU     @CVI((VB6+10.0)/20.0*255)
683       00007F                VB7D      EQU     @CVI((VB7+10.0)/20.0*255)
684    
685                             ; BIAS and CLEAR0 code
686                             BIAS
687                             ; Set DC bias supply voltages with DACs
688       Y:0031 Y:0031         CLEAR0    DC      ECLEAR0-CLEAR0-2
689                             ; Set the bias DACs
690                             ; Set the video offset voltage
691       Y:0032 Y:0032                   DC      CCD+BIASDAT+VOFFD
692       Y:0033 Y:0033                   DC      CCD+DACTIME*DELAY+BIASSEL+OFFSET
693       Y:0034 Y:0034                   DC      CCD+BIASSEL+INV
694                             ; Set CCD Output Drain voltage Vod
695       Y:0035 Y:0035                   DC      CCD+BIASDAT+VODD
696       Y:0036 Y:0036                   DC      CCD+DACTIME*DELAY+BIASSEL+OD
697       Y:0037 Y:0037                   DC      CCD+BIASSEL+INV
698                             ; Set CCD Reset Drain voltage Vrd
699       Y:0038 Y:0038                   DC      CCD+BIASDAT+VRDD
700       Y:0039 Y:0039                   DC      CCD+DACTIME*DELAY+BIASSEL+RD
701       Y:003A Y:003A                   DC      CCD+BIASSEL+INV
702                             ; Set CCD Output Transfer Gate voltage Vog
703       Y:003B Y:003B                   DC      CCD+BIASDAT+VOGD
704       Y:003C Y:003C                   DC      CCD+DACTIME*DELAY+BIASSEL+OG
705       Y:003D Y:003D                   DC      CCD+BIASSEL+INV
706                             ; Set B5
707       Y:003E Y:003E                   DC      CCD+BIASDAT+VB5D
708       Y:003F Y:003F                   DC      CCD+DACTIME*DELAY+BIASSEL+B5
709       Y:0040 Y:0040                   DC      CCD+BIASSEL+INV
710                             ; Set B6
711       Y:0041 Y:0041                   DC      CCD+BIASDAT+VB6D
712       Y:0042 Y:0042                   DC      CCD+DACTIME*DELAY+BIASSEL+B6
713       Y:0043 Y:0043                   DC      CCD+BIASSEL+INV
714                             ; Set B7
715       Y:0044 Y:0044                   DC      CCD+BIASDAT+VB7D
716       Y:0045 Y:0045                   DC      CCD+DACTIME*DELAY+BIASSEL+B7
717       Y:0046 Y:0046                   DC      CCD+BIASSEL+INV
718                             ECLEAR0
719    
720                             ; *** shorthand for waveforms ***
721       000077                P_DEL     EQU     @CVI((P_DELAY/50)-1)
722       000001                S_DEL     EQU     @CVI((S_DELAY/50)-1)
723       00009F                DWEL      EQU     @CVI((DWELL/50)-1)
724       770000                PCLK      EQU     CCD+P_DEL*DELAY
725       010000                SCLK      EQU     CCD+S_DEL*DELAY
726    
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1.asm  Page 13



727                             ; *** timing NOP ***
728       Y:0047 Y:0047         TNOP      DC      ETNOP-TNOP-2
729       Y:0048 Y:0048                   DC      $000F00
730       Y:0049 Y:0049                   DC      $000F00
731                             ETNOP
732    
733                             ; *** code for generating waveforms ***
734                                       IF      1
735       Y:004A Y:004A         PXFER     DC      EPXFER-PXFER-2
736                                       IF      0
738                                       ELSE
739                                       INCLUDE "p_12_321t.asm"
740                             ; p_12_321t.asm
741       Y:004B Y:004B                   DC      PCLK+TGH                          ; TGH
742       Y:004C Y:004C                   DC      PCLK+P2L                          ; 1
743       Y:004D Y:004D                   DC      PCLK+P3H                          ; 1+3
744       Y:004E Y:004E                   DC      PCLK+P1L                          ; 3
745       Y:004F Y:004F                   DC      PCLK+P2H                          ; 3+2
746       Y:0050 Y:0050                   DC      PCLK+P3L                          ; 2
747       Y:0051 Y:0051                   DC      PCLK+P1H                          ; 2+1
748       Y:0052 Y:0052                   DC      PCLK+TGL                          ; TGL
749                                       ENDIF
750                             EPXFER
751                                       INCLUDE "s_2_321w.asm"
752                             ; s_2_321w.asm generic SW
753    
754       Y:0053 Y:0053         FSXFER    DC      EFSXFER-FSXFER-2
755       Y:0054 Y:0054                   DC      SCLK+RGH                          ; reset
756       Y:0055 Y:0055                   DC      SCLK+RGL
757       Y:0056 Y:0056                   DC      SCLK+SWH
758       Y:0057 Y:0057                   DC      SCLK+S1H                          ; 2+1
759       Y:0058 Y:0058                   DC      SCLK+S2L                          ; 1
760       Y:0059 Y:0059                   DC      SCLK+S3H                          ; 1+3
761       Y:005A Y:005A                   DC      SCLK+S1L                          ; 3
762       Y:005B Y:005B                   DC      SCLK+S2H                          ; 3+2
763       Y:005C Y:005C                   DC      SCLK+S3L                          ; 2
764       Y:005D Y:005D                   DC      SCLK+SWL
765                             EFSXFER
766    
767       Y:005E Y:005E         SXFER0    DC      ESXFER0-SXFER0-2
768       Y:005F Y:005F                   DC      VP+%00011101
769       Y:0060 Y:0060                   DC      SCLK+RGH                          ; reset
770       Y:0061 Y:0061                   DC      SCLK+RGL
771       Y:0062 Y:0062                   DC      SCLK+SWH
772       Y:0063 Y:0063                   DC      SCLK+S1H                          ; 2+1
773       Y:0064 Y:0064                   DC      SCLK+S2L                          ; 1
774       Y:0065 Y:0065                   DC      SCLK+S3H                          ; 1+3
775       Y:0066 Y:0066                   DC      SCLK+S1L                          ; 3
776       Y:0067 Y:0067                   DC      SCLK+S2H                          ; 3+2
777       Y:0068 Y:0068                   DC      SCLK+S3L                          ; 2
778                             ESXFER0
779    
780       Y:0069 Y:0069         SXFER1    DC      ESXFER1-SXFER1-2
781       Y:006A Y:006A                   DC      SCLK+S1H                          ; 2+1
782       Y:006B Y:006B                   DC      SCLK+S2L                          ; 1
783       Y:006C Y:006C                   DC      SCLK+S3H                          ; 1+3
784       Y:006D Y:006D                   DC      SCLK+S1L                          ; 3
785       Y:006E Y:006E                   DC      SCLK+S2H                          ; 3+2
786       Y:006F Y:006F                   DC      SCLK+S3L                          ; 2
787                             ESXFER1
788    
789       Y:0070 Y:0070         SXFER2    DC      ESXFER2-SXFER2-2
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  s_2_321w.asm  Page 14



790                                       INTNOISE
799       Y:0078 Y:0078                   DC      SCLK+SWL
800                                       INTSIGNAL
807                             ESXFER2
808                                       ENDIF
809    
810                                       IF      0
819                                       ENDIF
820    
821                                       IF      0
830                                       ENDIF
831    
832                                       IF      0
841                                       ENDIF
842    
843                             ; *** reverse par shifting not used ***
844       00004A                RXFER     EQU     PXFER
845       00004A                PQXFER    EQU     PXFER
846    
847                             ; Check for overflow in the EEPROM case
848                                       IF      !1
852                                       ENDIF
853    
854                                ENDSEC                                    ; end of TIMAZCAM section
855    
856                                END                                       ; end of program

0    Errors
0    Warnings


