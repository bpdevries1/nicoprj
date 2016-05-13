# replace-relatie.tcl - vervang Relatie items door afzonderlijke URL's hiervoor.
# input: blokje XML waar 'Relatie' aantal keer in voorkomt.
# output: blokjes XML waar 'Relatie' vervangen is door specifieke requests: ZoekKlantBSN, ZoekKlantPC, SelectKlant, SelectPartner en SelectOverig.

proc main {} {
	set tekst [read stdin]
	set lst_pages [list ZoekKlantBSN ZoekKlantPC SelectKlant SelectPartner SelectOverig]
	foreach page $lst_pages {
		regsub -all "Relatie" $tekst $page tekst_page
		puts $tekst_page
		# puts "\n"
	}
}

main
