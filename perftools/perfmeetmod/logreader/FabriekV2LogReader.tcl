package require Itcl
package require ndv

::ndv::source_once [file join [file dirname [info script]] TaskLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] TaskLogHelper.tcl]
# ::ndv::source_once [file join [file dirname [info script]] JobV2InputHandler.tcl]
::ndv::source_once [file join [file dirname [info script]] JobV3InputHandler.tcl]

itcl::class FabriekV2LogReader {
  inherit TaskLogReader
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [FabriekV2LogReader #auto]}]
    $instance init $db
    return $instance  
  }

  private method det_kind {filename} {
    return "sturing" 
  }
  
  protected method register_handlers {} {
    # chain
    set lst_input_handlers {} 
    # register_handler [PrevInputHandler::new $this $log_helper]
    register_handler [FirstLastInputHandler::new $this $log_helper]
    register_handler [JobV3InputHandler::new $this $log_helper]
  }
  
  public method can_read {filename} {
    set name_ok 0
    set result 0
    # 30-3-2010 log kan ook Algemeen20100326.log heten (handmatige rename of archief-functie?)
    if {[regexp {Algemeen.*\.log} $filename]} {
      set name_ok 1 
    } elseif {[regexp {^[0-9]{8}_[0-9]+\.log} [file tail $filename]]} {
      set name_ok 1
    } elseif {[regexp {^[0-9]{8}\.xls} [file tail $filename]]} {
      # 3-5-2010 hernoemd naar xls, maar is gewoon tsv.
      set name_ok 1
    }
    if {$name_ok} {
      # bekijk inhoudelijk: V2 versie begint met een datum
      # 30-3-2010 kan blijkbaar ook met een lege regel beginnen, en daarna de datum.
      set f [open $filename r]
      set line ""
      # 7-4-2010 bij lege file niet blijven hangen, checken op eof.
      while {![eof $f] && ([string trim $line] == "")} {
        gets $f line
      }
      if {[regexp -- {^[-0-9]+ } $line]} {
        set result 10 
      }
      close $f
    } 
    return $result
  }

  public method det_task_name {line line_prev threadname} {
    if {[regexp {Extractie naar XML - RunId: [0-9]+ Succes} $line]} {
      set result "extractxml" 
    } elseif {[regexp {Laden brondata} $line]} {
      set result "ladenbrondata"
    } elseif {[regexp {^Einddtijd: [-0-9 :]+$} $line]} {
      set result "<ignore>" ; # want is vaak 6:00 uur 's ochtends.  
    } else {
      set result "logline" 
    }
    return $result
  }
  
  # bepaal threadnumber uit inhoud logfile
  protected method det_threadname_number {filename} {
    if {[regexp {lgemeen} $filename]} {
      return [list "sturing" 5] 
    } else {
      set f [open $filename r]
      set threadnr ""
      while {![eof $f]} {
        gets $f line
        if {[regexp {\\straat([0-9]+)} $line z threadnr]} {
          break 
        }
      }
      close $f
      return [list "fabriek" $threadnr]
    }
  }

}
