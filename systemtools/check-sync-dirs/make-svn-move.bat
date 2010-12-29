del make-svn-move.log
dir /bs "D:\ITX\Remote\svn\odmsdocs\trunk\docs"  >gmp-src.txt
rem tclsh make-svn-move.tcl gmp-src.txt "C:\aaa\odmsdocs-target" "D:\ITX\Remote\svn\odmsdocs\trunk\docs\10 Planning\10 GMP" svn-rename.bat svn-mkdir.bat
tclsh make-svn-move.tcl gmp-src.txt "C:\aaa\odmsdocs-target" "D:\ITX\Remote\svn\odmsdocs\trunk\docs" svn-move.bat svn-mkdir.bat

