# nevobo2xls.tcl - vertaal nevobo ovz naar formaat in excel sheet.

source lib-agenda.tcl

# Bron:
#nr.  	datum  	tijd  	teams  	zaal  	veld  	uitsl.
#H4K LA 	vr 23/09/2005 	20:15 	Unicornus H4 - Wilhelmina H5 	Sph. De Kuil 	3 	2-3
#Vr 14 november 	21:15 	H3I JH 	Wilhelmina HS 4 - VC Omniworld HS 6 	Sph.Schuilenbur... 	H3I 	 
#Vr 26 september***21:45***H3I CJ***Afas-LEOS HS 3 - Wilhelmina HS 4***Sph De Korf***H3I***

#Doel:
#Onderwerp	Begindatum	Begintijd	Einddatum	Eindtijd	Beschrijving

proc main {argc argv} {
	puts_header
	while {![eof stdin]} {
		gets stdin line
		set temp_lline [split $line "\t"]
		set lline {}
		foreach el $temp_lline {
			lappend lline [string trim $el]
		}
		# puts [join $lline "***"]
		if {[llength $lline] != 8} {
			puts stderr "Unable to handle line: $line (#[llength $lline])"
			continue
		}
		if {0} {		
Unable to handle line: Datum    Tijd    Veld    Code    Wedstrijd       Locatie
        Poule   Meer informatie (#8
Unable to handle line: Vr 25-9-2009     21:15   2       H2F DI  Wilhelmina HS 3
- Lovoc HS 1    Sph.Schuilenbur...      H2F     Details (#8
Unable to handle line: Za 3-10-2009     14:45   1       H2F HD  ODIS HS 1 - Wilh
elmina HS 3     Sph De Fuik     H2F     Details (#8
		}
		foreach {datum starttijd veld code wedstrijd lokatie code2 code} $lline {
			set ol_datum [calc_outlook_datum $datum]
			set eindtijd [::agenda::calc_eindtijd $starttijd]
			set onderwerp "$wedstrijd ($lokatie, veld $veld)"
			set beschrijving $onderwerp
			puts "\"$onderwerp\"\t$ol_datum\t$starttijd\t$ol_datum\t$eindtijd\t\"$beschrijving\""
		}



if {0} {

		set datum [lindex $lline 1]
		if {![regexp {[a-z]{2} (.*)} $datum z datum]} {
			continue
		}

		regsub -all "/" $datum "-" datum
		
		set tijd [lindex $lline 2]

		set teams [lindex $lline 3]
		if {![regexp {^(.*) - (.*)$} $teams z team1 team2]} {
			continue
		}
		#set team1 [string trim $team1]
		#set team2 [string trim $team2]

		set zaal [lindex $lline 4]
		set veld [lindex $lline 5]
		# puts "$datum\t$tijd\t$zaal\t$veld\t$team\t$tegenst"
		set onderwerp "$team1 - $team2 ($zaal veld $veld)"
		set beschrijving "$team1 - $team2 in $zaal op veld $veld"
		set eindtijd [::agenda::calc_eindtijd $tijd]
		puts "\"$onderwerp\"\t$datum\t$tijd\t$datum\t$eindtijd\t\"$beschrijving\""
}
		
	}
}

proc puts_header {} {
	puts "Onderwerp\tBegindatum\tBegintijd\tEinddatum\tEindtijd\tBeschrijving"
}

proc fail {str} {
	global stderr
	puts stderr $str
	exit 1
}

# @param datum: Vr 26 september
set maanden [list januari februari maart april mei juni juli augustus september oktober november december]
set i 1
foreach maand $maanden {
	set ar_maandnr($maand) $i
	incr i
}

# 9-9-2009 jaartal wordt nu ook meegegeven, dus simpel
proc calc_outlook_datum {datum} {
	set result [string range $datum 3 end]
	if {[regexp {^[0-9\-]+$} $result]} {
		return $result
	} else {
		puts stderr "Cannot calc_outlook_datum from: $datum"
		return "*$datum*"
	}
}

# 9-9-09 oude versie, toen jaar er nog niet bij zat.
proc calc_outlook_datum_old {datum} {
	global ar_maandnr
	# return "ol: $datum"
  set ol_datum "ol: $datum"
	if {[regexp {^.. ([0-9]+) (.+)$} $datum z dag maand]} {
		set maandnr $ar_maandnr($maand)
		set ol_datum [det_toekomst_datum $dag $maandnr]
	} else {
		puts stderr "Cannot calc outlook datum from: $datum"
	}
	return $ol_datum
}

main $argc $argv
