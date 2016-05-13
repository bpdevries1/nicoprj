# functionaliteit van calc-showcase.bat overnemen.
#
# uitgangspunten:
# per uitzoekpunt (whatif) een name, hier een lqntmp file en als output een generated-dir.
# meetwaarden ophalen en in 'generated' dir zetten. Hiernaar verwijzen vanuit de .m files (om .png te maken)

package require Itcl

# source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]

addLogger calccases
setLogLevel calccases info
# setLogLevel calccases debug

# class maar eenmalig definieren
if {[llength [itcl::find classes CCalcCases]] > 0} {
	return
}

itcl::class CCalcCases {

	public constructor {} {
	
	}

	public method handle_cases {lqns_control project_name} {
		$lqns_control set_project_name $project_name
		$lqns_control set_lqn_properties_filename [file join $project_name "TestPar.lqnprop"]
		set template_filename [file normalize [file join $project_name "TestPar.xmltmp"]]
		$lqns_control set_template_filename $template_filename

		$lqns_control set_entry_names [list EBr]
		# $lqns_control set_processor_name PABS EABS
		$lqns_control set_processor_name PWP EWP
		$lqns_control set_tijd_eenheid "sec"
		# $lqns_control set_method LQNS
		# $lqns_control set_method BOTH
		$lqns_control set_method LQSIM
		$lqns_control set_lqn_property Z 10

		# 3 assen, dus 3 loops in elkaar
		foreach call2 {EBVR EABS} {
			foreach  latency {0 0.5} {
				foreach exec_parallel {0 1} {
					handle_cases_point $lqns_control $call2 $latency $exec_parallel
				}
			}
		}
	}

	private method handle_cases_point {lqns_control call2 latency exec_parallel} {
		$lqns_control set_lqn_property Call2_entry $call2
		$lqns_control set_lqn_property D_ELcyBVR $latency
		$lqns_control set_lqn_property D_ELcyABS $latency
		$lqns_control set_lqn_property EXEC_PARALLEL $exec_parallel
		set str_case_point [det_str_case_point $call2 $latency $exec_parallel]
		
		# $lqns_control analyse N [list 1 2 3 4 5 6 8 10 20 50 75 100] $str_case_point
		# $lqns_control analyse N [list 1 10 20 50 75 100] $str_case_point
		$lqns_control analyse N [list 1 5 10 15 20] $str_case_point
	
	}
	
	private method det_str_case_point {call2 latency exec_parallel} {
		set str ""
		if {$call2 == "EBVR"} {
			append str "1srv-"
		} else {
			append str "2srv-"
		}
		append str "latency$latency-"
		if {$exec_parallel} {
			append str "par"
		}	else {
			append str "ser"
		}
		return $str
	}

	private method make_list {start step stop} {
		set result {}
		set i $start
		while {$i <= $stop} {
			lappend result $i
			set i [expr $i + $step]
		}
		return $result
	}

}


