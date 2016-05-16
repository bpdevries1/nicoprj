package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] AbstractLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

itcl::class PrevInputHandler {
 
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {reader log_helper} {
 		set instance [uplevel {namespace which [PrevInputHandler #auto]}]
    $instance init $reader $log_helper
    return $instance  
  }

  protected variable reader ; # to call det_task_name
  protected variable log_helper
  
  protected variable logfile_id
  protected variable threadname
  protected variable threadnr

  protected variable ts_prev
  protected variable line_prev
  
  public method init {a_reader a_helper} {
    set reader $a_reader 
    set log_helper $a_helper
  }

  public method file_start {a_filename a_logfile_id a_threadname a_threadnr} {
    set logfile_id $a_logfile_id
    set threadname $a_threadname
    set threadnr $a_threadnr

    set ts_prev ""
    set line_prev ""
  }
  
  public method handle_input {line {timestamp ""}} {
    if {$ts_prev == ""} {
      # 2 keer dezelfde timestamp meegeven.
      set ts1 $timestamp
    } else {
      set ts1 $ts_prev
    }
    set task_name [$reader det_task_name $line $line_prev $threadname]
    if {$task_name != "<ignore>"} {
      $log_helper insert_task $logfile_id $threadname $threadnr $task_name $ts1 $timestamp "$line - $line_prev"
      set line_prev $line
      set ts_prev $timestamp
    }
  }

  public method file_finished {} {
    # nothing here. 
  }
  
}
