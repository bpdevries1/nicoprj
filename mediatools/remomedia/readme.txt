Script for copying media files to removable media like SD-cards and MP3 players.

NdV, 9-12-2008.

copy_hp.bat - specific Harry Potter - delete
copy-sd-fast.tcl - split MP3 file
import-playlists.tcl - unknown
libpeerconnection.log - delete
maak_copy_sd_singles.tcl - windows with drive argument, 150 files default. Uses 'singles' in music MySQL db.
maak_copy_sd.tcl - looks like old version of maak_copy_sd_singles.tcl 
maak_m3u_f.bat - wrapper around maak_m3u_f.tcl 
maak_m3u_f.tcl - make playlist based on singles already on USB stick
music2sd.bat - wrapper around maak_copy_sd.tcl 
music-schema-only.sql - create tables script for Music DB.
playlist2sql.tcl - one off to import singles into DB.
queries.sql - misc queries on DB
readme.txt 
rename-files.tcl - helper script for converting m4a to mp3, to do changes in DB as well.
temp-filenames.tcl - DB cleanup?
test-db.tcl - just test on DB connection.

Copy new items to Philips MP3 player (10-01-2014)
=================================================
* Use maak_copy_sd_singles.tcl - std parameters should work.
* Check the generated file: /media/nas/copy-sd.sh
* Delete the current contents of the MP3 player
* execute copy-sd.sh script, this may take some time.
* Check if all files are available on MP3 player, and there is still some space available.

