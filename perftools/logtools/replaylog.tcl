# replay a log file with the same speed.
# goal: determine overhead of logging, tail and add timestamp.
# test with different settings for after, and maybe also with tail/addts combination.
# source file contains timestamps, which are used for realtime replay.
# target file does not contain timestamps, to simulate ODBC driver.

package require ndv

proc main {argv} {
  lassign $argv srcfile destfile
  set fi [open $srcfile r]
  set fo [open $destfile w]
  set started [clock milliseconds]
  gets $fi line
  regexp {^\[([0-9 .:-]+)\] (.*)$} $line z ts text
  # breakpoint
  # puts "ts1: $ts"
  set msec_started_file [to_msec $ts]
  set diff_start [expr $started - $msec_started_file]
  puts $fo $text
  flush $fo
  while {![eof $fi]} {
    gets $fi line
    regexp {^\[([0-9 .:-]+)\] (.*)$} $line z ts text
    set msec [to_msec $ts]
    # puts "ts2: $ts"
    set outtime [expr $msec + $diff_start]
    set curr_msec [clock milliseconds]
    # 20-8-2015 now output everything directly, to test CPU usage.
    while {0 && ($curr_msec < $outtime)} {
      after [expr $outtime - $curr_msec]
      set curr_msec [clock milliseconds]
    }
    puts $fo $text
    flush $fo
  }
  close $fi
  close $fo
}

# ts: timestamp including milliseconds
proc to_msec {ts} {
  regexp {^([^.]+)\.0*(\d+)$} $ts z ts_sec msec
  expr 1000 * [clock scan $ts_sec -format "%Y-%m-%d %H:%M:%S"] + $msec
}

proc to_msec2 {ts} {
  regexp {^([^.]+)(\.\d+)$} $ts z ts_sec msec
  return [expr 1000 * "[clock scan $ts_sec -format "%Y-%m-%d %H:%M:%S"]$msec"]
}

main $argv
