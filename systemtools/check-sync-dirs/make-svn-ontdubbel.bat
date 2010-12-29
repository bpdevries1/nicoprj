del make-svn-ontdubbel.log
dir /bs "D:\ITX\Remote\svn\odmsdocs\trunk\docs" | grep -v -i "Historie" >odmsdocs.txt
tclsh make-svn-ontdubbel.tcl odmsdocs.txt svn-ontdubbel.bat


