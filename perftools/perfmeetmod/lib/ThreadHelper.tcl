# Timestamp object, which contains date and time. Time in seconds, and possibly partial seconds.

package require Itcl
package require ndv

itcl::class ThreadHelper {

	private common log
	set log [::ndv::CLogger::new_logger [file tail [info script]] info]
	# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

	public proc new {} {
    set result [uplevel {namespace which [ThreadHelper #auto]}]
    return $result
	}

  private variable sec_time_margin
  private variable ar_heights
  private variable ar_n_heights
  
  public method set_sec_time_margin {a_sec_time_margin} {
    set sec_time_margin $a_sec_time_margin 
    $log debug "==> sec_time_margin: $sec_time_margin"
  }
  
  public method det_relative_height {name dt_start dt_end} {
    incr ar_n_heights($name) 0 ; # set to 0 if not exists, otherwise no-op.
    set rel_height 0
    set found 0
    while {$rel_height < $ar_n_heights($name)} {
      if {[enough_later $dt_start $ar_heights($name,$rel_height)]} {
        set found 1
        break
      }
      incr rel_height
    }
    if {!$found} {
      incr ar_n_heights($name) ; # now do add 1
    }
    set ar_heights($name,$rel_height) $dt_end
    $log debug "Rel height for $name ($dt_start => $dt_end): $rel_height"
    return $rel_height
    
  }
  
  # @return 1 if ts1 is sufficiently later than ts2
  private method enough_later {ts1 ts2} {
    if {$ts1 > $ts2} {
      # it's later, but is it enough?
      set sec1 [clock scan $ts1 -format "%Y-%m-%d %H:%M:%S"]
      set sec2 [clock scan $ts2 -format "%Y-%m-%d %H:%M:%S"]
      $log debug "sec1: $sec1"
      $log debug "sec2: $sec2"
      $log debug "margin: $sec_time_margin"
      $log debug "sec2 + margin: [expr $sec2 + $sec_time_margin]" 
      if {$sec1 > [expr $sec2 + $sec_time_margin]} {
        $log debug "0. enough later: $ts1 <-> $ts2" 
        return 1 
      } else {
        $log debug "1. not $ts1 <-> $ts2"
        return 0
      }
    } else {
      $log debug "2. not $ts1 <-> $ts2"
      return 0 
    }
  }

  # @return 1 if ts1 is sufficiently later than ts2
  # @note test-versie!
  private method enough_later_test {ts1 ts2 sec_time_margin} {
    if {$ts1 >= $ts2} {
      # it's later, but is it enough?
      set sec1 [clock scan $ts1 -format "%Y-%m-%d %H:%M:%S"]
      set sec2 [clock scan $ts2 -format "%Y-%m-%d %H:%M:%S"]
      if {$sec1 >= [expr $sec2 + $sec_time_margin]} {
        return 1 
      } else {
        $log debug "1. $ts1 <-> $ts2"
        return 0
      }
    } else {
      $log debug "2. $ts1 <-> $ts2"
      return 0 
    }
  }
  
}

