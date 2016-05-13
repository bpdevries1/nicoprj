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


		# omgeving
		set template_filename [file normalize [file join $project_name "CR2.xmltmp"]]
		$lqns_control set_template_filename $template_filename
		$lqns_control set_lqn_properties_filename [file join $project_name "CR2.lqnprop"]
		$lqns_control set_project_name $project_name

		# wat moet er gebeuren?
		$lqns_control set_method BOTH
		$lqns_control set_calc_asymp 0

		# waar moet op gelet worden?
		$lqns_control set_entry_name EBrKB
		$lqns_control set_processor_name PWPS EWPSKB
		$lqns_control set_tijd_eenheid "sec"

		# specifieke properties en wat varieren op de X-as?
		$lqns_control set_lqn_property Z 60
		#$lqns_control analyse N [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100 200 500 1000 2000 3000 4000 5000] Z60sec
		#$lqns_control analyse N [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100 200 300 400 500] Z60sec
		$lqns_control analyse N [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100 110 120 130] Z60sec		

		$lqns_control set_lqn_property N_BSB 16
		$lqns_control set_lqn_property N_BVR 2
		$lqns_control analyse N [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100 200 500 750 1000 1250 1500] scaled


		if {$TEST} {
			$lqns_control set_method LQNS
			$lqns_control analyse N [list 1 100] Z60sec
		}
		
	}

}


