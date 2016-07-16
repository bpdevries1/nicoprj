# procs for reading and writing (similiar to windows) .ini files, as used in Loadrunner.

# return a list, where each item is a dict: header and lines. Lines is a list.
proc ini_read {filename} {
  set ini {}
  set header ""
  set lines {}
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
  return $ini
}

# also make backup
proc ini_write {filename ini {translation crlf}} {
  set f [open [tempname $filename] w]
  fconfigure $f -translation $translation
  foreach d $ini {
    puts $f "\[[:header $d]\]"
    puts $f [join [:lines $d] "\n"]
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

# add line to ini, but only if it does not already exist
proc ini_add_no_dups {ini header new_line} {
  set lines [ini_lines $ini $header]
  if {[lsearch -exact $lines $new_line] < 0} {
    set ini [ini_add $ini $header $new_line]
  }
  return $ini
}

proc ini_lines {ini header} {
  foreach d $ini {
    if {[:header $d] == $header} {
      return [:lines $d]
    }
  }
  return {}
}

