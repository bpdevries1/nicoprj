#!/usr/bin/env tclsh861

# archive done items in a .org file and append to <name>-archive.org
package require ndv

proc main {argv} {
  lassign $argv orgfilename

  set archivename [append_filename $orgfilename archive]
  set orgnewname [append_filename $orgfilename new]
  #puts $orgfilename
  #puts $orgnewname
  #puts $archivename
  
  archive_org $orgfilename $orgnewname $archivename
}

proc append_filename {filename suffix} {
  set ftail [file tail $filename]
  set ext [file extension $filename]
  file join [file dirname $filename] "[file rootname $ftail]-$suffix$ext"
}

# do a one-pass through the file, append to archive and move to newname
# keep current path in all files (pathi, pathn, patha)
# also keep current output file
proc archive_org {orgfilename orgnewname archivename} {
  set fi [open $orgfilename r]
  set fn [open $orgnewname w]
  set fa [open $archivename a]
  set fcurr $fn
  set pathi {}
  set pathn {}
  set patha {}
  while {![eof $fi]} {
    gets $fi line
    if {[regexp {^(\*+) (.*)$} $line z stars item]} {
      set level [string length $stars]
      set pathi [change_path $pathi $level $item]
      if {[is_finished $item]} {
        set fcurr $fa
        write_parent_headers $fcurr $patha $pathi
        set patha $pathi
      } elseif {[is_todo $item]} {
        set fcurr $fn
        write_parent_headers $fcurr $pathn $pathi
        set pathn $pathi
      } else {
        # item without todo/done, so keep in current.
        # do set current path
        if {$fcurr == $fn} {
          set pathn $pathi
        } else {
          set patha $pathi
        }
      }
    } else {
      # not a heading line, so output to current output file.
      # all lines need to be written to current output file, so done after if.
    }
    puts $fcurr $line
  }
  close $fi
  close $fn
  close $fa
}

proc is_finished {item} {
  set status "<NONE>"
  regexp {^([^ ]+) } $item z status
  # breakpoint
  if {[lsearch {DONE CANCELLED DEFERRED} $status] >= 0} {
    return 1
  } else {
    return 0
  }
}

proc is_todo {item} {
  set status "<NONE>"
  regexp {^([^ ]+) } $item z status
  # breakpoint
  if {[lsearch {TODO STARTED WAITING APPT} $status] >= 0} {
    return 1
  } else {
    return 0
  }
}

proc change_path {path level item} {
  if {$level > [llength $path]} {
    linsert $path $level-1 $item
  } else {
    lreplace $path $level-1 end $item    
  }
}

# take care that item will be written to correct path, while not putting too many duplicate
# parent items
# examples:
# path_old is empty => write all of path_new, except for the last
# first item of path_old is the same as path_new, next items differ => write next items, except for last.
# old is a-b-c, new is a-b-d => do nothing, d will be written anyway
# first item of path_old is different from first of path_new => write out all parent items.
#
# so:
# start from the top: as long as old=new, do nothing. As soon as one element differnt, everything needs to be written.
proc write_parent_headers {f path_old path_new} {
  set start_new 0
  set new_1 [expr [llength $path_new] - 1]
  set old [llength $path_old]
  for {set i 0} {($i < $new_1) && ($i < $old)} {incr i} {
    if {[lindex $path_old $i] == [lindex $path_new $i]} {
      # ok, still the same, nothing to do
      incr start_new
    } else {
      # different, break out of loop and put new items.
      # not needed to set here, already done at previous item
      # set start_new $i
    }
  }
  for {set i $start_new} {$i < $new_1} {incr i} {
    puts $f "[stars [expr $i + 1]] [lindex $path_new $i]"
  }
}

proc stars {n} {
  string repeat "*" $n
}

main $argv