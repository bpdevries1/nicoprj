#!/usr/bin/env tclsh86

# create a file overview.org (emacs org-mode) which contains the first lines
# of each readme.txt or leesmij.txt file in each subdirectory.

set NLINES 10
set GLOBFILENAMES {read*me* lees*mij*}
set OUTFILENAME overview.org

proc main {argv} {
  global OUTFILENAME
  lassign $argv root_dir
  set f [open [file join $root_dir $OUTFILENAME] w]
  foreach subdir [lsort -nocase [glob -directory $root_dir -type d *]] {
    handle_dir $f $subdir    
  }
  write_gen_footer $f
  write_org_footer $f
  close $f
}

proc handle_dir {f dir} {
  global GLOBFILENAMES
  puts -nonewline $f "* [file tail $dir] - "
  set has_readme 0
  foreach glob_pattern $GLOBFILENAMES {
    foreach filename [glob -nocomplain -directory $dir -type f $glob_pattern] {
      handle_file $f $filename
      set has_readme 1
    }
  }
  if {!$has_readme} {
    puts $f "NO README FILE"
    puts $f [fileref [file join $dir "readme.txt"]]
  }
}

proc handle_file {f filename} {
  global NLINES
  set fi [open $filename r]
  set nread 0
  while {![eof $fi]} {
    gets $fi line
    # stop as soon as an empty line is read.
    if {[string trim $line] == ""} {
      break
    }
    puts $f [convert_line $line]
    incr nread
    if {$nread >= $NLINES} {
      break
    }
  }
  close $fi
  # puts $f "\[[file tail $filename]\]"
  puts $f [fileref $filename]
}

proc fileref {filename} {
  return "\[\[file:[file tail [file dirname $filename]]/[file tail $filename]\]\[[file tail $filename]\]\]"
  
}

proc convert_line {line} {
  if {[regexp {^\* } $line]} {
    return "*$line" ; # add another * so org-indent will work.
  } else {
    return $line    
  }
}

proc write_gen_footer {f} {
  global argv0 argv
  puts $f "\n* meta data"
  puts $f "Generated by: $argv0 $argv"
  puts $f "In: [pwd]"
  puts $f "On: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
}

proc write_org_footer {f} {
  puts $f "\n* org-mode configuration
#+STARTUP: indent
#+STARTUP: overview
#+STARTUP: hidestars
"
}

main $argv