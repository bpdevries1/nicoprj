package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] AbstractLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

itcl::class JobV2InputHandler {
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {reader log_helper} {
 		set instance [uplevel {namespace which [JobV2InputHandler #auto]}]
    $instance init $reader $log_helper
    return $instance  
  }

  protected variable reader ; # to call det_task_name
  protected variable log_helper
  
  protected variable logfile_id
  protected variable threadname
  protected variable threadnr

  protected variable ts_job_first
  protected variable ts_job_last
  protected variable job_current
  
  # protected variable ar_job_names
  
  public method init {a_reader a_helper} {
    set reader $a_reader 
    set log_helper $a_helper
  }

  public method file_start {a_filename a_logfile_id a_threadname a_threadnr} {
    $log debug "file_start"
    set logfile_id $a_logfile_id
    set threadname $a_threadname
    set threadnr $a_threadnr

    set ts_job_first ""
    set ts_job_last ""
    set job_current ""
  }
  
  public method handle_input {line {timestamp ""}} {
    $log debug "handle_input: $line *** $timestamp" 
    # 12-1-2010 15:37:02	AV2ACO03 - Opleveren data uit buffer en result.xml verplaatsten		Information		START
    # line: {13-1-2010 12:00:18} {AV2ACO02 - Ophalen data van FTP-server en Fabriek starten} {} Information {} {FTP Download gestart.}

    set lst [split $line "\t"]
    if {[llength $lst] == 6} {
      foreach {dt job_new z soort z beschrijving} $lst break
      if {$job_new == $job_current} {
        set ts_job_last $timestamp
      } else {
        # een nieuwe job, vorige afhandelen als er een is.
        if {$job_current != ""} {
          $log_helper insert_task $logfile_id $threadname $threadnr "[det_task_name $job_current]" $ts_job_first $ts_job_last
          # ook de tijd tussen de vorige en de huidige job
          $log_helper insert_task $logfile_id $threadname $threadnr "[det_task_name $job_current $job_new]" $ts_job_last $timestamp
        } else {
          # dit is de eerste job, nog niets loggen. 
        }
        set job_current $job_new
        set ts_job_first $timestamp
        set ts_job_last $timestamp
      }
    } else {
      # uit deze logline geen job naam te achterhalen.
      $log debug "Geen 4 items in line: $lst"
    }
  }

  public method file_finished {} {
    # laatste job nog loggen
    if {$job_current != ""} {
      $log_helper insert_task $logfile_id $threadname $threadnr "[det_task_name $job_current]" $ts_job_first $ts_job_last 
    }
  }

  # @param jobs: ofwel enkele job als AV2ACO04
  # @param jobs: ofwel 2 jobs (tijd hier tussen) als AV2ACO04 AV2ACO03
  # @note de jobs bevatten genoemde tekst, maar kunnen nog extra tekst bevatten, bv "AV2ACO09 - Archiveren en schonen"
  private method det_task_name {job1 {job2 ""}} {
    $log debug "det_task_name: $job1, $job2"
    if {[regexp {(CO[0-9]+)} $job1 z job1c]} {
      if {$job2 == ""} {
        set result $job1c 
      } else {
        if {[regexp {(CO[0-9]+)} $job2 z job2c]} {
          set result "$job1c-$job2c"
        } else {
          set result "X-$job1-$job2"
        }
      }
    } else {
      set result "W-$job1-$job2" 
    }
    $log debug "result: $result"
    return "$result"
  }
  
}
