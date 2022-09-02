Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 1



1                               COMMENT *
2      
3                        This file is used to generate boot DSP code for the timing board.
4                            This is Rev. 2.31 software.
5      
6                                *
7                                  PAGE    132                               ; Printronix page width - 132 columns
8      
9                        ;  Define some useful DSP register locations
10        000000         RST_ISR   EQU     $00                               ; Hardware reset interrupt
11        000006         ROM_ID    EQU     $06                               ; Location of program Identification = SWI interrupt
12        00000C         SSI_ISR   EQU     $0C                               ; SSI serial receiver interrupt address
13        00000E         SSI_ERR   EQU     $0E                               ; SSI interrupt with exception (error)
14        000014         SCI_ISR   EQU     $14                               ; SCI serial receiver interrupt address
15        000016         SCI_ERR   EQU     $16                               ; SCI interrupt with exception (error)
16        000018         START     EQU     $18                               ; Program starting address
17        000060         BUF_STR   EQU     $60                               ; Starting address of buffers in X:
18        000020         BUF_LEN   EQU     $20                               ; Length of each buffer
19        000060         SSI_BUF   EQU     BUF_STR                           ; Starting address of SSI buffer in X:
20        000080         SCI_BUF   EQU     SSI_BUF+BUF_LEN                   ; Starting address of SCI buffer in X:
21        0000A0         COM_BUF   EQU     SCI_BUF+BUF_LEN                   ; Starting address of command buffer in X:
22        0000C0         COM_TBL   EQU     COM_BUF+BUF_LEN                   ; Starting address of command table in X:
23        000018         NUM_COM   EQU     24                                ; Number of entries in command table
24        000457         TIMEOUT   EQU     1111                              ; Timeout for receiving complete command = 1 millisec
25        0000E8         APL_ADR   EQU     $E8                               ; Starting P: address of application program
26        000118         APL_LEN   EQU     $200-APL_ADR                      ; Maximum length of application program
27        004200         LD_X      EQU     $4200                             ; Assembler loads X: starting at this EEPROM address
28        004600         RD_X      EQU     $4600                             ; DSP reads X: from this EEPROM address
29        004300         LD_OVL    EQU     $4300                             ; Assembler loads P: overlay starting at this address
30        004000         ROM_OFF   EQU     $4000                             ; Boot program offset address in EEPROM
31     
32                       ;  Define DSP port addresses
33        00FFFE         BCR       EQU     $FFFE                             ; Bus (=Port A) Control Register -> Wait States
34        00FFE1         PCC       EQU     $FFE1                             ; Port C Control Register
35        00FFEC         CRA       EQU     $FFEC                             ; SSI Control Register A
36        00FFED         CRB       EQU     $FFED                             ; SSI Control Regsiter B
37        00FFEE         SSISR     EQU     $FFEE                             ; SSI Status Register
38        00FFEF         RCVR      EQU     $FFEF                             ; SSI Receive Register
39        00FFFF         IPR       EQU     $FFFF                             ; Interrupt Priority Register
40        00FFF0         SCR       EQU     $FFF0                             ; SCI Control Register
41        00FFF1         SSR       EQU     $FFF1                             ; SCI Status Register
42        00FFF2         SCCR      EQU     $FFF2                             ; SCI Clock Control Register
43        00FFF4         SRX       EQU     $FFF4                             ; SCI receive data register
44     
45                       ; Board status bits, defined at X:<STATUS = X:0
46        000000         IDLING    EQU     0                                 ; Set if in idle mode => clocking out
47        000001         IDLMODE   EQU     1                                 ; Set if need to idle after readout
48        000002         ST_ISR    EQU     2                                 ; Set if SSI, cleared if SCI
49        000003         DEBUG     EQU     3                                 ; Set if debug command
50        000007         ST_RAMP   EQU     7                                 ; Set if ramping DC bias supplies up
51     
52                       ;  After RESET jump to initialization code
53        P:0000 P:4000                   ORG     P:RST_ISR,P:RST_ISR+ROM_OFF
54     
55        P:0000 P:4000 0C00E9            JMP     <INIT                             ; Initialize DSP after hardware reset
56        P:0001 P:4001 000000            NOP
57     
58                              ;  Put the SSI interrupt service routine where the DSP56001 expects it
59        P:000C P:400C                   ORG     P:SSI_ISR,P:SSI_ISR+ROM_OFF
60        P:000C P:400C 0859AF            MOVEP             X:RCVR,X:(R1)+          ; Put the word in the SSI buffer
61        P:000D P:400D 000000            NOP
62     
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 2



63                              ;  The SSI interrupts to here when there is an error.
64        P:000E P:400E                   ORG     P:SSI_ERR,P:SSI_ERR+ROM_OFF
65        P:000E P:400E 0D009C            JSR     <CLR_SSI
66        P:000F P:400F 000000            NOP
67     
68                              ;  The SCI interrupts when it receives data from the utility board.
69        P:0014 P:4014                   ORG     P:SCI_ISR,P:SCI_ISR+ROM_OFF
70        P:0014 P:4014 0D0088            JSR     <SCI_RCV                          ; Jump to long interrupt service routine
71        P:0015 P:4015 000000            NOP
72     
73                              ;  The SCI interrupts to here when there is an error.
74        P:0016 P:4016                   ORG     P:SCI_ERR,P:SCI_ERR+ROM_OFF
75        P:0016 P:4016 0D00A1            JSR     <CLR_SCI
76        P:0017 P:4017 000000            NOP
77     
78                              ;  Put the ID words for this version of the ROM code. It is placed at
79                              ;   the address of the SWI = software interrupt, which we never use.
80        P:0006 P:4006                   ORG     P:ROM_ID,P:ROM_ID+ROM_OFF
81        P:0006 P:4006                   DC      $000000                           ; Institution
82                                                                                  ; Location
83                                                                                  ; Instrument
84        P:0007 P:4007                   DC      $023102                           ; Version 2.31, board #2 = timing
85     
86                              ;**************************************************************************
87                              ;                                                                         *
88                              ;    Permanent address register assignments                               *
89                              ;        R1 - Address of SSI receiver contents                            *
90                              ;        R2 - Address of SCI receiver contents                            *
91                              ;        R3 - Pointer to current top of command buffer                    *
92                              ;        R4 - Pointer to processed contents of command buffer             *
93                              ;        R5 - Temporary register for processing SSI and SCI contents      *
94                              ;        R6 - CCD clock driver address for CCD #0 = $FFB0                 *
95                              ;                It is also the A/D address of analog board #0            *
96                              ;                                                                         *
97                              ;    Other registers                                                      *
98                              ;        R0, R7 - Temporary registers used all over the place.            *
99                              ;        R5 - Can be used as a temporary register but is circular,        *
100                             ;               modulo 32.                                                *
101                             ;**************************************************************************
102    
103                             ;  Start the command interpreting code just above the ISRs
104       P:0018 P:4018                   ORG     P:START,P:START+ROM_OFF
105    
106                             ;  Test receiver contents - both SSI and SCI
107       P:0018 P:4018 0A00A0            JSET    #IDLING,X:STATUS,IDLE             ; See if we're idling
                        0000E8
108       P:001A P:401A 0D005C  L0        JSR     <RCV_TST                          ; Test to see if both receivers are empty
109       P:001B P:401B 0EA01A            JEQ     <L0                               ; If R1 and R2 are unchanged, keep trying
110    
111                             ;  Check header ID = (S,D,N) for self-consistency
112       P:001C P:401C 46E500  RCV_ID    MOVE              X:(R5),Y0               ; Get candidate header ID
113       P:001D P:401D 549700            MOVE              X:<MASK1,A1             ; Test for S.LE.3 and D.LE.3 and N.LE.7
114       P:001E P:401E 200056            AND     Y0,A
115       P:001F P:401F 0E2026            JNE     <RCV_SKP                          ; Test failed, skip over header ID
116       P:0020 P:4020 549800            MOVE              X:<MASK2,A1
117       P:0021 P:4021 200056            AND     Y0,A                              ; Test for S.NE.0 or D.NE.0
118       P:0022 P:4022 0EA026            JEQ     <RCV_SKP                          ; Test failed, skip over header ID
119       P:0023 P:4023 2C0700            MOVE              #7,A1
120       P:0024 P:4024 200056            AND     Y0,A                              ; Test for N.GE.1
121       P:0025 P:4025 0E2029            JNE     <RCV_PR                           ; Test suceeded - process command
122       P:0026 P:4026 205D00  RCV_SKP   MOVE              (R5)+                   ; Header ID is wrong - skip over it
123       P:0027 P:4027 0D0068            JSR     <R_PROC                           ; Update R#PROC
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 3



124       P:0028 P:4028 0C0018            JMP     <START                            ; Wait for the next command
125    
126                             ; Get all the words of the command before processing it
127       P:0029 P:4029 21C600  RCV_PR    MOVE              A,Y0                    ; Number of words in command header
128       P:002A P:402A 065784            DO      #TIMEOUT,TIM_OUT
                        000038
129       P:002C P:402C 222E00            MOVE              R1,A
130       P:002D P:402D 0A00A2            JSET    #ST_ISR,X:STATUS,RCV_WT1
                        000030
131       P:002F P:402F 224E00            MOVE              R2,A
132       P:0030 P:4030 200044  RCV_WT1   SUB     X0,A                              ; X0 = R#PROC from VME_TST or FO_TST
133       P:0031 P:4031 0E1034            JGE     <RCV_L1                           ; X1 = Destination mask $00FF00
134       P:0032 P:4032 459000            MOVE              X:<C32,X1               ; Correct for circular buffer
135       P:0033 P:4033 200060            ADD     X1,A                              ; No MOVE here - it isn't always executed
136       P:0034 P:4034 460355  RCV_L1    CMP     Y0,A      Y0,X:<NWORDS            ; Y0 = NWORDS from above
137       P:0035 P:4035 0E9038            JLT     <RCV_L2
138       P:0036 P:4036 00008C            ENDDO
139       P:0037 P:4037 0C003A            JMP     <MV_COM
140       P:0038 P:4038 000000  RCV_L2    NOP
141                             TIM_OUT
142       P:0039 P:4039 0C0026            JMP     <RCV_SKP                          ; Increment R5 and update R#PROC
143    
144                             ; We've got the complete command, so put it on the COM_BUF stack
145       P:003A P:403A 060300  MV_COM    DO      X:<NWORDS,SSI_WR
                        00003D
146       P:003C P:403C 56DD00            MOVE              X:(R5)+,A               ; R5 = R#PROC from RCV_TST
147       P:003D P:403D 565B00            MOVE              A,X:(R3)+
148                             SSI_WR
149       P:003E P:403E 0D0068            JSR     <R_PROC
150    
151                             ;  Process the receiver entry - is its destination number = D_BRD_ID?
152       P:003F P:403F 226E00  PRC_RCV   MOVE              R3,A                    ; Pointer to current contents of receiver
153       P:0040 P:4040 228400            MOVE              R4,X0                   ; Pointer to processed contents
154       P:0041 P:4041 459B45            CMP     X0,A      X:<DMASK,X1             ; Are they equal? Get destination mask
155       P:0042 P:4042 0EA018            JEQ     <START                            ; If unequal, there's a command to be processed
156       P:0043 P:4043 56E400            MOVE              X:(R4),A                ; Get the header ID
157       P:0044 P:4044 560200            MOVE              A,X:<HDR_ID             ; Save header ID
158       P:0045 P:4045 459A66            AND     X1,A      X:<DBRDID,X1            ; Extract destination byte only; Store ID
159       P:0046 P:4046 200065            CMP     X1,A                              ; ID = destination number?
160       P:0047 P:4047 0EA06E            JEQ     <COMMAND                          ; Yes, process it as a command
161       P:0048 P:4048 0E9054            JLT     <FFO_XMT                          ; Test to send to the fast fiber optic
162    
163                             ; Transmit words a byte at a time over the SCI to the Utility board
164       P:0049 P:4049 060300            DO      X:<NWORDS,DON_XMT                 ; Transmit NWORDS
                        000052
165       P:004B P:404B 609E00            MOVE              X:<SRXFST,R0            ; $FFF4 = SCI first byte address
166       P:004C P:404C 060380            DO      #3,SCI_SPT
                        000051
167       P:004E P:404E 0AB180  SCI_XMT   JCLR    #0,X:SSR,SCI_XMT                  ; Continue only if SCI XMT register is empty
                        00004E
168       P:0050 P:4050 45E400            MOVE              X:(R4),X1
169       P:0051 P:4051 455800            MOVE              X1,X:(R0)+              ; Write to SCI buffer, increment byte pointer
170                             SCI_SPT
171       P:0052 P:4052 205C00            MOVE              (R4)+                   ; Increment word pointer
172                             DON_XMT
173       P:0053 P:4053 0C0018            JMP     <START                            ; Check command continuation
174    
175                             ;  Transmit 24-bit words to the host computer three bytes at a time
176       P:0054 P:4054 060300  FFO_XMT   DO      X:<NWORDS,DON_FFO                 ; Transmit all the words in the command
                        00005A
177       P:0056 P:4056 061480            DO      #20,DLY_FFO                       ; Delay for the fast serial transmitter
                        000058
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 4



178       P:0058 P:4058 000000            NOP
179                             DLY_FFO
180       P:0059 P:4059 45DC00            MOVE              X:(R4)+,X1              ; Get each word
181       P:005A P:405A 4D6600            MOVE                          X1,Y:(R6)   ; And send it to the fast fiber optic
182                             DON_FFO
183       P:005B P:405B 0C0018            JMP     <START
184    
185                             ;  Test SSI and SCI receiver buffer contents
186       P:005C P:405C 448400  RCV_TST   MOVE              X:<R1PROC,X0            ; Get pointer to processed contents of buffer
187       P:005D P:405D 222E00            MOVE              R1,A                    ; Get current command buffer pointer
188       P:005E P:405E 209545            CMP     X0,A      X0,R5
189       P:005F P:405F 0EA062            JEQ     <SCI_TST
190       P:0060 P:4060 0A0022            BSET    #ST_ISR,X:<STATUS
191       P:0061 P:4061 00000C            RTS
192    
193       P:0062 P:4062 448500  SCI_TST   MOVE              X:<R2PROC,X0            ; Get pointer to processed contents of buffer
194       P:0063 P:4063 224E00            MOVE              R2,A                    ; Get current command buffer pointer
195       P:0064 P:4064 209545            CMP     X0,A      X0,R5
196       P:0065 P:4065 0EA067            JEQ     <SCI_RTS                          ; Process header ID if R# .NE. X:R#PROC
197       P:0066 P:4066 0A0002            BCLR    #ST_ISR,X:<STATUS
198       P:0067 P:4067 00000C  SCI_RTS   RTS
199    
200                             ; Update the pointer to the already processed comamnds
201       P:0068 P:4068 0A0082  R_PROC    JCLR    #ST_ISR,X:STATUS,SCI_L2           ; Does SSI or SCI have an entry?
                        00006C
202       P:006A P:406A 650400            MOVE              R5,X:<R1PROC            ; Update SSI pointer
203       P:006B P:406B 00000C            RTS
204       P:006C P:406C 650500  SCI_L2    MOVE              R5,X:<R2PROC            ; Update SCI pointer
205       P:006D P:406D 00000C            RTS
206    
207                             ;  Process the receiver entry - is it in the command table ?
208       P:006E P:406E 205C00  COMMAND   MOVE              (R4)+                   ; Increment over the header ID
209       P:006F P:406F 56DC00            MOVE              X:(R4)+,A               ; Get the command buffer entry
210       P:0070 P:4070 30C000            MOVE              #<COM_TBL,R0            ; Get command table starting address
211       P:0071 P:4071 061880            DO      #NUM_COM,END_COM                  ; Loop over command table
                        000078
212       P:0073 P:4073 45D800            MOVE              X:(R0)+,X1              ; Get the command table entry
213       P:0074 P:4074 67E065            CMP     X1,A      X:(R0),R7               ; Does receiver = table entries address?
214       P:0075 P:4075 0E2078            JNE     <NOT_COM                          ; No, keep looping
215       P:0076 P:4076 00008C            ENDDO                                     ; Restore the DO loop system registers
216       P:0077 P:4077 0AE780            JMP     (R7)                              ; Jump execution to the command
217       P:0078 P:4078 205800  NOT_COM   MOVE              (R0)+                   ; Increment the register past the table address
218                             END_COM
219    
220                             ;  It's not in the command table - send an error message
221       P:0079 P:4079 449F00  ERROR     MOVE              X:<ERR,X0               ; Send the message - there was an error
222       P:007A P:407A 0C007C            JMP     <FINISH1                          ; This protects against unknown commands
223    
224                             ; Send a reply packet - header ID and reply
225       P:007B P:407B 44A000  FINISH    MOVE              X:<DON,X0               ; Send a DONE message as a reply
226       P:007C P:407C 568200  FINISH1   MOVE              X:<HDR_ID,A             ; Get header of incoming command
227       P:007D P:407D 469C00            MOVE              X:<SMASK,Y0             ; This was the source byte, and is to
228       P:007E P:407E 468E56            AND     Y0,A      X:<TWO,Y0               ;    become the destination byte
229       P:007F P:407F 0608A0            REP     #8                                ; Shift right one byte, add it to the
230       P:0080 P:4080 460323            LSR     A         Y0,X:<NWORDS            ;     header, and put 2 as the number
231       P:0081 P:4081 469950            ADD     Y0,A      X:<SBRDID,Y0            ;  of words in the string
232       P:0082 P:4082 459B50            ADD     Y0,A      X:<DMASK,X1             ; Add source boards ID, set X1 for above
233       P:0083 P:4083 565B00            MOVE              A,X:(R3)+               ; Put header ID on the transmitter stack
234       P:0084 P:4084 445B00            MOVE              X0,X:(R3)+              ; Put value of XO on the transmitter stack
235       P:0085 P:4085 0C003F            JMP     <PRC_RCV                          ; Go get the next command
236    
237                             ; Test Data Link - simply return value received after 'TDL'
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 5



238       P:0086 P:4086 44DC00  TDL       MOVE              X:(R4)+,X0              ; Get data value
239       P:0087 P:4087 0C007C            JMP     <FINISH1                          ; Return from executing TDL command
240    
241                             ; Interrupt service routine for SCI serial link to utility board
242       P:0088 P:4088 050639  SCI_RCV   MOVEC             SR,X:<SAVE_SR           ; Save Status Register
243       P:0089 P:4089 600900            MOVE              R0,X:<SAVE_R0           ; Save R0
244       P:008A P:408A 550800            MOVE              B1,X:<SAVE_B1           ; Save B1
245       P:008B P:408B 450700            MOVE              X1,X:<SAVE_X1           ; Save X1
246       P:008C P:408C 608B00            MOVE              X:<SCI_R0,R0            ; Get previous value of SCI R0
247       P:008D P:408D 558A00            MOVE              X:<SCI_B1,B1            ; Get previous value of SCI B1
248       P:008E P:408E 45E000            MOVE              X:(R0),X1               ; Get the byte from the SCI
249       P:008F P:408F 0AD041            BCLR    #1,R0                             ; Test for the address being $FFF6 = last byte
250       P:0090 P:4090 20586A            OR      X1,B      (R0)+                   ; Add the byte into the 24-bit word
251       P:0091 P:4091 0E0095            JCC     <MID_BYT                          ; Not the last byte => only restore registers
252       P:0092 P:4092 555A00  END_BYT   MOVE              B1,X:(R2)+              ; Put the 24-bit word in the command buffer
253       P:0093 P:4093 609E00            MOVE              X:<SRXFST,R0            ; Initialize R0 to start of SCI
254       P:0094 P:4094 2D0000            MOVE              #0,B1                   ; Zero SCI_B1 for next SCI use
255       P:0095 P:4095 600B00  MID_BYT   MOVE              R0,X:<SCI_R0            ; Save SCI value of SCI address pointer
256       P:0096 P:4096 550A00            MOVE              B1,X:<SCI_B1            ; Save SCI_B1 for next SCI use
257       P:0097 P:4097 058639            MOVEC             X:<SAVE_SR,SR           ; Restore Status Register
258       P:0098 P:4098 608900            MOVE              X:<SAVE_R0,R0           ; Restore R0
259       P:0099 P:4099 558800            MOVE              X:<SAVE_B1,B1           ; Restore B1
260       P:009A P:409A 458700            MOVE              X:<SAVE_X1,X1           ; Restore X1
261       P:009B P:409B 000004            RTI                                       ; Return from interrupt service
262    
263                             ; Clear error condition and interrupt on SSI receiver
264       P:009C P:409C 0870AE  CLR_SSI   MOVEP             X:SSISR,X:RCV_ERR       ; Read SSI status register
                        000021
265       P:009E P:409E 0870AF            MOVEP             X:RCVR,X:RCV_ERR        ; Read receiver register to clear error
                        000021
266       P:00A0 P:40A0 000004            RTI
267    
268                             ; Clear error condition and interrupt on SSI receiver
269       P:00A1 P:40A1 0870B1  CLR_SCI   MOVEP             X:SSR,X:RCV_ERR         ; Read SCI status register
                        000021
270       P:00A3 P:40A3 0870B4            MOVEP             X:SRX,X:RCV_ERR         ; Read register to clear error
                        000021
271       P:00A5 P:40A5 000004            RTI
272    
273                             ; Overlay processing code - get the EEPROM address of routine
274       P:00A6 P:40A6 45F400  OVL_RDM   MOVE              #L_RDMEM,X1
                        004300
275       P:00A8 P:40A8 0C00B1            JMP     <OVL_LD
276       P:00A9 P:40A9 45F400  OVL_WRM   MOVE              #L_WRMEM,X1
                        00431D
277       P:00AB P:40AB 0C00B1            JMP     <OVL_LD
278       P:00AC P:40AC 45F400  OVL_LDA   MOVE              #L_LDA,X1
                        004341
279       P:00AE P:40AE 0C00B1            JMP     <OVL_LD
280       P:00AF P:40AF 45F400  OVL_RST   MOVE              #L_RST,X1
                        004365
281    
282                             ; Load overlay code from EEPROM to DSP memory
283       P:00B1 P:40B1 468F00  OVL_LD    MOVE              X:<THREE,Y0
284       P:00B2 P:40B2 2000E0            MPY     X1,Y0,A
285       P:00B3 P:40B3 67F422            ASR     A         #OVERLAY,R7
                        0000C0
286       P:00B5 P:40B5 0AC84F            BCLR    #15,A0
287       P:00B6 P:40B6 211000            MOVE              A0,R0                   ; R0 = address of routine*3 - $8000
288       P:00B7 P:40B7 062880            DO      #APL_ADR-OVERLAY,LD_OVL1          ; Maximum length of overlay
                        0000BF
289       P:00B9 P:40B9 060380            DO      #3,LD_OVL2                        ; Three bytes of ROM per instruction
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 6



                        0000BE
290       P:00BB P:40BB 07D88A            MOVE              P:(R0)+,A2              ; Read from EEPROM
291       P:00BC P:40BC 0608A0            REP     #8
292       P:00BD P:40BD 200022            ASR     A
293       P:00BE P:40BE 000000            NOP                                       ; DO loop restriction
294                             LD_OVL2
295       P:00BF P:40BF 075F8C            MOVE              A1,P:(R7)+              ; Write to DSP P: memory
296                             LD_OVL1
297                             OVERLAY                                             ; Overlays go here
298    
299                             ;  Specify the memory location where the readout program is to be loaded
300       P:00E8 P:40E8                   ORG     P:APL_ADR,P:APL_ADR+ROM_OFF
301    
302                             ; Define these as simple jump addresses so bootrom program is sure to work
303                             ;   until the application program can be loaded
304       P:00E8 P:40E8 0C007B  IDLE      JMP     <FINISH                           ; Reply and return
305    
306                             INIT                                                ; Must define this address for all cases
307    
308                             ;  Initialization of the DSP - system register, serial link, interrupts.
309                             ;    This is executed once on DSP boot from ROM, and is not incorporated
310                             ;    into any download code since its not needed.
311    
312       P:00E9 P:40E9 0582BA            MOVEC             #$82,OMR                ; Operating Mode Register = Normal
313                                                                                 ;    Expanded - set after reset by hwd.
314    
315       P:00EA P:40EA 08F4AC            MOVEP             #$6000,X:CRA            ; SSI programming - no prescaling,
                        006000
316                                                                                 ;   24 bits/word, on-demand communications,
317                                                                                 ;   no divide, max. rate clock = 5.11 MHz,
318    
319       P:00EC P:40EC 08F4AD            MOVEP             #$A830,X:CRB            ; SSI programming - OF0, OF1 don't apply;
                        00A830
320                                                                                 ;   SC0, SC1 are inputs, SC2 is output;
321                                                                                 ;   internal clock; word length frame sync;
322                                                                                 ;   asynchronous; continuous clock;
323                                                                                 ;   network mode to get on-demand;
324                                                                                 ;   RCV and its interrupts enabled;
325                                                                                 ;   TX and its interrrupts disabled.
326    
327       P:00EE P:40EE 08F4BF            MOVEP             #$B000,X:IPR            ; Set interrupt priorities
                        00B000
328                                                                                 ;   Host = IRQA = IRQB = 0
329                                                                                 ;   SCI = 1
330                                                                                 ;   SSI = 2 (highest)
331    
332       P:00F0 P:40F0 08F4B0            MOVEP             #$0B04,X:SCR            ; SCI programming: 11-bit asynchronous
                        000B04
333                                                                                 ;   protocol (1 start, 8 data, 1 even parity,
334                                                                                 ;   1 stop); LSB before MSB; enable receiver
335                                                                                 ;   and its interrupts; transmitter interrupts
336                                                                                 ;   disabled.
337    
338       P:00F2 P:40F2 08F4B2            MOVEP             #$0000,X:SCCR           ; SCI clock: maximum asynchronous
                        000000
339                                                                                 ;   data rate (312,500 kbits/sec); internal
340                                                                                 ;   clock.
341    
342       P:00F4 P:40F4 08F4A1            MOVEP             #$01FF,X:PCC            ; Port C are dedicated serial interface pins
                        0001FF
343                                                                                 ;   for the SSI and SCI.
344    
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 7



345                             ; Initialize X: data memory
346       P:00F6 P:40F6 60F400            MOVE              #RD_X,R0                ; Starting X: address in EEPROM
                        004600
347       P:00F8 P:40F8 310000            MOVE              #0,R1                   ; Put values starting at beginning of X:
348       P:00F9 P:40F9 060081            DO      #$100,X_MOVE                      ; Assume 256 = $100 values exist
                        000101
349       P:00FB P:40FB 060380            DO      #3,X_LOOP                         ; Reconstruct bytes to 24-bit words
                        000100
350       P:00FD P:40FD 07D88A            MOVE              P:(R0)+,A2              ; Get one byte from EEPROM
351       P:00FE P:40FE 0608A0            REP     #8
352       P:00FF P:40FF 200022            ASR     A                                 ; Shift right 8 bits
353       P:0100 P:4100 000000            NOP                                       ; DO loop restriction
354                             X_LOOP
355       P:0101 P:4101 545900            MOVE              A1,X:(R1)+              ; Write 24-bit words to X: memory
356                             X_MOVE
357    
358                             ; Initialize the permanent registers
359       P:0102 P:4102 316000            MOVE              #SSI_BUF,R1             ; Starting address of SSI buffer
360       P:0103 P:4103 328000            MOVE              #SCI_BUF,R2             ; Starting address of SCI buffer
361       P:0104 P:4104 33A000            MOVE              #COM_BUF,R3             ; Starting address of command buffer
362       P:0105 P:4105 610400            MOVE              R1,X:<R1PROC
363       P:0106 P:4106 620500            MOVE              R2,X:<R2PROC
364       P:0107 P:4107 227413            CLR     A         R3,R4
365       P:0108 P:4108 051FA1            MOVE              #31,M1                  ; All input buffers are circular, modulo 32
366       P:0109 P:4109 0462A1            MOVE              M1,M2
367       P:010A P:410A 0463A2            MOVE              M2,M3
368       P:010B P:410B 0464A3            MOVE              M3,M4
369       P:010C P:410C 0465A4            MOVE              M4,M5
370       P:010D P:410D 062080            DO      #32,ZERO_Y                        ; Zero all command buffers for debugging
                        000111
371       P:010F P:410F 565900            MOVE              A,X:(R1)+
372       P:0110 P:4110 565A00            MOVE              A,X:(R2)+
373       P:0111 P:4111 565B00            MOVE              A,X:(R3)+
374                             ZERO_Y
375       P:0112 P:4112 669D00            MOVE              X:<CCDSEL0,R6           ; Address of all CCD clocks and A/D #0
376    
377       P:0113 P:4113 56F400            MOVE              #$020002,A              ; Send $020002 'RST' reply to host computer
                        020002
378       P:0115 P:4115 565B00            MOVE              A,X:(R3)+
379       P:0116 P:4116 56F400            MOVE              #'RST',A
                        525354
380       P:0118 P:4118 565B00            MOVE              A,X:(R3)+
381       P:0119 P:4119 56F400            MOVE              #>2,A
                        000002
382       P:011B P:411B 560300            MOVE              A,X:<NWORDS
383    
384       P:011C P:411C 08F4BE            MOVEP             #$40,X:BCR              ; Wait states for P: access = EEPROM
                        000040
385       P:011E P:411E 00FCB8            ANDI    #$FC,MR                           ; Unmask all interrupts
386    
387                             ; Initialize all bias DACs to midrange = $80 benign values
388                             ;   Don't bother compresing this code too much since its
389                             ;   discarded after initialization
390       P:011F P:411F 44F400            MOVE              #$C00,X0
                        000C00
391       P:0121 P:4121 45F400            MOVE              #$040D80,X1
                        040D80
392       P:0123 P:4123 47F400            MOVE              #$1000,Y1               ; Isolate CCD number
                        001000
393       P:0125 P:4125 20001B            CLR     B                                 ; Initial value of CCD number
394       P:0126 P:4126 060880            DO      #8,SLOOP                          ; Loop over 8 analog boards for now
                        00012D
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 8



395       P:0128 P:4128 21EE00            MOVE              B,A
396       P:0129 P:4129 200042            OR      X0,A                              ; Add CCD number to register select
397       P:012A P:412A 566600            MOVE              A,X:(R6)
398       P:012B P:412B 21EE00            MOVE              B,A
399       P:012C P:412C 200062            OR      X1,A                              ; Add voltage to register select
400       P:012D P:412D 566678            ADD     Y1,B      A,X:(R6)                ; Write voltage, increment CCD number
401                             SLOOP
402    
403                             ; Put the video processor in a benign state
404       P:012E P:412E 56F400            MOVE              #$00F055,A              ; Select VP lines, set to $4D
                        00F055
405       P:0130 P:4130 566600            MOVE              A,X:(R6)
406    
407                             ;  All done with initialization code
408       P:0131 P:4131 0C003F            JMP     <PRC_RCV                          ; Go transmit 'RST' reply
409    
410                             ; Check for overflow
411                                       IF      @CVS(N,*)>$1FF
413                                       ENDIF                                     ;  will not be overwritten
414    
415                             ; Here begin the BOOT overlay programs
416                             ; Put them starting at address LD_OVL in EEPROM
417    
418       P:00C0 P:4300                   ORG     P:OVERLAY,P:LD_OVL
419       004300                L_RDMEM   SET     @LCV(L)                           ; Get load address for use in LD_OVL routine
420    
421                             ; Read DSP or EEPROM memory ('RDM' address): read memory, reply with value
422       P:00C0 P:4300 60E400  RDMEM     MOVE              X:(R4),R0               ; Need the address in an address register
423       P:00C1 P:4301 45DC00            MOVE              X:(R4)+,X1              ; Need address also in a 24-bit register
424       P:00C2 P:4302 0AC514            JCLR    #20,X1,RDX                        ; Test address bit for Program memory
                        0000CA
425       P:00C4 P:4304 220600            MOVE              R0,Y0                   ; We need the 16-bit address in a data register
426       P:00C5 P:4305 569100            MOVE              X:<C512,A
427       P:00C6 P:4306 458F55            CMP     Y0,A      X:<THREE,X1
428       P:00C7 P:4307 0EF0D2            JLE     <RDROM
429       P:00C8 P:4308 07E084            MOVE              P:(R0),X0               ; Read from Program memory
430       P:00C9 P:4309 0C007C            JMP     <FINISH1                          ; Send out a header ID with the value
431       P:00CA P:430A 0AC515  RDX       JCLR    #21,X1,RDY                        ; Test address bit for X: memory
                        0000CE
432       P:00CC P:430C 44E000            MOVE              X:(R0),X0               ; Write to X data memory
433       P:00CD P:430D 0C007C            JMP     <FINISH1                          ; Send out a header ID with the value
434       P:00CE P:430E 0AC516  RDY       JCLR    #22,X1,ERROR                      ; Test address bit for Y: memory
                        000079
435       P:00D0 P:4310 4CE000            MOVE                          Y:(R0),X0   ; Read from Y data memory
436       P:00D1 P:4311 0C007C            JMP     <FINISH1                          ; Send out a header ID with the value
437    
438                             ; Read from EEPROM. Read three bytes and concatenate them into
439                             ;   a 24-bit word before replying.
440       P:00D2 P:4312 2000E0  RDROM     MPY     X1,Y0,A                           ; Byte address = word address x 3
441       P:00D3 P:4313 200022            ASR     A                                 ; Eliminate zero fill of fractional multiply
442       P:00D4 P:4314 211000            MOVE              A0,R0                   ; Need to address P: memory
443       P:00D5 P:4315 060380            DO      #3,L1RDR
                        0000DA
444       P:00D7 P:4317 07D88A            MOVE              P:(R0)+,A2              ; Read each ROM byte
445       P:00D8 P:4318 0608A0            REP     #8
446       P:00D9 P:4319 200022            ASR     A                                 ; Move right into A1
447       P:00DA P:431A 000000            NOP
448                             L1RDR
449       P:00DB P:431B 218400            MOVE              A1,X0                   ; FINISH1 transmits X0 as its reply
450       P:00DC P:431C 0C007C            JMP     <FINISH1
451    
452                             ; Check that the overlay code is not too big
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 9



453                                       IF      @CVS(N,*)>APL_ADR
455                                       ENDIF                                     ;  will not be overwritten
456    
457    
458       P:00C0 P:431D                   ORG     P:OVERLAY,P:
459       00431D                L_WRMEM   SET     @LCV(L)                           ; Get load address for use in LD_OVL routine
460    
461                             ; Program WRMEM ('WRM' address datum): write to memory, reply 'DON'.
462       P:00C0 P:431D 60E400  WRMEM     MOVE              X:(R4),R0               ; Get the desired address
463       P:00C1 P:431E 45DC00            MOVE              X:(R4)+,X1              ; We need a 24-bit version of the address
464       P:00C2 P:431F 44DC00            MOVE              X:(R4)+,X0              ; Get datum into X0 so MOVE works easily
465       P:00C3 P:4320 0AC514            JCLR    #20,X1,WRX                        ; Test address bit for Program memory
                        0000CB
466       P:00C5 P:4322 220600            MOVE              R0,Y0                   ; We need the 16-bit address in a data register
467       P:00C6 P:4323 569100            MOVE              X:<C512,A
468       P:00C7 P:4324 458F55            CMP     Y0,A      X:<THREE,X1
469       P:00C8 P:4325 0EF0D3            JLE     <WRROM
470       P:00C9 P:4326 076084            MOVE              X0,P:(R0)               ; Write to Program memory
471       P:00CA P:4327 0C007B            JMP     <FINISH
472       P:00CB P:4328 0AC515  WRX       JCLR    #21,X1,WRY                        ; Test address bit for X: memory
                        0000CF
473       P:00CD P:432A 446000            MOVE              X0,X:(R0)               ; Write to X: memory
474       P:00CE P:432B 0C007B            JMP     <FINISH
475       P:00CF P:432C 0AC516  WRY       JCLR    #22,X1,ERROR                      ; Test address bit for Y: memory
                        000079
476       P:00D1 P:432E 4C6000            MOVE                          X0,Y:(R0)   ; Write to Y: memory
477       P:00D2 P:432F 0C007B            JMP     <FINISH
478    
479                             ; Write to ROM a byte at a time, delaying 10 milliseconds between each one
480       P:00D3 P:4330 2000E0  WRROM     MPY     X1,Y0,A                           ; Byte address = word address x 3
481       P:00D4 P:4331 200022            ASR     A                                 ; Eliminate zero fill of fractional multiply
482       P:00D5 P:4332 211000            MOVE              A0,R0                   ; Need to address P: memory
483       P:00D6 P:4333 0AD02E            JSET    #14,R0,ERROR                      ; Write protect BOOTROM code
                        000079
484       P:00D8 P:4335 208C00            MOVE              X0,A1                   ; Get data from command string
485       P:00D9 P:4336 060380            DO      #3,L1WRR                          ; Least significant bytes at lower addresses
                        0000E2
486       P:00DB P:4338 07588C            MOVEM             A1,P:(R0)+              ; Write least significant ROM byte
487       P:00DC P:4339 0608A0            REP     #8                                ; Not REP so its interrupteable
488       P:00DD P:433A 469622            ASR     A         X:<C50000,Y0            ; Move right one byte, enter delay
489       P:00DE P:433B 06C600            DO      Y0,L3WRR                          ; Delay by 10 milliseconds for EEPROM write
                        0000E1
490       P:00E0 P:433D 000000            NOP                                       ; Assume 20 MHz DSP56001
491       P:00E1 P:433E 000000            NOP
492                             L3WRR
493       P:00E2 P:433F 000000            NOP                                       ; DO loop nesting restriction
494                             L1WRR
495       P:00E3 P:4340 0C007B            JMP     <FINISH
496    
497                             ; Check that the overlay code is not too big
498                                       IF      @CVS(N,*)>APL_ADR
500                                       ENDIF                                     ;  will not be overwritten
501    
502    
503       P:00C0 P:4341                   ORG     P:OVERLAY,P:
504       004341                L_LDA     SET     @LCV(L)                           ; Get load address for use in LD_OVL routine
505    
506                             ;  Read EEPROM code into DSP memory starting at P:APL_ADR
507       P:00C0 P:4341 44DC00            MOVE              X:(R4)+,X0              ; Number of application program
508       P:00C1 P:4342 469300            MOVE              X:<C600,Y0
509       P:00C2 P:4343 458CD0            MPY     X0,Y0,A   X:<ZERO,X1
510       P:00C3 P:4344 449222            ASR     A         X:<C300,X0
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 10



511       P:00C4 P:4345 37E824            SUB     X,A       #APL_ADR,R7
512       P:00C5 P:4346 211000            MOVE              A0,R0                   ; EEPROM address = # x $600 - $300
513       P:00C6 P:4347 061881            DO      #APL_LEN,LD_LA2                   ; Load from APL_ADR to $200
                        0000CE
514       P:00C8 P:4349 060380            DO      #3,LD_LA1
                        0000CD
515       P:00CA P:434B 07D88A            MOVE              P:(R0)+,A2              ; Read from EEPROM
516       P:00CB P:434C 0608A0            REP     #8
517       P:00CC P:434D 200022            ASR     A
518       P:00CD P:434E 000000            NOP                                       ; DO loop restriction
519                             LD_LA1
520       P:00CE P:434F 075F8C            MOVE              A1,P:(R7)+              ; Write to DSP P: memory
521                             LD_LA2
522    
523                             ;  Splice the application and boot command tables together
524       P:00CF P:4350 37C000            MOVE              #COM_TBL,R7             ; Leave most of X: memory alone
525       P:00D0 P:4351 062080            DO      #32,LD_LA4                        ; 16 commands, 2 entries per command
                        0000D8
526       P:00D2 P:4353 060380            DO      #3,LD_LA3
                        0000D7
527       P:00D4 P:4355 07D88A            MOVE              P:(R0)+,A2              ; Read from EEPROM
528       P:00D5 P:4356 0608A0            REP     #8
529       P:00D6 P:4357 200022            ASR     A
530       P:00D7 P:4358 000000            NOP                                       ; DO loop restriction
531                             LD_LA3
532       P:00D8 P:4359 545F00            MOVE              A1,X:(R7)+              ; Write to DSP X: memory
533                             LD_LA4
534    
535                             ;  Transfer Y: memory, containing waveforms and readout parameters
536       P:00D9 P:435A 370000            MOVE              #0,R7                   ; Start at bottom of Y: memory
537       P:00DA P:435B 06C880            DO      #$200-32-APL_LEN,LD_LA6           ; Update Y: DSP memory
                        0000E2
538       P:00DC P:435D 060380            DO      #3,LD_LA5
                        0000E1
539       P:00DE P:435F 07D88A            MOVE              P:(R0)+,A2              ; Read from EEPROM
540       P:00DF P:4360 0608A0            REP     #8
541       P:00E0 P:4361 200022            ASR     A
542       P:00E1 P:4362 000000            NOP                                       ; DO loop restriction
543                             LD_LA5
544       P:00E2 P:4363 5C5F00            MOVE                          A1,Y:(R7)+  ; Write to DSP Y: memory
545                             LD_LA6
546       P:00E3 P:4364 0C007B            JMP     <FINISH
547    
548                             ; Check that the overlay code is not too big
549                                       IF      @CVS(N,*)>APL_ADR
551                                       ENDIF                                     ;  will not be overwritten
552    
553    
554       P:00C0 P:4365                   ORG     P:OVERLAY,P:
555       004365                L_RST     SET     @LCV(L)                           ; Get load address for use in LD_OVL routine
556    
557                             ;  Reset = Reboot
558       P:00C0 P:4365 000084  RST       RESET                                     ; Reset SSI peripheral
559       P:00C1 P:4366 059520            MOVE              X:<CFFFF,M0             ; Insure that its linear addressing
560       P:00C2 P:4367 059521            MOVE              X:<CFFFF,M1
561       P:00C3 P:4368 08F0BF            MOVEP             X:ZERO,X:IPR            ; Clear Interrupt Priority Register
                        00000C
562       P:00C5 P:436A 08F0BE            MOVEP             X:CFFFF,X:BCR           ; Many Wait States for PROM accesses
                        000015
563       P:00C7 P:436C 058C3B            MOVEC             X:<ZERO,SP              ; Clear the stack pointer
564       P:00C8 P:436D 059239            MOVEC             X:<C300,SR              ; Clear the Condition Code Register
565       P:00C9 P:436E 0501BA            MOVEC             #$01,OMR                ; Operating Mode Register = Reboot
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 11



566       P:00CA P:436F 000000            NOP                                       ; Allow one cycle delay for the remapping
567       P:00CB P:4370 0C0000            JMP     <$0                               ; Begin bootstrap from internal ROM
568    
569                             ; Check that the overlay code is not too big
570                                       IF      @CVS(N,*)>APL_ADR
572                                       ENDIF                                     ;  will not be overwritten
573    
574                             ; End of overlay programs
575    
576                             ;  ********* Beginning of X: definitions ************
577    
578                             ; Status and header ID processing words
579       X:0000 X:4200                   ORG     X:0,X:LD_X
580       X:0000 X:4200         STATUS    DC      800000                            ; Status word AzCam
581       X:0001 X:4201         OPTIONS   DC      1                                 ; Software options
582       X:0002 X:4202         HDR_ID    DC      0                                 ; Header ID of all commands
583       X:0003 X:4203         NWORDS    DC      0                                 ; Number of words in command
584       X:0004 X:4204         R1PROC    DC      0                                 ; Last processed value of SSI pointer R1
585       X:0005 X:4205         R2PROC    DC      0                                 ; Last processed value of SCI pointer R2
586    
587                             ;  Definitions in SCI ISR
588       X:0006 X:4206         SAVE_SR   DC      0
589       X:0007 X:4207         SAVE_X1   DC      0
590       X:0008 X:4208         SAVE_B1   DC      0
591       X:0009 X:4209         SAVE_R0   DC      0
592       X:000A X:420A         SCI_B1    DC      0
593       X:000B X:420B         SCI_R0    DC      $FFF4                             ; Starting address of the SCI
594    
595                             ;  Miscellaneous constant definitions
596       X:000C X:420C         ZERO      DC      0
597       X:000D X:420D         ONE       DC      1
598       X:000E X:420E         TWO       DC      2
599       X:000F X:420F         THREE     DC      3
600       X:0010 X:4210         C32       DC      32                                ; To correct for circular buffer addressing
601       X:0011 X:4211         C512      DC      512                               ; To read/write EEPROM
602       X:0012 X:4212         C300      DC      $300                              ; Constant for resetting the DSP
603       X:0013 X:4213         C600      DC      $600                              ; EEPROM space per application program
604       X:0014 X:4214         C4000     DC      $4000                             ; Offset into EEPROM for "boot" overlays
605       X:0015 X:4215         CFFFF     DC      $FFFF                             ; Constant for resetting the DSP
606       X:0016 X:4216         C50000    DC      50000                             ; Delay for WRROM = 5 millisec
607       X:0017 X:4217         MASK1     DC      $FCFCF8                           ; Mask for checking header ID
608       X:0018 X:4218         MASK2     DC      $030300                           ; Mask for checking header ID
609       X:0019 X:4219         SBRDID    DC      $020000                           ; Source Identification number
610       X:001A X:421A         DBRDID    DC      $000200                           ; Destination Identification number
611       X:001B X:421B         DMASK     DC      $00FF00                           ; Mask to get destination board number out
612       X:001C X:421C         SMASK     DC      $FF0000                           ; Mask to get source board number out
613       X:001D X:421D         CCDSEL0   DC      $FFB0                             ; Select to update CCD clocks and CCD #0 A/D
614       X:001E X:421E         SRXFST    DC      $FFF4                             ; Starting address of SCI receiver
615       X:001F X:421F         ERR       DC      'ERR'                             ; An error occurred
616       X:0020 X:4220         DON       DC      'DON'                             ; Command was fully processed
617       X:0021 X:4221         RCV_ERR   DC      0                                 ; Dummy location for receiver clearing
618    
619                             ;  Command table resident in X: data memory
620                             ;  The last part of the command table is not defined for "bootrom"
621                             ;     because it contains application-specific commands
622    
623       X:00C0 X:42C0                   ORG     X:COM_TBL,X:COM_TBL+LD_X
624       X:00C0 X:42C0                   DC      0,START,0,START,0,START,0,START   ; This is where application
625       X:00C8 X:42C8                   DC      0,START,0,START,0,START,0,START   ;   commands go
626       X:00D0 X:42D0                   DC      0,START,0,START,0,START,0,START
627       X:00D8 X:42D8                   DC      0,START,0,START,0,START,0,START
628       X:00E0 X:42E0                   DC      'TDL',TDL                         ; Test Data Link
Motorola DSP56000 Assembler  Version 6.3.0   117-07-02  09:26:43  tim1_boot.asm  Page 12



629       X:00E2 X:42E2                   DC      'ERR',START                       ; Nothing special
630       X:00E4 X:42E4                   DC      'RDM',OVL_RDM                     ; Read from DSP memory - overlay
631       X:00E6 X:42E6                   DC      'WRM',OVL_WRM                     ; Write to DSP memory
632       X:00E8 X:42E8                   DC      'LDA',OVL_LDA                     ; Load progam from EEPROM to DSP
633       X:00EA X:42EA                   DC      'RST',OVL_RST                     ; Re-boot DSP from on-board ROM
634       X:00EC X:42EC                   DC      0,START,0,START                   ; Room for two more "boot" commands
635    
636                             ;  End of command table
637    
638    
639                             ;  End of program
640                                       END

0    Errors
0    Warnings


