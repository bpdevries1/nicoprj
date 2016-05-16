#!/usr/bin/env tclsh86

#package require Tclx
#package require ndv
#package require fileutil
#package require textutil

#set log [::ndv::CLogger::new_logger [file tail [info script]] info]
#$log set_file "[file tail [info script]].log"

proc main {argv} {
  # log debug "argv: $argv"
  lassign $argv dir interval
  set dargv [dict create dir $dir interval $interval]
  curltest $dargv
}

proc curltest {dargv} {
  global f fa
  set dir [dict get $dargv dir]
  file mkdir $dir
  set fa [open [file join $dir "results-all.txt"] a]
  set f [open [file join $dir "results.csv"] a]
  set interval [expr 1000 * [dict get $dargv interval]]
  set db ""
  # [2013-10-23 16:42:05] https on qa (via proxy) not working.
  while {1} {
    # test1 $db $clientname qa "https://qal.www.philips-shop.de/store/myaccount/login.jsp"
    # exit
    # new ones 21-10-2013
    set clientname ""
    source tests.tcl
    if {0} {
    test1 $db $clientname qa "http://qal.www.philips-shop.de/store/"
    test1 $db $clientname qa "http://www.dev2.philips-shop.co.uk/store/"
    #test1 $db $clientname qa "https://www.dev2.philips-shop.co.uk/store/myaccount/login.jsp"
    
    test1 $db $clientname qa "http://qal.www.philips-tienda.es/store/index.jsp?country=ES&language=es"
    test1 $db $clientname qa "http://qal.www.philips-tienda.es/store/"
    test1 $db $clientname prod "https://www.philips-shop.de/store/myaccount/login.jsp"
    test1 $db $clientname prod "http://www.philipsstore.nl/store/"
    # log info "Wait $interval msec"
    }
    after $interval
  }
}

proc test1 {db clientname prodqa url} {
  global f fa stderr
  # log info "Get: $url"
  # set resulttext [exec -ignorestderr curl -w "@curlset.txt" -IXGET -H "Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no" -L --connect-timeout 20 --max-time 30 "$url"]
  #set cmd [list $curl_bin -w curlset.txt -IXGET -H "Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no" -L --connect-timeout 20 --max-time 30 $url] 
  # set resulttext [exec -ignorestderr $curl_bin -w "@curlset.txt" -IXGET -H "Pragma: akamai-x-cache-on, akamai-x-cache-remote-on, akamai-x-check-cacheable, akamai-x-get-cache-key, akamai-x-get-extracted-values, akamai-x-get-nonces, akamai-x-get-ssl-client-session-id, akamai-x-get-true-cache-key, akamai-x-serial-no" -L --connect-timeout 20 --max-time 30 "$url"]
  #log info "Executing: $cmd"
  puts stderr "Getting URL: $url"
  set errorCode 0
  catch {
    set resulttext ""
    set errorResult ""
    # set resulttext [exec -ignorestderr c:/util/cygwin/bin/bash ./curl$prodqa.sh $url]
    set resulttext [exec -ignorestderr bash.exe ./curl$prodqa.sh $url]
  } errorResult
  puts stderr "errorResult: $errorResult"
  if {$errorCode != 0} {
    puts stderr "$errorInfo - $errorCode"
  }
  #::errorInfo and ::errorCode 
  # log warn "Error during curl: $errorResult"
  set resulttext "$resulttext$errorResult"
  # log info "result: $resulttext"
  set msec [clock milliseconds]
  set sec [clock seconds]
  set msec2 [string range $msec end-2 end]
  set ts_cet [clock format $sec -format "%Y-%m-%d %H:%M:%S"]
  # set dct [dict create url $url resulttext $resulttext ts_cet $ts_cet]
  set dct [dict create url $url ts_cet $ts_cet time_total -1]
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
  # $db insert curltest $dct 
  puts $fa "result: $dct"
  flush $fa
  puts $f [join [list $ts_cet $msec2 $url [dict get $dct time_total]] ","]
  flush $f
}

main $argv
