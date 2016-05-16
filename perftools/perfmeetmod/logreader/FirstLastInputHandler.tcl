package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] AbstractLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

itcl::class FirstLastInputHandler {
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {reader log_helper} {
 		set instance [uplevel {namespace which [FirstLastInputHandler #auto]}]
    $instance init $reader $log_helper
    return $instance  
  }

  protected variable reader
  protected variable log_helper
  
  protected variable logfile_id
  protected variable threadname
  protected variable threadnr

  protected variable ts_eerste
  protected variable ts_laatste
  
  public method init {a_reader a_helper} {
    set reader $a_reader 
    set log_helper $a_helper
  }

  public method file_start {a_filename a_logfile_id a_threadname a_threadnr} {
    set logfile_id $a_logfile_id
    set threadname $a_threadname
    set threadnr $a_threadnr

    set ts_eerste ""
    set ts_laatste ""
  }
  
  public method handle_input {line {timestamp ""}} {
    if {$ts_eerste == ""} {
      set ts_eerste $timestamp 
    }
    set ts_laatste $timestamp
  }

  # actions at the end of the file.
  public method file_finished {} {
    $log debug "threadnr before insert: $threadnr"
    if {$threadname != "<unknown>"} {
      if {$ts_eerste != ""} {
        $log_helper insert_task $logfile_id $threadname $threadnr "file" $ts_eerste $ts_laatste
      } else {
        $log debug "ts_eerste == \"\", do not insert db record"   
      }
    } else {
      $log debug "threadname == <unknown>, do not insert db record"  
    }
  }
  
}
