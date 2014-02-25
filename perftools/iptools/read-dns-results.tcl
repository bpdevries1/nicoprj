#!/usr/bin/env tclsh86

# read-dns-results.tcl

package require ndv

ndv::source_once libdnsip.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

# if downloaded file has errors, move it to error-dir and mark in database so it can be downloaded again.

proc main {argv} {
  global dargv
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/dns-ip" "Directory where downloaded files are"}
    {db.arg "c:/projecten/Philips/dns-ip/dnsip.db" "SQLite DB"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  read_results $dargv
}

# @note kan goed dat DNS bij verschillende calls verschillende antwoorden geeft (op hetzelfde domain)
proc read_results {dargv} {
  set dir [:dir $dargv]
  set db [get_dnsip_db [:db $dargv]]
  $db in_trans {
    # breakpoint
    foreach filename [glob -directory $dir *.html] {
      read_results_file $db $filename
      # break ; # test
    }
  }
  $db close
}

proc read_results_file {db path} {
  log info "read: $path"
  set ts_cet [clock format [file mtime $path] -format "%Y-%m-%d %H:%M:%S"]
  if {[is_result_read $db $path $ts_cet]} {
    log info "Already read: $path, returning"
    return
  }
  set contents [read_file $path]
  set domain [det_domain_from_path $path]
  set curldnsout_id [$db insert curldnsout [vars_to_dict ts_cet path domain contents]]
  if {[regexp -nocase {<PRE>(.+)</PRE>} $contents z text]} {
    if {[regexp {Server: ([^\n]+).*\nName: ([^\n]+)\nAddress(es)?: (.+)\n(Aliases:)?} $text z dnsserver dnsname z ips]} {
      set dnsserver [string trim $dnsserver]
      set dnsname [string trim $dnsname]
      foreach ip [split $ips "\n"] {
        set ip_address [string trim $ip]
        if {[regexp {Aliases:} $ip_address]} {
          break ; # don't read stuff after aliases.
        }
        if {$ip != ""} {
          $db insert domainip [vars_to_dict curldnsout_id ts_cet domain dnsserver dnsname ip_address]
        }
      }
    }
  } else {
    log warn "No PRE element found in html (path: $path)"
  }
}

proc det_domain_from_path {path} {
  if {[regexp {^(.+)\.html} [file tail $path] z domain]} {
    return $domain
  } else {
    error "Cannot determine domain from path: $path"
  }
}

proc is_result_read {db path ts_cet} {
  set res [$db query "select * from curldnsout where path='$path' and ts_cet = '$ts_cet'"]
  if {[llength $res] > 0} {
    return 1
  } else {
    return 0
  }
}

main $argv
  
