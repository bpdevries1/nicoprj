package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] TaskLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

itcl::class SiebelLogReader {
  inherit TaskLogReader
  # inherit GeneralLogReader?
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [SiebelLogReader #auto]}]
    $instance init $db
    return $instance  
  }
  
  private method det_kind {filename} {
    return "siebel" 
  }

  # @result 1 als filename like "Conversion_28122009_run1.log"
  # @result 1 als filename like "Conversion_20100305_3.log"
  public method can_read {filename} {
    $log debug "can_read: $filename"
    if {[regexp {Conversion_[0-9]+_run[0-9]+.log} $filename]} {
      return 10 ; # groter dan GeneralLogReader 
    }
    if {[regexp {Conversion_[0-9]+_[0-9]+.log} $filename]} {
      return 10 ; # groter dan GeneralLogReader 
    }
    # Conversion_31_03_01.log
    if {[regexp {Conversion_[0-9]+_[0-9]+_[0-9]+.log} $filename]} {
      $log debug "Siebel log gevonden: $filename"
      return 10 ; # groter dan GeneralLogReader 
    }
    $log debug "filename is geen siebel log: $filename"
    return 0 
  }

  protected method register_handlers {} {
    chain
    #set lst_input_handlers {} 
    #register_handler [FirstLastInputHandler::new $this $log_helper]
    #register_handler [PrevInputHandler::new $this $log_helper]
    register_handler [CountInputHandler::new $this $log_helper "^Loading from "]
    $log debug "registered handlers for Siebel"
  }
  
  # default implementation: use parse_timestamp
  protected method handle_line {line} {
    # first check for parallel call with start and end times. Those are without msec's.
    # Loading from 12/28/2009 10:24:57 to 12/28/2009 10:24:57 (loadtime = 0 sec.)
    # Loading from 03/05/2010 11:38:20 to 03/05/2010 11:38:22 (loadtime = 2 sec.) for file 9876543254.xml, result : OK.
    # Loading from 03/05/2010 11:38:21 to 03/05/2010 11:38:23 (loadtime = 2 sec.) for file 9876543258.xml, result : FAILED,
    if {[regexp {^(.*) from ([0-9/ :]+) to ([0-9/ :]+) \(loadtime = .* result : ([A-Z]+)} $line z taskname str_from str_to result]} {
      set ts_from [Timestamp::new [clock scan $str_from -format "%m/%d/%Y %H:%M:%S"]] 
      set ts_to [Timestamp::new [clock scan $str_to -format "%m/%d/%Y %H:%M:%S"]]
      # $log_helper insert_task $logfile_id $threadname $threadnr $taskname $ts_from $ts_to
      $log_helper insert_task $logfile_id $threadname $threadnr "$taskname-$result" $ts_from $ts_to
    } else {
      # niets
    }
    # 13-4-2010 sowieso chain voor de first-last logline (task=file) handler.
    chain $line ; # call method from superclass
  }
  
  # called by PrevInputHandler.
  public method det_task_name {line line_prev threadname} {
    set result "logline" 
    return $result
  }
  
  
  protected method det_threadname_number {filename} {
    set dirname [file dirname $filename]
    set tail [file tail $filename]
    set threadname "<unknown>"
    set threadnr "1"
    if {[regexp {^Conversion_[0-9]+_run([0-9]+).log$} $tail z nr]} {
      set threadname "siebel" 
      # 8-1-2010 NdV: threadnr voorlopig uit filenaam bepalen. Beter is om afh van eerste en laatste tijden in de file deze te bepalen.
      set threadnr $nr
      $log debug "threadnr for $filename: $threadnr"
    } else {
      # error "Cannot parse: $filename"
      # 13-4-2010 _run komt ook niet altijd voor, handmatige rename? Wel threadname en nr zetten, anders doet first-last handler niets.
      set threadname "siebel"
      set threadnr 1
    }
    return [list $threadname $threadnr]
  }
  
}
