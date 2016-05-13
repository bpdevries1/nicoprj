# maakpdq.tcl - maak pdq onderdelen obv servers-d.txt

proc main {} {
	while {![eof stdin]} {
		gets stdin line
		lappend lines $line
	}

	puts "# nodes"
	foreach line $lines {
		foreach {name visits demand} $line {
			puts "pdq.nodes  = pdq.CreateNode(\"$name.CPU\", pdq.CEN, pdq.FCFS)"
		}
	}

	puts "\n# visits and service demands"
	foreach line $lines {
		foreach {name visits demand} $line {
			puts "pdq.SetVisits(\"$name.CPU\", \"wko\", [komma2punt $visits], [komma2punt $demand])"
		}
	}

}

proc komma2punt {value} {
	regsub -all "," $value "." value
	return $value
}

main
