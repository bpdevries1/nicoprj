package require Itcl
package require ndv
package require struct::list

# ::ndv::source_once alle logreaders
foreach filename [glob -nocomplain -type f -directory [file dirname [info script]] "*LogReader.tcl"] {
  ::ndv::source_once $filename 
}

itcl::class LogReaderFactory {
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc get_instance {db} {
    if {$instance == ""} {
   		set instance [uplevel {namespace which [LogReaderFactory #auto]}]
      $instance init $db
    }
    return $instance
  }
  
  # instance stuff
  private variable lst_readers
  private variable db
  
  public method init {a_db} {
    set db $a_db 
    set lst_readers {}
    foreach clazz [itcl::find classes ::*LogReader] {
      $log debug "Registering class: $clazz"
      # lappend lst_readers [${clazz}::get_instance]
      lappend lst_readers [${clazz}::new $db]
    }
  }
  
  public method get_reader {filename} {
    $log debug "get_reader: $filename"
    set lst [::struct::list mapfor reader $lst_readers {
      $log debug "can_read for: $reader, $filename"
      list $reader [$reader can_read $filename]
    }]
    #$log debug "lst1: $lst"
    set lst [::struct::list filterfor el $lst {
      [lindex $el 1] > 0
    }]
    #$log debug "lst2: $lst"
    set lst [lsort -decreasing -integer -index 1 $lst]
    #$log debug "lst3: $lst"
    if {[llength $lst] > 1} {
      $log debug "More than 1 reader for $filename: $lst"
      if {[lindex $lst 0 1] == [lindex $lst 1 1]} {
        $log warn "More than 1 reader with same can_read value for $filename: $lst"
        error "More than 1 reader with same can_read value for $filename: $lst"
      }
      set result [lindex $lst 0 0]
    } elseif {[llength $lst] == 1} {
      $log debug "reader found: [lindex $lst 0 0]" 
      set result  [lindex $lst 0 0]
    } else {
      $log debug "No reader found for $filename"
      set result ""
    }
    $log debug "get_reader result : $result"
    return $result
  }
  
}
