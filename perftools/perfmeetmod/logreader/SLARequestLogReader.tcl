package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] TaskLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

# NdV 9-9-2010 ook Force DB workflow logs inlezen, zelfde formaat als SLA logs.

itcl::class SLARequestLogReader {
  inherit TaskLogReader
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [SLARequestLogReader #auto]}]
    $instance init $db
    return $instance  
  }
  
  
  private method det_kind {filename} {
    return "slarequest" 
  }

  public method can_read {filename} {
    if {[regexp {SLARequest} $filename]} {
        return 10 
    }
    return 0
  }

 
  # bepaal threadnumber uit inhoud logfile
  protected method det_threadname_number {filename} {
    return [list "slarequest" 1]
  }

  protected method register_handlers {} {
    set lst_input_handlers {}
    # register_handler [SchedTimesCountInputHandler::new $this $log_helper]
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
#date1,time1,date2,time2,url,elapsed,subelapsed
#2010-09-02,12:31:00.027,2010-09-02,12:31:01.323,IAS.IASJob,1.296,0.000
    gets $fi header_line

    while {![eof $fi]} {
       gets $fi line
       set lst [split $line ","]
       if {[llength $lst] == 7} {
         lassign $lst date1 time1 date2 time2 url elapsed subelapsed
       } else {
         continue  
       }
       set ts_start [parse_sec_partsec $date1 $time1]
       if {$ts_first == ""} {
          set ts_first $ts_start 
       }
       set ts_end [parse_sec_partsec $date2 $time2]
       # $log_helper insert_task $logfile_id $threadname $threadnr "$threadname-[det_task_name $task]" $ts_start $ts_end $task
       $log_helper insert_task $logfile_id {*}[det_threadname_number_from_task $url] [det_task_name $url] $ts_start $ts_end $url
    }
    set ts_last $ts_end
    close $fi

    # -file
    # 2-9-2010 NdV file voegt hier weinig toe, zit alleen maar in de weg.
    # $log_helper insert_task $logfile_id $threadname $threadnr "file" $ts_first $ts_last

    $log debug "Calling input_handlers: SchedTimesCountInputHandler"
    foreach input_handler $lst_input_handlers {
      $input_handler file_finished
    }
  }

  protected method det_threadname_number_from_task {task} {
    if {[regexp {Job} $task]} {
      return [list "job" 1] 
    } else {
      return [list "request" 1]
    }
  }
  
  public method det_task_name {task} {
    # 29-1-2010 ook: XML files extracten
    if {[regexp {^(.+)Koppeling} $task z res]} {
      return $res 
    }
    return $task
  }
  
  # @param str_dt: 2010-09-02
  # @param str_tm: 12:31:00.027
  private method parse_sec_partsec {str_dt str_tm} {
    if {[regexp {^(.+)(\..+)$} $str_tm z str_sec partsec]} {
      # niets, info al in str_sec en partsec
    } else {
      set partsec ".0"
      set str_sec $str_tm
    }
    set sec [clock scan "$str_dt $str_sec" -format "%Y-%m-%d %H:%M:%S"]
    return [Timestamp::new $sec $partsec]
  }
  
}
