# Misc functions, move to other files when patterns/groups emerge.

# from tclhelp in lreplace.
# counter-proc to lappend.
proc lremove {listVariable value} {
  upvar 1 $listVariable var
  set idx [lsearch -exact $var $value]
  set var [lreplace $var $idx $idx]
}

