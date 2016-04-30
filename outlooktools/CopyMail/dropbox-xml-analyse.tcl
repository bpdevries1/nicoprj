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
  set outfilename "xml-times.tsv"
  set nfiles 0
  set nuuid 0
  foreach file [glob -directory $dir -type f *.xml] {
    log debug "Handling: $file"
    incr nfiles
    set sec_xmltime [file mtime $file]
    set text [read_file $file]
    # <Value>Perftest-2015-11-24--14-02-28.135-barcode 1 page scanned.pdf[ 1</Value>

    if {[regexp {<Value>Perftest-([0-9.-]+)-(.+.pdf)\[} $text z ts subject]} {
      log info "$ts *** $subject"
      set files($ts) [list $subject $sec_xmltime $file]
    } elseif {[regexp {<Value>([a-f0-9]+)\.pdf} $text z uuid]} {
      log info "uuid: $uuid"
      # hier mogelijk een lappend gebruiken!
      # set uuids($sec_xmltime) $uuid
      lappend uuids($sec_xmltime) $uuid
      incr nuuid
    } elseif {[regexp {<variable name="Subject">([^<]+)-Perftest-([^<]+)</variable>} $text z subject ts]} {
      # <variable name="Subject">Fax sent (3p) to '+31307124088' @+31307124088-Perftest-2015-12-05--11-59-00.509</variable>
      log info "$ts *** $subject"
      set files($ts) [list $subject $sec_xmltime $file]
      set outfilename "xmlfax-times.tsv"
    } else {                        
      log error "No subject found." 
      breakpoint
    }
  }

  puts "#Files read: $nfiles"
  puts "#Files with uuid: $nuuid"
  
  # set fo [open [file join $dir "xml-times.tsv"] w]
  set fo [open [file join $dir $outfilename] w]
  puts $fo [join [list ts sec1 xmltime sec_xmltime diff subject uuid] "\t"]
  foreach ts [lsort [array names files]] {
    lassign $files($ts) subject sec_xmltime file
    set sec1 [ts_parse_msec $ts]; # 
    set diff [format %.3f [expr $sec_xmltime-$sec1]]
    set xmltime [clock format $sec_xmltime -format "%Y-%m-%d %H:%M:%S"]
    puts $fo [join [list $ts $sec1 $xmltime $sec_xmltime $diff $subject ""] "\t"]
  }

  puts "#items in uuids array: [llength [array names uuids]]"

  set nput 0
  foreach sec_xmltime [lsort [array names uuids]] {
    foreach uuid $uuids($sec_xmltime) {
      set xmltime [clock format $sec_xmltime -format "%Y-%m-%d %H:%M:%S"]
      puts $fo [join [list "" "" $xmltime $sec_xmltime "" "" $uuid] "\t"]
      incr nput
    }
    # set uuid $uuids($sec_xmltime)
  }
  puts "#records put in output: $nput"
  
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
    try_eval {
      set res [expr [clock scan $sec -format "%Y-%m-%d--%H-%M-%S"] + $msec]
    } {
      log error "Parsing timestamp failed for: $ts/sec"
      breakpoint
    }
    return $res
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
