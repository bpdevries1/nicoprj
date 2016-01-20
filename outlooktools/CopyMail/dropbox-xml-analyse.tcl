# losse main-file om dynamisch aan te kunnen passen

package require ndv

file mkdir [file join [file dirname [info script]] log]
set time [clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]
set logname [file join [file dirname [info script]] log "dropbox-xml-$time.log"]

set debug 1

proc main {argv} {
  global argv0 debug
  lassign $argv config
  if {$config == ""} {
    puts "syntax: $argv0 <config.tcl>"
    exit 1
  }
  source $config

  analyse_files $dropbox_xml_folder
}

proc analyse_files {dir} {
  # show results ordered by start timestamp, which equals the timestamp in the subject field.
  foreach file [glob -directory $dir -type f *.xml] {
    log debug "Handling: $file"
    set sec_mtime [file mtime $file]
	set text [read_file $file]
	# <Value>Perftest-2015-11-24--14-02-28.135-barcode 1 page scanned.pdf[ 1</Value>

	if {[regexp {<Value>Perftest-([0-9.-]+)-(.+.pdf)\[} $text z ts subject]} {
	  log info "$ts *** $subject"
	  set files($ts) [list $subject $sec_mtime $file]
	} else {
	  log error "No subject found."
	  breakpoint
	}
  }
  
  set fo [open [file join $dir "xml-times.tsv"] w]
  puts $fo [join [list ts sec1 mtime sec_mtime diff subject] "\t"]
  foreach ts [lsort [array names files]] {
    lassign $files($ts) subject sec_mtime file
	set sec1 [ts_parse_msec $ts]
	set diff [format %.3f [expr $sec_mtime-$sec1]]
	set mtime [clock format $sec_mtime -format "%Y-%m-%d %H:%M:%S"]
	puts $fo [join [list $ts $sec1 $mtime $sec_mtime $diff $subject] "\t"]
  }
  close $fo
}

proc file_time {file} { 
  # set msec [clock milliseconds]
  set sec [file mtime $file]
  # set msec2 [expr $msec % 1000]
  return [clock format $sec -format "%Y-%m-%d %H:%M:%S"]
}

proc log {level str} {
	global logname debug
	if {$debug || ($level != "debug")} {
		set f [open $logname a]
		set logstring "\[[current_time]\] \[$level\] $str"
		puts $f $logstring
		close $f
		puts $logstring
	}
}

# @param ts - 2015-11-24--14-02-30.168
proc ts_parse_msec {ts} {
  if {[regexp {^([^.]+)(\.\d+)$} $ts z sec msec]} {
    expr [clock scan $sec -format "%Y-%m-%d--%H-%M-%S"] + $msec
  } else {
    log error "Cannot parse timestamp with msec: $ts"
	breakpoint
  }
}

proc current_time {} { 
  set msec [clock milliseconds]
  set sec [expr $msec / 1000]
  set msec2 [expr $msec % 1000]
  return "[clock format $sec -format "%Y-%m-%d %H:%M:%S.[format %03d $msec2] %z"]"
}


main $argv
