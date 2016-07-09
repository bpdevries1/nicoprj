# libdatetime.tcl - date and time functions, especially formatting and parsing.

# general naming of functions:
# parse_XXX - parse a string, return seconds since epoch, possibly using given format.
# format_XXX - format seconds since epoch to a string in a certain timezone and possibly given format.

namespace eval ::libdatetime {
  namespace export parse_cet now
  
  # convert string timestamp in CET timezone to seconds since epoch
  # format of string: 2016-06-09 15:52:22.096
  # @return seconds including milliseconds iff format is ok.
  # @return -1 iff format is not ok.
  proc parse_cet {ts_cet} {
    if {[regexp {^([^.]+)(\.\d+)?$} $ts_cet z ts msec]} {
      if {[catch {set sec [clock scan $ts -format "%Y-%m-%d %H:%M:%S"]}]} {
        return -1
      } else {
        if {$msec != ""} {
          expr $sec + $msec
        } else {
          return $sec
        }
      }
    } else {
      return -1
    }
  }

  # args - for future use.
  proc now {args} {
    # for now, the timestamp as can be inserted in sqlite
    clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S %z"
  }

  
}
