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
    {dir.arg "~/Ymor/Philips/Shop/curltest" "Dir to put output"}
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
  set dir [:dir $dargv]
  file mkdir $dir
  set dbname [file join $dir "curltest.db"]
  set db [dbwrapper new $dbname]
  prepare_db $db
  set interval [expr 1000 * [:interval $dargv]]
  set clientname [det_clientname]
  while {1} {
    test1 $db $clientname "https://www.philips-shop.de/store/myaccount/login.jsp"
    test1 $db $clientname "http://www.philipsstore.nl/store/"
    after $interval
  }
}

proc prepare_db {db} {
  $db add_tabledef curltest {id} {clientname ts_cet url server serverstore akserver \
    http_code http_connect {size_download integer} {num_connects integer} \
    {num_redirects integer} ssl_verify_result {time_namelookup real} \
    {time_connect real} {time_appconnect real} {time_pretransfer real} \
    {time_redirect real} {time_starttransfer real} {time_total real} \
    resulttext}
  $db create_tables
  $db prepare_insert_statements  
}

proc test1 {db clientname url} {
  log info "Get: $url"
  set resulttext [exec -ignorestderr curl -w "@curlset.txt" -IXGET -H "Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no" -L --connect-timeout 20 --max-time 30 "$url"]
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

main $argv
