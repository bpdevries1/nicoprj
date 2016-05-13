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
		# nu ook met load van 0 doorrekenen, met soms wel achtergrond proces.
		$lqns_control lqns_control $dirname 0 [list 0 10 100 200 500 800 1000] $template_filename $result_dirname Z0
		$lqns_control lqns_control $dirname 10 [list 0 10 100 200 500 800 1000 2000 3000 4000 4500 5000 6000 7000 8000 9000 10000] $template_filename $result_dirname Z10
	}

}


