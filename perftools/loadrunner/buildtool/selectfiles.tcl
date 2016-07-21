proc get_repo_libs {} {
  global repolibdir
  glob -nocomplain -tails -directory $repolibdir -type f *
}

# return sorted list of all (.c/.h) source files in project directory.
# so no config files etc.
# [2016-07-17 09:12] filter_ignore_files was always called in combination with this one,
# so make it standard.
proc get_source_files {} {
  set lst [concat [glob -nocomplain -tails -directory . -type f "*.c"] \
               [glob -nocomplain -tails -directory . -type f "*.h"]]
  lsort [filter_ignore_files $lst]
}

# delete combined_* files from list.
# maybe later use FP filter command
proc filter_ignore_files {source_files} {
  set res {}
  foreach src $source_files {
    if {[regexp {^combined_} $src]} {
      # ignore
    } elseif {$src == "pre_cci.c"} {
      # ignore
    } else {
      lappend res $src
    }
  }
  return $res
}

proc det_includes_files {source_files} {
  set res {}
  foreach source_file $source_files {
    lappend res {*}[det_includes_file $source_file]
  }
  lsort -unique $res
}

proc det_includes_file {source_file} {
  set res {}
  set f [open $source_file r]
  while {[gets $f line] >= 0} {
    if {[regexp {^#include "(.+)"} $line z include]} {
      # uts "FOUND include stmt: $include, line=$line"
      lappend res $include
    }
  }
  close $f
  return $res
}

proc in_lr_include {srcfile} {
  global lr_include_dir
  file exists [file join $lr_include_dir $srcfile]
}

proc get_action_files {} {
  set usr_file "[file tail [file normalize .]].usr"
  set ini [ini_read $usr_file]
  set lines [ini_lines $ini Actions]
  set res {}
  foreach line $lines {
    set filename [:1 [split $line "="]]
    if {![regexp {^vuser_} $filename]} {
      lappend res $filename
    }
  }
  # log debug "action files: $res"
  return $res
}


