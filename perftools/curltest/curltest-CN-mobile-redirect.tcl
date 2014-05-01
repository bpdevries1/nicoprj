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
    {dir.arg "c:/projecten/Philips/China/curltest" "Dir to put output"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {interval.arg "300" "Interval in seconds"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  curltest $dargv
}

proc curltest {dargv} {
  global curl_bin
  set curl_bin [det_curl_bin]
  set dir [:dir $dargv]
  file mkdir $dir
  set dbname [file join $dir "curltest.db"]
  set db [dbwrapper new $dbname]
  prepare_db $db
  set interval [expr 1000 * [:interval $dargv]]
  set clientname [det_clientname]
  while {1} {
    test1 $db $clientname "http://www.philips.com.cn/c/"
    test1 $db $clientname "http://www.philips.com.cn/c/" "122.227.101.81"
    test1 $db $clientname "http://www.philips.com.cn/c/" "210.192.114.146"
    test1 $db $clientname "http://www.philips.com.cn/c/" "210.192.114.152"
    log info "Wait $interval msec"
    after $interval
  }
}

proc prepare_db {db} {
  $db add_tabledef curltest {id} {clientname ts_cet url ip server serverstore akserver \
    http_code http_connect {size_download integer} {num_connects integer} \
    {num_redirects integer} ssl_verify_result {time_namelookup real} \
    {time_connect real} {time_appconnect real} {time_pretransfer real} \
    {time_redirect real} {time_starttransfer real} {time_total real} \
    resulttext has_mobile}
  $db create_tables
  $db prepare_insert_statements  
}

proc det_curl_bin {} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    return "c:/util/cygwin/bin/curl.exe"  
  } else {
    return "curl" 
  }
}

# @param ip: use specific IP Address to serve contents from. If empty, use DNS to resolve.
proc test1 {db clientname url {ip ""}} {
  global curl_bin
  log info "Get: $url"
  # set resulttext [exec -ignorestderr curl -w "@curlset.txt" -IXGET -H "Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no" -L --connect-timeout 20 --max-time 30 "$url"]
  #set cmd [list $curl_bin -w curlset.txt -IXGET -H "Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no" -L --connect-timeout 20 --max-time 30 $url] 
  # set resulttext [exec -ignorestderr $curl_bin -w "@curlset.txt" -IXGET -H "Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no" -L --connect-timeout 20 --max-time 30 "$url"]
  #log info "Executing: $cmd"
  try_eval {
    set resulttext ""
    # removed: -IXGET, because want to check body for occurence of m.philips.
    # removed: -w \"@curlset.txt\" because this does not work on Windows.
    set use_ip [det_use_ip $ip $url]
    # breakpoint
    
    set cmd "curl $use_ip -H \"Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no\" -L --connect-timeout 20 --max-time 30 \"$url\""
    log info "Exec cmd: $cmd"
    # breakpoint
    set resulttext [exec -ignorestderr {*}$cmd]
    # set resulttext [exec -ignorestderr $curl_bin ./curl$prodqa.sh $url]
  } {
    log warn "Error during curl: $errorResult"
    set resulttext "$resulttext$errorResult"
  }
  # log info "result: $resulttext"
  set ts_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  set dct [dict create url $url resulttext $resulttext ts_cet $ts_cet]
  dict set dct clientname $clientname
  if {![regexp {pshop-(prodl-app\d+)_(store\d+)} $resulttext z server serverstore]} {
    set server "<none>"
    set serverstore "<none>"
  }
  dict set dct server $server
  dict set dct serverstore $serverstore
  # X-Cache: TCP_MISS from a2-16-1-109 (AkamaiGHost/6.13.2-11322658) (-)
  if {![regexp {X-Cache: [^ ]+ from ([^ ]+)} $resulttext z akserver]} {
    set akserver "<none>" 
  }
  dict set dct akserver $akserver
  foreach line [split $resulttext "\n"] {
    if {[regexp {^([^ :]+): (.*)$} $line z nm val]} {
      dict set dct $nm $val 
    }
  }
  dict set dct has_mobile [det_has_mobile $resulttext]
  dict set dct ip $ip
  $db insert curltest $dct 
}

proc det_clientname {} {
  global env
  set res "<none>"
  catch {set res $env(HOSTNAME)}
  if {$res == "<none>"} {
    catch {set res [string trim [read_file "/etc/hostname"]]} 
  }
  return $res
}


proc det_has_mobile {resulttext} {
  regexp {m\.philips\.com\.cn} $resulttext
}

# @return string to include in curl cmdline to use ip address for url.
proc det_use_ip {ip url} {
  if {$ip == ""} {
    return ""
  }
  lassign [det_domain_port $url] domain port
  if {$domain == "<none>" || $port == "<none>"} {
    error "domain and/or port is <none>: $domain:$port"
  }
  return "--resolve $domain:$port:$ip"
}

proc det_domain_port {url} {
  set port ""
  if {[regexp {https?://([^/:]+)(:([0-9]+))?} $url z domain z port]} {
    if {$port == ""} {
      set port 80
    }
    list $domain $port
  } else {
    list "<none>" "<none>"
  }
}

main $argv
