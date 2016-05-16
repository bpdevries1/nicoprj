#!/home/nico/bin/tclsh

package require Tclx
package require csv

package require struct::list

interp alias {} map {} ::struct::list map
interp alias {} mapfor {} ::struct::list mapfor

interp alias {} filter {} ::struct::list filter
interp alias {} filterfor {} ::struct::list filterfor

interp alias {} iota {} ::struct::list iota

# own package
catch {package require ndv}

catch {set log [::ndv::CLogger::new_logger [file tail [info script]] debug]} 

proc main {argc argv} {
  set options {
    {path.arg "" "Path to loadrunner/sitescope raw data."}  
    {out.arg "tsv" "Relative path to output dir."}
    {clean "Clean the output dir before making graphs."}
    {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] path:"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  
  set tsv_dir [file join $ar_argv(path) $ar_argv(out)]
  if {$ar_argv(clean)} {
     file delete -force $tsv_dir
  }
  file mkdir $tsv_dir
  handle_path $ar_argv(path) $tsv_dir
}

proc handle_path {path tsv_dir} {
  global ar_title
  det_lst_names_used_sorted $path
  read_defs $path 
  # preprocess_offline $path
  
  # offline-sorted.dat has lines in correct order now.
  make_tsv $path
}

# read offline.dat, determine which names have values (not everything mentioned in def's has values
proc det_lst_names_used_sorted {path} {
  global lst_names_used_sorted
  log info "det_lst_names_used_sorted: start"
  set f [open [file join $path offline.dat] r]
  while {![eof $f]} {
    lassign [split [gets $f] " "] name
    if {$name != ""} {
      set ar_data($name) 1 
    }
  }
  close $f
  set lst_names_used_sorted [lsort [array names ar_data]]  
  log info "#names with values: [llength $lst_names_used_sorted]"
  log info "det_lst_names_used_sorted: finished"
}



# fill array ar_title: key=offline_datapoint_146, value=<linetitle_1>/<graphtitle>
proc read_defs {path} {
  log info "read_defs: start"
  foreach filename [glob -directory $path -type f "offl_*.def"] {
    read_def $filename  
  }
  log info "read_defs: finished"
}

# ar_title: from name to title
# ar_name: from title to name
proc read_def {filename} {
  global ar_title ar_name lst_names_used_sorted
  set f [open $filename r]
  gets $f line
  if {$line != "\[Graph definition\]"} {
    log warn "Unknown def file: $filename, first line != \[Graph definition\]: $line"
    return
  }
  while {![eof $f]} {
    gets $f line
    if {[regexp {^([^=]+)=(.*)$} $line z name val]} {
      set ar_val($name) $val
    }
  }
  close $f
  for {set i 1} {$i <= $ar_val(count)} {incr i} {
    # set ar_title($ar_val(DataPointLabel_$i)) "$ar_val(LineTitle_$i)$ar_val(GraphTitle)" ; # graphtitle starts with /, so not needed as separator.
    set name $ar_val(DataPointLabel_$i)
    set title "$ar_val(LineTitle_$i):$ar_val(GraphTitle)"
    if {[lsearch -exact -sorted $lst_names_used_sorted $name] > -1} {
      set ar_title($name) $title
      set ar_name($title) $name
    }
  }
}

proc preprocess_offline {path} {
  set max_diff [check_increasing $path]
  # set max_diff 12
  if {$max_diff > 0} {
    sort_increasing $path $max_diff
  } else {
    file copy -force [file join $path "offline.dat"] [file join $path "offline-sorted.dat"] 
  }
}

# check if timestamps in path/offline.dat are increasing (not decreasing)
proc check_increasing {path} {
  # set f [open [file join $path "offline-sorted.dat"] r]
  set f [open [file join $path "offline.dat"] r]
  set cur_max 0
  set max_diff 0
  set linenr 1
  while {![eof $f]} {
    lassign [split [gets $f] " "] name timestamp value
    if {$name == ""} {
      continue ; # last line is empty 
    }
    if {$timestamp < $cur_max} {
      set diff [expr $cur_max - $timestamp]
      if {$diff > $max_diff} {
        set max_diff $diff
        log warn "timestamp < cur_max: $timestamp < $cur_max (diff=$diff)"  
      }
    } else {
      set cur_max $timestamp 
    }
    incr linenr
  }
  close $f
  log info "max diff: $max_diff"
  return $max_diff
}

# sort offline.dat, results in offline.dat.sorted
proc sort_increasing {path max_diff} {
  log info "Sorting needed for offline.dat"
  set fi [open [file join $path "offline.dat"] r]
  set fo [open [file join $path "offline-sorted.dat"] w]
  # todo heb 1200 datapoints, dus blocksize mogelijk wat hoger zetten.
  set blocksize 10000
  set linenr 0
  set blocknr 1
  while {![eof $fi]} {
    set line [gets $fi]
    if {$line != ""} {
      lappend lines [split $line " "] 
    }
    incr linenr ; # linenr lines read.
    if {$linenr >= $blocksize} {
      log debug "Output block $blocknr"
      # output lines, keep lines close to the max timestamp
      set lines [lsort -integer -index 1 $lines]
      set cur_treshold [expr [lindex $lines end 1] - $max_diff]
      # breakpoint
      set keep_lines {}
      foreach line $lines {
        if {[lindex $line 1] < $cur_treshold} {
          puts $fo [join $line " "] 
        } else {
          lappend keep_lines $line 
        }
      }
      log debug "Keeping #lines: [llength $keep_lines]"
      flush $fo
      # breakpoint
      set lines $keep_lines
      set linenr 0
      incr blocknr
    }
  }
  # output the last block
  set lines [lsort -integer -index 1 $lines]
  foreach line $lines {
    puts $fo [join $line " "] 
  }
  close $fi
  close $fo
}

# make 'flat' tsv based on offline-sorted.dat and definitions
proc make_tsv {path} {
  global ar_title ar_name
  log info "make_tsv: start" 
  set lst_titles {}
  foreach el [array names ar_title] {
    lappend lst_titles $ar_title($el)
  }
  set i 0
  set lst_titles [lsort [array names ar_name]] 
  set ncol [llength $lst_titles]
  foreach el $lst_titles {
    # set ar_idx($el) $i
    set ar_idx($ar_name($el)) $i
    incr i
  }
  set fo [open [file join $path offline-flat.tsv] w]
  puts $fo "timestamp\t[join $lst_titles "\t"]"
  set fi [open [file join $path "offline-sorted.dat"] r]
  # set fi [open [file join $path "offline-s10000.dat"] r]
  set prev_ts 0
  empty_ar_val ar_val $ncol
  while {![eof $fi]} {
    set line [gets $fi]
    if {$line == ""} {
      continue 
    }
    lassign [split $line " "] name timestamp value
    if {$timestamp != $prev_ts} {
      if {$prev_ts != 0} {
        # handle previous timestamps
        puts -nonewline $fo [clock format $prev_ts -format "%H:%M:%S"]
        for {set i 0} {$i < $ncol} {incr i} {
          puts -nonewline $fo "\t$ar_val($i)" 
        }
        puts $fo ""
        # \t[join [mapfor el $lst_titles {id $ar_val($el)}] "\t"]"  
      }
      empty_ar_val ar_val $ncol
      set prev_ts $timestamp
    } ; # no else
    set ar_val($ar_idx($name)) $value
  }
  close $fi

  # handle last timestamp
  puts -nonewline $fo [clock format $prev_ts -format "%H:%M:%S"]
  for {set i 0} {$i < $ncol} {incr i} {
    puts -nonewline $fo "\t$ar_val($i)" 
  }
  puts $fo ""

  close $fo
  log info "make_tsv: finished" 
}

proc empty_ar_val {ar_val_name ncol} {
  upvar $ar_val_name ar_val
  for {set i 0} {$i < $ncol} {incr i} {
    set ar_val($i) "" 
  }
}


# with this proc no need to 'global log' in every proc, just do 'log XXX' instead of '$log XXX'
proc log {args} {
  global log
  $log {*}$args
}

# helper proc for use in map (and filter?)
proc id {val} {
  return $val
}

main $argc $argv

