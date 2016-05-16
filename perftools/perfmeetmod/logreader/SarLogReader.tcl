package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] AbstractLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] ResourceLogHelper.tcl]

itcl::class SarLogReader {
  inherit AbstractLogReader
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [SarLogReader #auto]}]
    $instance init $db
    return $instance  
  }

  public proc get_instance_old {} {
    if {$instance == ""} {
   		set instance [uplevel {namespace which [SarLogReader #auto]}]
    }
    return $instance  
  }

  protected variable db
  
  public method init {a_db} {
    set db $a_db
    set log_helper [TaskLogHelper::get_instance]
    $log_helper set_db $db
  }
   
  public method can_read {filename} {
    if {[regexp {^sar} [file tail $filename]]} {
      return 10 ; # meer dan van general.
    } else {
      return 0
    }
  }
  
  public method read_log {filename testrun_id} {
    $log debug "read_log: $filename, $db, $testrun_id"
    set reslog_helper [ResourceLogHelper::get_instance]
    $reslog_helper set_db $db
    set logfile_id  [$db insert_object logfile -testrun_id $testrun_id -path $filename -kind "sar"]
    set f [open $filename r]
    set linenr 0
    set machine "<unknown>"
    while {![eof $f]} {
      gets $f line
      incr linenr
      # SunOS u151 5.8 Generic_117350-47 sun4us    12/17/09
      if {[regexp {^SunOS ([^ ]+).*?([0-9/]+)$} $line z machine str_date]} {
        $log debug "read title line: $line"
        $log debug "str_date: $str_date"
        # beetje oppassen: jaar-deel slechts 2 cijfers.
        set sec_date [clock scan $str_date -format "%m/%d/%y" -gmt 1] 
        $reslog_helper det_machine $machine
      } elseif {[regexp {^[0-9:]{8}} $line]} {
        # header or data line
        set line [remove_double_spaces $line]
        # set lst $line ; # for now, maybe need more parsing.
        set lst [split $line " "]
        if {[string is double [lindex $lst 1]]} {
          # data line  
          $log debug "handling data line: $lst (#[llength $lst])"
          set sec_time0 [clock scan "00:00:00" -format "%H:%M:%S" -gmt 1]
          set sec_time [clock scan [lindex $lst 0] -format "%H:%M:%S" -gmt 1]
          set sec_dt [expr $sec_date + ($sec_time - $sec_time0)]
          set dt [clock format $sec_dt -format "%Y-%m-%d %H:%M:%S" -gmt 1]
          $log debug "$sec_date $sec_time0 $sec_time $sec_dt: $dt"
          set i 1
          foreach el [lrange $lst 1 end] {
            if {[string is double $el]} {
              set resname_id [$reslog_helper det_resname_id $ar_headings($i)]
              $db insert_object resusage -logfile_id $logfile_id -linenr $linenr -machine $machine \
                -resname_id $resname_id -value $el -dt $dt -dec_dt [$db dt_to_decimal $dt] 
            }
            incr i
          }

        } else {
          # header line
          $log debug "handling header line: $lst (#[llength $lst])"
          make_heading_array $lst ar_headings
        }
      } else {
        # possibly a blank line 
      }
    }

    close $f    
  }
  
  # @result: array: index => name, name == "" if it occurred before.
  private method make_heading_array {lst ar_name} {
    upvar $ar_name ar
    array unset ar
    set i 0
    foreach el $lst {
      set ar($i) $el
      incr i
    }
  }  
 
  # @note 4 spaces are first minimised to 2 spaces, then to 1.
  private method remove_double_spaces {line} {
    while {[regsub -all {  } $line " " line]} {}
    return $line
  }
}