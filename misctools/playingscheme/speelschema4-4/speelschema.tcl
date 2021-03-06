proc main {} {
	init
	calc_wedstrijden_rec [list [list A 1 B 2]]
}

proc init {} {
	global lst_heren lst_dames lst_alles ar_ntoplace nwedstrijden ar_samen
	set lst_heren [list A B C D]
	set lst_dames [list 1 2 3 4]
	set lst_alles [list A B C D 1 2 3 4]
	set nwedstrijden 8
	set nwedstrijden_pp [expr $nwedstrijden * 4 / ([llength $lst_heren] + [llength $lst_dames])]
	foreach h $lst_heren {
		set ar_ntoplace($h) $nwedstrijden_pp
	}
	foreach d $lst_dames {
		set ar_ntoplace($d) $nwedstrijden_pp
	}
	foreach h $lst_heren {
		foreach d $lst_dames {
			set ar_samen($h$d) 0
		}
	}
	
	# eerste wedstrijd vast invullen
	foreach s [list A B 1 2] {
		incr ar_ntoplace($s) -1
	}
	set ar_samen(A1) 1
	set ar_samen(B2) 1
}

proc calc_wedstrijden_rec {lst_wedstrijden} {
	global lst_heren lst_dames ar_ntoplace nwedstrijden ar_samen
	if {[llength $lst_wedstrijden] == $nwedstrijden} {
		print_oplossing $lst_wedstrijden
	} else {
		foreach h1 $lst_heren {
			if {$ar_ntoplace($h1) <= 0} {
				continue
			}
			foreach h2 $lst_heren {
				if {$ar_ntoplace($h2) <= 0} {
					continue
				}
				if {$h2 > $h1} {
					# dus niet gelijk, en geen dubbele hier
					foreach d1 $lst_dames {
						if {$ar_ntoplace($d1) <= 0} {
							continue
						}
						incr ar_samen($h1$d1)
						if {$ar_samen($h1$d1) > 1} {
							# spelen al samen in dit schema
							incr ar_samen($h1$d1) -1
							continue
						}
						foreach d2 $lst_dames {
							if {$d1 != $d2} {
								if {$ar_ntoplace($d2) <= 0} {
									continue
								}
								incr ar_samen($h2$d2)
								if {$ar_samen($h2$d2) > 1} {
									# spelen al samen in dit schema
									incr ar_samen($h2$d2) -1
									continue
								}
								
								# alle 4 moeten minimaal nog 1 keer spelen
								set spelers [list $h1 $d1 $h2 $d2]
								foreach speler $spelers {
									incr ar_ntoplace($speler) -1
								}
								# recursieve aanroep
								set lst_prev $lst_wedstrijden
								lappend lst_wedstrijden $spelers
								calc_wedstrijden_rec $lst_wedstrijden
								
								# en spul terugzetten
								set lst_wedstrijden $lst_prev
								foreach speler $spelers {
									incr ar_ntoplace($speler) 1
								}
								incr ar_samen($h2$d2) -1
							}
						}
						incr ar_samen($h1$d1) -1
					}
				}
			}
		}
	}
}

# @todo bepalen aantal verschillende, iets als

set noplossingen 0
set max_tot_verschillend 0
proc print_oplossing {lst_wedstrijden} {
	global noplossingen max_tot_verschillend lst_alles
	incr noplossingen
	array unset tegen
	foreach s1 $lst_alles {
		foreach s2 $lst_alles {
			if {$s1 != $s2} {
				set tegen($s1-$s2) 0
			}
		}
	}
	set lst_lines {}
	foreach wedstrijd $lst_wedstrijden {
		foreach {h1 d1 h2 d2} $wedstrijd {
			lappend lst_lines "$h1$d1 - $h2$d2"
			foreach s1 [list $h1 $d1] {
				foreach s2 [list $h2 $d2] {
					incr tegen($s1-$s2) 1
					incr tegen($s2-$s1) 1
					set tegen2($s1-$s2) 1
					set tegen2($s2-$s1) 1
				}
			}
		}
	}
	set tot_verschillend [llength [array names tegen2]]
	if {$tot_verschillend > $max_tot_verschillend} {
		set lst {}
		set geen_oplossing 0
		foreach el [lsort [array names tegen]] {
			lappend lst "$el: $tegen($el)"
			if {$tegen($el) > 2} {
				set geen_oplossing 1
			}
		}
		if {!$geen_oplossing} {
			set max_tot_verschillend $tot_verschillend
			puts "Oplossing $noplossingen:"
			puts [join $lst_lines "\n"]
			puts "\n#verschillende tegenstanders totaal: $tot_verschillend"
			puts [join $lst "; "]
			puts "--------"
		}
	}
}

main
