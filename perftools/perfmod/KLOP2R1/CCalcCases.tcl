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
		# handle_cases_openqn $lqns_control $project_name
	}

	private method handle_cases_closedqn {lqns_control project_name} {
		global env
		set TEST 0

		# omgeving
		set template_filename [file normalize [file join $project_name "KLOP2R1.xmltmp"]]
		$lqns_control set_template_filename $template_filename
		$lqns_control add_lqn_properties_filename [file join $project_name "KLOP2R1.lqnprop"]
		$lqns_control add_lqn_properties_filename [file join $project_name "KLOP2R1-PBrowser.lqnprop"]
		$lqns_control add_lqn_properties_filename [file join $project_name "KLOP2R1-PPortal.lqnprop"]
		$lqns_control add_lqn_properties_filename [file join $project_name "KLOP2R1-PGGHH.lqnprop"]
		$lqns_control add_lqn_properties_filename [file join $project_name "KLOP2R1-PGGHH-ServTest-minR.lqnprop"]
		# $lqns_control add_lqn_properties_filename [file join $project_name "KLOP2R1-PGGHH-ServTest.lqnprop"]
		# $lqns_control add_lqn_properties_filename [file join $project_name "KLOP2R1-PMF.lqnprop"]
		$lqns_control add_lqn_properties_filename [file join $project_name "KLOP2R1-PMF-ServTest.lqnprop"]
		$lqns_control set_project_name $project_name
		$lqns_control set_lqn_property LQN_Solver_Home $env(LQNS_HOME)
		
		# wat moet er gebeuren?
		$lqns_control set_method BOTH
		# $lqns_control set_method LQNS
		$lqns_control set_calc_asymp 0

		# waar moet op gelet worden?
		$lqns_control set_entry_names [list EBrowser]
		$lqns_control set_processor_name PGGHH ERaadpl_BDOrg
		$lqns_control set_tijd_eenheid "sec"

		$lqns_control set_lqn_property Z 15
		# $lqns_control set_lqn_property Z 5
		# mogelijk later Z=60 gebruiken, want uitg.punt is dat in model alleen calls die service-calls opleveren worden gemodelleerd, met kansen.
		# $lqns_control set_lqn_property Z 60
		
		if {$TEST} {
			$lqns_control set_method LQNS
			# $lqns_control set_method LQSIM
			# $lqns_control analyse N [list 1 10] Closed-Test
			$lqns_control set_lqn_property N 120
			# D_persoon = 0.022
			# $lqns_control analyse D_persoon [list 0.018 0.019 0.020 0.021 0.022] DPersoon 
			$lqns_control set_lqn_property D_persoon 0.010 
			# $lqns_control analyse D_persoon [list 0.010 0.012 0.014 0.016 0.018] DPersoon 
			$lqns_control analyse D_berichten [list 0.0018 0.0019 0.0020] DBerichten 
		} else {
			$lqns_control set_method LQSIM
			# $lqns_control analyse N [list 1 2 5 10 20 50 100 120 150 500 1000] ServTestMinR
			$lqns_control analyse N [list 1 2 5 10 20 50 100 120 150] ServTestMinR
			# $lqns_control analyse N [list 1 2 5 10 20 50 100 120 150] ServTest
			# $lqns_control analyse N [list 1 100] Closed
		}
	}	

}


