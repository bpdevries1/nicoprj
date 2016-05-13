# functionaliteit van calc-showcase.bat overnemen.
#
# uitgangspunten:
# per uitzoekpunt (whatif) een name, hier een lqntmp file en als output een generated-dir.
# meetwaarden ophalen en in 'generated' dir zetten. Hiernaar verwijzen vanuit de .m files (om .png te maken)

package require Itcl

# source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]

addLogger calccases
setLogLevel calccases info
setLogLevel calccases debug

# class maar eenmalig definieren
if {[llength [itcl::find classes CCalcCases]] > 0} {
	return
}

itcl::class CCalcCases {

	public constructor {} {
	
	}

	public method handle_cases {lqns_control dirname template_filename result_dirname} {
		$lqns_control set_background_process_type BG_SERVER
		# $lqns_control set_method LQSIM
		$lqns_control set_method LQNS
		# nu ook met load van 0 doorrekenen, met soms wel achtergrond proces.
		$lqns_control lqns_control $dirname 0 [list 0 1 2 3 4 5 6 8 10] $template_filename $result_dirname Z0
		$lqns_control lqns_control $dirname 1 [list 0 1 2 3 4 5 6 8 10 20 50 100] $template_filename $result_dirname Z1
		$lqns_control lqns_control $dirname 10 [list 0 1 2 3 4 5 6 8 10 20 50 100 200 300 400 500 600 700] $template_filename $result_dirname Z10
	}

}


