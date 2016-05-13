# lqns-control.tcl - controller script for repeatedly calling lqns and parsing results

proc main {argc argv} {
	set template_filename "demo.lqntmp"
	set rootname [file rootname $template_filename]
	set fo [open "generated/$rootname-calc.tsv" w]
	puts $fo "# N X R Z U"
	foreach N {1 2 3 4 5 6 8 10} {
		lqns $fo $template_filename $N 0.0
	}
	foreach N {1 5 10 20 50} {
		lqns $fo $template_filename $N 1.0
	}
	# 100 threads, Z = 10
	lqns $fo $template_filename 100 10.0

	close $fo
}

proc lqns {fo template_filename N Z} {
	set rootname [file rootname $template_filename]
	set lqn_filename "generated/$rootname-$N.lqn" 
	make_lqn $template_filename $lqn_filename $N $Z
	call_lqns $lqn_filename
	parse_results $lqn_filename X R U
	puts $fo "$N\t$X\t$R\t$Z\t$U"
}

proc make_lqn {template_filename lqn_filename N Z} {
	set fi [open $template_filename r]
	set fo [open $lqn_filename w]
	while {![eof $fi]} {
		gets $fi line
		set line [replace_line $line N $N]
		set line [replace_line $line Z $Z]
		puts $fo $line 
	} 
	close $fi
	close $fo
}

proc replace_line {line var_name var_value} {
	set $var_name $var_value
	set re "\\$\\{$var_name\\}"
	# regsub -all "\$\{$var_name\}" $line $var_value line
	regsub -all $re $line $var_value line
	# set line [subst $line]
	return $line
}

proc call_lqns {lqn_filename} {
	set LQNS_EXE "C:\\nico\\util\\lqn\\LQN Solvers\\lqns.exe"
	catch {set res [exec $LQNS_EXE $lqn_filename -p]} res_stderr
}

proc parse_results {lqn_filename X_name R_name U_name} {
	upvar $X_name X
	upvar $R_name R
	upvar $U_name U
	set p_filename "[file rootname $lqn_filename].p"
	set fi [open $p_filename r]
	while {![eof $fi]} {
		gets $fi line
		if {[regexp {^X [0-9]+$} $line]} {
			parse_response $fi R
		} elseif {[regexp {^FQ [0-9]+$} $line]} {
			parse_throughput $fi X
		} elseif {[regexp {^P CPU [0-9]+$} $line]} {
			parse_utilisation $fi U
		}
	} 	
}

proc parse_response {fi R_name} {
	upvar $R_name R
	
	set found 0
	while {![eof $fi] && !$found} {
		gets $fi line
		if {[regexp {^demo +: demo +([0-9.]+)} $line z resp]} {
			set R $resp
			set found 1
		}
	}
}

proc parse_throughput {fi X_name} {
	upvar $X_name X
	set found 0
	while {![eof $fi] && !$found} {
		gets $fi line
		if {[regexp {^demo +: demo +([0-9.]+)} $line z thr]} {
			set X $thr
			set found 1
		}
	}
}

proc parse_utilisation {fi U_name} {
	upvar $U_name U
	set found 0
	while {![eof $fi] && !$found} {
		gets $fi line
		set name [lindex $line 0]
		if {$name == "demo_cpu"} {
			set U [lindex $line 5]
			set found 1
		}
	}
}

main $argc $argv
