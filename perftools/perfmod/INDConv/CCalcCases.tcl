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
		# omgeving
		set template_filename [file normalize [file join $project_name "INDConv.xmltmp"]]
		$lqns_control set_template_filename $template_filename
		$lqns_control set_lqn_properties_filename [file join $project_name "INDConv.lqnprop"]
		$lqns_control set_project_name $project_name

		# wat moet er gebeuren?
		$lqns_control set_method BOTH
		# $lqns_control set_method LQNS
		$lqns_control set_calc_asymp 0

		# waar moet op gelet worden?
		# $lqns_control set_entry_names [list EBP1 EBP2]
		$lqns_control set_entry_names [list EScheduler]
		$lqns_control set_processor_name PConversie EConversie
		$lqns_control set_tijd_eenheid "sec"

    # $lqns_control set_method LQNS
    # $lqns_control set_method BOTH
    $lqns_control set_method LQSIM
    $lqns_control set_lqn_property Z 0
    $lqns_control analyse N [list 4] Z0sec
    # $lqns_control analyse N [list 1 10] Z0sec
    # $lqns_control analyse Xin [list 1 2 3 3.2 3.4] openqn
    # $lqns_control analyse Xin [list 1] openqn
    # $lqns_control analyse Xin [list 1 2] openqn
  }



}


