#!/usr/bin/env tclsh86

package require ndv

# history
# 2015-08-11 NdV ook delete uit status halen en git rm maken.

proc main {argv} {
  # eerst alleen nicoprj
  set os [det_os]
  set commit_msg ""
  if {[:# $argv] > 0} {
    lassign $argv dir commit_msg
    cd $dir
  } else {
    if {$os == "windows"} {
      cd "c:/nico/nicoprj"
    } else {
      cd ~/nicoprj 
    }
  }
  set res [exec git status]
  puts "result of git-status:"
  puts $res
  set filename "git-add-commit.sh" 
  set f [open $filename w]
  fconfigure $f -translation lf
  puts $f "# $filename"
  puts $f "# Adding files to git and commit"
  set has_changes [puts_changes $f $res $commit_msg]
  puts $f "# name of file to exec: $filename"
  close $f
  if {$os == "windows"} {
    # exec c:/util/notepad++/notepad++.exe $filename
    set npp_exe [det_npp_exe]
    exec $npp_exe $filename
  } else {
    exec -ignorestderr chmod +x $filename
    exec -ignorestderr gedit $filename &
  }
}

proc det_npp_exe {} {
  # set lst_loc {"c:/util/notepad++/notepad++.exe" "H:\\Disciplines\\Trim\\Testing\\Tooling\\Notepad++Portable\\Notepad++Portable.exe"}
  set lst_loc {"c:/util/notepad++/notepad++.exe" "C:\\PCC\\Util\\PortableApps\\Notepad++Portable\\app\\notepad++\\notepad++.exe"}
  foreach loc $lst_loc {
    if {[file exists $loc]} {
      return $loc
    }
  }
  return ""
}

proc det_os {} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    return windows 
  } else {
    return unix 
  }
}

proc puts_changes {f res commit_msg} {
  set has_changes 0
  set in_untracked 0
  set files {}
  set deleted_files {}
  foreach line [split $res "\n"] {
    # puts "handle line: $line"
    # linux: no # at start of line, maybe dependent on git version.
    if {[regexp {^#?[ \t]+modified:[ \t]+(.+)$} $line z filename]} {
      # puts $f "# modified file: $filename"
      # puts $f "# git add $filename"
      # puts "-> added"
      lappend files $filename
      set has_changes 1
    } elseif {[regexp {^#?[ \t]+deleted:[ \t]+(.+)$} $line z filename]} {
      lappend deleted_files $filename
      set has_changes 1
    } elseif {[regexp {Untracked files:} $line]} {
      set in_untracked 1
      # puts "-> in_untracked"
    } elseif {$in_untracked} {
      if {[regexp {to include in what will be co} $line]} {
        # ignore this one.
        # puts "-> ignored 1"
      } elseif {[ignore_file $line]} {
        # ignore this one.
        # puts "-> ignored 2"
      } elseif {[regexp {^#?[ \t]+(.+[^/])$} $line z filename]} {
        # path should not end in /, don't add dirs.
        # puts $f "# new file: $filename"
        # puts $f "# git add $filename"
        # puts "-> added"
        lappend files $filename
        set has_changes 1
      } elseif {[regexp {^#?[ \t]+(.+[/])$} $line z filename]} {
        # puts $f "# new DIRECTORY: $filename"
        # puts $f "# git add $filename"
        # puts "-> added"
        lappend files $filename
        set has_changes 1
      } else {
        # puts "-> ignored 3" 
        if {[regexp {clj} $line]} {
          # breakpoint
        }
      }
    } else {
      # puts "-> ignored 4" 
      if {[regexp {modified} $line]} {
        # breakpoint
      }
    }
  }
  set prev_dir "<none>"
  set dt [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  foreach file [lsort $files] {
    set dir [file dirname $file]
    if {$dir != $prev_dir} {
      if {$prev_dir != "<none>"} {
        # puts $f "# git commit -m \"Changes for $prev_dir at $dt\""
        # puts $f "# git commit -m \"$commit_msg\""
        if {$commit_msg != ""} {
          puts $f "git commit -m \"$commit_msg\""
        } else {
          puts $f "# git commit -m \"<fill in>\""
        }
      }
    }
    puts $f "git add \"$file\""
    set prev_dir $dir
  }
  foreach file [lsort $deleted_files] {
    set dir [file dirname $file]
    if {$dir != $prev_dir} {
      if {$prev_dir != "<none>"} {
        if {$commit_msg != ""} {
          puts $f "git commit -m \"$commit_msg\""
        } else {
          puts $f "# git commit -m \"<fill in>\""
        }
      }
    }
    puts $f "git rm \"$file\""
    set prev_dir $dir
  }
  
  # puts $f "# git commit -m \"Changes for $prev_dir at $dt\""
  if {$commit_msg != ""} {
    puts $f "git commit -m \"$commit_msg\""
  } else {
    puts $f "# git commit -m \"<fill in>\""
  }
  
  return $has_changes
}

proc ignore_file {line} {
  if {[regexp {git-add-commit.sh} $line]} {
    return 1
  } elseif {[regexp {saveproc.txt} $line]} {
    return 1
  } else {
    return 0
  }
}

main $argv
