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
		handle_cases_relatie $lqns_control $project_name
		# handle_cases_per_page $lqns_control $project_name
		# handle_cases_openqn $lqns_control $project_name
	}

	private method handle_cases_relatie {lqns_control project_name} {
		set TEST 0

		# omgeving
		set template_filename [file normalize [file join $project_name "CR2.xmltmp"]]
		$lqns_control set_template_filename $template_filename
		$lqns_control set_lqn_properties_filename [file join $project_name "CR2.lqnprop"]
		$lqns_control set_project_name $project_name

		# wat moet er gebeuren?
		# $lqns_control set_method BOTH
		$lqns_control set_method LQNS
		$lqns_control set_calc_asymp 0

		# waar moet op gelet worden?
		$lqns_control set_entry_names [list EBr EESBBericht EESBRelatie]
		# $lqns_control set_entry_names [list EESBBericht EESBRelatie]
		# $lqns_control set_entry_names [list EBr EHttpInlog EHttpRelatie]
		$lqns_control set_processor_name P151 EWPS
		$lqns_control set_tijd_eenheid "sec"

		if {!$TEST} {
			if {1} {
				$lqns_control set_entry_names [list EBr]
				# specifieke properties en wat varieren op de X-as?
				$lqns_control set_lqn_property Z 0
				$lqns_control analyse N [list 1 2 3 4 5 6 8 10] Z0sec
		
				$lqns_control set_lqn_property Z 1
				$lqns_control analyse N [list 1 5 10 20 30 40 50 70 75 80 100] Z1sec		
	
				# $lqns_control set_lqn_property Z 10
				# $lqns_control analyse N [list 1 10 20 50 75 100 150 200 250] Z10sec		

			}

			if {0} {
				# nogmaals uitvoeren, dan R's van ESB meten, deze later combineren met meetresultaten.
				$lqns_control set_entry_names [list EBr EESBBericht EESBRelatie]
				$lqns_control set_method BOTH

				$lqns_control set_lqn_property Z 0
				$lqns_control analyse N [list 1 2 3 4 5 6 8 10] Z0sec-ESB

				$lqns_control set_lqn_property Z 1
				$lqns_control analyse N [list 1 5 10 20 30 40 50 70 75 80 100] Z1sec-ESB
			}
			
			if {1} {
				# geschaalde omgeving, doel is N=1500, Z=60, R < 2.
				
				# taken op een processor
				$lqns_control set_lqn_property NT_Http 1500
				$lqns_control set_lqn_property NT_WPS 200
				$lqns_control set_lqn_property NT_ESB_Relatie 50
				$lqns_control set_lqn_property NT_ESB_Bericht 50
				
				# aantal processoren
				# $lqns_control set_lqn_property N_151 12
				$lqns_control set_lqn_property N_151 10
				$lqns_control set_lqn_property N_154 8
				
				$lqns_control set_entry_names [list EBr]
				$lqns_control set_method BOTH
				$lqns_control set_lqn_property Z 27
				$lqns_control analyse N [list 1 100 200 500 800 1000 1200 1435 1750] scaled		

				$lqns_control set_lqn_property N 1435
				$lqns_control analyse N_151 [list 1 2 4 6 8 10 12] scaled-N151
			}
			
				
			# test met D_Bvr variabel
			if {0} {
				$lqns_control set_lqn_property Z 0
				$lqns_control set_lqn_property D_BVR 0.2
				$lqns_control analyse N [list 1 2 3 4 5 6 8 10] Z0sec
			}
	
			if {0} {
				$lqns_control set_lqn_property N_ESB 16
				$lqns_control set_lqn_property N_BVR 2
				$lqns_control analyse N [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100 200 500 750 1000 1250 1500] scaled
			}
		}
		
		if {$TEST} {
			$lqns_control set_method LQNS
			$lqns_control set_entry_names [list EBr EESBBericht EESBRelatie]
			$lqns_control set_lqn_property Z 0
			# $lqns_control analyse N [list 1 2 3 4 5 6 8 10] Z0sec-test
			$lqns_control analyse N [list 1 10] Z0sec-test

			if {1} {			
				# taken op een processor
				$lqns_control set_lqn_property NT_Http 500
				$lqns_control set_lqn_property NT_WPS 200
				$lqns_control set_lqn_property NT_ESB_Relatie 50
				$lqns_control set_lqn_property NT_ESB_Bericht 50
				
				# aantal processoren
				$lqns_control set_lqn_property N_151 10
				$lqns_control set_lqn_property N_154 8
				
				# $lqns_control set_entry_names [list EBr]
				$lqns_control set_entry_names [list EBr EESBBericht EESBRelatie]
				# $lqns_control set_method BOTH
				$lqns_control set_method LQNS
				$lqns_control set_lqn_property Z 27
				$lqns_control set_lqn_property N 1435
				$lqns_control analyse N_151 [list 6 8] scaled-N151-test
			}
		}
	}

	private method handle_cases_per_page {lqns_control project_name} {
		set TEST 0

		# omgeving
		set template_filename [file normalize [file join $project_name "CR2-diff-url.xmltmp"]]
		$lqns_control set_template_filename $template_filename
		$lqns_control set_lqn_properties_filename [file join $project_name "CR2.lqnprop"]
		$lqns_control set_project_name $project_name

		# wat moet er gebeuren?
		# $lqns_control set_method BOTH
		$lqns_control set_method LQNS
		$lqns_control set_calc_asymp 0

		# waar moet op gelet worden?
		# $lqns_control set_entry_names EBr
		$lqns_control set_entry_names [list EBr EHttpInlog EHttpZoeSN EHttpZoekPC EHttpSelectKlant EHttpSelectOverig]
		$lqns_control set_processor_name PWPS EWPS
		$lqns_control set_tijd_eenheid "sec"

		# specifieke properties en wat varieren op de X-as?
		$lqns_control set_lqn_property Z 0
		#$lqns_control analyse N [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100 200 500 1000 2000 3000 4000 5000] Z60sec
		#$lqns_control analyse N [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100 200 300 400 500] Z60sec
		$lqns_control analyse N [list 1 2 3 4 5 6 8 10] Z0sec-url

		$lqns_control set_lqn_property Z 1
		$lqns_control analyse N [list 1 5 10 20 30 40 50 75 100] Z1sec-url

		$lqns_control set_lqn_property Z 10
		$lqns_control analyse N [list 1 10 20 50 75 100 150 200 250] Z10sec-url



	}

	private method handle_cases_openqn {lqns_control project_name} {
		set TEST 0

		# omgeving
		# set template_filename [file normalize [file join $project_name "CR2-openqn.xmltmp"]]
		set template_filename [file normalize [file join $project_name "CR2.xmltmp"]]
		$lqns_control set_template_filename $template_filename
		$lqns_control set_lqn_properties_filename [file join $project_name "CR2.lqnprop"]
		$lqns_control set_project_name $project_name

		# wat moet er gebeuren?
		$lqns_control set_method BOTH
		# $lqns_control set_method LQNS
		$lqns_control set_calc_asymp 0

		# waar moet op gelet worden?
		$lqns_control set_entry_names [list EBr EESBBericht EESBRelatie]
		# $lqns_control set_entry_names [list EESBBericht EESBRelatie]
		# $lqns_control set_entry_names [list EBr EHttpInlog EHttpRelatie]
		$lqns_control set_processor_name P151 EWPS
		$lqns_control set_tijd_eenheid "sec"

		if {1} {
			# $lqns_control set_method LQNS
			$lqns_control set_method BOTH
			$lqns_control set_lqn_property N 100
			$lqns_control analyse N [list 1 2 3 4 5 6 8 10] Z0sec
			$lqns_control analyse Xin [list 1 2 3 3.2 3.4 3.6 3.8 4] openqn
		}
	}	

}


