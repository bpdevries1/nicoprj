#! /usr/bin/env tclsh

package require ndv

require libio io

use libfp

set_log_global info

proc main {argv} {
  global crons
  # [2017-04-14 20:13] put default dirs both for PC and laptop:
  set options {
    {crontab.arg "" "Specify crontab tcl file, default is $env(USERPROFILE)/.config/tclcron/tclcron.tcl on windows."}
    {debug "Set loglevel to debug"}
  }
  set usage ": [file tail [info script]] \[options]:"
  set opt [getoptions argv $options $usage]
  if {[:debug $opt]} {
    # $log set_log_level debug
    set_log_global debug
  }
  set crontab [det_crontab $opt]
  log debug "crontab file: $crontab"
  set crons [list]
  source $crontab
  set crons [lsort -command cron_compare $crons]
  # breakpoint
  cron_loop
  vwait forever
} 

# TODO: each 10 seconds, only 1 command is executed for now, should be enough, but should check all items.
proc cron_loop {} {
  global crons
  log debug "cron_loop: start"
  set item [first $crons]
  set now [clock seconds]
  if {[:next_sec $item] <= $now} {
    # it's time.
    log debug "It's time, executing command: $item"
    # exec {*}[:cmd $item]
    # TODO: should log somewhere if the exec fails.
    try_eval {
      exec -ignorestderr {*}[:cmd $item]
    } {
      log error "$errorResult"
    }
    if {[:mn $item] == "now"} {
      # just executed once directly for testing, don't repeat.
      set crons [rest $crons];  # drop first item
    } else {
      set next_sec [det_next_sec $item]
      set item_new [dict merge $item [vars_to_dict next_sec]] 
      set crons [lreplace $crons 0 0 $item_new]; # replace first item with the new one with updated next time.
      set crons [lsort -command cron_compare $crons]
    }
  } else {
    # nothing, wait another 10 seconds.
  }
  after 10000 cron_loop;        # every 10 seconds
}

proc det_crontab {opt} {
  global tcl_platform env
  if {[:crontab $opt] != ""} {
    return [:crontab $opt]
  }
  if {$tcl_platform(platform) == "windows"} {
    return [file join $env(USERPROFILE) .config tclcron tclcron.tcl]
  } else {
    return [file join ~ .config tclcron tclcron.tcl]
  }
}

proc cron {mn hr wd md month args} {
  global crons
  set cmd [join $args " "]
  log debug "$mn $hr $wd $md $month => $cmd"
  set item [vars_to_dict mn hr wd md month cmd]
  set next_sec [det_next_sec $item]
  lappend crons [dict merge $item [vars_to_dict next_sec]]
}

# could become quite complicated. First only check minute and hour.
# also first assume these are fixed integers, like 15 22 to execute at 22:15.
proc det_next_sec {item} {
  set hr [:hr $item]
  set mn [:mn $item]
  set now [clock seconds]
  if {($hr == "*") && ($mn == "*")} {
    # TODO: should be at start of next minute, now waiting 60 seconds always.
    set next_sec [clock add $now 1 minute]
  } elseif {$mn == "now"} {
    # specific for testing, execute directly, possibly only once.
    set next_sec [clock add $now 5 seconds]
  } else {
    set next_sec [clock scan "$hr:$mn" -format "%H:%M"]; # time for today, could be in the past.    
  }
  if {$next_sec < $now} {
    set next_sec [clock add $next_sec 1 day]
  }
  return $next_sec
}

# compare 2 command dicts, for sorting the list on the timestamp the command needs to be executed.
proc cron_compare {cmd1 cmd2} {
  set t1 [:next_sec $cmd1]
  set t2 [:next_sec $cmd2]
  if {$t1 < $t2} {
    return -1
  } elseif {$t1 > $t2} {
    return 1
  } else {
    return 0
  }
}

main $argv
