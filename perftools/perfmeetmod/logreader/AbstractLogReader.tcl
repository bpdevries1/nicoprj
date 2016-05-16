package require Itcl
package require ndv

itcl::class AbstractLogReader {
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc get_instance_old {} {
    if {$instance == ""} {
   		set instance [uplevel {namespace which [AbstractLogReader #auto]}]
    }
    return $instance  
  }

  public proc new {db} {
    set instance [uplevel {namespace which [AbstractLogReader #auto]}]
    return $instance
  }
  
  public method can_read {filename} {
    return 0
  }


  public method read_log {filename db testrun_id} {
    $log warn "read_log called for AbstractLogReader"
  }
  
}