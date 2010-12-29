del make-svn-rename-versie.log
dir /bs "D:\ITX\Remote\svn\odmsdocs\trunk\docs" | grep -v -i "Historie" >odmsdocs.txt
tclsh make-svn-rename-versie.tcl odmsdocs.txt svn-rename-versie.bat


