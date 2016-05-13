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
		handle_cases_closedqn $lqns_control $project_name
	}

	private method handle_cases_closedqn {lqns_control project_name} {
		global env
		set TEST 0

		# omgeving
		set template_filename [file normalize [file join $project_name "KLOP2R1.xmltmp"]]
		$lqns_control set_template_filename $template_filename
		$lqns_control add_lqn_properties_filename [file join $project_name "KLOP2R1.lqnprop"]
		$lqns_control set_project_name $project_name
		$lqns_control set_lqn_property LQN_Solver_Home $env(LQNS_HOME)
		
		# wat moet er gebeuren?
		$lqns_control set_method BOTH
		# $lqns_control set_method LQNS
		$lqns_control set_calc_asymp 0

		# waar moet op gelet worden?
		$lqns_control set_entry_names [list EBrowser]
		$lqns_control set_processor_name PP5 EService
		$lqns_control set_tijd_eenheid "sec"

		$lqns_control set_lqn_property Z 5
		
		if {$TEST} {
			$lqns_control set_method LQNS
			$lqns_control analyse N [list 1 10] Closed-Test
		} else {
			$lqns_control set_method LQSIM
			$lqns_control analyse N [list 1 2 5 10 20 40 80 100 120 150 200] Closed-MSU40
			
			$lqns_control set_lqn_property P5_MSU 100.0
			$lqns_control analyse N [list 1 2 5 10 20 40 80 100 120 150 200 250 300] Closed-MSU100
			
			# nu speedfactor == MSU's
			# $lqns_control set_lqn_property D_Service [expr [$lqns_control get_lqn_property D_Service] * 40]
			$lqns_control set_lqn_property N 1800
			$lqns_control analyse P5_MSU [list 20 40 80 120 200 300 400] VarMSUP5-N1800
		}
	}	

}


