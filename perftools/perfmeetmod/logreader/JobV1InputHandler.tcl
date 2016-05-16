package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] AbstractLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

itcl::class JobV1InputHandler {
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {reader log_helper} {
 		set instance [uplevel {namespace which [JobV1InputHandler #auto]}]
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
  
  protected variable ar_job_names
  
  public method init {a_reader a_helper} {
    set reader $a_reader 
    set log_helper $a_helper
    set ar_job_names(CO01) "1-unknown"
    set ar_job_names(CO02) "2-fabriek"
    set ar_job_names(CO03) "3-siebel"
    set ar_job_names(CO04) "4-retourdata"
    set ar_job_names(CO05) "5-unknown"
    set ar_job_names(CO06) "6-filenet"
    set ar_job_names(CO07) "7-convdat"
    set ar_job_names(CO08) "8-stoppen"
    set ar_job_names(CO09) "9-schonen"
    set ar_job_names(CO10) "10-logsfout"
    set ar_job_names(CO11) "11-controlestart"
    set ar_job_names(CO12) "12-klaar"
    
  }

  public method file_start {a_filename a_logfile_id a_threadname a_threadnr} {
    set logfile_id $a_logfile_id
    set threadname $a_threadname
    set threadnr $a_threadnr

    set ts_job_first ""
    set ts_job_last ""
    set job_current ""
  }
  
  public method handle_input {line {timestamp ""}} {
    if {[regexp {^-+ (.+) - } $line z job_new]} {
      if {$job_new == $job_current} {
        set ts_job_last $timestamp
      } else {
        # een nieuwe job, vorige afhandelen als er een is.
        if {$job_current != ""} {
          $log_helper insert_task $logfile_id $threadname $threadnr [det_task_name $job_current] $ts_job_first $ts_job_last 
          # ook de tijd tussen de vorige en de huidige job
          $log_helper insert_task $logfile_id $threadname $threadnr [det_task_name $job_current $job_new] $ts_job_last $timestamp
        } else {
          # dit is de eerste job, nog niets loggen. 
        }
        set job_current $job_new
        set ts_job_first $timestamp
      }
    } else {
      # uit deze logline geen job naam te achterhalen. 
    }
  }

  public method file_finished {} {
    # laatste job nog loggen
    if {$job_current != ""} {
      $log_helper insert_task $logfile_id $threadname $threadnr [det_task_name $job_current] $ts_job_first $ts_job_last 
    }
  }

  # @param jobs: ofwel enkele job als AV2ACO04
  # @param jobs: ofwel 2 jobs (tijd hier tussen) als AV2ACO04 AV2ACO03
  private method det_task_name {job1 {job2 ""}} {
    $log debug "det_task_name: $job1, $job2"
    if {[regexp {(CO[0-9]+)$} $job1 z job1c]} {
      if {$job2 == ""} {
        if {[array get ar_job_names $job1c] != {}} {
          set result $ar_job_names($job1c) 
        } else {
          set result "Z-$job1c" 
        }
      } else {
        if {[regexp {(CO[0-9]+)$} $job2 z job2c]} {
          if {[array get ar_job_names "$job1c-$job2c"] != {}} {
            set result $ar_job_names($job1c-$job2c)
          } else {
            # set result "$job1-$job2"
            # 13-1-2010 NdV tussen 2 acties, nu even op wait zetten, beter pas bij de graph maken te bepalen.
            set result "wait"
          }
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
