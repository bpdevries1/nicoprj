package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] TaskLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]
::ndv::source_once [file join [file dirname [info script]] SelectieCountInputHandler.tcl]

itcl::class SelectieLogReader {
  inherit TaskLogReader
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [SelectieLogReader #auto]}]
    $instance init $db
    return $instance  
  }
  
  
  private method det_kind {filename} {
    return "selectie" 
  }

  protected method register_handlers {} {
    chain
    register_handler [SelectieCountInputHandler::new $this $log_helper]
  }
   
  # @result 10 als filename like "Scheduler.log.1"
  public method can_read {filename} {
    # logging_20100331_selectie.csv
    if {[regexp {logging_[0-9_]+_selectie.csv} $filename]} {
        return 10 
    }
    return 0
  }

  public method det_task_name {line line_prev threadname} {
    set result "logline" 
    return $result
  }
  
  protected method det_threadname_number {filename} {
    return [list "selectie" 0]
  }

}
