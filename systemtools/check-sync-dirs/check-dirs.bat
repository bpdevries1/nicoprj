dir %1 /sb >repodir.txt
dir %2 /sb >checkdir.txt
tclsh check-files.tcl repodir.txt checkdir.txt >check-dirs-result.txt

