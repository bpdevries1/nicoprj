mkdir c:/projecten/Philips/scat-an
touch c:/projecten/Philips/scat-an/scat-an.db
./dbscript.tcl -script copy-dailystatuslog.sql -rootdir c:/projecten/Philips/KNDL -dbpattern "*/keynotelogs.db"
