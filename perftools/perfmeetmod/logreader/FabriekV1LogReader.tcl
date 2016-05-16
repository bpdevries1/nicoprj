package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] TaskLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]
::ndv::source_once [file join [file dirname [info script]] JobV1InputHandler.tcl]

itcl::class FabriekV1LogReader {
  inherit TaskLogReader
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [FabriekV1LogReader #auto]}]
    $instance init $db
    return $instance  
  }
  
  
  private method det_kind {filename} {
    if {[regexp {lgemeen} $filename]} {
      return "fabriek-alg" 
    } else {
      return "fabriek"
    }
  }

  protected method register_handlers {} {
    chain
    register_handler [JobV1InputHandler::new $this $log_helper]
  }
  
  public method can_read {filename} {
    set name_ok 0
    set result 0
    if {[regexp {Algemeen\.log} $filename]} {
      set name_ok 1 
    } elseif {[regexp {^[0-9]{8}_[0-9]+\.log} [file tail $filename]]} {
      set name_ok 1
    }
    if {$name_ok} {
      # bekijk inhoudelijk: oude versie begint met ----
      set f [open $filename r]
      gets $f line
      if {[regexp -- {^------} $line]} {
        set result 10 
      }
      close $f
    } 
    return $result
  }

  public method det_task_name {line line_prev threadname} {
    if {[regexp {Extractie naar XML - RunId: [0-9]+ Succes} $line]} {
      set result "extractxml" 
    } elseif {[regexp {Laden brondata} $line]} {
      set result "ladenbrondata"
    } elseif {[regexp {^Einddtijd: [-0-9 :]+$} $line]} {
      set result "<ignore>" ; # want is vaak 6:00 uur 's ochtends.  
    } else {
      set result "logline" 
    }
    return $result
  }
  
  # bepaal threadnumber uit inhoud logfile
  protected method det_threadname_number {filename} {
    set f [open $filename r]
    set threadnr ""
    while {![eof $f]} {
      gets $f line
      if {[regexp {\\straat([0-9]+)} $line z threadnr]} {
        break 
      }
    }
    close $f
    return [list "fabriek" $threadnr]
  }

}
