package require ndv

# TODO cmdline pars lezen, nu eerst CBW-script
# TODO functie calls ook opnemen, mogelijk in losse graph, waarsch veel groter.
# TODO Keuze welke files eigenlijk hetzelfde moeten zijn over projecten heen (lib-files) en welke kunnen varieren.
# - bv globals.h zou vast moeten zijn, include global_specific.h.
# - mogelijk ook voor vuser_init, hier ook veel vaste dingen in.
# - Action.c is wel altijd anders, mag ook.
# TODO kleurgebruik, zie ook vorige, welke soort:
# - libs van LR zelf: web_api.h, deze is altijd hetzelfde.
# - ook vugen.h van RN zou hetzelfde moeten zijn.
# - maker en beheerder van lib moet duidelijk zijn, ook scope: is dit script specifiek. Ook bv rcc_functions die voor alle rcc scripts van toepassing is.

# TODO CBW:
# - dynatrace.c direct in globals.h? deze wil je altijd.

proc main {} {
  set_dot_exe {C:\PCC\Util\GraphViz2.38\bin\dot.exe}
  set dir c:/PCC/Nico/VuGen/RCC_CashBalancingWidget

  # dict lappend includes src incl
  # dict set cfiles src 1

  dict set cfiles Main 1
  dict set includes Main {globals.h vuser_init.c Action.c vuser_end.c}
  foreach file [glob -directory $dir -type f {*.[ch]}] {
    if {[regexp {combined_} $file]} {
      continue
    }
    dict set cfiles [file tail $file] 1
    set f [open $file r]
    while {[gets $f line] >= 0} {
      # #include "globals_specific.h"
      if {[regexp {^#include "([^ ]+)"} $line z included]} {
        dict lappend includes [file tail $file] $included
      }
    }
    close $f
  }

  set basename "CBW-includes"
  set dotfile "$basename.dot"
  set pngfile "$basename.png"

  
	set f [open $dotfile w]
	write_dot_header $f
	# write_dot_title $f $basename

  # TODO dit moet eigenlijk if 0 worden, maar dan nog errors, ook in combi met dict create hieronder.
  if 1 {
    dict for {cfile _} $cfiles {
      # only put node as start-node if it has includes.
      if {[dict_get $includes $cfile] != {}} {
        set node [puts_node_stmt $f $cfile]
        dict set nodes $cfile $node
      }
    }
  }
 
  # set nodes [dict create]
  dict for {cfile includes} $includes {
    if {[dict_get $includes $cfile] != {}} {
      set node [puts_node_stmt $f $cfile]
      dict set nodes $cfile $node
    }
    foreach incl $includes {
      if {[dict_get $nodes $incl] == {}} {
        dict set nodes $incl [puts_node_stmt $f $incl]
      }
      # puts $f [edge_stmt [dict get $nodes $cfile] [dict get $nodes $incl] label "#include"]
      puts $f [edge_stmt [dict get $nodes $cfile] [dict get $nodes $incl]]
    }
  }
  
  if 0 {
    dict for {cfile _} $cfiles {
      puts "c-file: $cfile"
      puts "includes: [dict_get $includes $cfile]"
    }
  }

	write_dot_footer $f
	
	close $f
	
	do_dot $dotfile $pngfile
	
  
}

proc main_old {} {
	set_dot_exe {C:\PCC\Util\GraphViz2.38\bin\dot.exe}
  
	set f [open testdot.dot w]
	write_dot_header $f
	write_dot_title $f "Test GraphViz"
	
	set node1 [puts_node_stmt $f "Node 1" color blue]
	set node2 [puts_node_stmt $f "Node 2" color blue]
	puts $f [edge_stmt $node1 $node2 color red label edgelabel]
	write_dot_footer $f
	
	close $f
	
	do_dot testdot.dot testdot.png
	
}

main
