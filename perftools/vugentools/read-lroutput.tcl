#!/usr/bin/env tclsh86
package require ndv
package require tdbc::sqlite3

ndv::source_once lib_lgoutput.tcl

proc main {argv} {
  lassign $argv logdir pattern
  puts "logdir: $logdir"
  set dbname [file join $logdir "lroutput.db"]
  set db [get_output_db $dbname]
  foreach logfile [glob -directory $logdir $pattern] {
    readlogfile $logfile $db
  }
}

proc readlogfile {path db} {
  puts "Reading: $path"
  # set ts_cet [clock format [file mtime $logfilepath] -format "%Y-%m-%d %H:%M:%S"]
  set logfile [file tail $path]
  set vuserid [det_vuserid $logfile]
  set ts_cet [clock format [file mtime $path] -format "%Y-%m-%d %H:%M:%S"]
  set logfile_id [$db insert logfile [vars_to_dict path ts_cet vuserid]]
  $db in_trans {
    read_blocks $path insert_block $db $logfile_id
  }
}

proc insert_block {db logfile_id linestart lineend firstline restlines sourcefile sourceline relmsec relframeid internalid url} {
  set blocktype [det_blocktype $firstline]
  set proxy [det_proxy $blocktype $restlines]
  $db insert logblock [vars_to_dict logfile_id linestart lineend firstline restlines sourcefile sourceline relmsec relframeid internalid url blocktype proxy]
}

set block_re_types {
"request headers" request_headers
"response headers" response_headers
"response overhead" response_overhead
"ENCODED response" encoded_response
"DECODED response" decoded_response
}

proc det_blocktype {line} {
  global block_re_types
  foreach {re tp} $block_re_types {
    if {[regexp $re $line]} {
      return $tp
    }
  }
  return ""
}

proc det_proxy {blocktype restlines} {
  if {[regexp {headers} $blocktype]} {
    return [regexp {Proxy-Connection: } $restlines]
  } else {
    return 0
  }
}

# sort-of lib-function, but for now still specific. Can't seem to use re_split.
proc read_blocks {path args} {
  set f [open $path r]
  
  set linestart 1
  set lineend 1
  gets $f firstline

  # invariants: firstline is filled, restlines not important, linestart and lineend are
  # correctly filled (point to first and last line of block)
  while {![eof $f]} {
    set restlines {}
    while {![eof $f]} {
      gets $f line
      if {[is_first_block_line $line]} {
        break
      } else {
        if {[regexp {^[^ ]+\(\d+\):     (.*)$} $line z line2]} {
          lappend restlines $line2
        } ; # else nothing, should not happen.
        incr lineend
      }
    }
    # in regexp hieronder was $firstline $line, en toch leek het te werken...
    if {[regexp {^(([^ ]+)\((\d+)\): )?(t=(\d+)ms: )?(.*)$} $firstline z z sourcefile sourceline z relmsec fline2]} {
      regexp {\[issued at ([^ ]+)\((\d+)\)\]$} $fline2 z sourcefile sourceline ; # regexp only sets var if match occurs.
      set relframeid 0
      set internalid 0
      set url ""
      # (RelFrameId=1, Internal ID=86)
      regexp {\(RelFrameId=(\d*), Internal ID=(\d*)\)} $fline2 z relframeid internalid
      # Resource "https://securepat01.rabobank.com/cras/css/3/style.css" is in the cach
      regexp {"(http.+?)"} $fline2 z url
      {*}$args $linestart $lineend $fline2 [join $restlines "\n"] $sourcefile $sourceline $relmsec $relframeid $internalid $url
    } else {
      error "regexp not matched, should not happen: $"
    }
    

    set firstline $line
    set linestart [expr $lineend + 1]
    set lineend $linestart
    # TODO end-checks at EOF, seems to work for now.
  }
  close $f
}

proc is_first_block_line {line} {
  if {[regexp {^[^ ]+\(\d+\):     } $line]} {
    return 0 ; # line with spaces after filename, so it's a rest-line
  } else {
    return 1
  }
}

proc det_vuserid {logfile} {
  if {[regexp {_(\d+).log} $logfile z vuser]} {
    return $vuser
  } else {
    # fail "Could not determine vuser from logfile: $logfile"
    return -1 ; # eg output.txt from VuGen.
  }
}

main $argv
