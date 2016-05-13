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
		# set template_filename [file normalize [file join $project_name "Cluster.lqntmp"]]
		$lqns_control set_project_name $project_name
		set template_filename [file normalize [file join $project_name "Cluster.xmltmp"]]
		set lqn_properties_filename [file join $project_name "Cluster.lqnprop"]
		$lqns_control set_entry_name EBrKB
		# $lqns_control set_processor_name PWPS EWPSKB
		$lqns_control set_processor_name P140 EWPSKB1
		$lqns_control set_tijd_eenheid "sec"

		set lqn_properties_filename [file join $project_name "Cluster.lqnprop"]

		####### Zowel LQNS als simulatie met oplopend aantal gebruikers.
		if {1} {
			# $lqns_control set_method BOTH
			# $lqns_control set_method LQSIM
			$lqns_control set_method LQNS
			$lqns_control set_calc_asymp 0

			$lqns_control set_template_filename $template_filename
			$lqns_control set_lqn_properties_filename [file join $project_name "Cluster.lqnprop"]
			# $lqns_control set_dirname $dirname
			# $lqns_control set_result_dirname $result_dirname

			$lqns_control set_lqn_property Z 0
			$lqns_control analyse N [list 1 2 3 4 5 6 8 10] Z-0sec
		}

		##### Oplopende wachttijd met 1000 gebruikers ############
		if {0} {
			$lqns_control set_method BOTH
			set l_0_30 {}
			for {set i 0} {$i <= 20} {incr i 5} {
				lappend l_0_30 $i
			}
			for {set i 22} {$i <= 50} {incr i 2} {
				lappend l_0_30 $i
			}
			# $lqns_control lqns_control $dirname $l_0_30 [list 1000] $template_filename $lqn_properties_filename $result_dirname Z-var
		}

		######## Open QN #########
		$lqns_control set_method BOTH
		set template_filename [file normalize [file join $project_name "Cluster-OpenQN.xmltmp"]]
		set lqn_properties_filename [file join $project_name "Cluster.lqnprop"]
		$lqns_control set_calc_asymp 0
		# $lqns_control lqns_control $project_name 0 [list 1 2 3 4 5 6 8 10 15 20 22 24 26 28 30 31 32 33 34 40] $template_filename $lqn_properties_filename $result_dirname OpenQN-1

	}


}


