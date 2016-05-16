package require Itcl
package require ndv
package require csv

::ndv::source_once [file join [file dirname [info script]] AbstractLogReader.tcl]
::ndv::source_once [file join [file dirname [info script]] ResourceLogHelper.tcl]

itcl::class TypeperfLogReader {
  inherit AbstractLogReader
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	  
  private common instance  ""

  public proc new {db} {
 		set instance [uplevel {namespace which [TypeperfLogReader #auto]}]
    $instance init $db
    return $instance  
  }
  
  public proc get_instance_old {} {
    if {$instance == ""} {
   		set instance [uplevel {namespace which [TypeperfLogReader #auto]}]
    }
    return $instance  
  }

  protected variable db
  
  # private variable ar_resname_id
  public method init {a_db} {
    set db $a_db
    set log_helper [TaskLogHelper::get_instance]
    $log_helper set_db $db
  }
  
  public method can_read {filename} {
    if {[file extension $filename] == ".csv"} {
      if {[regexp {typeperf} $filename]} {
        return 10 ; # meer dan van general.
      } else {
        # ook als op eerste regel (PDH-CSV 4.0) staat
        set f [open $filename r]
        gets $f line
        close $f
        if {[regexp {\(PDH-CSV 4.0\)} $line]} {
          return 10 ; # meer dan van general.
        } else {
          return 0
        }
      }
    } else {
      return 0 
    }
  }

  public method read_log {filename testrun_id} {
    $log debug "read_log: $filename, $db, $testrun_id"
    set f [open $filename r]
    gets $f line
    set lst [::csv::split $line]
    make_heading_array $lst ar_headings machine
    set reslog_helper [ResourceLogHelper::get_instance]
    $reslog_helper set_db $db
    set logfile_id [$db insert_object logfile -testrun_id $testrun_id -path $filename -kind "typeperf"]
    $reslog_helper det_machine $machine
    set linenr 1
    while {![eof $f]} {
      gets $f line
      incr linenr
      set lst [::csv::split $line]
      if {[parse_timestamp [lindex $lst 0] dt partsec]} {
        set i 1
        foreach el [lrange $lst 1 end] {
          if {$ar_headings($i) != "<double>"} {
            if {[string is double $el]} {
              # set resname_id [det_resname_id $db $ar_headings($i)]
              set resname_id [$reslog_helper det_resname_id $ar_headings($i)]
              $db insert_object resusage -logfile_id $logfile_id -linenr $linenr -machine $machine \
                -resname_id $resname_id -value $el -dt $dt -dec_dt [$db dt_to_decimal "$dt$partsec"]
            }
          }
          incr i
        }
      } else {
        $log debug "Could not parse timestamp for: [lindex $lst 0]" 
      }
    }
    close $f
  }
  
  
  # @result: array: index => name, name == "" if it occurred before.
  private method make_heading_array {lst ar_name machine_name} {
    upvar $ar_name ar
    upvar $machine_name machine
    set machine "<unknown>"
    set i 0
    foreach el $lst {
      # zoek element in lijst, als gevonden positie kleiner is dan huidige, is deze dubbel
      if {[lsearch -exact $lst $el] == $i} {
        if {[regexp {^\\\\([^\\]+)\\(.+)$} $el z mach name]} {
          set ar($i) $name
          set machine $mach
        } else {
          set ar($i) $el
        }
      } else {
        $log debug "Dubbel element $i: $el" 
        set ar($i) "<double>"
      }
      incr i
    }
  }
  
  # @param str: 12/19/2009 04:16:54.621
  # @param dt: 19-12-2009 04:16:54
  # @param partsec: .621
  private method parse_timestamp {str dt_name partsec_name} {
    upvar $dt_name dt
    upvar $partsec_name part_sec
    if {[regexp {^([^.]+)(\..*)$} $str z str_dt part_sec]} {
      set sec [clock scan $str_dt -format "%m/%d/%Y %H:%M:%S"]
      set dt [clock format $sec -format "%Y-%m-%d %H:%M:%S"]
      return 1
    } else {
      return 0 
    }
  }
  
}