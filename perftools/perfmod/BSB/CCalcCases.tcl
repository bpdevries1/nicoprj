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
		# set template_filename [file normalize [file join $project_name "BSB.lqntmp"]]
		set template_filename [file normalize [file join $project_name "BSB.xmltmp"]]
		set lqn_properties_filename [file join $project_name "BSB.lqnprop"]
		$lqns_control set_entry_names [list EClPers]

		$lqns_control set_processor_name PCPU ECPUPers
		$lqns_control set_tijd_eenheid "sec"
		# $lqns_control set_calc_asymp 0
		# $lqns_control set_calc_asymp 1 ; # werkt hier niet, N betekent even wat anders, berekening loopt in de soep.
		$lqns_control set_method BOTH
		
		####### Zowel LQNS als simulatie met oplopend aantal gebruikers.

		$lqns_control set_project_name $project_name
		# $lqns_control set_result_dirname $result_dirname

		# axislabels
		$lqns_control set_axis_label msgsize "msgsize (kilobyte)"
		$lqns_control set_axis_label factor_non_pers "Factor niet-persistente berichten"

		# multiclass
		if {0} {
			$lqns_control set_template_filename [file normalize [file join $project_name "BSB.xmltmp"]]
			$lqns_control set_lqn_properties_filename [file join $project_name "BSB.lqnprop"]
			$lqns_control set_method LQNS
			# N moet groter dan 1, omdat hiermee verhouding wordt bepaald. Niet bepalen met factor in aantal calls naar BSB,
			# want wil R en X per class zien.
			$lqns_control set_entry_names [list EClPers EClNon]
			$lqns_control set_lqn_property Z 0
			$lqns_control set_lqn_property N 10
			$lqns_control set_lqn_property factor_non_pers 0.6
			$lqns_control analyse msgsize [list 1 2 5 10 20 50 100 200] closed-mc-60-40

			# ook std pers en non-pers, wel N op 10 houden ter vergelijking.
			# $lqns_control set_lqn_property N 1
			
			$lqns_control set_entry_names [list EClPers]
			$lqns_control set_lqn_property factor_non_pers 0.0
			$lqns_control analyse msgsize [list 1 2 5 10 20 50 100 200] closed-pers

			$lqns_control set_entry_names [list EClNon]
			# $lqns_control set_entry_name EClNon
			$lqns_control set_processor_name PCPU ECPUNon
			$lqns_control set_lqn_property factor_non_pers 1.0
			$lqns_control analyse msgsize [list 1 2 5 10 20 50 100 200] closed-nonpers
		
			# dan nog de factor laten loopen, bij msgsize = 10
			# $lqns_control set_entry_name EClNon
			$lqns_control set_processor_name PCPU ECPUNon
			$lqns_control set_lqn_property msgsize 10
			$lqns_control set_entry_names [list EClPers EClNon]
			$lqns_control analyse factor_non_pers [list 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0] closed-fct_np
			# $lqns_control analyse factor_non_pers [list 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0] closed-fct_np_nonpers

			if {0} {
				# niet meer nodig, nu zowel pers als non-pers in 1 grafiek.
				$lqns_control set_entry_name EClPers
				$lqns_control set_processor_name PCPU ECPUPers
				$lqns_control set_lqn_property msgsize 10
				$lqns_control analyse factor_non_pers [list 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0] closed-fct_np_pers
			}		
		}

		# multiclass, open QN
		if {1} {
			$lqns_control set_template_filename [file normalize [file join $project_name "BSBOpenQN.xmltmp"]]
			$lqns_control set_lqn_properties_filename [file join $project_name "BSBOpenQN.lqnprop"]
			# $lqns_control set_method LQNS
			$lqns_control set_method BOTH
			# N moet groter dan 1, omdat hiermee verhouding wordt bepaald. Niet bepalen met factor in aantal calls naar BSB,
			# want wil R en X per class zien.
			$lqns_control set_lqn_property Z 0

			# wat varieren met goede Xin (= arrival rate)
			# Uit loopen van Xin blijkt 60 wel aardig te zijn: tegen max, maar moet nog kunnen.
			$lqns_control set_lqn_property Xin 1.0
			$lqns_control set_lqn_property factor_non_pers 0.6
			$lqns_control analyse msgsize [list 1 2 5 10 20 50 100 200] open-mc-60-40

			# ook std pers en non-pers, wel N op 10 houden ter vergelijking.
			
			$lqns_control set_lqn_property factor_non_pers 0.0
			$lqns_control analyse msgsize [list 1 2 5 10 20 50 100 200] open-pers

			$lqns_control set_entry_name EClNon
			$lqns_control set_processor_name PCPU ECPUNon
			$lqns_control set_lqn_property factor_non_pers 1.0
			$lqns_control analyse msgsize [list 1 2 5 10 20 50 100 200] open-nonpers
		
			# dan nog de factor laten loopen, bij msgsize = 10
			# Uit loopen van Xin blijkt 60 wel aardig te zijn: tegen max, maar moet nog kunnen.
			# Dit is wel bij factor 0.6, dus bij factor 0.0 toch weer veel te hoog
			$lqns_control set_lqn_property Xin 30.0
			$lqns_control set_entry_name EClNon
			$lqns_control set_processor_name PCPU ECPUNon
			$lqns_control set_lqn_property msgsize 10
			$lqns_control analyse factor_non_pers [list 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0] open-fct_np_nonpers

			$lqns_control set_entry_name EClPers
			$lqns_control set_processor_name PCPU ECPUPers
			$lqns_control set_lqn_property msgsize 10
			$lqns_control analyse factor_non_pers [list 0.0 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1.0] open-fct_np_pers

			# arrival rate laten oplopen, met factor 0.6
			$lqns_control set_lqn_property factor_non_pers 0.6
			$lqns_control set_entry_name EClPers
			$lqns_control set_processor_name PCPU ECPUPers
			$lqns_control set_lqn_property msgsize 10
			$lqns_control analyse Xin [list 1.0 5.0 10.0 20.0 30.0 40.0 50.0 60.0 62.0 64.0 66.0 68.0 70.0] open-Xin
				
		}

		# test
		if {0} {
			$lqns_control set_template_filename [file normalize [file join $project_name "BSB.xmltmp"]]
			$lqns_control set_lqn_properties_filename [file join $project_name "BSB.lqnprop"]
			$lqns_control set_method LQNS
			# N moet groter dan 1, omdat hiermee verhouding wordt bepaald. Niet bepalen met factor in aantal calls naar BSB,
			# want wil R en X per class zien.
			
			$lqns_control set_lqn_property Z 0
			$lqns_control set_lqn_property N 10
			$lqns_control set_entry_name EClNon
			$lqns_control set_processor_name PCPU ECPUNon
			$lqns_control set_lqn_property factor_non_pers 1.0
			$lqns_control analyse msgsize [list 1 2 5 10 20 50 100 200] nonpers
		}
		
		#test 2
		if {0} {
			$lqns_control set_lqn_property Z 0
			$lqns_control set_lqn_property N 10
			$lqns_control set_lqn_property factor_non_pers 0.6
			$lqns_control analyse msgsize [list 1] mc-60-40
			
		}

	}


}


