# general helper function for platform specific functions.

package require ndv

# set_var

proc find_newest {lst_paths file_spec} {
  foreach path $lst_paths {
    set lst [lsort -decreasing [glob -nocomplain -directory $path $file_spec]]
    if {[llength $lst] > 0} {
      return [lindex $lst 0]
    }
  }
  return "" ; # if nothing found  
}
