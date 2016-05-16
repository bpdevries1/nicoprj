package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] AbstractLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

itcl::class SelectieCountInputHandler {
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {reader log_helper} {
 		set instance [uplevel {namespace which [SelectieCountInputHandler #auto]}]
    $instance init $reader $log_helper
    return $instance  
  }

  protected variable reader
  protected variable log_helper
  protected variable count_regexp
  protected variable count
  
  protected variable filename
  protected variable logfile_id
  protected variable threadname
  protected variable threadnr

  public method init {a_reader a_helper} {
    set reader $a_reader 
    set log_helper $a_helper
  }

  public method file_start {a_filename a_logfile_id a_threadname a_threadnr} {
    set filename $a_filename
    set logfile_id $a_logfile_id
    set threadname $a_threadname
    set threadnr $a_threadnr
  }
  
  public method handle_input {line {timestamp ""}} {
    # nothing, handle counting at file end.
  }

  # actions at the end of the file.
  public method file_finished {} {
    set count 0
    foreach sel_filename [glob -nocomplain -directory [file dirname $filename] "selectie*.csv"] {
       set text [read_file $sel_filename]
       set nlines [regexp -all "\n" $text]
       incr count [expr $nlines - 1]
    }
    
    $log debug "File finished, calling reader update_logfile_count"
    $reader update_logfile_count $count
  }
  
}
