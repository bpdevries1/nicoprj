# films2agenda.tcl - converteer films van OLV naar formaat dat in outlook geimporteerd kan worden.
# werkt als filter: stdin, stdout.

# globals
set FIELDS [list Onderwerp Begindatum Begintijd Einddatum Eindtijd Beschrijving]

set MAANDNR(januari) 1
set MAANDNR(februari) 2
set MAANDNR(maart) 3
set MAANDNR(april) 4
set MAANDNR(mei) 5
set MAANDNR(juni) 6
set MAANDNR(juli) 7
set MAANDNR(augustus) 8
set MAANDNR(september) 9
set MAANDNR(oktober) 10
set MAANDNR(november) 11
set MAANDNR(december) 12

# film: assoc array:
# - titel
# - beschrijving
# - datums: lijst van lijst met begindatum, begintijd

proc input {} {  	 	 	
	do 21 t/m vr 22 september  
	
Romance & Cigarettes  John Turturro   [Film]
	
Romance and Cigarettes is een aanstekelijke ‘working-class-musical’ over een Newyorkse staalarbeider die moet kiezen tussen zijn vrouw en zijn verleidelijke minnares. In zijn hart is hij een goede man en probeert hij alles in het werk te stellen om een weg terug te vinden naar zijn gezin. In een aaneenschakeling van krankzinnige scènes, aandoenlijk knullig gechoreografeerde dansjes en bekende, door de acteurs gezongen liefdesliedjes, geven de personages uiting aan hun gevoelens.



		
	Verenigde Staten 2006, lengte 115 minuten, regie John Turturro, met Kate Winslet, Susan Sarandon, James Gandolfini
	Entree (excl. verzendkosten) € 6.80  TDLV-pas € 5.00  Jeugd € 6.80  Jeugd TDLV-pas € 5.00  CJP € 5.50  65+ € 5.50 [seks] [grof taalgebruik]
	donderdag 21 september 2006 - 14:00 uur 	Koop kaarten 	
	donderdag 21 september 2006 - 21:45 uur 	Koop kaarten 	
	vrijdag 22 september 2006 - 16:30 uur 	Koop kaarten 	
	vrijdag 22 september 2006 - 21:45 uur 	Koop kaarten 	
}

proc main {argc argv} {
	puts_header
	reset_film film ; # zodat lijst van datums al bestaat.
	while {![eof stdin]} {
		gets stdin line
		if {[regexp {^(.*) \[Film\]$} $line z titel]} {
			puts_film film
			reset_film film
			set film(titel) $titel
			# 2 regels verder staan dan de beschrijving
			gets stdin line
			gets stdin line
			set beschr $line
			# de eerstvolgende niet-lege regel bevat verder info
			gets stdin line
			set line [string trim $line]
			while {$line == ""} {
				gets stdin line
				set line [string trim $line]
			}
			set film(beschrijving) "$beschr\n$line"
		} elseif {[regexp {Entree \(excl. verzendkosten\)} $line]} {
			# alle regels hieronder tot eerstvolgende niet-lege zijn show-datums
			gets stdin line
			set line [string trim $line]
			while {$line != ""} {
				lappend film(datums) [parse_datum $line]
				gets stdin line
				set line [string trim $line]
			}
		}

	}
	puts_film film
}

# line: 	donderdag 21 september 2006 - 14:00 uur 	Koop kaarten
# result: [list "21-9-2006" "14:00"]
# toch ook op 'Koop kaarten' letten, want kan ook 'afgelast' zijn.
proc parse_datum {line} {
	log "parse_datum: $line"
	if {[regexp {dag ([0-9]+) ([a-z]+) ([0-9]{4}) - ([0-9]{2}:[0-9]{2}) uur.*Koop kaarten} $line z dag str_maand jaar tijd]} {
		set maand [det_maand $str_maand]
		return [list "$dag-$maand-$jaar" $tijd]
	} else {
		return {}
	}
}

proc det_maand {str_maand} {
	global MAANDNR
	return $MAANDNR($str_maand)
}

proc puts_header {} {
	global FIELDS
	puts [join $FIELDS "\t"]
}

proc puts_film {film_name} {
	upvar $film_name film
	if {$film(titel) == ""} {
		return
	}
	foreach datum $film(datums) {
		puts_film_datum $film(titel) $film(beschrijving) $datum
	}
}

proc puts_film_datum {titel beschrijving datum} {
	if {[llength $datum] != 2} {
		return
	}
	set begindatum [lindex $datum 0]
	set begintijd [lindex $datum 1]
	set eindtijd [calc_eindtijd $begintijd]
	# alleen printen als de film 's avonds draait
	if {$begintijd >= "18:00"} {
		puts "\"$titel\"\t$begindatum\t$begintijd\t$begindatum\t$eindtijd\t\"$beschrijving\""
	}
}

# eindtijd 2 uur later zetten als begintijd, kan later nog naar tijdsduur kijken.
proc calc_eindtijd {begintijd} {
	regexp {^(.*):(.*)$} $begintijd z uur minuut
	set einduur [expr $uur + 2]
	if {$einduur >= 24} {
		set einduur 23
	}
	return "$einduur:$minuut"
}

proc reset_film {film_name} {
	upvar $film_name film
	set film(titel) ""
	set film(beschrijving) ""
	set film(datums) {}
}

set LOG 0
proc log {str} {
	global stderr LOG
	if {$LOG} {
		puts stderr $str
	}
}

main $argc $argv
