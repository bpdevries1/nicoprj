del make-svn-ontdubbel.log
dir /bs "D:\ITX\Remote\svn\odmsdocs\trunk\docs" | grep -v "90 Historie" >odmsdocs.txt
tclsh make-svn-move-historie.tcl odmsdocs.txt svn-move-historie.bat


