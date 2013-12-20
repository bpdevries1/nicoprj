#!/usr/bin/env tclsh86

package require ndv

proc main {argv} {
  # eerst alleen nicoprj
  cd "c:/nico/nicoprj"
  set res [exec git status]
  set filename "git-add-commit.sh" 
  set f [open $filename w]
  fconfigure $f -translation lf
  puts $f "# $filename"
  puts $f "# Adding files to git and commit"
  set has_changes [puts_changes $f $res]
  if {$has_changes} {
    set dt [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
    puts $f "git commit -m \"Changes for $dt\""
    puts $f "# gitpush"
  } else {
    puts $f "# No changes"
  }
  puts $f "# $filename"
  close $f
}

proc puts_changes {f res} {
  set has_changes 0
  set in_untracked 0
  foreach line [split $res "\n"] {
    if {[regexp {^#[ \t]+modified:[ \t]+(.+)$} $line z filename]} {
      puts $f "# modified file: $filename"
      puts $f "git add $filename"
      set has_changes 1
    } elseif {[regexp {Untracked files:} $line]} {
      set in_untracked 1
    } elseif {$in_untracked} {
      if {[regexp {to include in what will be co} $line]} {
        # ignore this one.
      } elseif {[regexp {git-add-commit.sh} $line]} {
        # ignore this one.
      } elseif {[regexp {^#[ \t]+(.+[^/])$} $line z filename]} {
        # path should not end in /, don't add dirs.
        puts $f "# new file: $filename"
        puts $f "git add $filename"
        set has_changes 1
      } elseif {[regexp {^#[ \t]+(.+[/])$} $line z filename]} {
        puts $f "# new DIRECTORY: $filename"
        puts $f "git add $filename"
        set has_changes 1
      }
    }
  }
  return $has_changes
}

main $argv
