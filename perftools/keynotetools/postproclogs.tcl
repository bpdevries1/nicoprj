#!/usr/bin/env tclsh86

# @todo use postproclogs.tcl library, create/fill checkrun table.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

source libpostproclogs.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  # lassign $argv dirname
  set options {
    {srcdir.arg "c:/projecten/Philips/KN-analysis" "Source dir with Keynote API databases (keynotelogs.db)"}
    {srcpattern.arg "*" "Pattern for subdirs in srcdir to use"}
    {maxurls.arg "20" "max nr of urls to put in maxitem (for graphs)"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]   
  handle_srcdirroot [from_cygwin [:srcdir $dargv]] [:srcpattern $dargv] [:maxurls $dargv]
}

proc handle_srcdirroot {srcdir srcpattern max_urls} {
  foreach subdir [glob -directory $srcdir -type d $srcpattern] {
    handle_srcdir $subdir $max_urls
    # exit ; # for test
  }
}

# specific proc to just do post processing
proc handle_srcdir {dir max_urls} {
  log info "handle_srcdir: $dir"
  post_proc_srcdir $dir $max_urls
}

main $argv

