#!/usr/bin/env tclsh86

# Analyse vugen output (in output.txt), generate requests.
# Goal: check if orig CBW script (still) has the same URL's as a new recording.
# Use log instead of script.c, so implicit URL's will also be noted.
# input: output.txt (generated by VuGen)
# output: report/log-urls.csv (; separated file, easy to open in Excel)
#
# syntax: $argv0 <project-dir>

package require textutil::split
package require Tclx
package require ndv
package require csv

interp alias {} splitx {} ::textutil::split::splitx

set DEBUG 0

proc main {argv} {
  lassign $argv prj_dir
  set in_name [file join $prj_dir output.txt]
  set out_name [file join $prj_dir report log-urls-[file tail $prj_dir].csv]
  file mkdir [file join $prj_dir report]
  set fo [open $out_name w]
  puts $fo [join [list file linenr transaction domain url] ";"]
  set fi [open $in_name r]
  set transaction "<none>"
  while {![eof $fi]} {
    gets $fi line
	if {[regexp {\.c\(\d+\): Notify: Transaction .([^ ]+). started.} $line z tn]} {
	  set transaction $tn
	}
	if {[regexp {^([^.]+.c)\((\d+)\): t=\d+ms: \d+-byte request headers for .(.*?). \(RelFrameId=\d*, Internal ID=\d*\)} $line z file linenr url]} {
      puts $fo [join [list $file $linenr $transaction [url2dom $url] $url] ";"]
	} elseif {[regexp {request headers} $line]} {
	  breakpoint
	}
  }
  close $fo
  close $fi
}

proc url2dom {url} {
  if {[regexp {://([^/]+)/} $url z dom]} {
    return $dom
  } else {
    return $url
  }
  
}

main $argv
