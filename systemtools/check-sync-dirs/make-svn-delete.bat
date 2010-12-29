del make-svn-delete.log
dir /bs "D:\ITX\Remote\svn\odmsdocs\trunk\docs" | grep -v "90 Historie" >odmsdocs.txt
tclsh make-svn-delete.tcl odmsdocs.txt svn-delete.bat


