rem Create .lod file for utility board
rem MPL 14Aug08

rem Directory paths - change as needed
set ROOT=\azcam\MotorolaDSPTools\
set ROOT3=%ROOT%CLAS563\BIN\
set ROOT0=%ROOT%CLAS56\BIN\

%ROOT0%asm56000 -b -lutilboot1.ls utilboot1.asm
%ROOT0%asm56000 -b -lutil1.ls -d DOWNLOAD 1 -d POWER R6 util1.asm 

%ROOT0%dsplnk -b util1.cld -v utilboot1.cln util1.cln

rem del util1.lod
del utilboot1.cln
del util1.cln

%ROOT0%cldlod util1.cld > util1.lod

del util1.cld

pause

