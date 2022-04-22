rem Create .s file for Gen1 PCI board
rem MPL 14Aug08

rem Directories - change as needed
set ROOT=\azcam\MotorolaDSPTools\
set ROOT3=%ROOT%CLAS563\BIN\
set ROOT0=%ROOT%CLAS56\BIN\

%ROOT3%asm56300 -b -l pci1boot.ls -d DOWNLOAD ROM pci1boot.asm

%ROOT3%dsplnk -b pci1.cld -v pci1boot.cln

del pci1boot.cln
del pci1.lod

%ROOT3%cldlod pci1.cld > pci1.lod

%ROOT3%srec -bs pci1.lod

del pci1.cld
del pci1.lod

pause

