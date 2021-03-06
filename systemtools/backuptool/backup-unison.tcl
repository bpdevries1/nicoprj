#! /home/nico/bin/tclsh861

package require ndv

proc main {argv} {
  set options {
    {nomedia "Don't sync/backup media folders/drives"}
  }
  set opt [getoptions argv $options ""]
  if {[unison_running]} {
    log "WARN: Unison already running, exit."
    exit 1
  }
  # set unison_dir "/home/nico/.unison"
  set unison_dir [file normalize ~/.unison]
  
  set projects [det_projects $unison_dir $opt]
  puts "projects: $projects"
  # exit
  # projects is list of: project, freq_hours, prio
  # sort on priority, params: project, freq_hours
  foreach el [lsort -integer -index 2 $projects] {
    backup_unison {*}[lrange $el 0 1] $unison_dir
  }
}

proc unison_running {} {
  return 0 ; # TODO aanpassen weer.
  set ok 0
  catch {
    set res [exec ps -ef | grep \"unison -auto -batch\" | grep -v grep | grep -v backup-unison.tcl]
    set ok 1
  }
  if {!$ok} {
    log "ERROR: could not exec ps for unison, exiting"
    exit 2
  }
  if {$res == ""} {
    # ok
    return 0
  } else {
    log "WARN: unison running, exiting:"
    log $res
    return 1
  }
}

# result (projects) is list of: project, freq_hours, prio
# only add profile to result (without .prf) iff it has frequency and priority settings
proc det_projects {unison_dir opt} {
  set res {}
  foreach prf [glob -directory $unison_dir *.prf] {
    set freq ""
    set prio ""
    set f [open $prf r]
    set txt [read $f]
    close $f

    if {[:nomedia $opt]} {
      if {[is_media $prf $txt]} {
        log "-nomedia set, ignore: $prf"
        continue
      }
    }
    
    if {[regexp {\n#!frequency_hours *= *(\d+)} $txt z fr]} {
      set freq $fr
    }
    if {[regexp {\n#!priority *= *(\d+)} $txt z pr]} {
      set prio $pr
    }
    if {($prio != "") && ($freq != "")} {
      lappend res [list [file rootname [file tail $prf]] $freq $prio]
    } else {
      log "WARN: No freq/prio found in $prf"
    }
  }
  return $res
}

proc is_media {prf txt} {
  foreach re {{root\s*=\s*/media/nas5tb_\d} {root\s*=\s*/media/nas/}} {
    if {[regexp $re $txt]} {
      return 1
    }  
  }
  return 0
}

# if a succesful backup has been done longer than 3 days ago, try a new one.
# check unison exit-codes, possibly not all drives are mounted (eg laptop)
proc backup_unison {prj freq_hours unison_dir} {
  log "backup_unison: $prj"
  set last_ok [read_last_ok $prj]
  if {[too_long_ago $last_ok $freq_hours]} {
    log "too long ago, start new backup..."
    set started [now_fmt]
    rm_unison_log $unison_dir $prj
    set exitcode [do_exec /home/nico/bin/unison -auto -batch $prj >/dev/null 2>@1]
    if {$exitcode <= 2} {
      # code 1 en 2 zijn kleine fouten, ook markeren als ok.
      write_last_ok $prj $started
    } else {
      log "backup $prj caused some errors, exitcode: $exitcode"
    }
    log "backup finished"
  } else {
    log "backup done not too long ago, so nothing to do."
  }
  log "backup_unison: $prj finished"
}

proc rm_unison_log {unison_dir prj} {
  set logfile [unison_logfile $unison_dir $prj]
  if {$logfile != ""} {
    log "Remove unison logfile: $logfile"
    file delete $logfile
  }
}

# return name of unison log file as mentioned in ~/.unison/$prj.prj
proc unison_logfile {unison_dir prj} {
  set prj_file [file join $unison_dir "${prj}.prf"]
  set text [read_file $prj_file]
  # logfile = /home/nico/log/unison/home-nico.log
  if {[regexp {\slogfile\s*=\s*([^\n]+)\n} $text z logfile]} {
    return $logfile
  }
  return ""
}

if 0 {
  Unison exit codes:
  0: successful synchronization; everything is up-to-date now.
  1: some files were skipped, but all file transfers were successful.
  2: non-fatal failures occurred during file transfer.
  3: a fatal error occurred, or the execution was interrupted.
}

# [2016-11-20 19:41] for now only log result when exitcode > 2
# some minor errors cannot be helped, such as changed files.
proc do_exec {args} {
  set res -1
  catch {
    set res [exec {*}$args]
  } result options
  set exitcode [det_exitcode $options]
  if {$exitcode > 2} {
    log "exitcode: $exitcode"
    log "res: $res"
    log "result: $result"
    log "options: $options"
  }
  return $exitcode
}

proc det_exitcode {options} {
  if {[dict exists $options -errorcode]} {
    set details [dict get $options -errorcode]
  } else {
    set details ""
  }
  if {[lindex $details 0] eq "CHILDSTATUS"} {
    set status [lindex $details 2]
    return $status
  } else {
    # No errorcode, return 0, as no error has been detected.
    return 0
  }
}

proc too_long_ago {last_ok freq_hours} {
  # global BACKUP_INTERVAL_HOURS
  if {$last_ok == "<none>"} {
    return 1 ; # first time, no succesful backups yet, so too_long_ago == 1
  }
  set sec_ago [clock scan $last_ok -format "%Y-%m-%d %H:%M:%S"]
  set sec_now [clock seconds]
  set hours_diff [expr 1.0*($sec_now - $sec_ago) / 3600]
  log "hours_diff: $hours_diff"
  if {$hours_diff > $freq_hours} {
    return 1
  } else {
    return 0
  }
}

proc read_last_ok {prj} {
  set fn [last_ok_filename $prj]
  if {[file exists $fn]} {
    set f [open $fn r]
    gets $f last_ok
    close $f
    return $last_ok
  } else {
    return "<none>"
  }
}

proc write_last_ok {prj started} {
  set f [open [last_ok_filename $prj] w]
  puts $f $started
  close $f
}

proc last_ok_filename {prj} {
  return [file join /home/nico .unison "$prj.last_ok"]
}

proc now_fmt {} {
  clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"
}

set LOG_STDOUT 0
proc log {str} {
  global LOG_STDOUT stderr
  set f [open "/home/nico/log/backup-unison.log" a]
  puts $f "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] $str"
  close $f
  if {$LOG_STDOUT} {
    puts stderr "$str"
  }
}

main $argv
