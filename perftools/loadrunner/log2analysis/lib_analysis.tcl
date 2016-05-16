package require struct::list

# @todo format eigenlijk vervangen door iden-functie.
# 26-12-2011 this one was already in ~/nicoprj/lib/generallib.tcl
proc get_array_values {ar_name args} {
  upvar $ar_name ar
  struct::list mapfor el $args {format %s $ar($el)}
}

# split tekst in $fd based on regexp $re. When a line matches $re, the previous lines will be sent to $callbackproc
# with additional $args
# and after this the previous lines block will be re-initialised with current line (which matched $re)
# 26-12-2011 this one was already in ~/nicoprj/lib/generallib.tcl
proc file_block_splitter {fd re callbackproc args} {
  set lst_lines {}
  set in_block 0
  while {![eof $fd]} {
    gets $fd line
    if {[regexp $re $line]} {
      if {$in_block} {
        $callbackproc [join $lst_lines "\n"] {*}$args
      }
      set in_block 1
      set lst_lines [list $line]
    } else {
      if {$in_block} {
        lappend lst_lines $line
      }
    }
  }
  if {$in_block} {
    $callbackproc [join $lst_lines "\n"] {*}$args
  }
}
