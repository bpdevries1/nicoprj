package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] TaskLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]

itcl::class ExtractieLogReader {
  inherit TaskLogReader
  # inherit GeneralLogReader?
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc get_instance_old {} {
    if {$instance == ""} {
   		set instance [uplevel {namespace which [ExtractieLogReader #auto]}]
    }
    return $instance  
  }

  public proc new {db} {
 		set instance [uplevel {namespace which [ExtractieLogReader #auto]}]
    $instance init $db
    return $instance  
  }
  
  private method det_kind {filename} {
    return "extractie" 
  }

  protected method register_handlers {} {
    chain
    register_handler [CountInputHandler::new $this $log_helper "extraheren en dumpen Kraan"]
  }
  
  # @result 10 als filename like "logging_20091219_1_extractie.csv"
  # @result 10 als filename like "logging_20091219_1_extractie.csv"
  # @note don't check for typeperf and sar files, can_read values of those should be higher than this one.
  public method can_read {filename} {
    if {[regexp {extractie_[0-9]+.log} $filename]} {
      return [expr [chain $filename] + 1] ; # groter dan GeneralLogReader 
    } elseif {[regexp {logging_.*_extractie.csv} $filename]} {
      return [expr [chain $filename] + 1] ; # groter dan GeneralLogReader 
    } else {
      return 0 
    }
  }

  public method det_task_name {line line_prev threadname} {
    if {[regexp {extraheren en dumpen Kraan} $line]} {
      set result "dossgrp" 
    } else {
      set result "logline" 
    }
    return $result
  }
  
  
  protected method det_threadname_number {filename} {
    set dirname [file dirname $filename]
    set tail [file tail $filename]
    set threadname "<unknown>"
    set threadnr "1"
    if {[regexp {^logging_[0-9]{8}_([0-9]+)_extractie} $tail z nr]} {
      set threadname "logextr" 
      # 8-1-2010 NdV: threadnr voorlopig uit filenaam bepalen. Beter is om afh van eerste en laatste tijden in de file deze te bepalen.
      set threadnr $nr
      $log debug "threadnr for $filename: $threadnr"
    } elseif {[regexp {^extractie_([0-9]+).log} $tail z nr]} {
      set threadname "extr"
      set threadnr $nr
    } else {
      # error "Cannot parse: $filename"
    }
    return [list $threadname $threadnr]
  }
  
}
