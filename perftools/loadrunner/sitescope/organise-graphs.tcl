#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list
package require math
package require math::statistics ; # voor bepalen std dev.

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log ar_argv
  
  $log debug "argv: $argv"
  set options {
      {dir.arg "." "Directory to work on."}
      {rep.arg "CPU-Graphs" "Report name."}
      {re.arg "<H3>CPU Utilization on (\[^<\]+)</H3>" "Regexp to use"}
      {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  set fo [open [file join $ar_argv(dir) "$ar_argv(rep).html"] w]
  set hh [ndv::CHtmlHelper::new]
  $hh set_channel $fo
  $hh write_header "$ar_argv(rep)"
  $hh table_start
  set first 1
  foreach dirname [lsort [glob -directory $ar_argv(dir) -type d 2011*]] {
    handle_dir $hh $dirname $first
    set first 0
  }
  close $fo
}

# search for all occurences of "CPU Utilization on " in the HTML,
# and put an IMG link to the corresponding graph in the new HTML.
# @param first: if true, determine the columns and make a header-row.
proc handle_dir {hh dirname first} {
  foreach filename [glob -nocomplain -directory $dirname Report*.html] {
    handle_html_file $hh $dirname $filename $first    
  }
}

proc handle_html_file {hh dirname filename first} {
  set cpu_res_list [det_cpu_res_list $filename]
  # was if $first, now have the header between all graph rows.
  if {1} {
    set lst_header "Date"
    foreach el $cpu_res_list {
      lappend lst_header [lindex $el 0] 
    }
    $hh table_header {*}$lst_header
  }
  $hh table_row_start
  $hh table_data [file tail $dirname]
  foreach el $cpu_res_list {
    $hh table_data [$hh get_img [file join [file tail $dirname] [lindex $el 1]]] 
  }
  $hh table_row_end
}

proc det_cpu_res_list {filename} {
  global ar_argv
  
  set f [open $filename r]
  set res {}
  while {![eof $f]} {
    gets $f line
    # if {[regexp {<H3>CPU Utilization on ([^<]+)</H3>} $line z sysname]} {}
    if {[regexp $ar_argv(re) $line z sysname]} {      
      while {![regexp {<IMG} $line]} {
        gets $f line 
      }
      set lines $line
      while {![regexp {src=".+.jpg"} $lines]} {
        gets $f line
        set lines "$lines$line"
      }
      set url_path "<none>"
      regexp {src="http://[0-9.:]+(.+)">} $lines z url_path
      if {$url_path == "<none>"} {
        breakpoint 
      }
      set url_file [file tail $url_path]
      lappend res [list $sysname $url_file]
    }
  }
  close $f
  return $res
}

main $argc $argv
