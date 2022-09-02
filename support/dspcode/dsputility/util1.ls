Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:30  util1.asm  Page 1



1                               COMMENT *
2      
3                        This file is used to generate DSP code for the utility board. It will time
4                             the exposure, operate the shutter, control the CCD temperature and
5                             turn the analog power on. This is Rev. 2.31 software.
6      
7                        -d 1 1  To generate code for downloading to DSP memory.
8                        -d 1 0  To generate code for writing to the EEPROM.
9      
10                       Modified by MPL for AzCam and PCI interface 12-Feb-04
11     
12                       last change 20Aug04 MPL
13                               *
14                                 PAGE    132                               ; Printronix page width - 132 columns
15     
16                       ; Name it a section so it doesn't conflict with other application programs
17                                 SECTION UTILICE
18     
19                       ;  These are also defined in "utilboot.asm", so be sure they agree
20        000009         APL_NUM   EQU     9                                 ; Application number from 1 to 10
21        000098         APL_ADR   EQU     $98                               ; Starting address of application program
22        000080         BUF_STR   EQU     $80                               ; Starting address of buffers in X:
23        000020         BUF_LEN   EQU     $20                               ; Length of buffers
24        000080         SCI_BUF   EQU     BUF_STR                           ; Starting address of SCI buffer in X:
25        0000A0         COM_BUF   EQU     SCI_BUF+BUF_LEN                   ; Starting address of command buffer in X:
26        0000C0         COM_TBL   EQU     COM_BUF+BUF_LEN                   ; Starting address of command table in X:
27     
28                       ;  Define some useful constants
29        001EE0         APL_XY    EQU     $1EE0                             ; Starting address in EEPROM of X: and Y: values
30        000046         DLY_MUX   EQU     70                                ; Number of DSP cycles to delay for MUX settling
31        000064         DLY_AD    EQU     100                               ; Number of DSP cycles to delay for A/D settling
32     
33                       ; Assign addresses to port B data register
34        00FFE4         PBD       EQU     $FFE4                             ; Port B Data Register
35        00FFFF         IPR       EQU     $FFFF                             ; Interrupt Priority Register
36     
37                       ;  Addresses of memory mapped components in Y: data memory space
38                       ;  Write addresses first
39        00FFF0         WR_DIG    EQU     $FFF0                             ; was $FFFF  Write Digital output values D00-D15
40        00FFF1         WR_MUX    EQU     $FFF1                             ; Select MUX connected to A/D input - one of 16
41        00FFF2         EN_DIG    EQU     $FFF2                             ; Enable digital outputs
42        00FFF7         WR_DAC3   EQU     $FFF7                             ; Write to DAC#3 D00-D11
43        00FFF6         WR_DAC2   EQU     $FFF6                             ; Write to DAC#2 D00-D11
44        00FFF5         WR_DAC1   EQU     $FFF5                             ; Write to DAC#1 D00-D11
45        00FFF4         WR_DAC0   EQU     $FFF4                             ; Write to DAC#0 D00-D11
46     
47                       ;  Read addresses next
48        00FFF0         RD_DIG    EQU     $FFF0                             ; Read Digital input values D00-D15
49        00FFF1         STR_ADC   EQU     $FFF1                             ; Start ADC conversion, ignore data
50        00FFF2         RD_ADC    EQU     $FFF2                             ; Read A/D converter value D00-D11
51        00FFF7         WATCH     EQU     $FFF7                             ; Watch dog timer - tell it that DSP is alive
52     
53                       ;  Bit definitions of STATUS word
54        000000         ST_SRVC   EQU     0                                 ; Set if ADC routine needs executing
55        000001         ST_EX     EQU     1                                 ; Set if timed exposure is in progress
56        000002         ST_SH     EQU     2                                 ; Set if shutter is open
57        000003         ST_READ   EQU     3                                 ; Set if a readout needs to be initiated
58     
59                       ; Bit definitions of software OPTIONS word
60        000000         OPT_SH    EQU     0                                 ; Set to open and close shutter
61        000001         OPT_RDC   EQU     1                                 ; Set to readout CCD after expose
62     
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:30  util1.asm  Page 2



63                       ;  Bit definitions of Port B = Host Processor Interface
64        000000         HVEN      EQU     0                                 ; Enable high voltage PS (+36V nominal)- Output
65        000001         LVEN      EQU     1                                 ; Enable low voltage PS (+/-15 volt nominal) - Output
66        000002         PWRST     EQU     2                                 ; Reset power conditioner counter - Output
67        000003         SHUTTER   EQU     3                                 ; Control shutter - Output
68        000004         IRQ_T     EQU     4                                 ; Request interrupt service from timing board - Output
69        000005         SYS_RST   EQU     5                                 ; Reset entire system - Output
70        000008         WATCH_T   EQU     8                                 ; Processed watchdog signal from timing board - Input
71     
72                       ;**************************************************************************
73                       ;                                                                         *
74                       ;    Register assignments                                                 *
75                       ;        R1 - Address of SCI receiver contents                            *
76                       ;        R2 - Address of processed SCI receiver contents                  *
77                       ;        R3 - Pointer to current top of command buffer                    *
78                       ;        R4 - Pointer to processed contents of command buffer             *
79                       ;        N4 - Address for internal jumps after receiving 'DON' replies    *
80                       ;        R0, R5, R6, A, X0, X1 and Y0 - For use by program only           *
81                       ;        R7 - For use by SCI ISR only                                     *
82                       ;        B and Y1 - For use by timer ISR only                             *
83                       ;                                                                         *
84                       ;**************************************************************************
85     
86                       ;  Specify execution and load addresses
87                                 IF      1
88        P:0098 P:0098                   ORG     P:APL_ADR,P:APL_ADR               ; Download address
89                                        ELSE
91                                        ENDIF
92     
93                              ;  The TIMER addresses must be defined here and SERVICE must follow to match
94                              ;    up with the utilboot code
95        P:0098 P:0098 0C00B0            JMP     <SERVICE                          ; Millisecond timer interrupt
96     
97                              ;  The TIMER interrupt service routine (ISR) keeps track of exposure times
98        P:0099 P:0099 000004  TIMER     RTI                                       ; RTI for now so downloading works
99                              ;TIMER  MOVEC   SR,Y:<SV_SR             ; Save Status Register
100       P:009A P:009A 0A0081            JCLR    #ST_EX,X:STATUS,NO_TIM            ; Continue on if we're not exposing
                        0000A7
101       P:009C P:009C 578000            MOVE              X:<ONE,B                ; Constant to increment EL_TIM
102       P:009D P:009D 4F9700            MOVE                          Y:<EL_TIM,Y1 ; Get elapsed time
103       P:009E P:009E 4F9878            ADD     Y1,B                  Y:<TGT_TIM,Y1 ; Get Target time for code below
104       P:009F P:009F 5F1700            MOVE                          B,Y:<EL_TIM ; EL_TIM = EL_TIM + 1
105       P:00A0 P:00A0 20007C            SUB     Y1,B
106       P:00A1 P:00A1 0E90A7            JLT     <NO_TIM                           ; If (EL .GE. TGT) we've timed out
107       P:00A2 P:00A2 0A0023            BSET    #ST_READ,X:<STATUS                ; Set so a readout will be initiated
108    
109                             ;  Close the shutter at once if needed; return from interrupt
110       P:00A3 P:00A3 0A0080            JCLR    #OPT_SH,X:OPTIONS,NO_TIM          ; Close the shutter only if needed
                        0000A7
111       P:00A5 P:00A5 0AA403            BCLR    #SHUTTER,X:PBD                    ; Set Port B bit #3 to close shutter
112       P:00A6 P:00A6 0A0022            BSET    #ST_SH,X:<STATUS                  ; Set status to mean shutter closed
113                             NO_TIM
114       P:00A7 P:00A7 0A0020            BSET    #ST_SRVC,X:<STATUS                ; SERVICE needs executing
115       P:00A8 P:00A8 05B779            MOVEC                         Y:<SV_SR,SR ; Restore Status Register
116       P:00A9 P:00A9 000000            NOP
117       P:00AA P:00AA 000004            RTI                                       ; Return from TIMER interrupt
118    
119                             RDCCD
120                             ;       MOVE    X:<VME,B
121                             ;       MOVE    B,X:(R3)+               ; Header ID from Utility to VME
122                             ;       MOVE    Y:<RDC,B
123                             ;       MOVE    B,X:(R3)+               ; Put VMEINF board in readout mode
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:30  util1.asm  Page 3



124                             ;       MOVE    X:<TIMING,B
125                             ;       MOVE    B,X:(R3)+               ; Header ID from Utility to timing
126                             ;       MOVE    Y:<RDC,B
127                             ;       MOVE    B,X:(R3)+               ; Start reading out the CCD
128    
129                             ; for AzCam, this is the readout only, not CLR, shutter, or exposure timing
130       P:00AB P:00AB 578000            MOVE              X:<TIMING,B
131       P:00AC P:00AC 575B00            MOVE              B,X:(R3)+               ; Header ID from Utility to timing
132       P:00AD P:00AD 5FA900            MOVE                          Y:<RDC,B
133       P:00AE P:00AE 575B00            MOVE              B,X:(R3)+               ; Start reading out the CCD
134       P:00AF P:00AF 0C0000            JMP     <START
135    
136                             ; This long subroutine is executed every millisecond, but isn't an ISR so
137                             ;   that care need not be taken to preserve registers and stacks.
138                             SERVICE
139       P:00B0 P:00B0 0A0000            BCLR    #ST_SRVC,X:<STATUS                ; Clear request to execute SERVICE
140       P:00B1 P:00B1 0A0083            JCLR    #ST_READ,X:<STATUS,UPD_DIG        ; Initiate readout if timer done
                        0000BC
141       P:00B3 P:00B3 0A0081            JCLR    #OPT_RDC,X:<OPTIONS,NO_RDC        ; don't read as an option
                        0000B9
142       P:00B5 P:00B5 568000            MOVE              X:<TIMING,A
143       P:00B6 P:00B6 565B00            MOVE              A,X:(R3)+               ; Header ID from Utility to timing
144       P:00B7 P:00B7 5EA900            MOVE                          Y:<RDC,A
145       P:00B8 P:00B8 565B00            MOVE              A,X:(R3)+               ; Start reading out the CCD
146                             NO_RDC
147       P:00B9 P:00B9 0A0001            BCLR    #ST_EX,X:<STATUS                  ; Exposure is no longer in progress
148       P:00BA P:00BA 0A0003            BCLR    #ST_READ,X:<STATUS                ; clear flag
149       P:00BB P:00BB 00000C            RTS                                       ; Return now to save time
150    
151                             ; Update all the digital input/outputs; reset watchdog timer
152       P:00BC P:00BC 0970F0  UPD_DIG   MOVEP             Y:RD_DIG,Y:DIG_IN       ; Read 16 digital inputs
                        000000
153       P:00BE P:00BE 09F4B2            MOVEP             #1,Y:EN_DIG             ; Enable digital outputs
                        000001
154       P:00C0 P:00C0 09F0F0            MOVEP             Y:DIG_OUT,Y:WR_DIG      ; Write 16 digital outputs
                        000001
155    
156                             ; Update the 4 DACs
157       P:00C2 P:00C2 09F0F4            MOVEP             Y:DAC0,Y:WR_DAC0        ; Write to DAC0
                        000002
158       P:00C4 P:00C4 09F0F5            MOVEP             Y:DAC1,Y:WR_DAC1        ; Write to DAC1
                        000003
159       P:00C6 P:00C6 09F0F6            MOVEP             Y:DAC2,Y:WR_DAC2        ; Write to DAC2
                        000004
160       P:00C8 P:00C8 09F0F7            MOVEP             Y:DAC3,Y:WR_DAC3        ; Write to DAC3
                        000005
161    
162                             ; Analog Input processor - read the 16 A/D inputs
163       P:00CA P:00CA 448000            MOVE              X:<ONE,X0               ; For incrementing accumulator to select MUX
164       P:00CB P:00CB 350713            CLR     A         #<AD_IN,R5              ; Will contain MUX number
165       P:00CC P:00CC 060640            DO      Y:NUM_AD,LOOP_AD                  ; Loop over each A/D converter input
                        0000D9
166       P:00CE P:00CE 09CE31            MOVEP             A,Y:WR_MUX              ; Select MUX input
167       P:00CF P:00CF 0646A0            REP     #DLY_MUX                          ; Wait for the MUX to settle
168       P:00D0 P:00D0 5C3600            MOVE                          A1,Y:<SV_A1 ; REP is OK since delay < SCI time per byte
169       P:00D1 P:00D1 094631            MOVEP             Y:STR_ADC,Y0            ; Start A/D conversion - dummy read
170       P:00D2 P:00D2 0664A0            REP     #DLY_AD                           ; Wait for the A/D to settle
171       P:00D3 P:00D3 468000            MOVE              X:<CFFF,Y0
172       P:00D4 P:00D4 094C32            MOVEP             Y:RD_ADC,A1             ; Get the A/D value
173       P:00D5 P:00D5 200056            AND     Y0,A                              ; A/D is only valid to 12 bits
174       P:00D6 P:00D6 0BCC4B            BCHG    #11,A1                            ; Change 12-bit 2's complement to unipolar
175       P:00D7 P:00D7 5C5D00            MOVE                          A1,Y:(R5)+  ; Put the A/D value in the table
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:30  util1.asm  Page 4



176       P:00D8 P:00D8 5CB600            MOVE                          Y:<SV_A1,A1 ; Restore A1 = MUX number
177       P:00D9 P:00D9 200040            ADD     X0,A                              ; Increment A = MUX number by one
178                             LOOP_AD
179       P:00DA P:00DA 09F0B1            MOVEP             X:ONE,Y:WR_MUX          ; Sample +5V when idle
                        000000
180    
181                             ; Control the CCD Temperature
182                             ; The algorithmn assumes a reverse biased diode whose A/D count A_CCDT
183                             ;   is proportional to temperature. Don't start controlling temperature
184                             ;   until it falls below target temperature.
185    
186       P:00DC P:00DC 4C9C00            MOVE                          Y:<T_CCDT,X0 ; Get actual CCD temperature
187       P:00DD P:00DD 5E8C00            MOVE                          Y:<A_CCDT,A ; Get lower CCD temperature limit
188       P:00DE P:00DE 200044            SUB     X0,A
189       P:00DF P:00DF 21C400            MOVE              A,X0
190       P:00E0 P:00E0 4E9D00            MOVE                          Y:<T_COEFF,Y0
191       P:00E1 P:00E1 2000D0            MPY     X0,Y0,A                           ; A = (actual - target) * T_COEFF
192       P:00E2 P:00E2 4D8200            MOVE                          Y:<DAC0,X1  ; A positive -> actual > target ->
193       P:00E3 P:00E3 4C9E00            MOVE                          Y:<DAC0_LS,X0 ;   too cold -> add more heat
194       P:00E4 P:00E4 200020            ADD     X,A                               ; Add both least and most significant
195                                                                                 ;   words (X0 and X1) to accumulator A
196       P:00E5 P:00E5 4CB500            MOVE                          Y:<C825,X0  ; Heats greater than this are not allowed
197       P:00E6 P:00E6 200045            CMP     X0,A
198       P:00E7 P:00E7 0E90EA            JLT     <TST_LOW
199       P:00E8 P:00E8 208E00            MOVE              X0,A                    ; Make it the maximum heat
200       P:00E9 P:00E9 0C00ED            JMP     <WR_DAC
201       P:00EA P:00EA 200003  TST_LOW   TST     A                                 ; Heats of less than zero are not allowed
202       P:00EB P:00EB 0E70ED            JGT     <WR_DAC
203       P:00EC P:00EC 568000            MOVE              X:<ZERO,A               ; No heat
204       P:00ED P:00ED 09CE34  WR_DAC    MOVEP             A,Y:WR_DAC0             ; Update DAC and record of it
205       P:00EE P:00EE 5E0200            MOVE                          A,Y:<DAC0
206       P:00EF P:00EF 581E00            MOVE                          A0,Y:<DAC0_LS
207       P:00F0 P:00F0 00000C            RTS                                       ; Return from subroutine SERVICE call
208    
209    
210                             ; Shutter support subroutines for the TIMER executive
211                             ;   Also support shutter connection to timing board for now.
212       P:00F1 P:00F1 0AA423  OSHUT     BSET    #SHUTTER,X:PBD                    ; Clear Port B bit #3 to open shutter
213       P:00F2 P:00F2 0A0002            BCLR    #ST_SH,X:<STATUS                  ; Clear status bit to mean shutter open
214       P:00F3 P:00F3 00000C            RTS
215    
216       P:00F4 P:00F4 0AA403  CSHUT     BCLR    #SHUTTER,X:PBD                    ; Set Port B bit #3 to close shutter
217       P:00F5 P:00F5 0A0022            BSET    #ST_SH,X:<STATUS                  ; Set status to mean shutter closed
218       P:00F6 P:00F6 00000C            RTS
219    
220                             ; These are called directly by command, so need to call subroutines in turn
221       P:00F7 P:00F7 0D00F1  OPEN      JSR     OSHUT                             ; Call open shutter subroutine
222       P:00F8 P:00F8 0C0000            JMP     <FINISH                           ; Send 'DON' reply
223       P:00F9 P:00F9 0D00F4  CLOSE     JSR     CSHUT                             ; Call close shutter subroutine
224       P:00FA P:00FA 0C0000            JMP     <FINISH                           ; Send 'DON' reply
225    
226    
227                             ;  **************  BEGIN  COMMAND  PROCESSING  ***************
228                             ; Start power-on cycle
229       P:00FB P:00FB 0AA422  P_ON      BSET    #PWRST,X:PBD                      ; Reset power control board
230       P:00FC P:00FC 0AA402            BCLR    #PWRST,X:PBD
231    
232                             ;  Set up the bias voltage DACs and clock drivers on the analog boards
233       P:00FD P:00FD 568000            MOVE              X:<TIMING,A
234       P:00FE P:00FE 565B00            MOVE              A,X:(R3)+               ; Header ID from Utility to timing
235       P:00FF P:00FF 5EB000            MOVE                          Y:<IDL,A
236       P:0100 P:0100 565B00            MOVE              A,X:(R3)+               ; Start up the clock drivers
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:30  util1.asm  Page 5



237       P:0101 P:0101 74F400            MOVE              #P_ON1,N4               ; Set internal jump address after 'DON'
                        000104
238       P:0103 P:0103 0C0000            JMP     <XMT_CHK                          ; Send out commands to timing board
239    
240                             ;  Now ramp up the low voltages (+/- 15V)
241       P:0104 P:0104 0AA421  P_ON1     BSET    #LVEN,X:PBD                       ; Make sure line is high to start with
242       P:0105 P:0105 06FFA0            REP     #255                              ; The power conditioner board wants to
243       P:0106 P:0106 0BA401            BCHG    #LVEN,X:PBD                       ;   see 128 H --> L transitions
244       P:0107 P:0107 09F4B1            MOVEP             #2,Y:WR_MUX             ; Select +15V MUX input
                        000002
245       P:0109 P:0109 060000            DO      X:<C50000,WT_PON2                 ; Wait 60 millisec for settling
                        00010C
246       P:010B P:010B 0604A0            REP     #4
247       P:010C P:010C 094637            MOVEP             Y:WATCH,Y0              ; Reset watchdog timer
248                             WT_PON2
249       P:010D P:010D 094631            MOVEP             Y:STR_ADC,Y0            ; Start A/D conversion - dummy read
250       P:010E P:010E 0664A0            REP     #DLY_AD                           ; Wait for the A/D to settle
251       P:010F P:010F 448013            CLR     A         X:<CFFF,X0              ; This saves some space
252       P:0110 P:0110 094C32            MOVEP             Y:RD_ADC,A1             ; Get the A/D value
253       P:0111 P:0111 4CA146            AND     X0,A                  Y:<T_P15,X0 ; A/D is only valid to 12 bits
254    
255                             ; Test that the voltage is in the range abs(initial - target) < margin
256       P:0112 P:0112 5C2644            SUB     X0,A                  A1,Y:<I_P15
257       P:0113 P:0113 4CA226            ABS     A                     Y:<K_P15,X0
258       P:0114 P:0114 200044            SUB     X0,A
259       P:0115 P:0115 0E7147            JGT     <PERR                             ; Take corrective action
260    
261       P:0116 P:0116 09F4B1  TST_M15   MOVEP             #3,Y:WR_MUX             ; Select -15v MUX input
                        000003
262       P:0118 P:0118 0646A0            REP     #DLY_MUX                          ; Wait for the MUX to settle
263       P:0119 P:0119 000000            NOP
264       P:011A P:011A 094631            MOVEP             Y:STR_ADC,Y0            ; Start A/D conversion - dummy read
265       P:011B P:011B 0664A0            REP     #DLY_AD                           ; Wait for the A/D to settle
266       P:011C P:011C 448013            CLR     A         X:<CFFF,X0              ; Clear A, so put it in REP argument
267       P:011D P:011D 094C32            MOVEP             Y:RD_ADC,A1             ; Get the A/D value
268       P:011E P:011E 4CA346            AND     X0,A                  Y:<T_M15,X0 ; A/D is only valid to 12 bits
269    
270                             ; Test that the voltage is in the range abs(initial - target) < margin
271       P:011F P:011F 5C2744            SUB     X0,A                  A1,Y:<I_M15
272       P:0120 P:0120 4CA426            ABS     A                     Y:<K_M15,X0
273       P:0121 P:0121 200044            SUB     X0,A
274       P:0122 P:0122 0E7147            JGT     <PERR
275    
276                             ;  Now turn on the high voltage HV (nominally +36 volts)
277       P:0123 P:0123 0AA420  HV_ON     BSET    #HVEN,X:PBD                       ; Make sure line is high to start with
278       P:0124 P:0124 06FFA0            REP     #255                              ; The power conditioner board wants to
279       P:0125 P:0125 0BA400            BCHG    #HVEN,X:PBD                       ;   see 128 H --> L transitions
280       P:0126 P:0126 09F4B1            MOVEP             #1,Y:WR_MUX             ; Select high voltage MUX input
                        000001
281       P:0128 P:0128 060000            DO      X:<C50000,WT_HV                   ; Wait 5 millisec for settling
                        00012A
282       P:012A P:012A 000000            NOP
283                             WT_HV
284       P:012B P:012B 094631            MOVEP             Y:STR_ADC,Y0            ; Start A/D conversion - dummy read
285       P:012C P:012C 0664A0            REP     #DLY_AD                           ; Wait for the A/D to settle
286       P:012D P:012D 448013            CLR     A         X:<CFFF,X0              ; Clear A, so put it in REP argument
287       P:012E P:012E 094C32            MOVEP             Y:RD_ADC,A1             ; Get the A/D value
288       P:012F P:012F 4C9F46            AND     X0,A                  Y:<T_HV,X0  ; A/D is only valid to 12 bits
289    
290                             ; Test that the voltage is in the range abs(initial - target) < margin
291       P:0130 P:0130 5C2544            SUB     X0,A                  A1,Y:<I_HV
292       P:0131 P:0131 4CA026            ABS     A                     Y:<K_HV,X0
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:30  util1.asm  Page 6



293       P:0132 P:0132 200044            SUB     X0,A
294       P:0133 P:0133 0E7147            JGT     <PERR                             ; Take corrective action
295    
296                             ; Command the timing board to turn on the analog board DC bias voltages
297       P:0134 P:0134 568000            MOVE              X:<TIMING,A
298       P:0135 P:0135 565B00            MOVE              A,X:(R3)+               ; Header ID from Utility to timing
299       P:0136 P:0136 5EAF00            MOVE                          Y:<SBV,A
300       P:0137 P:0137 565B00            MOVE              A,X:(R3)+               ; Set bias voltages
301       P:0138 P:0138 74F400            MOVE              #P_ON2,N4               ; Set internal jump address after 'DON'
                        00013B
302       P:013A P:013A 0C0000            JMP     <XMT_CHK                          ; Send out commands to timing board
303    
304                             ; Command the timing board to reset the analog board A/D converter(s)
305       P:013B P:013B 568000  P_ON2     MOVE              X:<TIMING,A
306       P:013C P:013C 565B00            MOVE              A,X:(R3)+               ; Header ID from Utility to timing
307       P:013D P:013D 5EB100            MOVE                          Y:<RAD,A
308       P:013E P:013E 565B00            MOVE              A,X:(R3)+               ; Set bias voltages
309       P:013F P:013F 74F400            MOVE              #P_ON3,N4               ; Set internal jump address after 'DON'
                        000142
310       P:0141 P:0141 0C0000            JMP     <XMT_CHK                          ; Send out commands to timing board
311    
312                             ;  Reply with a nice DONE message to the host computer
313       P:0142 P:0142 568000  P_ON3     MOVE              X:<HOST,A
314       P:0143 P:0143 565B00            MOVE              A,X:(R3)+               ; Header ID to host
315       P:0144 P:0144 568000            MOVE              X:<DON,A
316       P:0145 P:0145 565B00            MOVE              A,X:(R3)+               ; Power is now ON
317       P:0146 P:0146 0C0000            JMP     <XMT_CHK                          ; Go transmit reply
318    
319                             ;  Or, return with an error message
320       P:0147 P:0147 568000  PERR      MOVE              X:<HOST,A
321       P:0148 P:0148 565B00            MOVE              A,X:(R3)+               ; Header ID to host
322       P:0149 P:0149 568000            MOVE              X:<ERR,A
323       P:014A P:014A 565B00            MOVE              A,X:(R3)+               ; Power is ON
324       P:014B P:014B 0C0000            JMP     <XMT_CHK                          ; Go transmit reply
325    
326                             ; Power off
327       P:014C P:014C 0AA422  P_OFF     BSET    #PWRST,X:PBD                      ; Reset power control board
328       P:014D P:014D 0AA402            BCLR    #PWRST,X:PBD
329       P:014E P:014E 0C0000            JMP     <FINISH                           ; Reply 'DON'
330    
331                             ; Reset the timing board
332       P:014F P:014F 0AA405  SYSRST    BCLR    #SYS_RST,X:PBD
333       P:0150 P:0150 06C8A0            REP     #200                              ; Circuit stabilization delay > 50T
334       P:0151 P:0151 000000            NOP
335       P:0152 P:0152 0AA425            BSET    #SYS_RST,X:PBD
336       P:0153 P:0153 56F400            MOVE              #50000,A                ; Delay 10 millisec for timing board
                        00C350
337       P:0155 P:0155 06CE00            DO      A,DLY_RST                         ;   to reset
                        000158
338       P:0157 P:0157 000000            NOP
339       P:0158 P:0158 000000            NOP
340                             DLY_RST
341       P:0159 P:0159 0C0000            JMP     <FINISH                           ; Reply 'DON'
342    
343                             ; Start an exposure
344                             ; Modified for AzCam and V1.7
345                             STRT_EX
346                             ;       BSET    #OPT_RDC,X:<OPTIONS     ; starts readout in SERVICE when timer done
347                             ; this should be done optionally in azcam
348    
349                             ;       MOVE    X:<TIMING,A
350                             ;       MOVE    A,X:(R3)+       ; Header ID from Utility to timing
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:30  util1.asm  Page 7



351                             ;       MOVE    Y:<CLR,A
352                             ;       MOVE    A,X:(R3)+       ; Clear the CCD
353                             ;       MOVE    #DONECLR,N4     ; Set internal jump address after 'DON'
354                             ;       JMP     <XMT_CHK        ; Transmit these
355    
356                             ; Come to here after timing board has signaled that CLEAR is done
357                             ; set shutter and load exposure time
358                             DONECLR
359       P:015A P:015A 0B00A0            JSSET   #OPT_SH,X:<OPTIONS,OSHUT          ; Open shutter if needed
                        0000F1
360       P:015C P:015C 0A0021            BSET    #ST_EX,X:<STATUS                  ; Set for exposure in progress
361       P:015D P:015D 200013            CLR     A
362       P:015E P:015E 5E1700            MOVE                          A,Y:<EL_TIM ; Initialize elapsed time
363    
364                             ; issue IIA to init PCI card for readout
365                             ;       MOVE    #$030102,A
366       P:015F P:015F 568000            MOVE              X:<VME,A
367       P:0160 P:0160 565B00            MOVE              A,X:(R3)+
368       P:0161 P:0161 56F400            MOVE              #'IIA',A                ; Rev. 1.7
                        494941
369       P:0163 P:0163 565B00            MOVE              A,X:(R3)+
370       P:0164 P:0164 0C0000            JMP     <XMT_CHK                          ; Issue IIA and send DON to host
371    
372       P:0165 P:0165 0A0001  PAUSE     BCLR    #ST_EX,X:<STATUS                  ; Take out of exposing mode
373       P:0166 P:0166 0B00A0            JSSET   #OPT_SH,X:<OPTIONS,CSHUT          ; Close shutter if needed
                        0000F4
374       P:0168 P:0168 0C0000            JMP     <FINISH                           ; Issue 'DON' and get next command
375    
376       P:0169 P:0169 0A0021  RESUME    BSET    #ST_EX,X:<STATUS                  ; Put in exposing mode
377       P:016A P:016A 0B00A0            JSSET   #OPT_SH,X:<OPTIONS,OSHUT          ; Open shutter if needed
                        0000F1
378       P:016C P:016C 0C0000            JMP     <FINISH                           ; Issue 'DON' and get next command
379    
380       P:016D P:016D 0A0001  ABORT     BCLR    #ST_EX,X:<STATUS                  ; Take out of exposing mode
381       P:016E P:016E 568000            MOVE              X:<TIMING,A
382       P:016F P:016F 565B00            MOVE              A,X:(R3)+               ; Header ID from Utility to timing
383       P:0170 P:0170 5EB000            MOVE                          Y:<IDL,A
384       P:0171 P:0171 565B00            MOVE              A,X:(R3)+               ; Put timing board in IDLE mode
385       P:0172 P:0172 568000            MOVE              X:<VME,A
386       P:0173 P:0173 565B00            MOVE              A,X:(R3)+               ; Header ID to VME interface
387       P:0174 P:0174 5EAA00            MOVE                          Y:<ABR,A
388       P:0175 P:0175 565B00            MOVE              A,X:(R3)+               ; Abort readout
389       P:0176 P:0176 0D00F4            JSR     <CSHUT                            ; To be sure
390       P:0177 P:0177 0C0000            JMP     <FINISH                           ; Issue 'DON' and get next command
391    
392                             ;  A 'DON' reply has been received in response to a command issued by
393                             ;    the Utility board. Read the X:STATUS bits in responding to it.
394    
395                             ;  Test if an internal program jump is needed fter receiving a 'DON' reply
396       P:0178 P:0178 239000  PR_DONE   MOVE              N4,R0                   ; Get internal jump address
397       P:0179 P:0179 3C0000            MOVE              #<START,N4              ; Set internal jump address to default
398       P:017A P:017A 0AE080            JMP     (R0)                              ; Jump to the internal jump address
399    
400                             ;  Check for program overflow - its hard to overflow since this application
401                             ;   can be very large indeed
402                                       IF      @CVS(N,*)>APL_XY
404                                       ENDIF                                     ;  will not be overwritten
405    
406                             ;  Command table resident in X: data memory
407                             ;  The last part of the command table is not defined for "bootrom"
408                             ;     because it contains application-specific commands
409    
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:30  util1.asm  Page 8



410                                       IF      1                                 ; Memory offsets for downloading code
411       X:00C0 X:00C0                   ORG     X:COM_TBL,X:COM_TBL
412                                       ELSE                                      ; Memory offsets for generating EEPROMs
414                                       ENDIF
415       X:00C0 X:00C0                   DC      'PON',P_ON                        ; Power ON
416       X:00C2 X:00C2                   DC      'POF',P_OFF                       ; Power OFF
417       X:00C4 X:00C4                   DC      'SEX',STRT_EX                     ; Start exposure
418       X:00C6 X:00C6                   DC      'PEX',PAUSE                       ; Pause exposure
419       X:00C8 X:00C8                   DC      'REX',RESUME                      ; Resume exposure
420       X:00CA X:00CA                   DC      'AEX',ABORT                       ; Abort exposure
421       X:00CC X:00CC                   DC      'OSH',OPEN                        ; Open shutter
422       X:00CE X:00CE                   DC      'CSH',CLOSE                       ; Close shutter
423       X:00D0 X:00D0                   DC      'SYR',SYSRST                      ; Reset system, that is, timing board
424       X:00D2 X:00D2                   DC      'DON',PR_DONE                     ; Process DON reply
425       X:00D4 X:00D4                   DC      'RDC',RDCCD
426       X:00D6 X:00D6                   DC      'TST',FINISH                      ; Test to see if we are loaded
427       X:00D8 X:00D8                   DC      0,START,0,START
428       X:00DC X:00DC                   DC      0,START,0,START
429    
430                             ; Y: parameter table definitions, containing no "bootrom" definitions
431                                       IF      1
432       Y:0000 Y:0000                   ORG     Y:0,Y:0                           ; Download address
433                                       ELSE
435                                       ENDIF
436       Y:0000 Y:0000         DIG_IN    DC      0                                 ; Values of 16 digital input lines
437       Y:0001 Y:0001         DIG_OUT   DC      0                                 ; Values of 16 digital output lines
438       Y:0002 Y:0002         DAC0      DC      0                                 ; Table of four DAC values to be output
439       Y:0003 Y:0003         DAC1      DC      1000
440       Y:0004 Y:0004         DAC2      DC      2000
441       Y:0005 Y:0005         DAC3      DC      3000
442       Y:0006 Y:0006         NUM_AD    DC      16                                ; Number of inputs to A/D converter
443       Y:0007 Y:0007         AD_IN     DC      0,0,0,0,0,0,0,0
444       Y:000F Y:000F                   DC      0,0,0,0,0,0,0,0                   ; Table of 16 A/D values
445       Y:0017 Y:0017         EL_TIM    DC      0                                 ; Number of milliseconds elapsed
446       Y:0018 Y:0018         TGT_TIM   DC      6000                              ; Number of milliseconds desired in exposure
447       Y:0019 Y:0019         U_CCDT    DC      $C20                              ; Upper range of CCD temperature control loop
448       Y:001A Y:001A         L_CCDT    DC      $C50                              ; Lower range of CCD temperature control loop
449       Y:001B Y:001B         K_CCDT    DC      85                                ; Constant of proportionality for CCDT control
450       00000C                A_CCDT    EQU     AD_IN+5                           ; Address of CCD temperature in A/D table
451       Y:001C Y:001C         T_CCDT    DC      $0FFF                             ; Target CCD T for small increment algorithmn
452       Y:001D Y:001D         T_COEFF   DC      $010000                           ; Coefficient for difference in temperatures
453       Y:001E Y:001E         DAC0_LS   DC      0                                 ; Least significant part of heater voltage
454    
455                             ; Define power supply turn-on variables
456       Y:001F Y:001F         T_HV      DC      $388                              ; Target HV supply voltage
457       Y:0020 Y:0020         K_HV      DC      $248                              ; Tolerance of HV supply voltage = LARGE
458       Y:0021 Y:0021         T_P15     DC      $580                              ; Target +15 volts supply voltage
459       Y:0022 Y:0022         K_P15     DC      $80                               ; Tolerance of +15 volts supply voltage = 0.5v
460       Y:0023 Y:0023         T_M15     DC      $A60                              ; Target -15 volts supply voltage
461       Y:0024 Y:0024         K_M15     DC      $80                               ; Tolerance of -15 volts supply voltage
462       Y:0025 Y:0025         I_HV      DC      0                                 ; Initial value of HV
463       Y:0026 Y:0026         I_P15     DC      0                                 ; Initial value of +15 volts
464       Y:0027 Y:0027         I_M15     DC      0                                 ; Initial value of -15 volts
465    
466                             ; Define some command names
467       Y:0028 Y:0028         CLR       DC      'CLR'                             ; Clear CCD
468       Y:0029 Y:0029         RDC       DC      'RDC'                             ; Readout CCD
469       Y:002A Y:002A         ABR       DC      'ABR'                             ; Abort readout
470       Y:002B Y:002B         OSH       DC      'OSH'                             ; Open shutter connected to timing board
471       Y:002C Y:002C         CSH       DC      'CSH'                             ; Close shutter connected to timing board
472       Y:002D Y:002D         POK       DC      'POK'                             ; Message to host - power in OK
473       Y:002E Y:002E         PER       DC      'PER'                             ; Message to host - ERROR in power up sequence
Motorola DSP56000 Assembler  Version 6.3.0   113-08-19  11:38:30  util1.asm  Page 9



474       Y:002F Y:002F         SBV       DC      'SBV'                             ; Message to timing - set bias voltages
475       Y:0030 Y:0030         IDL       DC      'IDL'                             ; Message to timing - put camera in idle mode
476       Y:0031 Y:0031         RAD       DC      'RAD'                             ; Message to timing - reset A/D
477    
478                             ; Miscellaneous
479       Y:0032 Y:0032         L_ADDR    DC      $200                              ; Last address written to EEPROM
480       Y:0033 Y:0033         AD_MASK   DC      $FFFFC0                           ; Mask for A6 - A15
481       Y:0034 Y:0034         SEX_ID    DC      0                                 ; Header ID for reply to SEX command
482       Y:0035 Y:0035         C825      DC      $825
483       Y:0036 Y:0036         SV_A1     DC      0                                 ; Save register A1 during analog processing
484       Y:0037 Y:0037         SV_SR     DC      0                                 ; Save status register during timer processing
485       Y:0038 Y:0038                   DC      0                                 ; pad (used by gen 2)
486       Y:0039 Y:0039                   DC      0
487       Y:003A Y:003A                   DC      0
488       Y:003B Y:003B                   DC      0
489    
490                             ; During the downloading of this application program the one millisecond
491                             ;   timer interrupts are enabled, so the utility board will attempt to execute
492                             ;   the partially downloaded TIMER routine, and crash. A workaround is to
493                             ;   put a RTI as the first instruction of TIMER so it doesn't execute, then
494                             ;   write the correct instruction only after all the rest of the application
495                             ;   program has been downloaded. Here it is -
496    
497                                       IF      1
498       P:0099 P:0099                   ORG     P:APL_ADR+1,P:APL_ADR+1
499                                       ELSE
501                                       ENDIF
502       P:0099 P:0099 053779  TIMER1    MOVEC                         SR,Y:<SV_SR ; Save Status Register
503    
504    
505                                ENDSEC                                    ; End of SECTION UTILICE
506    
507                      ; End of program
508                                END

0    Errors
0    Warnings


