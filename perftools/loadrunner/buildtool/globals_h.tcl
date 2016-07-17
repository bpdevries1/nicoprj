# add file to #include list in globals.h
proc globals_add_file_include {filename} {
  set fn "globals.h"
  set fi [open $fn r]
  set fo [open [tempname $fn] w]
  fconfigure $fo -translation crlf
  set in_includes 0
  set found 0
  while {[gets $fi line] >= 0} {
    if {$in_includes} {
      if {[regexp {\#include \"(.+)\"} $line z include]} {
        if {$include == $filename} {
          set found 1
        }
      } elseif {[string trim $line] == ""} {
        # ok, continue
      } else {
        # not in includes anymore, so add new one if needed
        if {!$found} {
          puts $fo "#include \"$filename\""
        }
        set in_includes 0
      }
    } else {
      if {[regexp {\#include} $line]} {
        # first line should always be lrun.h, so don't check on this one.
        set in_includes 1
      }
    }
    puts $fo $line
  }
  close $fo
  close $fi
  commit_file $fn
}

# // Global Variables
# int scripttest;
# char *userparam;
# ook soort kopjes, vgl ini file:
# //--------------------------------------------------------------------
# // Global Variables
proc globals_add_var {name datatype} {
  set text [read_file globals.h]
  if {$datatype == "int"} {
    set line "int $name;"  
  } elseif {$datatype == "str"} {
    set line "char *$name;"
  } else {
    error "Unknown datatype: $datatype (name=$name)"
  }
  set lines [split $text "\n"]
  if {[lsearch -exact $lines $line] < 0} {
    # new line
    set ndx [lsearch -exact $lines "// Global Variables"]
    set lines [linsert $lines $ndx+1 $line]
    set fo [open [tempname globals.h] w]
    fconfigure $fo -translation crlf
    puts -nonewline $fo [join $lines "\n"]
    close $fo
    commit_file globals.h
  }
}


