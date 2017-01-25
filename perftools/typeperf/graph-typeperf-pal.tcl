#!/usr/bin/env tclsh

#package require Tclx
package require ndv
#package require struct::set

require libio io
use libfp

set_log_global info

set script_dir [file dirname [info script]]
# TODO R-wrapper van central plek halen, mogelijk in ndv lib.
#set graphtools_dir [file join $script_dir .. .. .. nicoprj perftools graph graphtools]
#source [file join $graphtools_dir R-wrapper.tcl]

proc main {argv} {
  # global log
  log debug "argv: $argv"
  set options {
    {rootdir.arg "" "Root dir for db and graphs"}
	{dirs.arg "*" "Subdirs within rootdir to process (globs, : separated)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {incr "Incremental: only create graphs if they do not exist yet"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set opt [getoptions argv $options $usage]
  if {[:rootdir $opt] == ""} {
    log error "Mandatory argument rootdir not given."
	exit
  }
  log set_log_level [:loglevel $opt]
  # [2016-08-31 10:13:26] TODO: clean will not work correctly like this: will also remove .png screenshots!
  make_graphs $opt
}

proc make_graphs {opt} {
  set root [:rootdir $opt]
  foreach pat [split [:dirs $opt] ":"] {
	foreach dir [glob -nocomplain -type d -directory $root $pat] {
      # make_graphs_dir $opt $dir
      graph_typeperf $dir $opt
	}
  }
}

# deze met PAL-tool, dus niet met R en DB.
# alle csv's in dir die op eerste regel PDH-CSV hebben staan.
proc graph_typeperf {dir opt} {
  # breakpoint
  foreach filename [glob -nocomplain -directory $dir "*.csv"] {
	if {[should_handle? $opt $filename]} {
	  do_pal $filename $dir
	} else {
	  # breakpoint
	}
  }
}

proc should_handle? {opt filename} {
    set f [open $filename r]
	gets $f line
	set should_handle [regexp {PDH-CSV} $line]
	close $f
	if {$should_handle} {
		# check if done before and incremental set.
		if {[:incr $opt]} {
			if {[file exists [file rootname $filename]]} {
				return 0 ; # subdir with html/graphs already exists.
			} else {
				return 1
			}
		} else {
			return 1 ; # always create new html/graphs
		}
	} else {
		return 0
	}
}

# input: csv typeperf file
# output to dir: html + png's
proc do_pal {filename dir} {
  set old_dir [pwd]
  cd {c:\PCC\util\PAL}
  set output_htm "[file rootname [file tail $filename]].htm"
  set cmd [list Powershell -ExecutionPolicy ByPass -NoProfile -File ".\\PAL.ps1" -OutputDir [file nativename $dir] -Log [file nativename $filename] -ThresholdFile "c:\\PCC\\util\\PAL\\SQLServer2008R2.xml" -Interval "AUTO" -IsOutputHtml \$True -HtmlOutputFileName "$output_htm" -IsOutputXml \$False -XmlOutputFileName "\[LogFileName\]_PAL_ANALYSIS_\[DateTimeStamp\].xml" -AllCounterStats \$True -NumberOfThreads 4 -IsLowPriority \$True -OS "64-bit Windows Server 2008 R2" -PhysicalMemory "48" -UserVa "2048" -DisplayReport \$False]
  log debug "Executing: $cmd"
  exec -ignorestderr {*}$cmd
  
  cd $old_dir

}

main $argv
