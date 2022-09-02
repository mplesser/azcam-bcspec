Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:29  utilboot1.asm  Page 1



1                               COMMENT *
2      
3                        This file is used to generate boot DSP code for the utility board.
4                            This is Rev. 2.31 software.
5      
6                                *
7                                  PAGE    132                               ; Printronix page width - 132 columns
8      
9                        ;  Define some useful DSP register locations
10        000000         RST_ISR   EQU     $00                               ; Hardware reset interrupt
11        000006         ROM_ID    EQU     $06                               ; Location of ROM Identification words = SWI interrupt
12        000008         IRQA_ISR  EQU     $08                               ; Address of ISRA for 1 kHz timer interrupts
13        000014         SCI_ISR   EQU     $14                               ; SCI Receive data interrupt address
14        000016         SCI_ERR   EQU     $16                               ; SCI Receive with exception address
15        000018         START     EQU     $18                               ; Address for beginning of code
16        000080         BUF_STR   EQU     $80                               ; Starting address of buffers in X:
17        000020         BUF_LEN   EQU     $20                               ; Length of each buffer
18        000080         SCI_BUF   EQU     BUF_STR                           ; Starting address of SCI buffer in X:
19        0000A0         COM_BUF   EQU     SCI_BUF+BUF_LEN                   ; Starting address of command buffer in X:
20        0000C0         COM_TBL   EQU     COM_BUF+BUF_LEN                   ; Starting address of command table in X:
21        000018         NUM_COM   EQU     24                                ; Number of entries in the command table
22        000682         TIMEOUT   EQU     1666                              ; Timeout for receiving complete command = 1 millisec
23        000098         APL_ADR   EQU     $98                               ; Starting address of application program
24        001EE0         APL_XY    EQU     $1EE0                             ; Start of application data tables
25        006000         RST_OFF   EQU     $6000                             ; Reset code offset in EEPROM
26        006040         P_OFF     EQU     $6040                             ; P: memory offset into EEPROM
27        006100         X_OFF     EQU     $6100                             ; X: memory offset into EEPROM
28        006200         OVL_ADR   EQU     $6200                             ; P: start address for overlay routines
29        000046         DLY_MUX   EQU     70                                ; Number of DSP cycles to delay for MUX settling
30        000064         DLY_AD    EQU     100                               ; Number of DSP cycles to delay for A/D settling
31     
32                       ; Now assign a bunch of addresses to on-chip functions
33        00FFFE         BCR       EQU     $FFFE                             ; Bus (=Port A) Control Register -> Wait States
34        00FFE1         PCC       EQU     $FFE1                             ; Port C Control Register
35        00FFE0         PBC       EQU     $FFE0                             ; Port B Control Register
36        00FFE2         PBDDR     EQU     $FFE2                             ; Port B Data Direction Register
37        00FFE4         PBD       EQU     $FFE4                             ; Port B Data Register
38        00FFF0         SCR       EQU     $FFF0                             ; SCI Control Register
39        00FFF1         SSR       EQU     $FFF1                             ; SCI Status Register
40        00FFF2         SCCR      EQU     $FFF2                             ; SCI Clock Control Register
41        00FFF4         SRX       EQU     $FFF4                             ; SCI Receiver low address byte
42        00FFFF         IPR       EQU     $FFFF                             ; Interrupt Priority Register
43     
44                       ;  Addresses of memory mapped components in Y: data memory space
45                       ;  Write addresses first
46        00FFF0         WR_DIG    EQU     $FFF0                             ; Write Digital output values D00-D15
47        00FFF1         WR_MUX    EQU     $FFF1                             ; Select MUX connected to A/D input - one of 16
48        00FFF2         EN_DIG    EQU     $FFF2                             ; Enable digital outputs
49        00FFF7         WR_DAC3   EQU     $FFF7                             ; Write to DAC#3 D00-D11
50        00FFF6         WR_DAC2   EQU     $FFF6                             ; Write to DAC#2 D00-D11
51        00FFF5         WR_DAC1   EQU     $FFF5                             ; Write to DAC#1 D00-D11
52        00FFF4         WR_DAC0   EQU     $FFF4                             ; Write to DAC#0 D00-D11
53     
54                       ;  Read addresses next
55        00FFF0         RD_DIG    EQU     $FFF0                             ; Read Digital input values D00-D15
56        00FFF1         STR_ADC   EQU     $FFF1                             ; Start ADC conversion, ignore data
57        00FFF2         RD_ADC    EQU     $FFF2                             ; Read A/D converter value D00-D11
58        00FFF7         WATCH     EQU     $FFF7                             ; Watch dog timer - tell it that DSP is alive
59     
60                       ;  Bit definitions of STATUS word
61        000000         ST_SRVC   EQU     0                                 ; Set if SERVICE routine needs executing
62        000001         ST_EX     EQU     1                                 ; Set if timed exposure is in progress
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:29  utilboot1.asm  Page 2



63        000002         ST_SH     EQU     2                                 ; Set if shutter is open
64        000003         ST_READ   EQU     3                                 ; Set if a readout needs to be initiated
65     
66                       ; Bit definitions of software OPTIONS word
67        000000         OPT_SH    EQU     0                                 ; Set to open and close shutter
68     
69                       ;  Bit definitions of Port B = Host Processor Interface
70        000000         HVEN      EQU     0                                 ; Enable high voltage PS (+36V nominal)- Output
71        000001         LVEN      EQU     1                                 ; Enable low voltage PS (+/-15 volt nominal) - Output
72        000002         PWRST     EQU     2                                 ; Reset power conditioner counter - Output
73        000003         SHUTTER   EQU     3                                 ; Control shutter - Output
74        000004         IRQ_T     EQU     4                                 ; Request interrupt service from timing board - Output
75        000005         SYS_RST   EQU     5                                 ; Reset entire system - Output
76        000008         WATCH_T   EQU     8                                 ; Processed watchdog signal from timing board - Input
77        000009         PWREN     EQU     9                                 ; Enable power conditioner board - Output
78     
79                       ;**************************************************************************
80                       ;                                                                         *
81                       ;    Register assignments                                                 *
82                       ;        R1 - Address of SCI receiver contents                            *
83                       ;        R2 - Address of processed SCI receiver contents                  *
84                       ;        R3 - Pointer to current top of command buffer                    *
85                       ;        R4 - Pointer to processed contents of command buffer             *
86                       ;        N4 - Address for internal jumps after receiving 'DON' replies    *
87                       ;        R0, R5, R6, A, X0, X1 and Y0 - Freely available for program use  *
88                       ;        R7 - For use by SCI ISR only                                     *
89                       ;        B, Y1 - For use by timer ISR only                                *
90                       ;                                                                         *
91                       ;**************************************************************************
92     
93                       ;  Initialize the DSP. Because this is executed only on DSP boot from ROM
94                       ;     it is not incorporated into any download code.
95     
96        P:6000 P:6000                   ORG     P:RST_OFF,P:RST_OFF
97     
98        P:6000 P:6000 0502BA            MOVEC             #$02,OMR                ; Normal expanded mode
99        P:6001 P:6001 000000            NOP                                       ; Allow time for the remapping to occur
100       P:6002 P:6002 0AF080            JMP     INIT                              ; DSP resets to $E000, but we load program
                        006004
101                                                                                 ;   to EEPROM starting at RST_OFF = $6000
102    
103       P:6004 P:6004 08F4A4  INIT      MOVEP             #$023B,X:PBD            ; Power enables off, shutter high
                        00023B
104                                                                                 ;  (closed), IRQA, SYSRST, PWREN all high
105    
106       P:6006 P:6006 08F4A2            MOVEP             #$023F,X:PBDDR          ; H0 - H5 Outputs, H6 - H8 Inputs
                        00023F
107                                                                                 ; H9 = output
108    
109       P:6008 P:6008 0003F8            ORI     #$03,MR                           ; Temporarily mask interrupts
110    
111       P:6009 P:6009 08F4BF            MOVEP             #$8007,X:IPR            ; Enable IRQA = timer
                        008007
112                                                                                 ; Change priorities for operation
113                                                                                 ;   SCI = 1 = link to timing board
114                                                                                 ;   IRQA = 2 = timer
115                                                                                 ;   Host = SSI = IRQB = 0 = disabled
116    
117       P:600B P:600B 08F4B0            MOVEP             #$0B04,X:SCR            ; SCI programming: 11-bit asynchronous
                        000B04
118                                                                                 ;   protocol (1 start, 8 data, 1 even parity,
119                                                                                 ;   1 stop); LSB before MSB; enable receiver
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:29  utilboot1.asm  Page 3



120                                                                                 ;   and its interrupts; transmitter interrupts
121                                                                                 ;   disabled.
122    
123       P:600D P:600D 08F4B2            MOVEP             #$0000,X:SCCR           ; SCI clock: maximum asynchronous
                        000000
124                                                                                 ;   data rate (312,500 kbits/sec); internal
125                                                                                 ;   clock.
126    
127       P:600F P:600F 08F4A1            MOVEP             #>$03,X:PCC             ; Select Port C pins 1 and 2 for the SCI.
                        000003
128    
129       P:6011 P:6011 08F4BE            MOVEP             #$0022,X:BCR            ; Wait states for external memory accesses
                        000022
130                                                                                 ;   2 for PROM = 150 nsec
131                                                                                 ;   2 for A/D, DAC, etc. = 150 nsec
132    
133                             ; Load boot program into P: memory from EEPROM
134       P:6013 P:6013 60F400            MOVE              #P_OFF,R0               ; Starting P: address in EEPROM
                        006040
135       P:6015 P:6015 310000            MOVE              #0,R1                   ; Put values starting at beginning of P:
136       P:6016 P:6016 069A80            DO      #APL_ADR+2,P_MOVE                 ; Boot program is APL_ADR words long
                        006019
137                                                                                 ;     +2 is for SERVICE and TIMER stubs
138       P:6018 P:6018 07D88E            MOVE              P:(R0)+,A               ; Get one word from EEPROM
139       P:6019 P:6019 07598E            MOVE              A,P:(R1)+               ; Write it to DSP P: memory
140                             P_MOVE
141    
142                             ; Load X: data memory from EEPROM
143       P:601A P:601A 60F400            MOVE              #X_OFF,R0               ; Starting X: address in EEPROM
                        006100
144       P:601C P:601C 310000            MOVE              #0,R1                   ; Put values starting at beginning of X:
145       P:601D P:601D 060081            DO      #$100,X_MOVE                      ; Assume 256 = $100 values exist
                        006020
146       P:601F P:601F 07D88E            MOVE              P:(R0)+,A               ; Get one word from EEPROM
147       P:6020 P:6020 565900            MOVE              A,X:(R1)+               ; Write it to DSP X: memory
148                             X_MOVE
149    
150                             ; Initialize various registers
151       P:6021 P:6021 318000            MOVE              #SCI_BUF,R1
152       P:6022 P:6022 33A000            MOVE              #COM_BUF,R3
153       P:6023 P:6023 223200            MOVE              R1,R2
154       P:6024 P:6024 227400            MOVE              R3,R4
155       P:6025 P:6025 051FA1            MOVE              #31,M1                  ; Create circular buffers, modulo 32
156       P:6026 P:6026 0462A1            MOVE              M1,M2
157       P:6027 P:6027 0463A2            MOVE              M2,M3
158       P:6028 P:6028 0464A3            MOVE              M3,M4
159       P:6029 P:6029 3C1800            MOVE              #<START,N4
160       P:602A P:602A 678900            MOVE              X:<SRX_FST,R7           ; Starting address of SCI receiver
161       P:602B P:602B 00FCB8            ANDI    #$FC,MR                           ; Unmask interrupts
162       P:602C P:602C 0AA405            BCLR    #SYS_RST,X:PBD                    ; Reset timing board
163       P:602D P:602D 0614A0            REP     #20                               ; Reset must be low for awhile
164       P:602E P:602E 000000            NOP
165       P:602F P:602F 0AA425            BSET    #SYS_RST,X:PBD
166       P:6030 P:6030 569D00            MOVE              X:<HOST,A
167       P:6031 P:6031 565B00            MOVE              A,X:(R3)+
168       P:6032 P:6032 56A300            MOVE              X:<RST,A                ; Send 'RST' reply to host computer
169       P:6033 P:6033 565B00            MOVE              A,X:(R3)+
170       P:6034 P:6034 0C004B            JMP     <XMT_CHK                          ; Transmit 'RST' reply
171    
172                             ;  *****  Put interrupt service routine vectors in their required places  *****
173                             ;  After RESET jump to initialization code
174       P:0000 P:6040                   ORG     P:RST_ISR,P:RST_ISR+P_OFF
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:29  utilboot1.asm  Page 4



175       P:0000 P:6040 0AF080            JMP     INIT                              ; This is the interrupt service for RESET
                        006004
176    
177                             ;  The IRQA ISR is a long interrupt keyed to the 1 millisecond timer
178       P:0008 P:6048                   ORG     P:IRQA_ISR,P:IRQA_ISR+P_OFF
179       P:0008 P:6048 0BF080            JSR     TIMER                             ; Jump to long TIMER routine for service
                        000099
180    
181                             ;  The SCI interrupts when it receives data from the timing board.
182       P:0014 P:6054                   ORG     P:SCI_ISR,P:SCI_ISR+P_OFF
183       P:0014 P:6054 0BF080            JSR     SCI_RCV                           ; SCI Receive data interrupt service routine
                        000071
184    
185                             ;  The SCI interrupts to here when there is an error.
186       P:0016 P:6056                   ORG     P:SCI_ERR,P:SCI_ERR+P_OFF
187       P:0016 P:6056 0BF080            JSR     CLR_ERR
                        000081
188    
189                             ; Put the ID words for this version of the ROM code. It is placed at
190                             ;   the address of the SWI = software interrupt, which we never use.
191       P:0006 P:6046                   ORG     P:ROM_ID,P:ROM_ID+P_OFF
192       P:0006 P:6046                   DC      $000000                           ; Institution
193                                                                                 ; Location
194                                                                                 ; Instrument
195       P:0007 P:6047                   DC      $023103                           ; Version 2.31, Board #3 = Utility
196    
197                             ;  Start the command interpreting code
198       P:0018 P:6058                   ORG     P:START,P:START+P_OFF
199    
200                             ;  Check for TIMER interrupts and go handle them if necessary
201       P:0018 P:6058 0B00A0            JSSET   #ST_SRVC,X:STATUS,SERVICE         ; Do all millisecond service tasks
                        000098
202       P:001A P:605A 094E37            MOVEP             Y:WATCH,A               ; Reset watchdog timer
203    
204                             ;  Test SCI receiver pointers
205       P:001B P:605B 222E00            MOVE              R1,A                    ; Pointer to current contents of receiver
206       P:001C P:605C 224400            MOVE              R2,X0                   ; Pointer to processed contents
207       P:001D P:605D 46E245            CMP     X0,A      X:(R2),Y0               ; Are they equal? Get header ID
208       P:001E P:605E 0EA041            JEQ     <TST_COM                          ; Yes, so check the receiver stack
209    
210                             ;  Check candidate header ID = (S,D,N) for self-consistency
211       P:001F P:605F 549200            MOVE              X:<MASK1,A1             ; Test for S.LE.3 and D.LE.3 and N.LE.7
212       P:0020 P:6060 200056            AND     Y0,A                              ; Y0 = header ID from above
213       P:0021 P:6061 0E2028            JNE     <RCV_SKP                          ; Test failed, skip over header ID
214       P:0022 P:6062 549300            MOVE              X:<MASK2,A1             ; Test for S.NE.0 or D.NE.0
215       P:0023 P:6063 200056            AND     Y0,A
216       P:0024 P:6064 0EA028            JEQ     <RCV_SKP                          ; Test failed, skip over header ID
217       P:0025 P:6065 2C0700            MOVE              #7,A1                   ; Test for N.GE.1
218       P:0026 P:6066 200056            AND     Y0,A                              ; A = NWORDS in command
219       P:0027 P:6067 0E202E            JNE     <RCV_PR                           ; Test suceeded - process command
220       P:0028 P:6068 205A00  RCV_SKP   MOVE              (R2)+                   ; Header ID is wrong - skip over it
221       P:0029 P:6069 56A600            MOVE              X:<BAD_HDR,A            ; Increment BAD_HDR
222       P:002A P:606A 448C00            MOVE              X:<ONE,X0
223       P:002B P:606B 200040            ADD     X0,A
224       P:002C P:606C 562600            MOVE              A,X:<BAD_HDR
225       P:002D P:606D 0C0018            JMP     <START                            ; Keep monitoring receiver
226    
227                             ;  Get all the words of the command before processing it
228       P:002E P:606E 21C600  RCV_PR    MOVE              A,Y0                    ; Number of words in command header
229       P:002F P:606F 068286            DO      #<TIMEOUT,TIM_OUT
                        00003B
230       P:0031 P:6071 222E00            MOVE              R1,A
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:29  utilboot1.asm  Page 5



231       P:0032 P:6072 224400            MOVE              R2,X0
232       P:0033 P:6073 200044            SUB     X0,A
233       P:0034 P:6074 0E1037            JGE     <RCV_L1                           ; X1 = Destination mask $00FF00
234       P:0035 P:6075 458E00            MOVE              X:<C32,X1               ; Correct for circular buffer
235       P:0036 P:6076 200060            ADD     X1,A                              ; No MOVE here - it isn't always executed
236       P:0037 P:6077 460255  RCV_L1    CMP     Y0,A      Y0,X:<NWORDS
237       P:0038 P:6078 0E903B            JLT     <RCV_L2
238       P:0039 P:6079 00008C            ENDDO
239       P:003A P:607A 0C003D            JMP     <MV_COM
240       P:003B P:607B 000000  RCV_L2    NOP
241                             TIM_OUT
242       P:003C P:607C 0C0028            JMP     <RCV_SKP                          ; Increment R2 and BAD_HDR
243    
244                             ; We've got the complete SCI command, so put it on the COM_BUF stack
245       P:003D P:607D 060200  MV_COM    DO      X:<NWORDS,SCI_WR
                        000040
246       P:003F P:607F 56DA00            MOVE              X:(R2)+,A               ; R2 = SCI address
247       P:0040 P:6080 565B00            MOVE              A,X:(R3)+               ; R3 = command buffer address
248                             SCI_WR
249    
250                             ; Test the command stack too
251       P:0041 P:6081 226E00  TST_COM   MOVE              R3,A                    ; Pointer to current contents of receiver
252       P:0042 P:6082 228400            MOVE              R4,X0                   ; Pointer to processed contents
253       P:0043 P:6083 469B45            CMP     X0,A      X:<DMASK,Y0             ; Are they equal? Get destination mask
254       P:0044 P:6084 0EA018            JEQ     <START                            ; Go back to the top
255    
256                             ;  Process the receiver entry - is its destination number = D_BRD_ID?
257       P:0045 P:6085 56E400            MOVE              X:(R4),A                ; Get the header ID
258       P:0046 P:6086 560300            MOVE              A,X:<HDR_ID             ; Store it for later use
259       P:0047 P:6087 469A56            AND     Y0,A      X:<DBRDID,Y0            ; Extract destination byte only; Store ID
260       P:0048 P:6088 200055            CMP     Y0,A                              ; = destination number?
261       P:0049 P:6089 0EA052            JEQ     <COMMAND                          ; It's a command for this board
262       P:004A P:608A 0E7064            JGT     <ERROR                            ; Destination byte > #DBRDID, so error
263    
264                             ;  Transmit command over SCI
265       P:004B P:608B 226E00  XMT_CHK   MOVE              R3,A
266       P:004C P:608C 228400            MOVE              R4,X0
267       P:004D P:608D 200045            CMP     X0,A                              ; R4 is incremented by SCI_XMT
268       P:004E P:608E 0EA018            JEQ     <START                            ; We're all done, so start processing anew
269       P:004F P:608F 0BB1A0            JSSET   #0,X:SSR,SCI_XMT                  ; If SCI XMT register is empty, transmit byte
                        000086
270       P:0051 P:6091 0C004B            JMP     <XMT_CHK                          ; Keep looping
271    
272                             ;  Process the command - is it in the command table ?
273       P:0052 P:6092 205C00  COMMAND   MOVE              (R4)+                   ; Increment over the header ID
274       P:0053 P:6093 56DC00            MOVE              X:(R4)+,A               ; Get the command buffer entry
275       P:0054 P:6094 30C000            MOVE              #<COM_TBL,R0            ; Get command table address
276       P:0055 P:6095 061880            DO      #NUM_COM,END_COM                  ; Loop over command table
                        00005C
277       P:0057 P:6097 44D800            MOVE              X:(R0)+,X0              ; Get the command table entry
278       P:0058 P:6098 65E045            CMP     X0,A      X:(R0),R5               ; Are the receiver and table entries the same?
279       P:0059 P:6099 0E205C            JNE     <NOT_COM                          ; No, keep looping
280       P:005A P:609A 00008C            ENDDO                                     ; Restore the DO loop system registers
281       P:005B P:609B 0AE580            JMP     (R5)                              ; Jump execution to the command
282       P:005C P:609C 205800  NOT_COM   MOVE              (R0)+                   ; Increment the register past the table address
283                             END_COM
284    
285                             ;  Step over the remaining words in the command if there's an error
286       P:005D P:609D 568200            MOVE              X:<NWORDS,A
287       P:005E P:609E 448D00            MOVE              X:<TWO,X0
288       P:005F P:609F 200044            SUB     X0,A                              ; Header ID and command have been processed
289       P:0060 P:60A0 0EA064            JEQ     <ERROR
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:29  utilboot1.asm  Page 6



290       P:0061 P:60A1 06CE00            DO      A,INCR_R4
                        000063
291       P:0063 P:60A3 205C00            MOVE              (R4)+                   ; Increment over unprocessed part of comamnd
292                             INCR_R4
293    
294       P:0064 P:60A4 44A100  ERROR     MOVE              X:<ERR,X0               ; Send the message - there was an error
295       P:0065 P:60A5 0C0067            JMP     <FINISH1                          ; This protects against unknown commands
296    
297                             ; Command execution is nearly over - generate header ID and message.
298       P:0066 P:60A6 44A200  FINISH    MOVE              X:<DON,X0               ; Send a DONE message as a reply
299       P:0067 P:60A7 568300  FINISH1   MOVE              X:<HDR_ID,A             ; Get header of incoming command
300       P:0068 P:60A8 469C00            MOVE              X:<SMASK,Y0             ; This was the source byte, and is to
301       P:0069 P:60A9 468D56            AND     Y0,A      X:<TWO,Y0               ;   become the destination byte
302       P:006A P:60AA 0608A0            REP     #8                                ; Shift right one byte, add it to the
303       P:006B P:60AB 460223            LSR     A         Y0,X:<NWORDS            ;     header, and put 2 as the number
304       P:006C P:60AC 469950            ADD     Y0,A      X:<SBRDID,Y0            ;  of words in the string
305       P:006D P:60AD 200050            ADD     Y0,A
306       P:006E P:60AE 565B00            MOVE              A,X:(R3)+               ; Put header ID on the transmitter stack
307       P:006F P:60AF 445B00            MOVE              X0,X:(R3)+              ; Put value of X0 on the transmitter stack
308       P:0070 P:60B0 0C004B            JMP     <XMT_CHK                          ; Go transmit
309    
310                             ;  This ISR receives serial words a byte at a time over the asynchronous
311                             ;    serial link (SCI) and squashes them into a single 24-bit word
312       P:0071 P:60B1 050439  SCI_RCV   MOVEC             SR,X:<SAVE_SR           ; Save Status Register
313       P:0072 P:60B2 540600            MOVE              A1,X:<SAVE_A1           ; Save A1
314       P:0073 P:60B3 450500            MOVE              X1,X:<SAVE_X1           ; Save X1
315       P:0074 P:60B4 548A00            MOVE              X:<SRX_A1,A1            ; Get SRX value of accumulator contents
316       P:0075 P:60B5 45E700            MOVE              X:(R7),X1               ; Get the SCI byte
317       P:0076 P:60B6 0AD741            BCLR    #1,R7                             ; Test for the address being $FFF6 = last byte
318       P:0077 P:60B7 205F62            OR      X1,A      (R7)+                   ; Add the byte into the 24-bit word
319       P:0078 P:60B8 0E007C            JCC     <MID_BYT                          ; Not the last byte => only restore registers
320       P:0079 P:60B9 545900  END_BYT   MOVE              A1,X:(R1)+              ; Put the 24-bit word into the SCI buffer
321       P:007A P:60BA 678900            MOVE              X:<SRX_FST,R7           ; Restablish first address of SCI interface
322       P:007B P:60BB 2C0000            MOVE              #0,A1                   ; For zeroing out SRX_A1
323       P:007C P:60BC 540A00  MID_BYT   MOVE              A1,X:<SRX_A1            ; Save A1 for next interrupt
324       P:007D P:60BD 058439            MOVEC             X:<SAVE_SR,SR           ; Restore Status Register
325       P:007E P:60BE 548600            MOVE              X:<SAVE_A1,A1           ; Restore A1
326       P:007F P:60BF 458500            MOVE              X:<SAVE_X1,X1           ; Restore X1
327       P:0080 P:60C0 000004            RTI                                       ; Return from interrupt service
328    
329                             ; Clear error condition and interrupt on SCI receiver
330       P:0081 P:60C1 0870B1  CLR_ERR   MOVEP             X:SSR,X:RCV_ERR         ; Read SCI status register
                        000007
331       P:0083 P:60C3 0870B4            MOVEP             X:SRX,X:RCV_ERR         ; This clears any error
                        000007
332       P:0085 P:60C5 000004            RTI
333    
334                             ; Transmit 24-bit words over the SCI serial link to the timing board
335                             ;   Accumulator A does not have to be saved and restored because XMT_CHK
336                             ;   sets each each time it is needed.
337       P:0086 P:60C6 608800  SCI_XMT   MOVE              X:<STX_ADR,R0           ; Restore the starting address of the SCI
338       P:0087 P:60C7 56E400            MOVE              X:(R4),A
339       P:0088 P:60C8 566000            MOVE              A,X:(R0)                ; Transmit buffer
340       P:0089 P:60C9 0AD041            BCLR    #1,R0                             ; Test for last SCI address = $FFF6
341       P:008A P:60CA 0E808E            JCS     <DON_XMT                          ; If address = $FFF6 clean up
342       P:008B P:60CB 205800            MOVE              (R0)+
343       P:008C P:60CC 600800            MOVE              R0,X:<STX_ADR           ; Restore the starting address of the SCI
344       P:008D P:60CD 00000C            RTS
345                             ;  We're done tranmitting the three bytes of each 24-bit DSP word.
346       P:008E P:60CE 205C00  DON_XMT   MOVE              (R4)+
347       P:008F P:60CF 600800            MOVE              R0,X:<STX_ADR           ; Restore starting address of SCI = $FFF4
348       P:0090 P:60D0 00000C            RTS
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:29  utilboot1.asm  Page 7



349                             ; Write to EEPROM needs to execute from DSP memory rather than EEPROM memory
350                             ;   because EEPROM reads are disabled during the EEPROM write time.
351       P:0091 P:60D1 0AD52E  WRROM     JSET    #14,R5,ERROR                      ; Write protect BOOTROM code
                        000064
352       P:0093 P:60D3 076586            MOVE              Y0,P:(R5)               ; Write to Program memory
353       P:0094 P:60D4 061800            DO      X:<C50000,LP_WRR
                        000096
354       P:0096 P:60D6 094E37            MOVEP             Y:WATCH,A               ; Delay 10 millisec for EEPROM write
355                             LP_WRR
356       P:0097 P:60D7 0C0066            JMP     <FINISH
357    
358                             ; Check for overflow
359                                       IF      @CVS(N,*)>APL_ADR
361                                       ENDIF                                     ;  will not be overwritten
362    
363                             ;  Specify the memory location where the application program is to be loaded
364       P:0098 P:60D8                   ORG     P:APL_ADR,P:APL_ADR+P_OFF
365    
366                             ; Define TIMER as a simple jump addresses so the "bootrom" program
367                             ;   can work until the application program can be loaded
368       P:0098 P:60D8 00000C  SERVICE   RTS                                       ; Just return from subroutine call
369       P:0099 P:60D9 000004  TIMER     RTI                                       ; Just return from interrupt
370    
371    
372                             ;  This is the start of an overlay area. Its not actually an overlay because
373                             ;    code is executed from EEPROM directly, but we call it an overlay
374                             ;    because its similar code to the timing and VME boards that are overlays.
375    
376       P:6200 P:6200                   ORG     P:OVL_ADR,P:OVL_ADR
377    
378                             ; Test Data Link - simply return value received after 'TDL'
379       P:6200 P:6200 44DC00  TDL       MOVE              X:(R4)+,X0              ; Get data value
380       P:6201 P:6201 0C0067            JMP     <FINISH1                          ; Return from executing TDL command
381    
382                             ; Its a read from DSP memory - get the data and send it over the link
383       P:6202 P:6202 60E400  RDMEM     MOVE              X:(R4),R0               ; Need the address in an address register
384       P:6203 P:6203 44DC00            MOVE              X:(R4)+,X0              ; Need address also in a 24-bit register
385       P:6204 P:6204 0AC414            JCLR    #20,X0,RDX                        ; Test address bit for Program memory
                        006208
386       P:6206 P:6206 07E084            MOVE              P:(R0),X0               ; Read from Program memory
387       P:6207 P:6207 0C0067            JMP     <FINISH1                          ; Send out a header ID with the value
388       P:6208 P:6208 0AC415  RDX       JCLR    #21,X0,RDY                        ; Test address bit for X: memory
                        00620C
389       P:620A P:620A 44E000            MOVE              X:(R0),X0               ; Write to X data memory
390       P:620B P:620B 0C0067            JMP     <FINISH1                          ; Send out a header ID with the value
391       P:620C P:620C 0AC416  RDY       JCLR    #22,X0,ERROR                      ; Test address bit for Y: memory
                        000064
392       P:620E P:620E 4CE000            MOVE                          Y:(R0),X0   ; Read from Y data memory
393       P:620F P:620F 0C0067            JMP     <FINISH1                          ; Send out a header ID with the value
394    
395                             ; Program WRMEM - ('WRM' address datum), write to memory.
396       P:6210 P:6210 65E400  WRMEM     MOVE              X:(R4),R5               ; Get the desired address
397       P:6211 P:6211 44DC00            MOVE              X:(R4)+,X0              ; We need a 24-bit version of the address
398       P:6212 P:6212 46DC00            MOVE              X:(R4)+,Y0              ; Get datum into X0 so MOVE works easily
399       P:6213 P:6213 0AC414            JCLR    #20,X0,WRX                        ; Test address bit for Program memory
                        00621D
400       P:6215 P:6215 22A400            MOVE              R5,X0                   ; We need the 16-bit address in a data register
401       P:6216 P:6216 568F00            MOVE              X:<C512,A
402       P:6217 P:6217 200045            CMP     X0,A
403       P:6218 P:6218 0EF091            JLE     <WRROM                            ; Write to EEPROM if P: address >= $200
404       P:6219 P:6219 0AD52E  WRP       JSET    #14,R5,ERROR                      ; Write protect BOOTROM code
                        000064
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:29  utilboot1.asm  Page 8



405       P:621B P:621B 076586            MOVE              Y0,P:(R5)               ; Write to Program memory
406       P:621C P:621C 0C0066            JMP     <FINISH
407       P:621D P:621D 0AC415  WRX       JCLR    #21,X0,WRY                        ; Test address bit for X: memory
                        006221
408       P:621F P:621F 466500            MOVE              Y0,X:(R5)               ; Write to X: memory
409       P:6220 P:6220 0C0066            JMP     <FINISH
410       P:6221 P:6221 0AC416  WRY       JCLR    #22,X0,ERROR                      ; Test address bit for Y: memory
                        000064
411       P:6223 P:6223 4E6500            MOVE                          Y0,Y:(R5)   ; Write to Y: memory
412       P:6224 P:6224 0C0066            JMP     <FINISH
413    
414                             ;  Read EEPROM code into DSP locations starting at P:APL_ADR
415       P:6225 P:6225 0003F8  LDA       ORI     #$03,MR                           ; Temporarily mask interrupts
416       P:6226 P:6226 44DC00            MOVE              X:(R4)+,X0              ; Number of application program
417       P:6227 P:6227 568B00            MOVE              X:<ZERO,A
418       P:6228 P:6228 469545            CMP     X0,A      X:<C300,Y0
419       P:6229 P:6229 0AF0AA            JEQ     LDA_0                             ; Application #0 is a special case
                        006235
420       P:622B P:622B 458BD0            MPY     X0,Y0,A   X:<ZERO,X1
421       P:622C P:622C 449122            ASR     A         X:<C1D00,X0
422       P:622D P:622D 359820            ADD     X,A       #APL_ADR,R5
423       P:622E P:622E 211000            MOVE              A0,R0                   ; EEPROM address = # x $300 + $1D00
424       P:622F P:622F 066881            DO      #$200-APL_ADR,LD_LA0              ;  Thus  ( 1 <= # <= 10 )
                        006232
425       P:6231 P:6231 07D88E            MOVE              P:(R0)+,A               ; Read from EEPROM
426       P:6232 P:6232 075D8E            MOVE              A,P:(R5)+               ; Write to DSP
427                             LD_LA0
428    
429       P:6233 P:6233 0AF080            JMP     LD_X                              ; Keep R0 value
                        006240
430    
431                             ; Special case - application #0 can overfill from DSP to EEPROM memory
432       P:6235 P:6235 309800  LDA_0     MOVE              #APL_ADR,R0
433       P:6236 P:6236 066881            DO      #$200-APL_ADR,LD_LA1
                        00623D
434       P:6238 P:6238 0503BA            MOVE              #3,OMR                  ; Development mode - enable EEPROM memory
435       P:6239 P:6239 000000            NOP
436       P:623A P:623A 07E08E            MOVE              P:(R0),A                ; Read from EEPROM
437       P:623B P:623B 0502BA            MOVE              #2,OMR                  ; Normal mode - enable DSP P: memory
438       P:623C P:623C 000000            NOP
439       P:623D P:623D 07588E            MOVE              A,P:(R0)+               ; Write to DSP
440                             LD_LA1
441       P:623E P:623E 60F400            MOVE              #APL_XY,R0
                        001EE0
442       P:6240 P:6240 35C000  LD_X      MOVE              #COM_TBL,R5
443       P:6241 P:6241 062080            DO      #32,LD_LA2                        ; 16 application commands
                        006244
444       P:6243 P:6243 07D88E            MOVE              P:(R0)+,A
445       P:6244 P:6244 565D00            MOVE              A,X:(R5)+
446                             LD_LA2
447       P:6245 P:6245 350000            MOVE              #0,R5                   ; Start at bottom of Y: memory
448       P:6246 P:6246 060081            DO      #$100,LD_LA3                      ; Read from EEPROM and write
                        006249
449       P:6248 P:6248 07D88E            MOVE              P:(R0)+,A               ;   them to Y: memory
450       P:6249 P:6249 5E5D00            MOVE                          A,Y:(R5)+
451                             LD_LA3
452       P:624A P:624A 00FCB8            ANDI    #$FC,MR                           ; Unmask interrupts
453       P:624B P:624B 0C0066            JMP     <FINISH                           ; Send 'DON' message
454    
455                             ; Reset = Reboot
456       P:624C P:624C 000084  RESET     RESET                                     ; Reset I/O peripherals
457       P:624D P:624D 059720            MOVE              X:<CFFFF,M0             ; Insure that its linear addressing
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:29  utilboot1.asm  Page 9



458       P:624E P:624E 059721            MOVE              X:<CFFFF,M1             ;   for the INIT code
459       P:624F P:624F 08F0BF            MOVEP             X:ZERO,X:IPR            ; Clear Interrupt Priority Register
                        00000B
460       P:6251 P:6251 08F0BE            MOVEP             X:CFFFF,X:BCR           ; Many Wait States for PROM accesses
                        000017
461       P:6253 P:6253 058B3B            MOVEC             X:<ZERO,SP              ; Clear the stack pointer
462       P:6254 P:6254 059539            MOVEC             X:<C300,SR              ; Clear the Condition Code Register
463       P:6255 P:6255 0502BA            MOVEC             #$02,OMR                ; Operating Mode Register = Reboot
464       P:6256 P:6256 000000            NOP                                       ; Allow one cycle delay for the remapping
465       P:6257 P:6257 0AF080            JMP     INIT                              ; Re-initialize from EEPROM
                        006004
466    
467                             ; Parameter definitions in X: memory space
468       X:0000 P:6100                   ORG     X:0,P:X_OFF
469       X:0000 P:6100         STATUS    DC      0                                 ; Status word
470       X:0001 P:6101         OPTIONS   DC      0                                 ; Software options
471       X:0002 P:6102         NWORDS    DC      0                                 ; Number of words in destination command packet
472       X:0003 P:6103         HDR_ID    DC      0                                 ; 24-bit header containing board ID's
473    
474                             ; Places for saving register values
475       X:0004 P:6104         SAVE_SR   DC      0                                 ; Status Register
476       X:0005 P:6105         SAVE_X1   DC      0
477       X:0006 P:6106         SAVE_A1   DC      0
478       X:0007 P:6107         RCV_ERR   DC      0
479       X:0008 P:6108         STX_ADR   DC      $FFF4                             ; Current SCI XMT byte address ($FFF4, 5 or 6)
480       X:0009 P:6109         SRX_FST   DC      $FFF4                             ; Current SCI RCV byte address ($FFF4, 5 or 6)
481       X:000A P:610A         SRX_A1    DC      0                                 ; Contents of accumulator A1 in RCV ISR
482    
483                             ;  Constant definitions, useful for saving program memory space
484       X:000B P:610B         ZERO      DC      0
485       X:000C P:610C         ONE       DC      1
486       X:000D P:610D         TWO       DC      2
487       X:000E P:610E         C32       DC      32
488       X:000F P:610F         C512      DC      512                               ; Boundary between DSP and EEPROM P: memory
489       X:0010 P:6110         C4K       DC      4096                              ; Maximum size of application program
490       X:0011 P:6111         C1D00     DC      $1D00                             ; Offset for loading application programs
491       X:0012 P:6112         MASK1     DC      $FCFCF8                           ; Mask for checking header ID
492       X:0013 P:6113         MASK2     DC      $030300                           ; Mask for checking header ID
493       X:0014 P:6114         CFFF      DC      $FFF                              ; Mask for 12-bit A/D converter
494       X:0015 P:6115         C300      DC      $300                              ; Constant for resetting the DSP
495       X:0016 P:6116         C600      DC      $600                              ; Constant for loading application programs
496       X:0017 P:6117         CFFFF     DC      $FFFF                             ; Constant for resetting the DSP
497       X:0018 P:6118         C50000    DC      50000                             ; 5 millisec delay for +/- 15v settling
498       X:0019 P:6119         SBRDID    DC      $030000                           ; Source Identification number
499       X:001A P:611A         DBRDID    DC      $000300                           ; Destination Identification number
500       X:001B P:611B         DMASK     DC      $00FF00                           ; Mask to get destination board number out
501       X:001C P:611C         SMASK     DC      $FF0000                           ; Mask to get source board number out
502       X:001D P:611D         HOST      DC      $030002                           ; Header ID to host computer
503       X:001E P:611E         VME       DC      $030102                           ; Header ID to VMEINF board
504       X:001F P:611F         TIMING    DC      $030202                           ; Header ID to timing board
505       X:0020 P:6120         UTIL      DC      $030302                           ; Header ID to utility board
506       X:0021 P:6121         ERR       DC      'ERR'                             ; For sending error messages
507       X:0022 P:6122         DON       DC      'DON'                             ; For sending completion messages
508       X:0023 P:6123         RST       DC      'RST'                             ; Reply to host after board is reset
509    
510                             ; Miscellaneous
511       X:0024 P:6124         L_ADDR    DC      $200                              ; Last address written to EEPROM
512       X:0025 P:6125         AD_MASK   DC      $FFFFC0                           ; Mask for A6 - A15
513       X:0026 P:6126         BAD_HDR   DC      0                                 ; NUmber of bad headers
514    
515                             ;  The last part of the command table is not defined for "bootrom"
516                             ;  Command table resident in X: data memory; 32 entries maximum
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:29  utilboot1.asm  Page 10



517       X:00C0 P:61C0                   ORG     X:COM_TBL,P:COM_TBL+X_OFF
518       X:00C0 P:61C0                   DC      0,START,0,START,0,START,0,START   ; This is where application
519       X:00C8 P:61C8                   DC      0,START,0,START,0,START,0,START   ;    commands go
520       X:00D0 P:61D0                   DC      0,START,0,START,0,START,0,START
521       X:00D8 P:61D8                   DC      0,START,0,START,0,START,0,START
522       X:00E0 P:61E0                   DC      'TDL',TDL                         ; Test Data Link
523       X:00E2 P:61E2                   DC      'RDM',RDMEM                       ; Read DSP or EEPROM memory
524       X:00E4 P:61E4                   DC      'WRM',WRMEM                       ; Write DSP or EEPROM memory
525       X:00E6 P:61E6                   DC      'LDA',LDA                         ; Load application program from EEPROM
526       X:00E8 P:61E8                   DC      'RST',RESET                       ; Reboot DSP from on-board EEPROM
527       X:00EA P:61EA                   DC      'ERR',START                       ; Do nothing
528       X:00EC P:61EC                   DC      0,START,0,START
529    
530                             ; End of program
531                                       END

0    Errors
0    Warnings


