package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] TaskLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

itcl::class SchedulerLogReader {
  inherit TaskLogReader
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [SchedulerLogReader #auto]}]
    $instance init $db
    return $instance  
  }
  
  
  private method det_kind {filename} {
    return "scheduler" 
  }

  # @result 10 als filename like "Scheduler.log.1"
  public method can_read {filename} {
    # 15-1-2010 kan ook Scheduler_1.log zijn, dus voor nu alles met scheduler is goed.
    if {[regexp {Scheduler} $filename]} {
      if {[regexp -nocase {times} $filename]} {
        return 0; # separate reader for scheduler.log.times 
      } else {
        return 10
      }
    }
    return 0
  }

  public method det_task_name {line line_prev threadname} {
    # 29-1-2010 ook: XML files extracten
    if {[regexp {Extractie naar XML - RunId: [0-9]+ Succes} $line]} {
      set result "extractxml" 
    } elseif {[regexp {XML files extracten} $line]} {
      set result "extractxml"
    } elseif {[regexp {Laden brondata} $line]} {
      set result "ladenbrondata"
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
      if {[regexp {Start Scheduler - Config file.*Prog\\straat([0-9]+) config.xml} $line z threadnr]} {
        break 
      }
    }
    close $f
    return [list "scheduler" $threadnr]
  }

}
