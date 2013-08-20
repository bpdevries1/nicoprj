#!/usr/bin/env tclsh86

# download-urls.tcl

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  global dct_argv
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/Mobile-CN/" "Directory to download files to"}
    {config.arg "urls.txt" "File with URL's to download"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dct_argv [::cmdline::getoptions argv $options $usage]
  download_files [:config $dct_argv] [:dir $dct_argv]
}

proc download_files {config_file dir} {
  file mkdir $dir
  foreach url [split [string trim [read_file $config_file]] "\n"] {
    download_file $url $dir  
  }
}

proc download_file {url dir} {
  set local_name [det_local_name $dir $url]
  if {[file exists $local_name]} {
    log info "Already have $local_name, continuing" ; # or stopping?
    return
  }
  
  # set cmd [list curl -o $local_name "$url"]
  # log debug "cmd: $cmd"
  try_eval {
    # set res [exec -ignorestderr {*}$cmd]
    set res [exec -ignorestderr curl -o $local_name "$url"]
    log debug "res: $res"
  } {
    log warn "$errorResult $errorCode $errorInfo, continuing"   
  }
}

proc det_local_name {dir url} {
  set tail [file tail $url]
  if {[string trim $tail] == ""} {
    set tail "empty[expr rand()]"  
  }
  regsub -all {[ $]} $tail "_" tail
  
  file join $dir $tail
}

main $argv
