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
		set TEST 1

		# omgeving
		set template_filename [file normalize [file join $project_name "POCHPS.xmltmp"]]
		$lqns_control set_template_filename $template_filename
		$lqns_control set_lqn_properties_filename [file join $project_name "POCHPS.lqnprop"]
		$lqns_control set_project_name $project_name

		# wat moet er gebeuren?
		$lqns_control set_method BOTH
		# $lqns_control set_method LQNS
		$lqns_control set_calc_asymp 0

		# waar moet op gelet worden?
		# $lqns_control set_entry_names [list EBP1 EBP2]
		# $lqns_control set_entry_names [list EBr ETCReq EBSReq]
		$lqns_control set_entry_names [list EBr]
		$lqns_control set_processor_name P71 EBSReq
		$lqns_control set_tijd_eenheid "sec"

		# handle_cases_closed_httpdp $lqns_control $project_name
		handle_cases_closed_mqmb $lqns_control $project_name
		

	}	
	
	private method handle_cases_closed_httpdp {lqns_control project_name} {
			$lqns_control set_lqn_property Z 0

			# $lqns_control analyse N [list 1 2 3 4 5 6 8 10] Z0sec
			# eerst MessageBroker variant
			if {0} {
				$lqns_control set_lqn_property BS_CallMB 1
				$lqns_control set_lqn_property BS_CallDP 0
				$lqns_control analyse N [list 1 2 5 10] HTTPMB
		  }
			# en dan DataPower HTTP variant
			puts "Testje met get_property"
			puts "D_Cl: [$lqns_control get_lqn_property D_Cl]"
			$lqns_control set_lqn_property BS_CallMB 0
			$lqns_control set_lqn_property BS_CallDP 1
			$lqns_control set_lqn_property D_EBSReq [$lqns_control get_lqn_property D_EBSReq_HTTP]
			$lqns_control set_lqn_property D_EDPReq [$lqns_control get_lqn_property D_EDPReq_HTTP]
			# moet MBReq ook zetten, anders LQNS foutmelding
			$lqns_control set_lqn_property D_EMBReq [$lqns_control get_lqn_property D_EMBReq_HTTP]
			$lqns_control analyse N [list 1 2 5 10] HTTPDP

			# $lqns_control analyse Xin [list 1 2 3 3.2 3.4] openqn
			# $lqns_control analyse Xin [list 1 2] openqn
		
	}
	
	private method handle_cases_closed_mqmb {lqns_control project_name} {
			$lqns_control set_lqn_property Z 0

			$lqns_control set_lqn_property BS_CallMB 1
			$lqns_control set_lqn_property BS_CallDP 0
			$lqns_control analyse N [list 1 2 5 10] MQMB

			$lqns_control set_lqn_property D_EBSReq [$lqns_control get_lqn_property D_EBSReq_MQ]
			$lqns_control set_lqn_property D_EDPReq [$lqns_control get_lqn_property D_EDPReq_MQ]
			# moet MBReq ook zetten, anders LQNS foutmelding
			$lqns_control set_lqn_property D_EMBReq [$lqns_control get_lqn_property D_EMBReq_MQ]
			$lqns_control analyse N [list 1 2 5 10] MQMB-Z0

			$lqns_control set_lqn_property Z 1.000
			$lqns_control analyse N [list 1 2] MQMB-Z1

	}
	
	private method handle_cases_openqn {lqns_control project_name} {
		set TEST 0

		# omgeving
		set template_filename [file normalize [file join $project_name "SOABoek.xmltmp"]]
		$lqns_control set_template_filename $template_filename
		$lqns_control set_lqn_properties_filename [file join $project_name "SOABoek.lqnprop"]
		$lqns_control set_project_name $project_name

		# wat moet er gebeuren?
		$lqns_control set_method BOTH
		# $lqns_control set_method LQNS
		$lqns_control set_calc_asymp 0

		# waar moet op gelet worden?
		# $lqns_control set_entry_names [list EBP1 EBP2]
		$lqns_control set_entry_names [list EBP2]
		$lqns_control set_processor_name PBS2 EBS2
		$lqns_control set_tijd_eenheid "sec"

		if {1} {
			# $lqns_control set_method LQNS
			# $lqns_control set_method BOTH
			$lqns_control set_method LQSIM
			$lqns_control set_lqn_property N 100
			$lqns_control set_lqn_property Z 0
			# $lqns_control analyse N [list 1 2 3 4 5 6 8 10] Z0sec
			# $lqns_control analyse N [list 1 10] Z0sec
		  $lqns_control analyse Xin [list 1 2 3 3.2 3.4] openqn
			# $lqns_control analyse Xin [list 1 2] openqn
		}
	}	

}


