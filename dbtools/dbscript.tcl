#!/usr/bin/env tclsh86

package require Tclx
package require ndv
package require fileutil
package require textutil

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {db.arg "" "DB full path"}
    {rootdir.arg "" "Root directory that contains db's."}
    {dbpattern.arg "*.db" "Databases within rootdir to exec script in"}
    {script.arg "" "script.sql to execute"}
    {output.arg "" "If set, file to send query output to"}
    {coe "If set, continue-on-error"}
    {dryrun "If set, just print databases and statements, don't exec anything"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  do_script_dbs $dargv
}

proc do_script_dbs {dargv} {
  global fo
  # first handle single db argument, then rootdir/dbpattern combination.
  set stmts [det_statements [:script $dargv]]
  if {[:output $dargv] != ""} {
    set fo [open [:output $dargv] w]
    puts "Executing script: [:script $dargv] for DB's [:pattern $dargv]"
  } else {
    set fo ""
  }
  # set stmts [-> $dargv :script det_statements] ; possible, just like clojure?
  if {[:db $dargv] != ""} {
    do_statements_db [:db $dargv] $stmts $dargv 
  }
  if {[:rootdir $dargv] != ""} {
    foreach dbname [fileutil::findByPattern [:rootdir $dargv] [:dbpattern $dargv]] {
      do_statements_db $dbname $stmts $dargv
    }
  }
  if {$fo != ""} {
    close $fo
  }
}

proc det_statements {scriptname} {
  set lines [split [read_file $scriptname] "\n"]
  
  # remove comments, starting with --
  set lines2 [lmap line $lines {ifp [= [string range [string trim $line] 0 1] "--"] "" $line}]
  set stmts [textutil::splitx [join $lines2 "\n"] {;\n}]
  set stmts2 [filter el $stmts {not= [string trim $el] ""}]
  return $stmts2
}

proc do_statements_db {dbname stmts dargv} {
  global fo
  log info "Opened connection to: $dbname"
  set db [dbwrapper new $dbname]
  if {[:coe $dargv]} {
    set try "-try" 
  } else {
    set try "" 
  }
  foreach stmt $stmts {
    if {[:dryrun $dargv]} {
      log info "Dry run: $stmt"
    } else {
      log info "Executing statement: $stmt"
      if {[query_type $stmt] == "select"} {
        if {$fo != ""} {
          puts $fo "DB: $dbname - results:"
          set res [$db query $stmt]
          puts $fo [res2table $res]     
          flush $fo
        } else {
          log warn "select statement without output file set, not executing: $stmt"
        }
      } else {
        $db exec2 $stmt -log $try
      }
    }
  }  
  $db close  
  log info "Closed connection to: $dbname"
}

proc query_type {stmt} {
  if {[regexp -nocase {^select } $stmt]} {
    return "select"
  } else {
    return "change"
  }
}

# convert resultset (list of dicts) to a tab-seperated table.
# @todo? put lines (ascii-art) in result
proc res2table {res} {
  if {[llength $res] == 0} {
    return "No results"
  } else {
    # example: listc {$i * $i} i <- {1 2 3 4 5} {$i % 2 == 0} => 4 16
    set header [join [dict keys [lindex $res 0]] "\t"]
    set rows [listc {[join [dict values $row] "\t"]} row <- $res]
    return "$header\n[join $rows "\n"]"
  }
}

main $argv

