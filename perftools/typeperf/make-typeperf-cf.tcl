#!/usr/bin/env tclsh

# Should work on local PC and Calypso machine with lib ndv.
# package require tdom
package require ndv

set_log_global info

require libdatetime dt
use libfp

ndv::source_once libperf.tcl

set_log_global info

proc main {argv} {
  global argv0
  # lassign $argv config
  set config [lindex $argv 0]
  if {$config == ""} {
    puts "syntax: $argv0 <config.tcl>"
    exit 1
  }
  source $config
  uplevel #0 [list source $config];   # set params at global level.
  # init
  # forward_files_loop $dropbox_xml_folder_in $dropbox_xml_folder_out $check_freq_sec $check_max_files
  # insert_trades $dbdriver $dbserver $dbname $src_dir $save_dir_root $pacing_sec $runtime_sec $send_messages $save_messages
  # insert_trades;               # all params now in global vars.
  # odin_check
  make_typeperf_cf
}

proc make_typeperf_cf {} {
  global typeperf_dir
  set specs [split [read_file [file join $typeperf_dir "counter-specs.txt"]] "\n"]
  foreach filename [glob -directory $typeperf_dir *.cf] {
    if {[regexp -- {-sel\.} $filename]} {
      continue;                 # file already generated, don't use as source
    }
    make_selection $filename $specs
  }
}

# make perfmon/typeperf selection
proc make_selection {filename specs} {
  log info "Make selection for: $filename"
  set fi [open $filename r]
  set fo [open "[file rootname $filename]-sel[file extension $filename]" w]
  while {[gets $fi line] >= 0} {
    foreach spec $specs {
      if {$spec == ""} {continue}
      if {[regexp {^#} $spec]} {continue}
      if {[regexp {^/(.*)/$} $spec z re]} {
        if {[regexp $re $line]} {
          puts $fo $line
          break;                # just add counter once
        }
      } else {
        # literal check
        if {$line == $spec} {
          puts $fo $line
          break;                # just add counter once
        }
      }
    }
  }
  close $fi
  close $fo
  set fo [open "[file rootname $filename]-typeperf.bat" w]
  set basename [file tail [file rootname $filename]]
  set count [expr 4 * 3600 / 10]
  puts $fo {cd "%~dp0"}
  puts $fo "del $basename.csv"
  puts $fo "typeperf -cf $basename-sel.cf -si 10 -sc $count -o $basename.csv"
  puts $fo "cd -"
  close $fo
  file copy -force "[file rootname $filename]-typeperf.bat" "[file rootname $filename]-typeperf.txt"
}

main $argv

