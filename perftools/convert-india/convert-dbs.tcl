#!/usr/bin/env tclsh86

package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  global dargv
  log debug "argv: $argv"
  set options {
    {rootdir.arg "c:/aaa/KN-India" "Root directory for files for Indian Keynote system"}
    {config.arg "~/.config/keynote/nslookup.json" "File with Keynote specific config"}
    {h "Show help, including all actions"}
    {loglevel.arg "debug" "Log level (debug, info, warn)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  convert_dbs $dargv
  
  # convert_tcl_scripts $dargv
}

proc convert_dbs {dargv} {
  set db [dbwrapper new [file join [:rootdir $dargv] KNDL "combinereport.db"]]
  $db function path_c_d
  convert_table_field $db combinedatedir {dir}
  convert_table_field $db combinedef {cmds srcdir srcpattern targetdir}
  convert_table_field $db combinedefdir {dir}
  $db close
  
  set db [dbwrapper new [file join [:rootdir $dargv] KNDL "slotmeta-domains.db"]]
  $db function path_c_d
  convert_table_field $db script {path}
  $db close
}

proc convert_table_field {db table fields} {
  foreach field $fields {
    $db exec2 "update $table set $field = path_c_d($field)" -log
  }
}

proc convert_tcl_scripts {dargv} {
  # lib -> geen c:->d: vertaling!
  
  # "c:/ vervangen door "d:/
  # extra checkes dus.
  
  # gedaan met find/sed: / in search-string, dus separator is |
  # find . -type f -exec sed -i 's|"c:/|"d:/|g' '{}' \;
  # find . -type f -exec sed -i 's|"C:/|"D:/|g' '{}' \;

  
  # dbtools -> deze wel.
  #perftools
  #R
}

# replace c: in path with d:
proc path_c_d {str} {
  regsub -all -nocase -- "c:" $str "d:" str
  return $str
}

main $argv
