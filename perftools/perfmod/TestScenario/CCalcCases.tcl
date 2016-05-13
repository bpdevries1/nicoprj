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
		$lqns_control set_lqn_properties_filename [file join $project_name "TestLoop.lqnprop"]

		$lqns_control set_entry_names [list EBr]
		$lqns_control set_processor_name PBVR EBVR
		$lqns_control set_tijd_eenheid "sec"

		####### Met Inf server, dus alleen LQNS ######
		if {1} {
			$lqns_control set_method BOTH
			$lqns_control set_template_filename [file normalize [file join $project_name "TestLoop.xmltmp"]]
			$lqns_control set_lqn_property Z 60
			$lqns_control set_lqn_property NW_INF 1
			# tot N=600, hierna systeem verzadigd.
			$lqns_control analyse N [list 1 2 5 10] TestLoop-Z60sec
		}
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


