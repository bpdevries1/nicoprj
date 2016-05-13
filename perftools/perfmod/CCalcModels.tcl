# functionaliteit van calc-showcase.bat overnemen.
#
# uitgangspunten:

package require Itcl

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]

source CLqnsControl.tcl

addLogger calcmodels
setLogLevel calcmodels info
# setLogLevel calcmodels debug

# class maar eenmalig definieren
if {[llength [itcl::find classes CCalcModels]] > 0} {
	return
}

itcl::class CCalcModels {

	public constructor {} {
	
	}
	
	# @param project_name showcase-whatif
	public method calc_models {project_name} {
		log "start" debug calcmodels

		# set result_dirname [file join $project_name "generated-calc"]
		
		# file delete -force $result_dirname
		# directory zelf niet verwijderen, is vaak current dir in explorer etc.
		# 15-6-07: dirs niet verwijderen, per lqnscontrol.analyse doen.
		if {0} {
			log "$result_dirname: deleting contents..." debug calcmodels
			set filelist [glob -nocomplain -directory $result_dirname *]
			foreach filename $filelist {
				file delete -force $filename
			}
			file mkdir $result_dirname
		}

    set lqns_control [uplevel {namespace which [CLqnsControl #auto]}]

		set has_cases 0
		catch {
			source [file join $project_name CCalcCases.tcl]
			set has_cases 1
		} msg
		log "msg: $msg" debug calcmodels
		
		if {$has_cases} {
			set ccc [CCalcCases #auto]
			# $ccc handle_cases $lqns_control $project_name $result_dirname
			$ccc handle_cases $lqns_control $project_name
		} else {
			fail "Should have CCalcCases.tcl in $project_name"
		}
	
		log "finished" debug calcmodels
	}

}

proc main {argc argv} {
  check_params $argc $argv
	set project_name [lindex $argv 0]
  set calc_models [CCalcModels #auto]
  $calc_models calc_models $project_name
}

proc check_params {argc argv} {
  global env argv0
  if {$argc != 1} {
    # fail "syntax: $argv0 <template_filename> <result_dirname>; got $argv \[#$argc\]"
    fail "syntax: $argv0 <project_name>; got $argv \[#$argc\]"
  }
}

# aanroepen vanuit Ant, maar ook mogelijk om vanuit Tcl te doen.
if {[file tail $argv0] == [file tail [info script]]} {
  main $argc $argv
}
