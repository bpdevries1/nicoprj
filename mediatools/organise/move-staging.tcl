#!/usr/bin/env tclsh86
package require Itcl
package require Tclx ; # for try_eval
package require ndv

source [file join [file dirname [info script]] .. .. lib CLogger.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]
source [file join [file dirname [info script]] .. .. lib generallib.tcl]
source [file join [file dirname [info script]] .. lib setenv-media.tcl]

proc main {argv} {
	global env argv0
  if {[:# $argv] != 2} {
    puts stderr "syntax: $argv0 <idx> <new name>"
    puts stderr "use '-' for new name to keep name the same"
    exit 1
  }
  lassign $argv idx new_name
  set idx [:0 $argv]
  lassign [det_dirname $idx] dirname others
  if {$dirname == ""} {
    puts stderr "Index $idx not found in last search results (show-results.txt)"
    exit
  }
  move_staging $dirname $new_name
  move_trash $others
}

proc det_dirname {idx} {
  set f [open show-results.txt r]
  set res ""
  set others {}
  while {![eof $f]} {
    gets $f line
    if {[regexp {^(\d+) => \[[0-9 ,]+k\] (.+)$} $line z idx1 path]} {
      if {$idx == $idx1} {
        # found dir, now read files.
        set res $path
      } else {
        lappend others $path
      }
    }
  }
  close $f
  list $res $others
}

proc move_staging {orig_path new_name} {
  if {[regexp {/media/nas/media/Music/Albums} $orig_path]} {
    puts "Path already in destination location: $orig_path"
    return
  }
  set staging_dir "/media/nas/media/Music/_staging"
  if {$new_name == "-"} {
    set new_name [file tail $orig_path]
  }
  set new_path [file join $staging_dir $new_name]
  puts "Renaming $orig_path => $new_path"
  file rename $orig_path $new_path
}

proc move_trash {others} {
  foreach dirname $others {
    set trash_dir [file join [file dirname $dirname] "_trash"]
    set dest_dir [file join $trash_dir [file tail $dirname]]
    file mkdir $trash_dir
    puts "moving dir to trash: $dirname"
    file rename $dirname $dest_dir
  }
}

main $argv

