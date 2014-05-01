#!/usr/bin/env tclsh86

# read-domains.tcl - read list of domains into sqlite database for further processing.

package require ndv

ndv::source_once libdnsip.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

proc main {argv} {
  global dargv
  log debug "argv: $argv"
  set options {
    {domains.arg "c:/projecten/Philips/dns-ip/domains.txt" "File with domains, one per line"}
    {outdir.arg "c:/projecten/Philips/dns-ip" "Directory where downloaded files should be put"}
    {db.arg "c:/projecten/Philips/dns-ip/dnsip.db" "SQLite DB"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  read_domains $dargv
}

proc read_domains {dargv} {
  set outdir [:outdir $dargv]
  file mkdir $outdir
  set db [get_dnsip_db [:db $dargv]]
  foreach domain [split [read_file [:domains $dargv]] "\n"] {
    if {$domain != ""} {
      $db insert domain [dict create domain $domain]
    }
  }
  $db close
}

main $argv
