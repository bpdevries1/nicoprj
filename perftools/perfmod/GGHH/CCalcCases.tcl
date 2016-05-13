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
		# set template_filename [file normalize [file join $project_name "GGHH.lqntmp"]]
		set template_filename [file normalize [file join $project_name "GGHH.xmltmp"]]
		set lqn_properties_filename [file join $project_name "GGHH.lqnprop"]
		$lqns_control set_entry_name ECl
		$lqns_control set_processor_name PBVR EBVR3
		$lqns_control set_tijd_eenheid "sec"
		$lqns_control set_calc_asymp 0
		# $lqns_control set_calc_asymp 1 ; # werkt hier niet, N betekent even wat anders, berekening loopt in de soep.
		$lqns_control set_method BOTH
		
		####### Zowel LQNS als simulatie met oplopend aantal gebruikers.

		# test met nieuwe interface
		if {1} {
			# set lqn_properties_filename [file join $project_name "GGHH.lqnprop"]
			$lqns_control set_lqn_properties_filename [file join $project_name "GGHH.lqnprop"]
			$lqns_control set_project_name $project_name
			$lqns_control set_template_filename $template_filename
			$lqns_control set_method LQNS
			$lqns_control set_lqn_property Z 60
			# $lqns_control set_lqn_property Z 0
			$lqns_control set_lqn_property N 1500
			# $lqns_control set_lqn_property N 1 ; # eerst 1 gebruiker, om te checken.
			$lqns_control set_lqn_property N_BSB 1
			$lqns_control set_lqn_property N_BVR 1
			# X en R niet heel afhankelijk van N_BSN, omdat de grootste D (0,310) toch steeds maar een keer wordt gedaan.
			$lqns_control analyse N_BSN [list 0 1 2 3 4 5 6 8 10] selbsb

			# oplopend aantal CPU's voor de BSB
			$lqns_control set_method BOTH
			$lqns_control set_lqn_property N_BSN 1
			$lqns_control set_lqn_property N_BVR 4
			# $lqns_control analyse N_BSB [list 1 2 4 8 16] BSBCPUs
			$lqns_control analyse N_BSB [list 4 5 6 7 8 12 16 20] BSBCPUs

		
		}
	}

}


