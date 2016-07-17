# add file to #include list in globals.h
proc add_file_include {filename} {
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

