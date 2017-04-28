#! /usr/bin/env tclsh

package require ndv

# history
# 2015-08-11 NdV ook delete uit status halen en git rm maken.

use libfp

set_log_global info {filename -}

proc main {argv} {
  set os [det_os]
  if {$os == "windows"} {
    set git_exe [which_git c:/util/GitHub/cmd c:/PCC/util/cygwin/bin]
  } else {
    set git_exe "git"
  }
  lassign [det_dir_commit_msg $argv] dir commit_msg
  set orig_dir [pwd]
  cd $dir
  # set res [exec git status]
  set res [exec $git_exe status]
  puts "result of git-status:"
  puts $res
  # put git-add-commit.sh in current working dir where gac was called from.
  set filename [file join $orig_dir "git-add-commit.sh"]
  set f [open $filename w]
  fconfigure $f -translation lf
  puts $f "# $filename"
  puts $f "cd $dir"
  puts $f "# Adding files to git and commit"
  set has_changes [puts_changes $f $dir $res $commit_msg]
  puts $f "# remove file after executing"
  puts $f "rm $filename"
  puts $f "cd -"  
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
  cd $orig_dir
}

# [2017-04-27 22:49] commit msg meegeven doe ik eigenlijk nooit meer. Dir ook niet,
# maar nu nico functie door bv 'gac nicoprj' te kunnen zeggen, dan tijdelijke cd naar deze
# dir en hier git status etc uitvoeren.
proc det_dir_commit_msg {argv} {
  set dir "."
  set commit_msg "check"
  if {[count $argv] > 0} {
    if {[count $argv] == 1} {
      #lassign $argv commit_msg
      #set dir "."
      set dir [find_dir [first $argv]]
      if {$dir == ""} {
        log warn "dir not found: $argv, using ."
        set dir "."
      }
      set commit_msg "check"
    } else {
      # [2017-04-27 22:51] Deze nog als fallback houden.
      lassign $argv dir commit_msg
    }
  } else {
    set commit_msg check
    set dir .
  }
  list $dir $commit_msg
}

# search git-dir in default locations
proc find_dir {dir} {
  set root_dirs [list "~" "c:/PCC/Nico" "c:/Nico"]
  foreach root $root_dirs {
    set path [file join $root $dir]
    if {[file exists $path]} {
      return [file normalize $path]
    }
  }
  return ""
}

# TODO: deze dingen uit configs lezen?
proc det_npp_exe {} {
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

proc puts_changes {f root_dir res commit_msg} {
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
  # set dt [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  foreach file [lsort $files] {
    set dir [file dirname $file]
    if {$dir != $prev_dir} {
      if {$prev_dir != "<none>"} {
        # puts $f "# git commit -m \"Changes for $prev_dir at $dt\""
        # puts $f "# git commit -m \"$commit_msg\""
        if {$commit_msg != ""} {
          # puts $f "git commit -m \"$commit_msg\""
		  puts $f "git commit -m \"[det_commit_msg $commit_msg $prev_dir]\""
        } else {
          puts $f "# git commit -m \"<fill in>\""
        }
      }
    }
    # puts $f "# git diff \"$file\""
    # [2017-04-28 22:07] need full path now.
    # puts $f "# git diff \"$root_dir/$file\""
    puts $f "# git diff \"[file join $root_dir $file]\""
    puts $f "git add \"$file\""
    set prev_dir $dir
  }
  foreach file [lsort $deleted_files] {
    set dir [file dirname $file]
    if {$dir != $prev_dir} {
      if {$prev_dir != "<none>"} {
        if {$commit_msg != ""} {
          # puts $f "git commit -m \"$commit_msg\""
		  puts $f "git commit -m \"[det_commit_msg $commit_msg $prev_dir]\""
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
    # puts $f "git commit -m \"$commit_msg\""
    puts $f "git commit -m \"[det_commit_msg $commit_msg $prev_dir]\""
  } else {
    puts $f "# git commit -m \"<fill in>\""
  }
  
  return $has_changes
}

# use default commit messages for certain dirs like 'uren' and 'org'
proc det_commit_msg {msg dir} {
  set dir [file tail [file normalize $dir]]
  if {$msg == "check"} {
    set msg "check:$dir"
    # default, so may change based on dir
	if {$dir == "urenlog"} {
	  set msg "Urenlog"
	}
	if {$dir == "org"} {
	  set msg "Org files"
	}
  }
  return $msg
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

# search git.exe in directories mentioned in (varargs) args
proc which_git {args} {
	foreach dir $args {
		set exe [file join $dir "git.exe"]
		log debug "git exe option: $exe"
		if {[file exists $exe]} {
			return $exe
		}
	}
	error "No git.exe found in $args"
}

main $argv
