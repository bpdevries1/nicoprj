package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]

addLogger defmetingenspec
setLogLevel defmetingenspec info
setLogLevel defmetingenspec debug

# class maar eenmalig definieren
if {[llength [itcl::find classes CDefMetingenSpec]] > 0} {
	return
}

itcl::class CDefMetingenSpec {

	private variable build_label 
	private variable dirname

	public constructor {a_dirname} {
		set dirname $a_dirname
		set build_label [det_build_label $dirname]
	}

	private method det_build_label {dirname} {
		set f [open [file join $dirname "build-label.txt"] r]
		gets $f build_label
		close $f
		return $build_label
	}

	public method get_query {} {
		set query "select nthreads, rate, avgresptime, sleeptime, wps1_cputotal from testrun_props where build_label = '$build_label'
and run_label like '%aix141-%'
and not run_label like '%warmup%'
and not run_label like '%zl'
order by sleeptime, round(nthreads)"
	
		return $query
	}
	
}
