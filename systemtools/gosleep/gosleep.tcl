#!/home/nico/bin/tclsh861

# under root, tclsh861 cannot be found, so hardcode in first line
#!/usr/bin/env tclsh861

# TODO:
# deze mogelijk vanuit crontab aanroepen (in root-cron vanwege suspend)
# dan eerst kijken of bepaalde processen draaien, zoals amarok speelt nog.
# zo niet, dan acties doen en hierna sleep.

set LOG_STDOUT 1
set DO_SLEEP 1 ; # for debugging. Can be overrided in user config.

proc main {argv} {
  global USER cron_jobs DO_SLEEP LOGFILE
  set LOGFILE [det_logfile]
  set USER [det_user]  
  lassign $argv option
  set cron_jobs {}
  # TODO make sure we're running with sudo/root, pm-suspend needs this
  if {[is_unix]} {
    if {[curr_user] != "root"} {
      puts stderr "Not root, not able to exec pm-suspend, exiting..."
      exit 1
    }
  }

  #test_popup_msg
  #exit;                         # for now, testing.
  
  # call unison with normal user account
  # TODO: this code is specific, put in config file. Zou moeten kunnen, freq op 24h zetten.
  # do_exec_user $USER /home/nico/nicoprj/systemtools/backuptool/backup-unison.tcl
  
  # call other jobs (maybe private, put in other dir, read config)
  do_crons

  # 30-8-2015 do_crons may have set DO_SLEEP to 1, -n should override.
  if {$option == "-n"} {
    set DO_SLEEP 0
    puts stderr "Just do actions, don't sleep"
  }
  
  # go to sleep
  puts "DO_SLEEP: $DO_SLEEP"
  if {$DO_SLEEP} {
    log "GO TO SLEEP!"
    go_sleep
  } else {
    log "Don't really go to sleep."
  }
}

proc test_popup_msg {} {
  # try both from root and from nico.
  set popup [file normalize [file join [info script] .. .. .. lib test popupmsg.tcl]]
  log "popup: $popup"
  catch {exec -ignorestderr nohup $popup "Popup with root" &} msg
  log "catch msg root: $msg"

  catch {exec -ignorestderr sudo -u nico nohup $popup "Popup with nico" &} msg
  log "catch msg nico: $msg"

  log "finished popups"
}

proc do_crons {} {
  global USER cron_jobs DO_SLEEP
  # set user_config [file join /home $USER .config gosleep gosleep.tcl]
  set user_config [file join [config_dir $USER] gosleep.tcl]
  if {![file exists $user_config]} {
    log "no user_config: $user_config"
    return
  }
  source $user_config
  foreach job $cron_jobs {
    do_cron $job
  }
}

proc do_cron {job} {
  global USER
  lassign $job freq_hours cmd ; # cmd is a list
  set last_ok [read_last_ok $cmd]
  if {[too_long_ago $last_ok $freq_hours]} {
    log "too long ago, do action: $cmd..."
    set started [now_fmt]
    set exitcode [do_exec_user $USER {*}$cmd]
    # TODO: vraag of check op exitcode in het algemeen hier goed is. Zou altijd 0 moeten zijn.
    if {$exitcode <= 2} {
      # code 1 en 2 zijn kleine fouten, ook markeren als ok.
      write_last_ok $cmd $started
    }
    log "action finished: $cmd"
  } else {
    log "action done not too long ago, so nothing to do: $cmd"
  }
  log "do_cron: finished: $cmd"
}

# called from user-config
proc cron {freq_hours args} {
  global cron_jobs
  lappend cron_jobs [list $freq_hours $args]
}

proc go_sleep {} {
  log "Entering sleep-mode"
  if {[is_unix]} {
    set res [do_exec /usr/sbin/pm-suspend]  
  } else {
    # windows
    set res [do_exec {c:\Windows\system32\shutdown.exe} /h]
  }
  
  log "Result of suspend: $res"
}

##########################################################################
# TODO put procs below in lib, both used here and in backup-unison.tcl   #
##########################################################################

proc curr_user {} {
  exec /usr/bin/whoami
}

# execute a command as a specific user
proc do_exec_user {user args} {
  if {[is_unix]} {
    do_exec sudo -u $user {*}$args
  } else {
    # on windows sudo is not available, and suspend/sleep should work from current user
    do_exec {*}$args
  }
}

proc do_exec {args} {
  log "executing: $args"
  set res -1
  catch {
    # [2016-11-19 10:55] deze exec blijft hangen. Mss omdat niet alle child processes al klaar zijn, mss dus & aan het einde.
    # [2016-11-26 10:54] Added ignorestderr, otherwise many scripts will be seen as giving errors.
    set res [exec -ignorestderr {*}$args]
  } result options
  # [2016-11-23 22:02] lijkt dat een van deze logs een 'while executing' geeft, dus details erbij.
  log "res: $res (do_exec {*}$args)"
  log "result: $result (do_exec {*}$args)"
  log "options: $options (do_exec {*}$args)"
  set exitcode [det_exitcode $options]
  log "exitcode: $exitcode (do_exec {*}$args)"
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

# TODO: deze versie gebruikt cmd, in backup-unison wordt prj gebruikt.
proc read_last_ok {cmd} {
  set fn [last_ok_filename $cmd]
  if {[file exists $fn]} {
    set f [open $fn r]
    gets $f last_ok
    close $f
    return $last_ok
  } else {
    return "<none>"
  }
}

proc write_last_ok {cmd started} {
  set f [open [last_ok_filename $cmd] w]
  puts $f $started
  close $f
}

# TODO: deze ook anders dan in backup-unison
proc last_ok_filename {cmd} {
  global USER
  # return [file join /home/nico .unison "$prj.last_ok"]
  file join [config_dir $USER] "[replace_special $cmd].last_ok"
}

# replace special characters in cmd, so it can be user as a filename base.
proc replace_special {cmd} {
  regsub -all {[/ ?:*\{\}\\><&]} $cmd "_" cmd
  return $cmd
}

# TODO: other way to determine home dir of user?
proc config_dir {user} {
  if {[is_unix]} {
    file join /home $user .config gosleep  
  } else {
    # windows
    file join c:/ Users $user .config gosleep
  }
}

proc now_fmt {} {
  clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"
}

proc det_logfile {} {
  if {[is_unix]} {
    return "/home/nico/log/gosleep.log"  
  } else {
    # windows
    return "c:/logs/gosleep.log"
  }
}

proc det_user {} {
  if {[is_unix]} {
    return "nico"
  } else {
    return "ndvreeze"
  }
}

proc is_unix {} {
  global tcl_platform
  if {$tcl_platform(platform) == "unix"} {
    return 1
  } else {
    return 0
  }
}

proc log {str} {
  global LOG_STDOUT stderr LOGFILE
  # set f [open "/home/nico/log/backup-unison.log" a]
  set f [open $LOGFILE a]
  puts $f "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]\] $str"
  close $f
  if {$LOG_STDOUT} {
    puts stderr "$str"
  }
}

main $argv
