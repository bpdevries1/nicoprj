# Tcl 8.4 - don't use package ndv.
# package require ndv

source lib-copy.tcl

# TODO
# make working with Tcl 8.4:
# * clock command - maybe milliseconds not working.
# * dict possibly non existing
# * ndv package: which functions used.
# {*} does not work
# ActiveTcl 8.4 cannot be downloaded anymore.
file mkdir [file join [file dirname [info script]] log]
set time [clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]
set logname [file join [file dirname [info script]] log "dropbox-xml-$time.log"]

set debug 1

proc main {argv} {
  global argv0 debug
  # lassign $argv config
  set config [lindex $argv 0]
  if {$config == ""} {
    puts "syntax: $argv0 <config.tcl>"
    exit 1
  }
  source $config

  forward_files_loop $dropbox_xml_folder_in $dropbox_xml_folder_out $check_freq_sec $check_max_files
}

# tcl 8.4: cannot use star in braces
proc forward_files_loop {dropbox_xml_folder_in dropbox_xml_folder_out check_freq_sec check_max_files} {
  while 1 {
    log debug "Calling forward files"
    forward_files $dropbox_xml_folder_in $dropbox_xml_folder_out $check_freq_sec $check_max_files
  }
}

proc forward_files {indir outdir check_freq_sec check_max_files} {
  # set start_msec [clock milliseconds]
  set start_msec [clock clicks -milliseconds]
  set i 0
  foreach filename [glob -nocomplain -directory $indir *] {
    incr i
    forward_file $filename $outdir
    if {$i >= $check_max_files} {
      break
    }
  }
  wait_pacing $check_freq_sec $start_msec 
}

# move file to outdir and log the action.
proc forward_file {filename outdir} {
  set d [xmlfile_info $filename]
  log perf "Moved file: [file nativename $filename], [list_to_str $d]"
  set outpath [file join $outdir [file tail $filename]]
  file_rename $filename $outpath
}

# if to file already exists, add a -1 etc to the file.
proc file_rename {from to} {
  if {[file exists $to]} {
    set idx 1
    set to2 "[file rootname $to]-$idx[file extension $to]"
    while {[file exists $to2]} {
      incr idx
      set to2 "[file rootname $to]-$idx[file extension $to]"
    }
    set to $to2
  }
  file rename $from $to
}

# return dict with:
# subject - subject of the e-mail message
# ts_subject - timestamp part of the subject of the e-mail message
# sec_subject - time of the subject in xml as seconds since epoch
# ts_xmlfile - file time of the xml as a string with timezone
# sec_xmlfile - file time of the xml as seconds since epoch
# sec_diff - difference in seconds between sec_subject and sec_xmlfile
# uuid - if no subject/ts available.
proc xmlfile_info {filename} {
  set subject ""
  set ts_subject ""
  set sec_subject 0
  set ts_xmlfile ""
  set sec_xmlfile 0
  set sec_diff 0
  set uuid ""
  
  set sec_xmlfile [file mtime $filename]
  set ts_xmlfile [clock format $sec_xmlfile -format "%Y-%m-%d %H:%M:%S %z"]
  
  set text [read_file $filename]
  if {[regexp {<Value>Perftest-([0-9.-]+)-(.+.pdf)\[} $text z ts_subject subject]} {
    log debug "$ts_subject *** $subject"
    set sec_subject [ts_parse_msec $ts_subject]; # 
    set sec_diff [format %.3f [expr $sec_xmlfile - $sec_subject]]
  } elseif {[regexp {<Value>([a-f0-9]+)\.pdf} $text z uuid]} {
    log debug "uuid: $uuid"
  } elseif {[regexp {<variable name="Subject">([^<]+)-Perftest-([^<]+)</variable>} $text z subject ts_subject]} {
    # <variable name="Subject">Fax sent (3p) to '+31307124088' @+31307124088-Perftest-2015-12-05--11-59-00.509</variable>
    log debug "$ts_subject *** $subject"
    set sec_subject [ts_parse_msec $ts_subject]
    set sec_diff [format %.3f [expr $sec_xmlfile - $sec_subject]]
  } else {                        
    log error "No subject found." 
    # breakpoint
  }
  # vars_to_dict subject ts_subject sec_subject ts_xmlfile sec_xmlfile sec_diff uuid
  list subject $subject ts_subject $ts_subject sec_subject $sec_subject ts_xmlfile $ts_xmlfile sec_xmlfile $sec_xmlfile sec_diff $sec_diff uuid $uuid
}

# @param ts - 2015-11-24--14-02-30.168
# tcl 8.4, cannot use try_eval
proc ts_parse_msec {ts} {
  if {[regexp {^([^.]+)(\.\d+)$} $ts z sec msec]} {
    set res -1
    catch {set res [expr [clock scan $sec -format "%Y-%m-%d--%H-%M-%S"] + $msec]}
    if {$res == -1} {
      log error "Parsing timestamp failed for: $ts/sec"
    }
    return $res
  } else {
    log error "Cannot parse timestamp with msec: $ts"
    # breakpoint
  }
}

proc ts_parse_msec_old {ts} {
  if {[regexp {^([^.]+)(\.\d+)$} $ts z sec msec]} {
    try_eval {
      set res [expr [clock scan $sec -format "%Y-%m-%d--%H-%M-%S"] + $msec]
    } {
      log error "Parsing timestamp failed for: $ts/sec"
      breakpoint
    }
    return $res
  } else {
    log error "Cannot parse timestamp with msec: $ts"
    breakpoint
  }
}


main $argv
