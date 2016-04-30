# nevobo2xls.tcl - vertaal nevobo ovz naar formaat in excel sheet.

# Bron:
#nr.  	datum  	tijd  	teams  	zaal  	veld  	uitsl.
#H4K LA 	vr 23/09/2005 	20:15 	Unicornus H4 - Wilhelmina H5 	Sph. De Kuil 	3 	2-3


#Doel:
#Datum	Tijd	Lokatie	veld	Team	Tegenst.
#vr 23-sep-05	 19:45 	 Sph.Schuilenburg 	2	H4	Switch H2 


proc main {argc argv} {
	while {![eof stdin]} {
		gets stdin line
		set lline [split $line "\t"]
		#puts "---"
		#foreach el $lline {
	#		puts "el: $el"
		#}

		set datum [lindex $lline 1]
		if {![regexp {[a-z]{2} (.*)} $datum z datum]} {
			continue
		}

		set tijd [lindex $lline 2]

		set teams [lindex $lline 3]
		if {![regexp {^(.*) - (.*)$} $teams z team1 team2]} {
			continue
		}
		if {[regexp {Wilhelmina (H[0-9])} $team1 z team]} {
			set tegenst $team2
		} elseif {[regexp {Wilhelmina (H[0-9])} $team2 z team]} {
			set tegenst $team1
		} else {
			fail "Geen Wilhelmina teams: $team1 - $team2"
		}
		
		set zaal [lindex $lline 4]
		set veld [lindex $lline 5]

		puts "$datum\t$tijd\t$zaal\t$veld\t$team\t$tegenst"

		#puts "datum: $datum"
		#puts "tijd: $tijd"
		#puts "team1: $team1"
		#puts "team2: $team2"
		#puts "team: $team"
		#puts "tegenst: $tegenst"
		#puts "zaal: $zaal"
		#puts "veld: $veld"
	
		
		if {[regexp {[^\t]+\t[a-z][a-z] ([0-9]{2}/[0-9]{2}/[0-9]{4})\t([0-9][0-9]:[0-9][0-9])\t([^-]+) - ([^\t]+)\t([^\t]+)\t([^\t]+)} $line z datum tijd team1 team2 zaal veld]} {
			puts "datum: $datum"
			puts "tijd: $tijd"
			puts "team1: $team1"
			puts "team2: $team2"
			puts "zaal: $zaal"
			puts "veld: $veld"
			puts ""
		}
	}
}

proc fail {str} {
	global stderr
	puts stderr $str
	exit 1
}

main $argc $argv
