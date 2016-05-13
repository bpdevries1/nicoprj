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

	public method handle_cases {lqns_control dirname result_dirname} {
		set template_filename [file normalize [file join $dirname "CR1.lqntmp"]]
		set lqn_properties_filename [file join $dirname "lqn-properties.txt"]
		# $lqns_control set_background_process_type BG_SERVER
		$lqns_control set_entry_name EBrKB
		$lqns_control set_processor_name PWPS EWPSKB
		$lqns_control set_tijd_eenheid "sec"
		# $lqns_control lqns_control $dirname 0 [list 100] $template_filename $lqn_properties_filename $result_dirname Z-0sec
		# $lqns_control lqns_control $dirname 60 [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100] $template_filename $lqn_properties_filename $result_dirname Z-60sec

		# standaard
		# $lqns_control lqns_control $dirname 0 [list 1 2 3 4 5 6 8 10 20 30 40 50] $template_filename $lqn_properties_filename $result_dirname Z-0sec
		# $lqns_control lqns_control $dirname 60 [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100 200 500 1000 2000 3000 4000 5000] $template_filename $lqn_properties_filename $result_dirname Z-60sec

		# CR1-4s: 4 services
		$lqns_control set_entry_name EBrKB
		# @todo wil U van alle processen op de PWPS, nu niet te maken met BG proces.
		$lqns_control set_processor_name PWPS
		set template_filename [file normalize [file join $dirname "CR1-4s.lqntmp"]]
		set lqn_properties_filename [file join $dirname "CR1-4s.lqnprop"]
		# $lqns_control lqns_control $dirname 60 [list 1] $template_filename $lqn_properties_filename $result_dirname 4srv-Z-0sec
		$lqns_control lqns_control $dirname 0 [list 1 2 3 4 5 6 8 10 20 30 40 50] $template_filename $lqn_properties_filename $result_dirname 4srv-Z-0sec
		$lqns_control lqns_control $dirname 60 [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100 200 500 1000 2000 3000 4000 5000] $template_filename $lqn_properties_filename $result_dirname 4srv-Z-60sec
		# $lqns_control lqns_control $dirname [list 0 1 2 3 4 5 6 8 10 15 20 25 30 35 40 45 50 55 60] [list 4000] $template_filename $lqn_properties_filename $result_dirname 4srv-N-4000
		$lqns_control lqns_control $dirname [list 0 30 60 90 120] [list 4000] $template_filename $lqn_properties_filename $result_dirname 4srv-N-4000

		# met 2 portal servers.
		set template_filename [file normalize [file join $dirname "CR1-4s.lqntmp"]]
		set lqn_properties_filename [file join $dirname "R1-4s-2WPS.lqnprop"]
		$lqns_control lqns_control $dirname 60 [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100 200 500 1000 2000 3000 4000 5000] $template_filename $lqn_properties_filename $result_dirname 4srv-2WPS-Z-60sec




	}


}


