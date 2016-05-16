# create dot/graph for showing load model relations between equations and variables.

package require ndv
ndv::source_once libdot.tcl

proc main {} {
  global ar_node_name
  set f [open "eqs.dot" w]
  write_dot_header $f
  # write_dot_title $f "Loadmodel equations and checks"

  foreach varname {lf Ntestc Nvu Nvu.nrm Nvuprmp Nvuprmp.nrm Tpacing Trmp Trmpevery \
                  Truntime Tscen Tsteady Xscenph.nrm Xscenps Xscenps.avg Xscenps.rmp \
                  Rscen Zscen Ntrpscen R.max Z.avg Xtps} {
     # do_list [node_stmt $varname] {{set node1} {puts $f}}
     set ar_node_name($varname) [puts_node_stmt $f $varname]
  }

  # equations
  # input
  handle_formula $f "Xscenps = lf * Xscenph.nrm / 3600"
  handle_formula $f "Nvu = lf * Nvu.nrm"
  handle_formula $f "Nvuprmp = lf * Nvuprmp.nrm"
  
  # kern
  handle_formula $f "Tpacing = Nvu / Xscenps"
  handle_formula $f "Trmpevery = Nvuprmp * Tpacing / Nvu"
  handle_formula $f "Trmp = Trmpevery * (Nvu / Nvuprmp - 1)"
  
  # div
  handle_formula $f "Xscenps.rmp = 0.5 * Xscenps"
  handle_formula $f "Tsteady = Truntime - Trmp"
  handle_formula $f "Xscenps.avg = (Xscenps.rmp * Trmp + Xscenps * Tsteady) / Truntime"
  handle_formula $f "Ntestc = Xscenps.avg * Truntime"
  
  # Tscen
  handle_formula $f "Tscen = Rscen + Zscen"
  handle_formula $f "Rscen = Ntrpscen * R.max"
  handle_formula $f "Zscen = Ntrpscen * Z.avg"
  handle_formula $f "Xtps = Xscenps * Ntrpscen"
  # handle_formula $f ""
  
  # checks
  handle_formula $f "Tscen < Tpacing" 0 ; # geen equation, maar een check
  #handle_formula $f "" 0

  write_dot_footer $f
  close $f
  do_dot "eqs.dot" "eqs.png"
}

proc handle_formula {f eq {is_eq 1}} {
# regexp "(\\A| )abc(\\Z| )" "1 abc"
  global ar_node_name
  set color [ifelse $is_eq blue red]
  set eq_name [puts_node_stmt $f $eq shape rectangle color $color]
  foreach {nm val} [array get ar_node_name] {
    if {[regexp "(\\A|\[ \\(])${nm}(\\Z|\[ \\)])" $eq]} {
      if {$is_eq && [regexp "^${nm}(\\Z|\[ \\)])" $eq]} {
        # LHS
        puts $f [edge_stmt $eq_name $val color $color]
      } else {
        # RHS
        puts $f [edge_stmt $val $eq_name color $color]
      }
    }
  }
}

# @todo check ook doen, dan in het rood? geen LHS en RHS, evt een check als LHS, maar is extra


proc main_test {} {
  set f [open "eqs.dot" w]
  write_dot_header $f
  write_dot_title $f "Loadmodel equations and checks"
  # do_list [node_stmt "Item 1"] {{set node1} {puts $f}}
  # lassign [node_stmt "Item 1" color red] node1 str ; puts $f $str
  set node1 [puts_node_stmt $f "Item 1"]
 
  # do_list [node_stmt "Item 2"] {{set node2} {puts $f}}
  set node2 [puts_node_stmt $f "Item 2"]
  # lassign [node_stmt "Item 2" shape rectangle] node2 str ; puts $f $str
  puts $f [edge_stmt $node1 $node2 color green]
  write_dot_footer $f
  close $f
  do_dot "eqs.dot" "eqs.png"
}

main
#main_test


