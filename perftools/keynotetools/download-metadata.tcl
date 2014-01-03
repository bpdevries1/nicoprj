#!/usr/bin/env tclsh86

package require Tclx
package require ndv

proc main {argv} {
  # global nerrors
  
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL" "Directory to put downloaded keynote files"}
    {apikey.arg "~/.config/keynote/api-key.txt" "Location of file with Keynote API key"}
    {format.arg "json" "Format of downloaden file: json or xml"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dct_argv [::cmdline::getoptions argv $options $usage]

  get_meta_data $dct_argv
}

proc get_meta_data {dct_argv} {
  set root_dir [:dir $dct_argv]  
  set filename [file join $root_dir "slotmetadata-[clock format [clock seconds] -format "%Y-%m-%d"].[:format $dct_argv]"]
  set api_key [det_api_key [:apikey $dct_argv]]
  set cmd [list curl --sslv3 -o $filename "https://api.keynote.com/keynote/api/getslotmetadata?api_key=$api_key\&format=[:format $dct_argv]"]
  log debug "cmd: $cmd"
  try_eval {
    set res [exec -ignorestderr {*}$cmd]
    log debug "res: $res"
    return $filename
  } {
    log warn "$errorResult $errorCode $errorInfo, continuing"   
  }
  return ""
}

proc det_api_key {api_key_loc} {
  # string trim [read_file [file join ~ .config keynote api-key.txt]]
  # string trim [read_file "~/.config/keynote/api-key.txt"]
  string trim [read_file $api_key_loc]
}

if {[info level] == 0} {
  if {[file tail $argv0] == [file tail [info script]]} {
    set log [::ndv::CLogger::new_logger [file tail [info script]] info]
    $log set_file "[file tail [info script]].log"
    main $argv
  }
}

