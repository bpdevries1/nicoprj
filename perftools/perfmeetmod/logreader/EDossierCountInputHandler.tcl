package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] AbstractLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

itcl::class EDossierCountInputHandler {
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {reader log_helper} {
 		set instance [uplevel {namespace which [EDossierCountInputHandler #auto]}]
    $instance init $reader $log_helper
    return $instance  
  }

  protected variable reader
  protected variable log_helper
  protected variable count_regexp
  protected variable count
  protected variable prev_crv
  
  protected variable logfile_id
  protected variable threadname
  protected variable threadnr

  public method init {a_reader a_helper} {
    set reader $a_reader 
    set log_helper $a_helper
  }

  public method file_start {a_filename a_logfile_id a_threadname a_threadnr} {
    set logfile_id $a_logfile_id
    set threadname $a_threadname
    set threadnr $a_threadnr

    set count 0
    set prev_crv -1
  }
  
  public method handle_input {line {timestamp ""}} {
    if {[regexp --  {Kopieren gelukt voor : crv : ([0-9]+) document} $line z crv]} {
      if {$crv == $prev_crv} {
        # niets, al geteld 
      } else {
        incr count
        set prev_crv $crv
      }
    }
  }

  # actions at the end of the file.
  public method file_finished {} {
    $log debug "File finished, calling reader update_logfile_count"
    $reader update_logfile_count $count
  }
  
}
