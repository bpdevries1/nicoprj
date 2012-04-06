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
    
TODO
====
* Todo: boeken categoriseren wordt hiermee mss ook gemakkelijker, zeker nu ik verschillende bronnen, ook zowel ebooks als luisterboeken,
  ook kijken hoe je dit wilt organiseren, denk luisterenboeken in aparte /media/nas/media/audiobooks dir.
* Todo: kijk of ik John Irving - A prayer for Owen Meany heb en ook the day of the triffids (John Wyndham), vroeger gelezen, geloof wel goed.
  Deze stonden in Veronica gids als favo's van persoon die ik vergeten ben, maar geloof ik wel redelijk hoog heb zitten.
* sqlite: meerdere db's combineren? zodat hierbij queries te doen zijn? Of kun je queries over databases heen doen?
* Met attach kun je ze tegelijk querien: ATTACH c-root.db AS croot, select * from croot.files where ... Mogelijk is encoding een 
  issue, als op windows een andere wordt gebruikt. met .databases in sqlite3 cmdline kun je ze zien.
* In /media/nas/backups nog dingen die geen backup meer zijn, bron is weg, dus kan naar archief. Ook: verandert niet meer.
* in DellPC\c-drive\program-files nog wel boeiende progs, vooralsnog in archief, geinstalleerde program files, kan er mogelijk
  nog wat mee.
* Ook DellPC\d\cruiseresults naar archief, kijken hoeveel ik hiervan wil bewaren...
* Ook dellPC\d\nico en nicothuis: in hoeverre overlappend met huidige laptop etc.
* Ook dellpc\d\projecten: grotendeels al archief (?) checken of hier nog extra spul inzit.
* dellpc\d\util\perf: lqn, pdq en winmodtools, ook elders?
* delllaptop grotendeels zelfde verhaal: naar archief, dingen dubbel, weg.
* laptop-important onduidelijk welke laptop dit is/was.
* Bij (oude) backups is het helder dat er dubbele dingen zijn, naar archief, dus iets aan doen.
* Bij media etc is dit niet duidelijk, daar kan de size/md5 check dus helpen.
* Bepaalde soorten bestanden horen niet op bepaalde lokaties: .tcl files niet in /media bv, komt wel eens voor. 
  mp3 en avi files juist alleen in /media.
* current-backups: gemakkelijkst is huidige backup te renamen, een full backup te doen en dan de orig te verwijderen. Dit kun
  je regelmatig doen. 2 problemen hiermee: 1) in deze orig incremental backup kunnen dingen zitten die je wilt houden en
  2) je zou dit regelmatig willen checken in de database en dan afhandelen.
* Vooralsnog ignore gebruiken, om backup en cache even niet te doen, later wel, zie logboek [2012-01-29 16:23:53] ev,
* Bepalen wat voor mij heel belangrijk is, en dus op meer dan 2 plekken moet staan. Standaard is 2 plekken: bron+backup.
  Evt dingen bij als cache, maar is meer voor handigheid, niet voor veiligheid, kan evt meteen deleted worden.
* Laptop/install ook als een cache zien van /media/nas/install?
* Dingen die cache zijn, hoeven niet gebackupped te worden, zoals c:\media, c:\bieb, c:\install. Anderzijds kunnen dingen
  ook hier 'binnenkomen', als ik nieuwe software eerst in laptop/install neerzet, dan is backup wel handig. Of onderscheid
  maken tussen c:\install en c:\install-cache. Dit evt ook op dropbox doen, met bv bieb-cache.
* Als ik later opnieuw de boel inlees, dan meteen de goede kolommen met goede datatype.
* c:\aaa en /media/nas/aaa en ~/aaa zijn een soort temp-dirs. Ook werk-dirs, dus als het nog niet zo oud is, laten staan.
  als het oud is en 2x in aaa, dan mag sowieso 1 weg. Als er elders (in source) ook zoeen staat, mag die in aaa weg.
* Heb singles nu als cache gedefinieerd, kan er ook symlinks naar orig albums van maken, dan wel risico als albums verplaatsen etc.
  of album is niet zo leuk, wil weg, op 1 of 2 singles na. Dan singles plots niet meer cache, maar source. Sommige singles sowieso 
  alleen in source.
* Wat voor singles geldt, geldt dus ook voor Neil Young best of, zelf samengesteld uit andere albums.
* Moet nog wel iets met nicoprj en perftoolset, zowel op laptop als ubuntu, niet 1 van beide weg. Zolang ik met minimaal 10MB
  werk valt het wel mee, maar straks ook alles doen?
* /aaa/ dirs eerst op source gezet, en in tcl script -/- 100.
* Moest ook iets uit c:\windows\system32 verwijderd worden, geen goed plan. Deze gemarkeerd als system, dan niet meegenomen
  in zoektocht.
* c:/develop (vanwege java) ook als system noteren. Als iets system is, afblijven. Als in install en in system: ok. Als 2x in install, 
  dan mag er wel een weg. Als 2x in system, toch gewoon laten staan. Als in system/install en elders, mag elders weg.
* Lijkt bijna zinvol een rule engine te gebruiken.
* Toch belangrijk beide dingen te bekijken, en niet gewoon een ranglijst te maken.
* Groepen lijken toch belangrijk: system/progs/tools, install, source, backup, temp. Hierbinnen aspecten als .svn, uitzoeken.
  Als in 2 versch groepen, wint er 1, maar sowieso system nooit weg. install kan wel, source kan ook, als het dezelfde source is.
  Maar hoe zit het met git en svn, niet zo belangrijk zo lang het niet te groot is. In versch sources (laptop, ubuntu): afblijven.
* Had een dubbele entry in db naar dezelfde file, gevaarlijk, hier dus ook in script op checken, evt alleen in database 1 van beide weg.
  in praktijk kan dit wel gebeuren, als je later nog eens inlees, en gewoon een insert doet, geen upsert.
* Op media/nas nu zowel DellAxim als Dell-Axim-PDA. Niet zomaar weg omdat Dell Axim (bijna) weg, kunnen nog ergens notes zijn.
* Heb Downloads in ~ met torrent download, worden eerst lege bestanden gemaakt met 0-en, dus veel dezelfde. Deze natuurlijk niet
  verwijderen. Is wel een tempdir. Kan helpen om vlak voor verwijderen te checken of de datum en/of inhoud nog hetzelfde is, maar
  ook niet foolproof, als de download nog niet is begonnen. Dit is eigenlijk een soort extended memory, dus afblijven, alleen 
  wel opmerken mocht dit heel groot worden.
* Idee (uitvoerbaar?): zoek nu steeds 2 files die hetzelfde zijn: als 5 files hetzelfde zijn, vind je veel combi's. Kan deze
  5 ook met 1 query doen? Of bv wel starten met 1-op-1 check, als wat gevonden alles erbij zoeken en op volgorde zetten.
* Als 10 MB files klaar zijn, kijken wat er over is in oude backups: blijkbaar heb ik dit dan nergens anders, hoe komt dit?
  
Uitgangspunten en invarianten
=============================
* Zo zou het in theorie moeten zijn/worden, nadat ik klaar ben met opschonen, bij voorkeur ook zo ingericht dat het zo blijft.
* Backups: brondata is beschikbaar op andere lokatie (/home/nico, laptop, ndv.nl). Dus data die alleen in backup staat, en
  niet meer bij de bron, mag ofwel weg, ofwel naar een archief dir.
* Archief alleen op NAS, met backup naar 2TB.
* Media (music, films etc, alles in /media/nas/media) staat als bron op NAS, backup to 2TB.
* Dit geldt eigenlijk ook voor PC-kopie/f-drive
* Theorie is leuk, maar zal in praktijk veel tijd kosten te handhaven, tenzij ik dit kan automatiseren. Dus vooral focussen
  op grote bestanden, vooral als ze dubbel zijn of niet meer nodig.

Vragen/openstaande punten bij uitgangspunten
============================================
* Wat wil ik met de oude drives, niet veel ruimte op, of toch 1 met +100GB? De FAT is mogelijk een bootdisk, en verder ook
  images van drives, kan handig zijn, nu vergeten waar prog staat om te gebruiken. Als extra backup houden (als het er toch
  al op staat), lijkt beter dan leegmaken, kapotte drive en 'had ik het er maar op laten staan'.
* Kan evt ook in .zip/.rar gaan kijken. Voordeel van .zip is dat het kleiner is, sneller te kopieren, ook op USB en integrity
  check heeft. Nadeel is dat je programma hebt en bij corruptie van de zip je er niets meer mee kunt. Met losse files mss nog wel...
  
