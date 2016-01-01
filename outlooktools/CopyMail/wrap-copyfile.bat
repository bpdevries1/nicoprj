dir /S /B .\tcom3.9 >tcom_files.txt
dir /S /B .\ndv0.1.1 >ndv_files.txt
freewraptclsh copyfile.tcl -f tcom_files.txt -f ndv_files.txt

