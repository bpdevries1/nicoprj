#!/usr/bin/env tclsh861

# TODO als opnieuw genereren:

proc main {} {
  # set src_root /home/nico/nicoprjbb/sporttools/mediaweb/src/mediaweb
  set src_root /home/nico/aaa/mediaweb
  set target_root /tmp/mediaweb

  phase1 $src_root [file join $target_root phase1]
  phase2 [file join $target_root phase1] [file join $target_root phase2]
}

proc phase1 {src target} {
  file mkdir $target
  foreach filename [glob -tails -directory $src *.clj] {
    if {[regexp {^(.+)_(.+).clj$} $filename z main sub]} {
      copy_sub $src $target $main $sub
    } else {
      # mainly just copy, but remove load calls
      copy_no_load [file join $src $filename] [file join $target $filename]
    }
  }
  foreach subdir {component endpoint} {
    file mkdir [file join $target $subdir]
    foreach filename [glob -nocomplain -tails -directory [file join $src $subdir] *.clj] {
      file copy -force [file join $src $subdir $filename] [file join $target $subdir $filename]
    }
  }
}

proc copy_no_load {src target} {
  set fi [open $src r]
  set fo [open $target w]
  while {[gets $fi line] >= 0} {
    if {[regexp {^\(load.+\)} $line]} {
      puts $fo ";; $line"
    } else {
      puts $fo $line
    }
  }
  close $fi
  close $fo
}

proc copy_sub {src_dir target_dir main sub} {
  set ns_decl [get_ns_decl [file join $src_dir "$main.clj"]]
  regsub "mediaweb\.$main" $ns_decl "mediaweb.$main.$sub" ns_decl
  set target_subdir [file join $target_dir $main]
  file mkdir $target_subdir
  set fi [open [file join $src_dir "${main}_${sub}.clj"] r]
  set fo [open [file join $target_subdir "${sub}.clj"] w]
  while {[gets $fi line] >= 0} {
    if {[regexp {in-ns} $line]} {
      puts $fo $ns_decl
    } else {
      puts $fo $line
    }
  }
  close $fi
  close $fo
}

proc get_ns_decl {src} {
  set ns_decl ""
  set f [open $src r]
  while {[gets $f line] >= 0} {
    if {[regexp {^\(ns } $line]} {
      set ns_decl $line
      while {[gets $f line] >= 0} {
        if {[string trim $line] == ""} {
          break
        } else {
          append ns_decl "\n$line"
        }
        
      }
      break
    }
  }
  close $f
  return $ns_decl
}

proc phase2 {src target} {
  foreach subdir {. helpers models views endpoint component} {
    foreach filename [glob -nocomplain -tails -directory [file join $src $subdir] *.clj] {
      convert_ns_use $src $target $subdir $filename
    }
  }
}

proc convert_ns_use {src_root target_root subdir filename} {
  global ns_ar
  set target_dir [file join $target_root $subdir]
  file mkdir $target_dir
  set fi [open [file join $src_root $subdir $filename] r]
  set fo [open [file join $target_dir $filename] w]
  set ns_decl ""
  set lines {}
  array unset ns_ar
  while {[gets $fi line] >= 0} {
    if {[regexp {^\(ns } $line]} {
      set ns_decl $line
      while {[gets $fi line] >= 0} {
        if {[string trim $line] == ""} {
          break
        } else {
          append ns_decl "\n$line"
        }
      }
    } else {
      # before or mostly after a ns-decl
      lappend lines [convert_ns_line $line $src_root]
    }
  }
  puts $fo ";; ns-decl follows:"
  # puts $fo $ns_decl
  puts $fo [merge_ns_decl $ns_decl $subdir $filename]
  puts $fo ""
  puts $fo ";; lines follow:"
  puts $fo [join $lines "\n"]
  
  close $fi
  close $fo
}

proc convert_ns_line {line src_root} {
  global ns_ar
  set line2 $line
  foreach ns {h models views} {
    # symbol zoeken beetje lastig, nu positieve search, characters die wel in een symbol kunnen voorkomen. Nu alleen -, _ en ? als extra tekens. Andere gebruik ik hier toch niet.
    if {[regexp "^(.*)$ns/(\[a-zA-Z0-9_?-\]+)(.*)$" $line2 z pre symbol post]} {
      set sub [find_symbol_def_sub $src_root $symbol $ns]
      if {$sub == ""} {
        # not found in sub, should be in main, change nothing.
        set line2 "[convert_ns_line $pre $src_root]$ns/$symbol[convert_ns_line $post $src_root]"  
      } else {
        lappend ns_ar([to_subdir $ns],$sub) $symbol
        if {$ns == "h"} {
          # no namespace clash with helper functions, so use :refer
          set line2 "[convert_ns_line $pre $src_root]$symbol[convert_ns_line $post $src_root]"  
        } else {
          # namespace clash possible, use :as
          set line2 "[convert_ns_line $pre $src_root][to_as $ns $sub]/$symbol[convert_ns_line $post $src_root]"
        }
      }
    }
  }
  if {[regexp {TODO.*TODO} $line]} {
    puts "2 TODO's in line: $line"
  }
  return $line2
}

proc to_as {ns sub} {
  return "[string range $ns 0 0][string range $sub 0 0]"
}

# find symbol definition (something with def or defn) in one of the sub-namespaces of ns
# src_root is phase 1, already split into multiple files, just search all in subdir
proc find_symbol_def_sub {src_root symbol ns} {
  foreach filename [glob -directory [file join $src_root [to_subdir $ns]] *.clj] {
    if {[find_symbol_def_file $filename $symbol]} {
      return [file tail [file rootname $filename]]
    }
  }
  # return "persoon"
  return ""
}

proc to_subdir {ns} {
  if {$ns == "h"} {
    return helpers
  }
  return $ns
}

proc find_symbol_def_file {filename symbol} {
  set found 0
  set f [open $filename r]
  while {[gets $f line] >= 0} {
    if {[regexp "\\(def\[^ \]* $symbol" $line]} {
      set found 1
    }
  }
  close $f
  return $found
}

proc merge_ns_decl {ns_decl subdir filename} {
  global ns_ar
  regexp {^(.*)\)$} $ns_decl z ns_decl1 
  set res $ns_decl1
  # append res "\n;; TODO: add these in correct syntax:"
  if {[llength [array names ns_ar]] > 0} {
    append res "\n  (:require"
    foreach el [lsort [array names ns_ar]] {
      lassign [split $el ","] main sub
      if {$main == "helpers"} {
        if {![circular_ref $main $sub $subdir $filename]} {
          append res "\n            \[mediaweb.$main.$sub :refer \[[join [lsort -unique $ns_ar($el)] " "]\]\]"
        }
      } else {
        if {![circular_ref $main $sub $subdir $filename]} {
          append res "\n            \[mediaweb.$main.$sub :as [to_as $main $sub]\]"
        }
      }
      # append res "\n:require $main.$sub :refer [join [lsort -unique $ns_ar($el)] " "]"
    }
    if {$subdir == "models"} {
      if {[file tail $filename] != "entities.clj"} {
        append res "\n            \[mediaweb.models.entities :refer :all\]"
      }
    }
    # [mediaweb.models.entities :refer :all] toevoegen bij alle model files.
    append res ")"
  }
  append res ")"
  return $res
}

proc circular_ref {main sub subdir filename} {
  if {$main == $subdir} {
    if {$sub == [file rootname [file tail $filename]]} {
      return 1
    }
  }
  return 0
}

main
