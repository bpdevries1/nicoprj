package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] TaskLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]
::ndv::source_once [file join [file dirname [info script]] SchedTimesCountInputHandler.tcl]

itcl::class SchedulerTimesLogReader {
  inherit TaskLogReader
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [SchedulerTimesLogReader #auto]}]
    $instance init $db
    return $instance  
  }
  
  
  private method det_kind {filename} {
    return "schedulertimes" 
  }

  # @result 10 als filename like "Scheduler.log.1"
  public method can_read {filename} {
    if {[regexp {Scheduler.Times.log} $filename]} {
        return 10 
    }
    return 0
  }

 
  # bepaal threadnumber uit inhoud logfile
  protected method det_threadname_number {filename} {
    return [list "schedtimes" 1]
  }

  protected method register_handlers {} {
    set lst_input_handlers {}
    register_handler [SchedTimesCountInputHandler::new $this $log_helper]
  }
    
  public method read_log {filename testrun_id} {
    $log debug "read_log: $filename, $db, $testrun_id"
    set logfile_id [$db insert_object logfile -testrun_id $testrun_id -path $filename -kind [det_kind $filename]]

    foreach {threadname threadnr} [det_threadname_number $filename] break
    $log debug "read_log: $filename: $threadname *** $threadnr ***"
    
    foreach input_handler $lst_input_handlers {
      $input_handler file_start $filename $logfile_id $threadname $threadnr
    }
    
    set fi [open $filename r]
    set ts_first ""
    # 29-1-2010 threadnr (3) is er nu bijgekomen, dus 7 elementen.
    # Initialize DCF;3;29-1-2010;13:31:05.210;29-1-2010;13:31:07.819;00:00:02.6094418
    while {![eof $fi]} {
       gets $fi line
       set lst [split $line ";"]
       if {[llength $lst] == 6} {
         foreach {task str_dt_start str_tm_start str_dt_end str_tm_end str_duration} $lst break
       } elseif {[llength $lst] == 7} {
         foreach {task threadnr str_dt_start str_tm_start str_dt_end str_tm_end str_duration} $lst break
       } else {
         continue  
       }
       set ts_start [parse_sec_partsec $str_dt_start $str_tm_start]
       if {$ts_first == ""} {
          set ts_first $ts_start 
       }
       set ts_end [parse_sec_partsec $str_dt_end $str_tm_end]
       # $log_helper insert_task $logfile_id $threadname $threadnr "$threadname-[det_task_name $task]" $ts_start $ts_end $task
       $log_helper insert_task $logfile_id $threadname $threadnr [det_task_name $task] $ts_start $ts_end $task
    }
    set ts_last $ts_end
    close $fi

    # -file
    $log_helper insert_task $logfile_id $threadname $threadnr "file" $ts_first $ts_last

    $log debug "Calling input_handlers: SchedTimesCountInputHandler"
    foreach input_handler $lst_input_handlers {
      $input_handler file_finished
    }

    
  }
  
  private method det_task_name_old {task} {
    return "logline"
  }

  public method det_task_name {task} {
    # 29-1-2010 ook: XML files extracten
    if {[regexp {Extractie naar XML - RunId: [0-9]+ Succes} $task]} {
      set result "extractxml" 
    } elseif {[regexp {XML files extracten} $task]} {
      set result "extractxml"
    } elseif {[regexp {Laden brondata} $task]} {
      set result "ladenbrondata"
    } else {
      set result "logline" 
    }
    return $result
  }
  
  private method parse_sec_partsec {str_dt str_tm} {
    if {[regexp {^(.+)(\..+)$} $str_tm z str_sec partsec]} {
      # niets, info al in str_sec en partsec
    } else {
      set partsec ".0"
      set str_sec $str_tm
    }
    set sec [clock scan "$str_dt $str_sec" -format "%d-%m-%Y %H:%M:%S"]
    return [Timestamp::new $sec $partsec]
  }
  
}
