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
		set TEST 0

		set template_filename [file normalize [file join $project_name "KLOP2.xmltmp"]]
		$lqns_control set_template_filename $template_filename
		$lqns_control set_lqn_properties_filename [file join $project_name "KLOP2.lqnprop"]
		$lqns_control set_project_name $project_name

		# wat moet er gebeuren?
		# $lqns_control set_method BOTH
		$lqns_control set_method LQNS
		$lqns_control set_calc_asymp 0

		# waar moet op gelet worden?
		$lqns_control set_entry_names [list EBr EESBBericht EESBRelatie]
		$lqns_control set_processor_name PSys ESys
		$lqns_control set_tijd_eenheid "sec"
		$lqns_control set_entry_names [list EKlant EMW ESys]

		# eerst KLOP2 release 1
		if {!$TEST} {
			if {1} {
				$lqns_control set_entry_names [list EKlant]
				$lqns_control set_method LQNS
				# $lqns_control set_method BOTH
				$lqns_control set_lqn_property N_MW 450
				$lqns_control analyse Xin [list 0.5 1.0 1.5 2.0 2.5] Rel1-openqn
		
				# dan KLOP2 end state
				$lqns_control set_lqn_property N_MW 1450
				$lqns_control analyse Xin [list 1 2 3 4 5 6 7 8] Endstate-openqn
			}
			if {0} {
				# $lqns_control set_method LQNS
				$lqns_control set_method LQSIM
				$lqns_control set_lqn_property N_MW 450
				$lqns_control set_lqn_property Z_Klant 0
				# $lqns_control analyse N_Klanten [list 1 10 20 50 100 150 200 500 1000 2000] Rel1-test-closedqn
				$lqns_control analyse N_Klanten [list 1 100 200 300 400 500 600 700] Rel1-closedqn
			
				$lqns_control set_method LQSIM
				$lqns_control set_lqn_property N_MW 1450
				$lqns_control set_lqn_property Z_Klant 0
				# $lqns_control analyse N_Klanten [list 1 10 20 50 100 150 200 500 1000 2000] Rel1-test-closedqn
				$lqns_control analyse N_Klanten [list 1 200 500 1000 2000 3000 4000] Endstate-closedqn
			}
		}
		
		if {$TEST} {
			if {0} {
				$lqns_control set_method LQSIM
				$lqns_control set_lqn_property N_MW 450
				$lqns_control analyse Xin [list 1 2 3 4 5 6 7] Rel1-test-openqn
			}
			if {1} {
				$lqns_control set_method LQNS
				$lqns_control set_lqn_property N_MW 450
				$lqns_control set_lqn_property Z_Klant 0
				# $lqns_control analyse N_Klanten [list 1 10 20 50 100 150 200 500 1000 2000] Rel1-test-closedqn
				$lqns_control analyse N_Klanten [list 1 100 200 300 400 500] Rel1-test-closedqn
			}
		}
	}

}


