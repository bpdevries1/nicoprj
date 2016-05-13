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
		set template_filename [file normalize [file join $dirname "Koffie.lqntmp"]]
		set lqn_properties_filename [file join $dirname "lqn-properties.txt"]
		# $lqns_control set_background_process_type BG_SERVER
		$lqns_control set_entry_name EKlKoffie
		$lqns_control set_processor_name Automaat EAuKoffie
		$lqns_control set_tijd_eenheid "min"
		$lqns_control lqns_control $dirname 0 [list 1 2 3 4 5 6 8 10] $template_filename $lqn_properties_filename $result_dirname Z0
		$lqns_control lqns_control $dirname 30 [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100] $template_filename $lqn_properties_filename $result_dirname Z-30min
		$lqns_control lqns_control $dirname 60 [list 1 2 3 4 5 6 8 10 20 30 40 50 60 70 80 90 100] $template_filename $lqn_properties_filename $result_dirname Z-60min
	}


}


