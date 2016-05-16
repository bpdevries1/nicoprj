# Timestamp object, which contains date and time. Time in seconds, and possibly partial seconds.

package require Itcl
package require ndv

itcl::class Timestamp {

	private common log
	set log [::ndv::CLogger::new_logger [file tail [info script]] info]
	# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

	public proc new {sec {part_sec ".0"}} {
    set ts [uplevel {namespace which [Timestamp #auto]}]
    $ts init $sec $part_sec
    return $ts
	}

  private variable sec
  private variable part_sec
  
	public method init {a_sec a_part_sec} {
    set sec $a_sec
    set part_sec $a_part_sec
	}

  public method det_sec_duration {ts_end} {
     return [expr [$ts_end to_seconds] - [to_seconds]]
  }
  
  # @return timestamp as formatted string: %Y-%m-%d %H:%M:%S (without partial seconds)
  public method to_string {} {
    return [clock format $sec -format "%Y-%m-%d %H:%M:%S"]
  }

  # @return timestamp as (mysql) decimal: %Y%m%d%H%M%S.ppp
  public method to_decimal {} {
    return "[clock format $sec -format "%Y%m%d%H%M%S"]$part_sec"
  }
  
  # @return float including partial seconds
  public method to_seconds {} {
    return [expr $sec + $part_sec]
  }
  
}

