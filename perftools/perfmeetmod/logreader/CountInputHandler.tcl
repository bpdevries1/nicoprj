package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] AbstractLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

itcl::class CountInputHandler {
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {reader log_helper a_count_regexp} {
 		set instance [uplevel {namespace which [CountInputHandler #auto]}]
    $instance init $reader $log_helper $a_count_regexp
    return $instance  
  }

  protected variable reader
  protected variable log_helper
  protected variable count_regexp
  protected variable count
  
  protected variable logfile_id
  protected variable threadname
  protected variable threadnr

  public method init {a_reader a_helper a_count_regexp} {
    $log debug "Init called with count_regexp: $a_count_regexp"
    set reader $a_reader 
    set log_helper $a_helper
    set count_regexp $a_count_regexp
  }

  public method file_start {a_filename a_logfile_id a_threadname a_threadnr} {
    set logfile_id $a_logfile_id
    set threadname $a_threadname
    set threadnr $a_threadnr

    set count 0
  }
  
  public method handle_input {line {timestamp ""}} {
    if {[regexp -- $count_regexp $line]} {
      incr count 
    }
  }

  # actions at the end of the file.
  public method file_finished {} {
    $log debug "File finished, calling reader update_logfile_count"
    $reader update_logfile_count $count
  }
  
}
