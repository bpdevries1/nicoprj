#!/usr/bin/env tclsh

# Build tool, mainly for VuGen scripts and libraries
# [2016-08-10 22:53] Starting to be useful for other kinds of projects (ahk, tcl, clj)

package require ndv

set_log_global info

ndv::source_once task.tcl configs.tcl prjgroup.tcl prjtype.tcl selectfiles.tcl backup.tcl \
    lib/inifile.tcl lib/misc.tcl init.tcl lr_params.tcl templates.tcl parse.tcl \
    syncrepo.tcl regsub.tcl files.tcl text.tcl comment.tcl domains.tcl \
    vuser_init.tcl globals_h.tcl checks.tcl clean.tcl trans.tcl \
    steps.tcl report.tcl

proc main {argv} {
  set dir [file normalize .]
  set tname [task_name [lindex $argv 0]]
  if {$tname == ""} {set tname help}
  set trest [lrange $argv 1 end]
  if {[in_bld_subdir? $dir]} {
    puts "In buildtool subdir, exiting: $dir"
    return
  }
  if {[is_prjgroup_dir $dir]} {
    handle_prjgroup_dir $dir $tname $trest
  } else {
    handle_script_dir $dir $tname $trest
  }
}

# [2016-08-10 21:11] TODO: later call this one 'handle_project_dir'. Not now, still confusing name.
proc handle_script_dir {dir tname trest} {
  global as_prjgroup buildtool_env
  if {($tname == "init") || ([current_version] == [latest_version])} {
    if {[file exists [buildtool_env_tcl_name]]} {
      uplevel #0 {source [buildtool_env_tcl_name]}
    } else {
      puts "do bld init-env!"
      return
    }
    puts "env: $buildtool_env"
    if {$tname != "init"} {
      uplevel #0 {source [config_tcl_name]}
      source_prjtype
    }
    set as_prjgroup 0
    set_origdir ; # to use by all subsequent tasks.
    task_$tname {*}$trest
    mark_backup $tname $trest
    check_temp_files
  } else {
    puts "Update config version with init -update"
  }
}

# source all tcl files in bldprjlib iff defined.
proc source_prjtype {} {
  global bldprjlib
  if {![info exists bldprjlib]} {
    log info "No prjtype specific build lib"
    return
  }
  # use lsort to have option to source in specific order if needed
  foreach libfile [lsort [glob -nocomplain -directory $bldprjlib *.tcl]] {
    # ndv::source_once?
    source $libfile
  }
}

proc buildtool_dir {} {
  global argv0
  # set res [file dirname [file normalize [info script]]]
  # [2016-08-10 22:31] info script does not work now, because this proc is called from
  # .bld/config.tcl, and returns .bld dir.
  set res [file dirname [file normalize $argv0]]
  log debug "buildtool_dir: $res"
  return $res
}

# return true iff dir is .bld dir or subdir of this.
proc in_bld_subdir? {dir} {
  foreach el [file split $dir] {
    if {$el == ".bld"} {
      return 1
    }
  }
  return 0
}

if {[this_is_main]} {
  main $argv  
} else {
  puts "not main"  
}

