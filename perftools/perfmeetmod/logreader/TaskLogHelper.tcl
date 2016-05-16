package require Itcl
package require ndv
package require control

control::control assert enabled 1

::ndv::source_once [file join [file dirname [info script]] .. lib Timestamp.tcl]

itcl::class TaskLogHelper {
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc get_instance {} {
    if {$instance == ""} {
   		set instance [uplevel {namespace which [TaskLogHelper #auto]}]
    }
    return $instance  
  }

  private variable db
  private variable ar_resname_id
  
  public method set_db {a_db} {
    set db $a_db 
  }

  # 6-5-2010 NdV alleen inserten als ts_start en ts_end ongelijk leeg.
  public method insert_task {logfile_id threadname threadnr taskname ts_start ts_end {details ""}} {
    if {($ts_start != "") && ($ts_end != "")} { 
      #control::assert {$ts_start != ""}
      #control::assert {$ts_end != ""}
      set sec_duration [$ts_start det_sec_duration $ts_end]
      set id [$db insert_object task -logfile_id $logfile_id -threadname $threadname \
          -threadnr $threadnr \
          -taskname $taskname \
          -dt_start [$ts_start to_string] -dt_end [$ts_end to_string] \
          -dec_start [$ts_start to_decimal] \
          -dec_end [$ts_end to_decimal] \
          -sec_duration $sec_duration \
          -details [string range $details 0 1022]] 
      return $id
    } else {
      return -1 
    }
  }
  
  # @param start, end: 2009-12-26 12:00:00
  # @param *_partsec: .123
  # @deprecated
  private method insert_task_old {logfile_id threadname threadnr taskname start start_partsec end end_partsec} { 
    set sec_duration [expr [ts_to_sec $end $end_partsec] - [ts_to_sec $start $start_partsec]]  
    $db insert_object task -logfile_id $logfile_id -threadname $threadname \
        -threadnr $threadnr \
        -taskname $taskname \
        -dt_start $start -dt_end $end -dec_start [$db dt_to_decimal "$start$start_partsec"] \
        -dec_end [$db dt_to_decimal "$end$end_partsec"] \
        -sec_duration $sec_duration
  }
  
  # @param ts: yyyy-mm-dd hh:mm:ss
  # @param part_sec: .123
  # @result: number of seconds including partial seconds.
  public method ts_to_sec {ts part_sec} {
    return [expr [clock scan $ts -format "%Y-%m-%d %H:%M:%S"] + $part_sec]
  }

  # @param ts: timestamp object: if "", a new object will be created, otherwise the existing timestamp will be filled.
  # @return "" if no timestamp found in line
  # @return a new timestamp object if a timestamp is found in line.
  public method parse_timestamp {line {ts ""}} {
    if {[parse_timestamp_intern $line str_ts partsec]} {
      set sec [clock scan $str_ts -format "%Y-%m-%d %H:%M:%S"]
      if {$ts == ""} {
        return [Timestamp::new $sec $partsec]
      } else {
        $ts init $sec $partsec
        return $ts
      }
    } else {
      return "" 
    }
  }
  
  # @result: 1 als timestamp geparsed, result in out_timestamp in formaat: yyyy-mm-dd hh:mm:ss
  #          out_partsec: .123 of .0 als er geen is.
  #          0 als geen timestamp geparsed.
  # @deprecated, of iig private.
  private method parse_timestamp_intern {line out_timestamp_name out_partsec_name} {
    # global log
    upvar $out_timestamp_name out_timestamp
    upvar $out_partsec_name out_partsec
    set out_timestamp ""
    set out_partsec ".0" ; # bevat iets als ".123" als er wel iets instaat.
    set result 0

    # Siebel: returned the following error:"The value '26-6-1900 0:00:00' for field 'End Date' is required to be '>= [Start Date]'.
    # Siebel: Please enter a value that is ' >= 26-6-1990 0:00:00'.(SBL-DAT-00521)"(SBL-EAI-04451).
    if {[regexp {^(.*)error:"The value '[-0-9 :]+' for field(.*)} $line z s1 s2]} {
      set line "$s1$s2"
    }
    # 12-3-2010 zou eigenlijk = <date> ipv >= <date> doen, maar mis dan dingen als ==== <date> =====
    if {[regexp {^(.*)' >= [-0-9 :]+'(.*)} $line z s1 s2]} {
      set line "$s1$s2"
    }
    
    # 2009/12/19 - 04:32:28
    if {[regexp {^([0-9]{4})/([0-9]{1,2})/([0-9]{1,2}) - ([0-9]{2}):([0-9]{2}):([0-9]{2})(\.[0-9]+)?} $line z jr maand dag hr min sec partsec]} {
      set result 1
    }
    # 19/12/2009 - 04:27:01
    if {[regexp {^([0-9]{1,2})/([0-9]{1,2})/([0-9]{4}) - ([0-9]{2}):([0-9]{2}):([0-9]{2})(\.[0-9]+)?} $line z dag maand jr hr min sec partsec]} {
      set result 1
    }
    # 12-1-2010 16:33:02
    # 19-12-2009 5:04:40
    if {[regexp {([0-9]{1,2})-([0-9]{1,2})-([0-9]{4}) ([0-9]{1,2}):([0-9]{2}):([0-9]{2})(\.[0-9]+)?} $line z dag maand jr hr min sec partsec]} {
      set result 1
    }
    # Siebel log: 2009-12-28 10:25:59.579    
    # 2009-12-28 10:23:31.218 of 2009-10-22 16:13:23,093 ofwel een punt of komma als partsec scheidingsteken.
    if {[regexp {([0-9]{4})-([0-9]{1,2})-([0-9]{1,2}) ([0-9]{1,2}):([0-9]{2}):([0-9]{2})([,.][0-9]+)?} $line z jr maand dag hr min sec partsec]} {
      set result 1
    }
    if {$result} {
      # $log debug "uur1: $hr"
      if {[regexp {^0.$} $hr]} {
        regsub {^0} $hr "" hr
      }
      # $log debug "uur2: $hr"
      set out_timestamp [format "%s-%s-%s %02d:%s:%s" $jr $maand $dag $hr $min $sec]
      if {$partsec == ""} {
        set out_partsec ".0"
      } else {
        regsub -all "," $partsec "." partsec
        set out_partsec $partsec
      }
    }
    return $result
  }
  
}
