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

		$lqns_control set_entry_names [list EBr]
		$lqns_control set_processor_name PABS EABS
		$lqns_control set_tijd_eenheid "sec"

		####### Met Inf server, dus alleen LQNS ######
		if {1} {
			if {1} {
				$lqns_control set_method LQNS
				$lqns_control set_template_filename [file normalize [file join $project_name "TestSer.xmltmp"]]
				$lqns_control set_lqn_property Z 60
				$lqns_control set_lqn_property NW_INF 1
				# tot N=600, hierna systeem verzadigd.
				$lqns_control analyse N [concat [list 1 2 3 4 5 6 8 10] [make_list 20 20 100] [make_list 200 100 600]] Ser-Inf-Z60sec
			}

			####### Test Parallelle calls ######
			if {1} {
				# $lqns_control set_method LQNS
				$lqns_control set_template_filename [file normalize [file join $project_name "TestPar.xmltmp"]]
				$lqns_control set_method LQNS
				$lqns_control set_lqn_property Z 60
				$lqns_control set_lqn_property NW_INF 1
				# tot N=600
				$lqns_control analyse N [concat [list 1 2 3 4 5 6 8 10] [make_list 20 20 100] [make_list 200 100 600]] Par-Inf-Z60sec
			}
		}

		####### Test ######
		if {0} {
			# $lqns_control set_method LQNS
			$lqns_control set_template_filename [file normalize [file join $project_name "TestParMin.xmltmp"]]
			$lqns_control set_method BOTH
			$lqns_control set_lqn_property Z 100
			$lqns_control set_lqn_property D_BVR 20.0
			# $lqns_control set_lqn_property D_ABS 3.0
			$lqns_control set_lqn_property D_WP 0.0001
			$lqns_control set_lqn_property N 1
			$lqns_control analyse D_ABS [make_list 5 5 30] ParMinDABS-Z10sec

			$lqns_control set_lqn_property D_ABS 20
			$lqns_control set_lqn_property D_WP 0.0001
			$lqns_control set_lqn_property N 1
			$lqns_control analyse D_BVR [make_list 5 5 30] ParMinDBVR-Z10sec
		}

		if {0} {
			####### Test ######
			if {1} {
				# $lqns_control set_method LQNS
				$lqns_control set_template_filename [file normalize [file join $project_name "TestSer.xmltmp"]]
				$lqns_control set_method BOTH
				$lqns_control set_lqn_property Z 10
				$lqns_control set_lqn_property NW_INF 0
				$lqns_control analyse N [list 1 2 3 4 5 6 8 10] Ser-Z10sec
			}

			####### Test Parallelle calls ######
			if {1} {
				# $lqns_control set_method LQNS
				$lqns_control set_template_filename [file normalize [file join $project_name "TestPar.xmltmp"]]
				$lqns_control set_method BOTH
				$lqns_control set_lqn_property Z 10
				$lqns_control set_lqn_property NW_INF 0
				$lqns_control analyse N [list 1 2 3 4 5 6 8 10] Par-Z10sec
			}

			####### Test ######
			if {1} {
				# $lqns_control set_method LQNS
				$lqns_control set_template_filename [file normalize [file join $project_name "TestSer.xmltmp"]]
				$lqns_control set_method BOTH
				$lqns_control set_lqn_property Z 10
				$lqns_control set_lqn_property NW_INF 1
				$lqns_control analyse N [list 1 2 3 4 5 6 8 10] Ser-Inf-Z10sec
			}

			####### Test Parallelle calls ######
			if {1} {
				# $lqns_control set_method LQNS
				$lqns_control set_template_filename [file normalize [file join $project_name "TestPar.xmltmp"]]
				$lqns_control set_method BOTH
				$lqns_control set_lqn_property Z 10
				$lqns_control set_lqn_property NW_INF 1
				$lqns_control analyse N [list 1 2 3 4 5 6 8 10] Par-Inf-Z10sec
			}
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


