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
      {rep.arg "Message-counts" "Report name."}
      {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  set fo [open [file join $ar_argv(dir) "$ar_argv(rep).tsv"] w]
  set first 1
  foreach dirname [lsort [glob -directory $ar_argv(dir) -type d 2011*]] {
    handle_dir $fo $dirname $first
    set first 0
  }
  close $fo
}

# search for all occurences of "CPU Utilization on " in the HTML,
# and put an IMG link to the corresponding graph in the new HTML.
# @param first: if true, determine the columns and make a header-row.
proc handle_dir {fo dirname first} {
  foreach filename [glob -nocomplain -directory $dirname Report*.html] {
    handle_html_file $fo $dirname $filename $first    
  }
}

proc handle_html_file {fo dirname filename first} {
  set q_res_list [det_q_res_list $filename]
  # was if $first, now have the header between all graph rows.
  if {$first} {
    set lst_header [list "Date"]
    foreach el $q_res_list {
      lappend lst_header [lindex $el 0] 
    }
    puts $fo [join $lst_header "\t"]
  }
  puts -nonewline $fo [file tail $dirname]
  foreach el $q_res_list {
    puts -nonewline $fo "\t[lindex $el 1]"
  }
  puts $fo ""
}

#    <TD>MSMQ Queue\abatst30\private$\activebank.auctionevent\Messages in 
#    Queue</TD>
#    <TD align=right>37837.0</TD>
proc det_q_res_list {filename} {
  global ar_argv
  
  set f [open $filename r]
  set res {}
  while {![eof $f]} {
    gets $f line
    if {[regexp {<TD>MSMQ Queue} $line]} {      
      set lines $line
      while {![regexp {</TD} $lines]} {
        gets $f line 
        set lines "$lines$line"
      }
      gets $f line
      if {[regexp {<TD>MSMQ Queue\\([^\\]+)\\private\$\\(.+)\\Messages +in +Queue</TD>} $lines z sysname queue]} {
        if {[regexp {<TD align=right>([0-9.]+)</TD>} $line z max]} {
          lappend res [list "$sysname\\$queue" $max] 
        }
      }
    }
  }
  close $f
  return $res
}

main $argc $argv
