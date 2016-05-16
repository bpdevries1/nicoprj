package require tclodbc
package require ndv
package require Tclx

::ndv::source_once lib_analysis.tcl
::ndv::source_once DBSLA2analysis.tcl
::ndv::source_once DBForce2analysis.tcl
::ndv::source_once Filelog2analysis.tcl
::ndv::source_once LRAnalysisWriter.tcl
::ndv::source_once ExtendedAnalysisWriter.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log db ar_settings ar_argv
  get_cmdline_args $argv
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  $log info START

  lassign [det_ts1_ts2] ts1 ts2
  set_which_logs

 
  read_settings $ar_argv(settings)
  $log debug "settings: [array get ar_settings]"
  set local_log_root [det_local_log_root $ts1 $ts2]
  # file mkdir $local_log_root
  
  set lst_writers [list [ExtendedAnalysisWriter new -directory [file join $local_log_root extended]] \
                        [LRAnalysisWriter new -directory [file join $local_log_root analysis]]]
  
  if {$ar_argv(sla)} {
    get_sla_logs {*}[get_array_values ar_settings sladb sladbuser sladbpassword] [file join $local_log_root analysis] $ts1 $ts2 $lst_writers
  }
  if {$ar_argv(force)} {
    get_force_workflow_logs {*}[get_array_values ar_settings forcedb forcedbuser forcedbpassword] [file join $local_log_root analysis] $ts1 $ts2 $lst_writers
  }
  if {$ar_argv(log)} {
    get_force_logs $local_log_root $ts1 $ts2
    handle_force_file_logs [file join $local_log_root logs] [file join $local_log_root analysis] $ts1 $ts2 $lst_writers
  }
  $log info FINISHED
}

proc get_cmdline_args {argv} { 
  global ar_argv log
  $log debug "argv: $argv"
  # @todo 3 opties bothtimes, threadnr en ms verwijderen
  set options {
    {settings.arg "settings.txt" "Settings file with DB en server logfile settings"}
    {ts1.arg "start-test" "Timestamp begin (start-test of 2010-08-11 10:02:03)"}
    {ts2.arg "current-time" "Timestamp einde (current-time of 2010-08-11 10:02:03)"}
    {name.arg "name" "name of testrun, put in directory name."}
    {sla "Get SLA info from DB"}
    {force "Get Force workflow info from DB"}
    {log "Get Application logs from server file system"}
    {loglevel.arg "" "Zet globaal log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  
  if {0} {
    {ms "" "Put (also) milliseconds in output files"}
    {bothtimes "Put start and end time in output files"}
    {threadnr "Put threadnr in output files"}
  }
   
}

proc det_ts1_ts2 {} {
  global ar_argv log
  if {$ar_argv(ts1) == "start-test"} {
    set ts1 [read_file -nonewline "start-test.txt"]
  } else {
    set ts1 $ar_argv(ts1)
  }
  if {$ar_argv(ts2) == "current-time"} {
    set ts2 [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  } else {
    set ts2 $ar_argv(ts2)
  }
  $log debug "timestamp1 (start): $ts1"
  $log debug "timestamp2 (end  ): $ts2"
  list $ts1 $ts2
}

proc set_which_logs {} {
  global ar_argv log
  if {($ar_argv(sla) == 0) && ($ar_argv(log) == 0) && ($ar_argv(force) == 0)} {
    set ar_argv(sla) 1
    set ar_argv(log) 1
    set ar_argv(force) 1
  }
}

proc read_settings {settings_filename} {
  global ar_settings
  foreach line [split [read_file $settings_filename] "\n"] {
    if {[regexp {^#} $line]} {
      continue
    }
    if {[regexp {^([^=]+)=(.*)$} $line z nm val]} {
      set ar_settings([string trim $nm]) [string trim $val]
    }
  }
}

proc det_local_log_root {ts1 ts2} {
  global ar_settings ar_argv
  regsub -all {[ :]} $ts1 "-" ts1
  regsub -all {[ :]} $ts2 "-" ts2
  return [file join $ar_settings(local_log_root) "$ar_argv(name)-$ts1-$ts2"]
}

# @param local_log_root: date, hierbinnen log en analysis dirs.
# @todo aanpassen als andere from-subdirs ook beschouwd moeten worden.
proc get_force_logs {local_log_root ts1 ts2} {
  global ar_settings log
  for {set i_server 1} {$i_server <= $ar_settings(nlogs)} {incr i_server} {
    get_force_logs_server $local_log_root $ts1 $ts2 {*}[get_log_settings $i_server]
  }
}

proc get_force_logs_server {local_log_root ts1 ts2 driveletter unc user password} {
  global log ar_settings
  connect_unc_drive $driveletter $unc $user $password
  set from_dir "${driveletter}:/"
  set to_dir [file join $local_log_root logs]
  file mkdir $to_dir
  set lst_patterns [split $ar_settings(log_file_patterns) ";"]
  foreach glob_pattern $lst_patterns {
    $log debug "Looking for $glob_pattern files in $from_dir"
    foreach from_file [glob -directory $from_dir $glob_pattern] {
      if {[clock format [file mtime $from_file] -format "%Y-%m-%d %H:%M:%S"] >= $ts1} {
        $log debug "Copying source log: $from_file"
        file copy $from_file $to_dir
      } else {
        if {[regexp {.txt$} $from_file]} {
          # 24-8-2010 NdV nieuwste file altijd meenemen, kan zijn dat mtime niet is aangepast, omdat file nog open is.
          $log debug "Copying source log: $from_file"
          file copy $from_file $to_dir
        } else {
          $log debug "Logfile $from_file too old, don't copy ([clock format [file mtime $from_file] -format "%Y-%m-%d %H:%M:%S"] < $ts1"
        }  
      }
    }
  }  
}

# @return list met 4 items: driveletter, unc-root, user, password
proc get_log_settings {i_server} {
  global ar_settings log
  $log debug "ar_settings: [array get ar_settings]"
  struct::list mapfor name {log_driveletter log_unc_root log_user log_password} {
    set ar_settings(${name}${i_server})
  }
}

proc connect_unc_drive {driveletter unc user password} {
  global log
  if {[file exists "${driveletter}:"]} {
    $log debug "Already connected, returning"
    return
  }
  
  exec net use ${driveletter}: $unc $password /user:$user /persistent:yes
  
  if {[file exists "$driveletter:"]} {
    $log info "Connected drive"
  } else {
    $log error "Connection failed: net use ${driveletter}: $unc $password /user:$user /persistent:yes"
  }
}

proc do_writers {lst_writers args} {
  foreach writer $lst_writers {
    $writer {*}$args 
  }
}

if {[file tail $argv0] == [file tail [info script]]} {
  main $argc $argv
}  
