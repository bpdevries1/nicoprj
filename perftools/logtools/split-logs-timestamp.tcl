package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "logs/[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

if 0 {
  opzet:
  per file:
  * bepaal timestamp log formaat: regexp voor line (met haakjes, eerste haakjespaar), clock format string, wel/geen gmt
    - automatisch bepalen, maar eerst paar standaarden obv zelf kijken in logs en op filename checken.
  * voor elke regel: bepaal timestamp obv log formaat, leeg als niets gevonden, anders sec_utc.
  * als geen timestamp, dan zelfde doen als bij vorige regel.
  * status bijhouden: huidige/eerstvolgende periode, en de rest van de periodes.
    - kan zijn dat log begint na de eerste periode.
  * status: in een periode, of erbuiten.
  * output files: in subdirs aanmaken obv label.
  
}

# define testruns which overlap with dotcom logfiles
proc define_tests {} {
  define_test run383 "2015-11-02 15:00:00" 483 60
  define_test run384 "2015-11-03 17:00:00" 483 60
}

# 172.18.38.97 - - [03/Nov/2015:22:58:33 +0100] "GET /DotCom/en/images/Jan-profile-low.jpg HTTP/1.1" 200 30372
# per regel 4 elementen: regexp voor filename, regexp voor line, timestamp format en gmt 0/1.
# 2015-09-11 00:32:01,743
# [Tue, 03 Nov 2015 23:21:23 GMT]
# <sys id="1" timestamp="Oct 09 08:39:58 2012" intervalms="0.000">
# [05/Nov/2015:04:02:15 +0100]
# [Thu Nov 05 04:02:15 2015] [error]
# [11/5/15 0:03:56:396 CET]
set ts_formats {
  dotcomlive {^([0-9 :-]+),} "%Y-%m-%d %H:%M:%S" 0
  geolocation {^([0-9 :-]+),} "%Y-%m-%d %H:%M:%S" 0
  http_access {\[([0-9A-Za-z/: +-]+)\]} "%d/%b/%Y:%H:%M:%S %z" 0
  http_error {^\[[^,]+, ([0-9A-Za-z: +-]+)\]} "%d %b %Y %H:%M:%S %z" 0
  native_stderr {timestamp="([0-9A-Za-z :]+)"} "%b %d %H:%M:%S %Y" 0
  privacypolicyframework {^([0-9 :-]+),} "%Y-%m-%d %H:%M:%S" 0
  ssl-access {\[([0-9A-Za-z/: +-]+)\]} "%d/%b/%Y:%H:%M:%S %z" 0
  ssl-error {^\[[^ ]+ ([0-9A-Za-z: ]+)\]} "%b %d %H:%M:%S %Y" 0
  SystemOut {^\[([0-9A-Za-z: /]+):\d{3} CET\]} "%m/%d/%y %H:%M:%S" 0
}

proc main {argv} {
  define_tests
  log_periods
  # set root_dir {C:\PCC\Nico\Projecten\dotcom\serverlogs\baseline-shared\untarred\test}
  set root_dir {C:\PCC\Nico\Projecten\dotcom\serverlogs\baseline-shared\untarred}
  handle_dir $root_dir
  # als timestamp van file al ouder is dan eerste start, kun je 'em sowieso overslaan.
}

proc handle_dir {dir} {
  foreach filename [glob -nocomplain -directory $dir -type f *] {
    handle_file $filename
  }
}

proc handle_file {filename} {
  global periods
  
  if {[file mtime $filename] < [first_period_start]} {
    log info "File timestamp before first period, ignore: $filename"
    move_handled $filename
    return
  }

  set fmt [det_format $filename]
  if {$fmt == {}} {
    log warn "Unknown format, ignore file: $filename"
    return
  }
  # lassign $fmt lre tsf gmt

  log info "Handling $filename with fmt: $fmt"
  
  set fperiods $periods
  set in_period 0
  set period [:0 $fperiods]
  set fperiods [lrange $fperiods 1 end]

  set fi [open $filename r]
  set linenr 0
  while {[gets $fi line] >= 0} {
    incr linenr
    if {[expr $linenr % 10000] == 0} {
      log debug "Lines handled: $linenr"
    }
    set ts [det_ts $line $fmt [file tail $filename] $linenr]
    if {$ts == 0} {
      # no timestamp found, handle same as previous
      if {$in_period} {
        puts $fo $line
      } else {
        # ignore line, not in time period
      }
    }
    while {($period != {}) && ($ts > [:sec_end $period])} {
      # voorbij de huidige period. Evt vorige afsluiten
      log debug "Voorbij huidige periode"
      if {$in_period} {
        close $fo
        set in_period 0
      }
      set period [:0 $fperiods]
      set fperiods [lrange $fperiods 1 end]
    }
    if {$period == {}} {  
      # geen periodes meer, klaar.
      log debug "Geen periodes meer, klaar"
      if {$in_period} {   
        close $fo
        set in_period 0
      }
      break
    }
    # ts nu iig voor sec_end van de huidige period
    if {$ts >= [:sec_start $period]} { # 
      # in periode, dus output!
      if {!$in_period} {
        log debug "Maak file voor nieuwe periode"
        set out_dir [file join [file dirname $filename] [:label $period]]
        file mkdir $out_dir
        set fo [open [file join $out_dir [file tail $filename]] w]
        set in_period 1
      }
      puts $fo $line
    } else {        
      # nog voor de start van de period, nog even niets.
    }
  }

  close $fi

  move_handled $filename
  
  if {$in_period} {
    close $fo
  }
}

proc move_handled {filename} {
  set handled_dir [file join [file dirname $filename] _handled]
  file mkdir $handled_dir
  file rename $filename [file join $handled_dir [file tail $filename]]
  
}

proc first_period_start {} {
  global periods
  :sec_start [:0 $periods]
}

proc det_ts {line fmt filename linenr} {
  lassign $fmt lre tsf gmt
  if {[regexp $lre $line z ts]} {
    try_eval {
      return [clock scan $ts -format $tsf -gmt $gmt]  
    } {
      log error "Scanning timestamp failed for $line \[${filename}#$linenr\] => $ts (fmt=$fmt)"
      # breakpoint
      # possibly corrupted logfile, continue for now.
      return 0
    }
  } else {
    if {[regexp CET $line]} {
      log warn "CET found in line, but no timestamp?: $line"
      # breakpoint
    }
    return 0
  }
}

proc det_format {filename} {
  global ts_formats
  foreach {fre lre tsf gmt} $ts_formats {
    if {[regexp $fre $filename]} {
      return [list $lre $tsf $gmt]
    }
  }
  return {}
}

# define 3 periods: pre-test, test, and post-test
# periods: List of Dict: label, sec_start, sec_end. Both times in seconds since epoch
# - invariant: periods is time sequentially ordered, with no overlap.
# param utc_start: formatted string of timestamp in UTC/GMT.
proc define_test {label utc_start minutes_test minutes_around} {
  global periods
  set sec_start [clock scan $utc_start -gmt 1 -format "%Y-%m-%d %H:%M:%S"]
  set sec_end [clock add $sec_start $minutes_test minutes]
  #lappend periods [dict create label "$label-pre" sec_start [clock add $sec_start -$minutes_around minutes] sec_end $sec_start]
  #lappend periods [dict create label "$label-test" sec_start $sec_start sec_end $sec_end]
  #lappend periods [dict create label "$label-post" sec_start $sec_end sec_end [clock add $sec_end $minutes_around minutes]]

  # toch 1 periode met marge ervoor en erna.
  # reden: dan beter in Splunk in lezen, minder groepen, minder complex. In Splunk zelf wel filters te maken op periodes.
  lappend periods [dict create label $label sec_start [clock add $sec_start -$minutes_around minutes] sec_end [clock add $sec_end $minutes_around minutes]]
}

proc log_periods {} {
  global periods
  foreach period $periods {
    # log debug "period: $period"
    log debug "[:label $period]: [ts_fmt [:sec_start $period]] => [ts_fmt [:sec_end $period]]"
  }
}

proc ts_fmt {sec} {
  clock format $sec -format "%Y-%m-%d %H:%M:%S"
}

main $argv
