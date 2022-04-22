@echo on
rem *** Make DSP timing code files for ARC22 timing board ***

set CCD=90PrimeOne

set ARC22DIR=.\arc22timing\

call %ARC22DIR%Generate_ARC22_Code.bat %CCD% config0 %ARC22DIR%

rem pause
