#!/usr/bin/env tclsh86
package require Itcl
package require Tclx ; # for try_eval
package require ndv

package require term
package require term::ansi::code::attr
package require term::ansi::send
term::ansi::send::import

source [file join [file dirname [info script]] .. .. lib CLogger.tcl]
source [file join [file dirname [info script]] .. lib libmusic.tcl]
source [file join [file dirname [info script]] .. .. lib generallib.tcl]
source [file join [file dirname [info script]] .. lib setenv-media.tcl]

# TODO 4-12-2015
# Soms mp3's in subdir van hoofddir, bv cd. _trash is dan subdir van deze hoofddir-niet de bedoeling, moet gewoon tijdelijk/music/trash zijn. Even kijken hoe vaak dit voorkomt.

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
  if {$idx == 0} {
    puts "index 0 given, move all to trash"
    # puts "others: $others"
  } else {
    if {$dirname == ""} {
      puts stderr "Index $idx not found in last search results (show-results.txt)"
      exit
    }
    move_staging $dirname $new_name    
  }
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
  puts_colour green "Renaming $orig_path => $new_path"
  file rename $orig_path $new_path
}

proc move_trash {others} {
  foreach dirname $others {
    set trash_dir [file join [file dirname $dirname] "_trash"]
    set dest_dir [file join $trash_dir [file tail $dirname]]
    file mkdir $trash_dir
    puts_colour red "moving dir to trash: $dirname"
    # puts "trash_dir: $trash_dir"
    # puts "dest_dir: $dest_dir"
    file rename $dirname $dest_dir
  }
}

proc puts_colour {colour str} {
  send::sda_fg$colour
  puts $str
  # 5-12-2015 oude kleur te bewaren?
  send::sda_fgwhite
}

main $argv

