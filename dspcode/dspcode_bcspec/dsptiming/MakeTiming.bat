@echo off
rem Creates .lod files for ARC timing boards
rem MPL 14Aug08

rem arguments => CONTROLLER   MODE   SHIFT
rem CONTROLLER is   gen1 gen2 gen3
rem MODE is         norm mpp
rem SHIFT is         LR LL UL UR

rem Directory paths - change as needed
set ROOT=\azcam\MotorolaDSPTools\
set ROOT3=%ROOT%CLAS563\BIN\
set ROOT0=%ROOT%CLAS56\BIN\

@echo on

rem *** set mpp flag  -> default is mpp mode ***
set MPPFLAG=-d MPP 1
set TYPE=mpp

if /i %2 EQU mpp (
set MPPFLAG=-d MPP 1
set TYPE=mpp
)

if /i %2 EQU norm (
set MPPFLAG=-d MPP 0
set TYPE=norm
)

rem *** set shift flag -> default is LR ***
set SHIFTDIR=LR
set SHIFTFLAG=-d SHIFTLR 1 -d SHIFTLL 0 -d SHIFTUL 0 -d SHIFTUR 0

if /i %3 EQU LR (
set SHIFTFLAG=-d SHIFTLR 1 -d SHIFTLL 0 -d SHIFTUL 0 -d SHIFTUR 0
set SHIFTDIR=LR
)
if /i %3 EQU LL (
set SHIFTFLAG=-d SHIFTLR 0 -d SHIFTLL 1 -d SHIFTUL 0 -d SHIFTUR 0
set SHIFTDIR=LL
)
if /i %3 EQU UL (
set SHIFTFLAG=-d SHIFTLR 0 -d SHIFTLL 0 -d SHIFTUL 1 -d SHIFTUR 0
set SHIFTDIR=UL
)
if /i %3 EQU UR (
set SHIFTFLAG=-d SHIFTLR 0 -d SHIFTLL 0 -d SHIFTUL 0 -d SHIFTUR 1
set SHIFTDIR=UR
)

rem *** assemble gen1 code ***
if /i %1 EQU gen1 (

rem *** assemble boot code ***
%ROOT0%asm56000 -b -ltim1_boot.ls tim1_boot.asm

%ROOT0%asm56000 -ltim1_%TYPE%_%SHIFTDIR%.ls -b -d DOWNLOAD 1 %SHIFTFLAG% %MPPFLAG% tim1.asm
%ROOT0%dsplnk -b tim1.cld -v tim1_boot.cln tim1.cln
del tim1.cln
%ROOT0%cldlod tim1.cld > tim1_%TYPE%_%SHIFTDIR%.lod
del tim1.cld

del tim1_boot.cln
)

rem *** assemble gen2 code ***
if /i %1 EQU gen2 (

rem *** assemble boot code ***
%ROOT0%asm56000 -b -ltim2_boot.ls tim2_boot.asm

%ROOT0%asm56000 -ltim2_%TYPE%_%SHIFTDIR%.ls -b -d DOWNLOAD HOST %SHIFTFLAG% %MPPFLAG% tim2.asm
%ROOT0%dsplnk -b tim2.cld -v tim2_boot.cln tim2.cln 
del tim2.cln
%ROOT0%cldlod tim2.cld > tim2_%TYPE%_%SHIFTDIR%.lod
del tim2.cld

del tim2_boot.cln
)

rem *** assemble gen3 code ***
if /i %1 EQU gen3 (

%ROOT3%asm56300 -ltim3_%TYPE%_%SHIFTDIR%.ls -b -d DOWNLOAD HOST %SHIFTFLAG% %MPPFLAG% tim3.asm
%ROOT3%dsplnk -b tim3.cld -v tim3.cln 
del tim3.cln
%ROOT3%cldlod tim3.cld > tim3_%TYPE%_%SHIFTDIR%.lod
del tim3.cld
)

rem pause
