Disk Catalog
============
Goals: 
* find duplicate files on filesystem in an efficient way
* check if all files have been backupped (compare source and backup dir)

Ideas
=====
* Use MD5 (md5sum) to determine a checksum of each file.
* Maybe first focus on big files, although shorter source and documents may be at least as important.
* Store everything in sqlite, see how big it gets.
* Every file becomes a row in the 'files' table.
* Columns: filename, path, date, size, md5sum, lastchecked (when is the file last checked, md5 etc determined)
* Columns: something like status, to determine if it is unique or not, has a backup, is in archive? Maybe better in a separate table?
* Also contents of zip/rar files? Sometimes chose to archive a project in a zip file.

Other progs
===========
* Search: find duplicates, compare contents, manage harddisk.

Algorithm
=========
* This kind of thing still looks to be better in Tcl than Clojure.
* Handle each directory, for each directory call md5sum *, parse the results.
* Or tcl only, see below
* No idea which is faster, and if it really matters.
* Could be this is a long running process, and need some way to mark where we are. Depth first seems fine, for breath-first
  it seems we need more memory to keep stats. So do a glob at root level, save all dirs in a table. Then repeat as long as
  there are rows in the table: get a row, handle the dir for files directly in this dir, then get the subdirs, add the subdirs
  to the table, remove the directory. Could do something like 'select from table limit 100'
* Need to add sqlite transactions (see graphdata) for more speed.  
* Need indexes on filename, path, size, md5sum.
* linux cmd cannot handle "*", it is filled out by bash, but not by tcl. With large directories, the cmdline might become large.
  not sure how tcl glob would handle this. Wait and find out if it is needed.
* See also Todo's at the end of this file.
    
#Gets MD5 hash
 proc md5 {string} {
     #tcllib way:
     package require md5
     string tolower [::md5::md5 -hex $string]

     #BSD way:
     #exec -- md5 -q -s $string
 
     #Linux way:
     #exec -- echo -n $string | md5sum | sed "s/\ *-/\ \ /"

     #Solaris way:
     #lindex [exec -- echo -n $string | md5sum] 0

     #OpenSSL way:
     #exec -- echo -n $string | openssl md5
 }
 
 
package require struct::list
package require fileutil

[::fileutil::cat $filename]

# wel vraag of deze met grote files om kan gaan.
::md5::md5 -hex [::fileutil::cat make-svn-ontdubbel.tcl]

# je kan ook channel of file opgeven, dus dit lijkt wel de eerste manier.
::md5::md5  ? -hex ?  [ -channel channel | -file filename | string ]

[2012-01-19 22:25:52] met backup ook iets gedaan dat je checkt of er wat veranderd is. Hele harddisk duurt erg lang, en
                      zal nu met md5 nog langer duren. Dit is dus niet iets wat je veel wilt doen.
[2012-01-19 22:26:55] bijhouden waar je bent klinkt wel noodzakelijk, maar eerst zonder beginnen.
[2012-01-19 22:27:15] dirs doorlopen wel net als backup? bv niet symlinks doorlopen. Mss ook ignorefiles toepassen.
[2012-01-20 08:28:37] foutmelding in dir /home/nico/oltest, zie onder.
[2012-01-21 19:13:22] moet SQL escapen dus, jammer.

[21-01-12 14:56:34] [catalogdisk.tcl] [debug] handling: /home/nico/oltest/out/Personal/Verwijderde items/Adressen/Collega's
[2012-01-22 01:20:39] bugs opgelost, nu /home/nico goed ingelezen, totaal 22.39-00.55=2:16. 
   102.872 files, totalsize=76 550 712 988.0 ofwel 76GB.
[2012-01-22 01:25:09] aan de andere kant met du -H blijkt in / 115G totaal te zijn, met 84GB gebruikt, zou meeste dus in /home/nico
   zitten.
[2012-01-22 01:26:44] dubbele dingen op andere lokatie dan mijn home-dir zijn niet zo waarschijnlijk, wel dingen in /opt, /var
   /etc
[2012-01-22 01:27:55] nu eerst /media/nas aanzetten.
[2012-01-22 01:28:55] ook bv /aaa dirs staan ofwel in mij home, ofwel op /media/nas/aaa.
[2012-01-22 01:29:54] waar ik overal books/ict heb, is ook wel leuk te weten: /media/nas, laptop, dropbox. Als /media/nas
   de bron is, en de andere 2 puur omdat je er dan beter bijkan, is het goed. Op laptop zou nog meer kunnen staan dan in
   dropbox, omdat daar meer ruimte is.

   
* Todo: klein stukje van md5 via laptop doen, komt er hetzelfde uit? Hier wel tcl interne methode doen, dus kan anders zijn. Mss
via cygwin ook de md5sum te krijgen, zou je wel verwachten.

* Todo: andere oude drives die via PC te benaderen zijn (/media?) ook indexeren.

* Todo: boeken categoriseren wordt hiermee mss ook gemakkelijker, zeker nu ik verschillende bronnen, ook zowel ebooks als luisterboeken,
  ook kijken hoe je dit wilt organiseren, denk luisterenboeken in aparte /media/nas/media/audiobooks dir.
  
