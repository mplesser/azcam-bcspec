@echo on
rem *** Make DSP timing code files for ARC22 timing board ***

set CCD=90Prime

set ARC22DIR=.\arc22timing\

call %ARC22DIR%Generate_ARC22_Code.bat %CCD% config1 %ARC22DIR%

rem pause
