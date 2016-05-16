package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] TaskLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]
::ndv::source_once [file join [file dirname [info script]] CountInputHandler.tcl]

itcl::class VerwijderLogReader {
  inherit TaskLogReader
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [VerwijderLogReader #auto]}]
    $instance init $db
    return $instance  
  }
  
  
  private method det_kind {filename} {
    return "verwijder" 
  }

  protected method register_handlers {} {
    chain
    register_handler [CountInputHandler::new $this $log_helper "einde verwerk dossier"]
  }
   
  # @result 10 als filename like "Scheduler.log.1"
  public method can_read {filename} {
    if {[regexp {logging_[0-9_]+_verwijderen.csv} $filename]} {
        return 10 
    }
    return 0
  }

  public method det_task_name {line line_prev threadname} {
    if {[regexp {start verwerk dossier} $line]} {
      set result "verwijder-start" 
    } elseif {[regexp {einde verwerk dossier} $line]} {
      set result "verwijder-einde"
    } else {
      set result "logline" 
    }
    return $result
  }
  
  protected method det_threadname_number {filename} {
    if {[regexp {logging_[0-9]{8}_([0-9]+)_verwijderen.csv} $filename z threadnr]} {
      return [list "verwijder" $threadnr]
    } else {
      return [list "verwijder" 0]
    }
  }

}
