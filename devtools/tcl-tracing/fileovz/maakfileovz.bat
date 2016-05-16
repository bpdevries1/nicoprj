rem Maak overzicht van alles sourcefiles met status en comments uit files.

set SOURCE_DIR=C:\vreen00_toolset2\CxR_Toolset\Perf\toolset\cruise\checkout

del /s %SOURCE_DIR%\newfiles.txt
del /s %SOURCE_DIR%\ccaddfiles.bat
del /s %SOURCE_DIR%\deletefiles.bat
tclsh maakfileovz.tcl
