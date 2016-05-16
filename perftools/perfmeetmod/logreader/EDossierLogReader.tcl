package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] TaskLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]
::ndv::source_once [file join [file dirname [info script]] EDossierCountInputHandler.tcl]

itcl::class EDossierLogReader {
  inherit TaskLogReader
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [EDossierLogReader #auto]}]
    $instance init $db
    return $instance  
  }
  
  
  private method det_kind {filename} {
    return "edossier" 
  }

  protected method register_handlers {} {
    chain
    register_handler [EDossierCountInputHandler::new $this $log_helper]
  }
   
  # @result 10 als filename like "Scheduler.log.1"
  public method can_read {filename} {
    if {[regexp {EdossierLogging} $filename]} {
        return 10 
    }
    return 0
  }

  public method det_task_name {line line_prev threadname} {
    if {[regexp {Kopieren gelukt voor} $line]} {
      set result "edossier" 
    } else {
      set result "logline" 
    }
    return $result
  }
  
  protected method det_threadname_number {filename} {
    # even simpel houden
    return [list "edossier" 0]
  }

}
