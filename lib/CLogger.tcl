# General logging facility.

# History
# 2013-03-15 NdV removed global/common logfile, now only log instance logfiles.

# TODO:
# * use info stacklevel to also log the calling procedure.
# * option to log in milli/microseconds.
package require Itcl

package provide ndv 0.1.1

# [2016-07-23 14:24] assert (in package control) also here, callback with log.
package require control

#### logging helper proc ####
# [2016-07-23 21:39] this one before namespace/classdef, because classdef returns if
# class already exists. Need proc log to be defined again, to override logarithm function.
proc log {args} {
  global log
  # variable log
  $log {*}$args
}

namespace eval ::ndv {
	# class maar eenmalig definieren
	if {[llength [itcl::find classes CLogger]] > 0} {
		return
	}
	
	namespace export CLogger

	itcl::class CLogger {
	
		private common int_level
		set int_level(trace) 14
		set int_level(debug) 12
		set int_level(perf) 10
		set int_level(info) 8
		set int_level(notice) 6
		set int_level(warn) 4
		set int_level(error) 2
		set int_level(critical) 0

    # 8-1-2010 NdV lijst bijhouden van alle loggers, om in een keer alle loglevels aan te kunnen passen.
    private common lst_loggers {}
    
		public proc new_logger {a_name a_log_level} {
			set result [uplevel {namespace which [::ndv::CLogger \#auto]}]
			$result set_name $a_name
			$result set_log_level $a_log_level
			lappend lst_loggers $result
      return $result
		}
	
    public proc set_log_level_all {a_log_level} {
      foreach logger $lst_loggers {
        $logger set_log_level $a_log_level 
      }
    }
    
		private variable name
		private variable log_level
		private variable filename
		private variable f_log
	
		# 22-8-2014 NdV public is needed for Tcl8.6.1/Itcl4.0b7.
		public constructor {} {
			set name ""
			set log_level critical
				set filename ""
				set f_log -1
		}
		
		public method set_name {a_name} {
			set name $a_name
		}	
		
		public method set_log_level {a_log_level} {
			set log_level $int_level($a_log_level)
		}
	
		public method get_log_level {} {
			return $log_level
		}
		
    # @param append: should logfile be appended to, default it is overwritten.
		public method set_file {a_filename {append 0}} {
      file mkdir [file dirname $a_filename]
      set filename $a_filename
      if {$append} {
        set f_log [open $filename a]
      } else {
        set f_log [open $filename w]
      }
      log_intern "Opened logfile: $filename" debug
    }

    public method close_file {} {
      set filename ""
      if {$f_log != -1} {
        close $f_log
        set f_log -1
      }
    }
	
		public method trace {str} {
			log_intern $str trace
		}
	
		public method debug {str} {
			log_intern $str debug
		}
		
		public method perf {str} {
			log_intern $str perf
		}
		
		public method info {str} {
			log_intern $str info
		}
		
		public method notice {str} {
			log_intern $str notice
		}
	
		public method warn {str} {
			log_intern $str warn
		}
	
		public method error {str} {
			log_intern $str error
		}
	
		public method critical {str} {
			log_intern $str critical
		}
		
		public method log {str {level critical}} {
			log_intern $str $level
		}
		
		public method log_start_finished {script {loglevel -1}} {
			perf "start"
			uplevel $script
			perf "finished"
		}

		public method start_stop {args} {
			perf "start: [lindex $args 0]"
			uplevel {*}$args
			perf "finished: [lindex $args 0]"
		}
		
		public method log_intern {str {level critical} {pref_stacklevel -2}} {
			global stderr
			# puts stderr "int_level($level) = $int_level($level) ; log_level = $log_level"
			if {$int_level($level) <= $log_level} {
				# puts stderr "info level: [info level]"
				set stacklevel [::info level]
				if {$stacklevel > 1} {
					# puts stderr "\[[clock format [clock seconds] -format "%d-%m-%y %H:%M:%S"]\] \[$service\] \[$level\] $str *** \[[info level -1]\]"
					# puts stderr "\[[clock format [clock seconds] -format "%d-%m-%y %H:%M:%S"]\] \[$name\] \[$level\] $str *** \[[::info level $pref_stacklevel]\]"
				} 
        # set str_log "\[[clock format [clock seconds] -format "%d-%m-%y %H:%M:%S"]\] \[$name\] \[$level\] $str" 
        # 24-12-2013 changed date format to standard, also used within SQLite.
        if {$name == ""} {
          set brackets_name ""
        } else {
          set brackets_name "\[$name\] "
        }
        set str_log "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S %z"]\] $brackets_name\[$level\] $str" 
        puts stderr $str_log
				flush stderr ; # could be that stderr is redirected.
        if {$f_log != -1} {
          puts $f_log $str_log
          flush $f_log
        }
			}
		}
	}
}

# 27-3-2013 NdV define default logger object.
# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# set log [::ndv::CLogger::new_logger [file tail $argv0] debug]

# set global log object to be used by global log proc.
# if already set, don't set again.
proc set_log_global {level {options {}}} {
  global log tcl_platform
  # puts "set_log_global called with level: $level"
  # info vars cannot be used to check for existency, as it is already visible by using global log
  if {![catch {set log}]} {
    #puts "set_log_global already done, returning."
    #puts "info vars log: [info vars log]"
    return
  }
  if {[:showfilename $options] == 0} {
    set log [::ndv::CLogger::new_logger "" $level]
  } else {
    set log [::ndv::CLogger::new_logger [file tail [info script]] $level]  
  }
  set append 0
  if {[:filename $options] != ""} {
    set logfile_name [:filename $options]
    if {[:append $options] > 0} {
      set append 1
    }
  } else {
    set logfile_name "logs/[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"
    set append 0
  }
  $log set_file $logfile_name $append
  
  # create symlink, maybe also do in set_file.
  if {$tcl_platform(platform) == "unix"} {
    if {[:filename $options] == ""} {
      set symlink_name "logs/[file tail [info script]]-latest.log"
      file delete $symlink_name
      # puts stderr "point $symlink_name -> $logfile_name"
      file link -symbolic $symlink_name [file tail $logfile_name]
    } else {
      # fixed logname, no need to make symlink.
    }
  } else {
    # check: voor windows nu ook mogelijk? of nog steeds alleen voor dirs?
  }
}

proc assert_callback {args} {
  set str [join $args " "]
  catch {log error $str}
  puts stderr $str
  # TODO: make conditional on some setting, don't want this in production, would stop processing.
  breakpoint
  return -code error
}

# first enable, then import in namespace
::control::control assert enabled 1

# also first set callback
# configure assert, also to use logger
# ::control::control assert enabled 1
::control::control assert callback assert_callback

# only import after settings done.
# don't 'use' here, keep packages independent.
# use control assert
namespace import ::control::assert

