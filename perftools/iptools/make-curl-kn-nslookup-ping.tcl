#!/usr/bin/env tclsh86

# make-curl-kn-nslookup-ping.tcl - make shell script to do remote nslookup's with Keynote and also Ping's.
# @note bij script uitvoeren als script (./get-ips.sh) geeft server steeds een 400-bad request.
# @note met copy paste in bash gaat het wel beter (op Windows), maar dan ook na verloop van tijd een error-400 bad request.

package require ndv
package require json

ndv::source_once libdnsip.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

# if downloaded file has errors, move it to error-dir and mark in database so it can be downloaded again.

proc main {argv} {
  global dargv
  log debug "argv: $argv"
  set options {
    {db.arg "c:/projecten/Philips/dns-ip/dnsip.db" "SQLite DB"}
    {outdir.arg "c:/projecten/Philips/dns-ip" "Directory where downloaded files should be put"}
    {config.arg "~/.config/keynote/nslookup.json" "File with Keynote specific config"}
    {ping "Also make ping shell file"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  make_nslookup $dargv
  if {[:ping $dargv]} {
    make_ping $dargv
  }
}

proc make_nslookup {dargv} {
  set outdir [:outdir $dargv]
  file mkdir $outdir
  set db [get_dnsip_db [:db $dargv]]
  dict_to_vars [json::json2dict [read_file [:config $dargv]]]
  
  # @todo also redo all option?
  set fo [open [file join $outdir "get-ips.sh"] w]
  foreach row [$db query "select domain from domain
                          where not domain in (
                            select distinct domain from domainip
                          )"] {
    set domain [:domain $row]
    puts $fo "curl -o ${domain}.html \"http://${nslookup_ip}/scripts/diag2.plx?function=nslookup&target=$domain&ts=$ts\""
  }
  close $fo
}

proc make_ping {dargv} {
  set outdir [:outdir $dargv]
  file mkdir $outdir
  set db [get_dnsip_db [:db $dargv]]
  # @todo also redo all option?
  # @check if pings have already been done (new table)
   
  set fo [open [file join $outdir "do-pings.sh"] w]
  set prev_domain "<none>"
  set prev_ip "<none>"
  # @todo domain meeselecteren is onzin.
  foreach row [$db query "select distinct domain, ip_address from domainip where ip_address not like '%:%' order by domain, ip_address"] {
    dict_to_vars $row
    if {[ip_similar $prev_domain $prev_ip $domain $ip_address]} {
      log info "IP similar to previous, don't check: $prev_domain $prev_ip $domain $ip_address"
    } else {
      puts_curl_pings $fo $ip_address $dargv
    }
    set prev_domain $domain
    set prev_ip $ip_address
  }
  close $fo
}

proc ip_similar {dom1 ip1 dom2 ip2} {
  if {$dom1 == $dom2} {
    if {[first3 $ip1] == [first3 $ip2]} {
      return 1
    } else {
      return 0
    }
  } else {
    return 0 ; # not similar if different domains.
  }
}

# return first 3 components of IPv4 address
proc first3 {ip} {
  join [lrange [split $ip "."] 0 2] "."
}

proc puts_curl_pings {fo ip_address dargv} {
  puts $fo "# pinging $ip_address from several locations"
  dict_to_vars [json::json2dict [read_file [:config $dargv]]]
   
  foreach host_ip $ping_ips {
    puts $fo "curl -o ping-$ip_address-$host_ip.html \"http://${host_ip}/scripts/diag2.plx?function=ping&target=${ip_address}&ts=$ts\""
  }
  puts $fo ""
}

main $argv
  
  