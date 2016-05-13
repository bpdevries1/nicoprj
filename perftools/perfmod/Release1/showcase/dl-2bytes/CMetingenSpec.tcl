package require Itcl

addLogger defmetingenspec
setLogLevel defmetingenspec info
setLogLevel defmetingenspec debug

# class maar eenmalig definieren
if {[llength [itcl::find classes CMetingenSpec]] > 0} {
	return
}

itcl::class CMetingenSpec {

	private variable build_label 
	private variable dirname

	public constructor {a_dirname} {
		set dirname $a_dirname
		# set build_label build.328
		set build_label build.339
		# set build_label build.336; # 10, 20, 50, 100 threads overdag.
	}

	public method get_query {} {
	set query "select nthreads, rate, avgresptime, sleeptime, wps1_cputotal from testrun_props where build_label = '$build_label'
and run_label like '%2bytes%'
and not run_label like '%warmup%'
and not run_label like '%zl'
order by sleeptime, round(nthreads)"
	
		return $query
	}
	
}
