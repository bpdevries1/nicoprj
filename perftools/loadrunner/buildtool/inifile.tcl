# procs for reading and writing (similiar to windows) .ini files, as used in Loadrunner.

# return a list, where each item is a dict: header and lines. Lines is a list.
proc ini_read {filename {fail_on_file_not_found 1}} {
  set ini {}
  set header ""
  set lines {}
  if {[file exists $filename]} {
    set f [open $filename r]
    while {[gets $f line] >= 0} {
      if {[regexp {^\[(.+)\]$} $line z h]} {
        if {$header != ""} {
          lappend ini [dict create header $header lines $lines]
        }
        set header $h
        set lines {}
      } else {
        lappend lines $line
      }
    }
    if {$header != ""} {
      lappend ini [dict create header $header lines $lines]
    }
    close $f
  } else {
    if {$fail_on_file_not_found} {
      error "File not found: $filename"
    } else {
      # nothing, return empty ini
    }
  }
  return $ini
}

# also make backup
proc ini_write {filename ini {translation crlf}} {
  set f [open [tempname $filename] w]
  fconfigure $f -translation $translation
  foreach d $ini {
    puts $f "\[[:header $d]\]"
    # don't put empty lines
    foreach line [:lines $d] {
      if {$line != ""} {
        puts $f $line
      }
    }
    # puts $f [join [:lines $d] "\n"]
  }
  close $f
  commit_file $filename
}

# add header/line combination to ini
# add to existing header if it exists, otherwise create new header at the end.
proc ini_add {ini header line} {
  set res {}
  set found 0
  foreach d $ini {
    if {[:header $d] == $header} {
      dict lappend d lines $line
      set found 1
    }
    lappend res $d
  }
  if {!$found} {
    lappend res [dict create header $header lines [list $line]]
  }
  return $res
}

# set all lines under a heading, eg for sorting
# return updated ini
proc ini_set_lines {ini header lines} {
  set res {}
  set found 0
  foreach grp $ini {
    if {[:header $grp] == $header} {
      lappend res [dict create header $header lines $lines]
      set found 1
    } else {
      lappend res $grp 
    }
  }
  if {!$found} {
    lappend res [dict create header $header lines $lines]
  }
  return $res
}

# add line to ini, but only if it does not already exist
proc ini_add_no_dups {ini header line} {
  set lines [ini_lines $ini $header]
  if {[lsearch -exact $lines $line] < 0} {
    set ini [ini_add $ini $header $line]
  }
  return $ini
}

proc ini_lines {ini header} {
  foreach d $ini {
    if {[:header $d] == $header} {
      return [:lines $d]
    }
  }
  return [list]
}

# return 1 iff line exists under header
proc ini_exists {ini header line} {
  if {[lsearch -exact [ini_lines $ini $header] $line] >= 0} {
    return 1
  } else {
    return 0
  }
}

# set value for name under header, create iff new.
proc ini_set_param {ini header name value} {
  set lines [ini_lines $ini $header]
  set ndx [lsearch -regexp $lines "^$name\\s*="]
  if {$ndx >= 0} {
    set lines [lreplace $lines $ndx $ndx "$name=$value"]
  } else {
    lappend lines "$name=$value"
  }
  set ini [ini_set_lines $ini $header $lines]
  return $ini
}

