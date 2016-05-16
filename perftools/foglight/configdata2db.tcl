package require ndv
package require tdbc::sqlite3

proc main {} {
  set f [open "configuration-data-all.txt" r]
  file delete "configdata.db"
  set db [dbwrapper new "configdata.db"]
  $db add_tabledef configdata {id} {configtype value machine} 
  $db create_tables 0
  $db prepare_insert_statements
  set text [read $f]
  set lines [split $text "\n"]
  $db in_trans {
	  for {set i 0} {$i < [expr [llength $lines] - 2]} {incr i} {
      lassign [lrange $lines $i $i+2] l0 l1 l2
      # breakpoint
        #ActiveDirectoryModel
        #	All AD Domains
        #AD_Domain
      # eerste en laatste regel zonder tab, middelste met tab
      if {![start_tab $l0] && [start_tab $l1] && ![start_tab $l2]} {
        set configtype [string tolower $l0]
        set vaue "<unknown>"
        regexp {^\t(.*)$} $l1 z value
        set value [string tolower $value]
        # overslaan als er spaties in de value zitten
        if {[ignore_value $configtype $value]} {
          continue
        }
        if {[regexp {^([^\.]+)\.} $value z m]} {
          set machine $m
        } else {
          set machine $value
        }
        $db insert configdata [vars_to_dict configtype value machine]
      }
      if {[regexp {mdc01.resource.intra} $l1]} {
        # breakpoint
      }
	  }
  }	
  close $f
  $db close
}

proc start_tab {line} {
  regexp {^\t} $line]
}

proc ignore_value {configtype value} {
  if {[regexp { } $value]} {
    return 1
  }
  
  return 0
}

main