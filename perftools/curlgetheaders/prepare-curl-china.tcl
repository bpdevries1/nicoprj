#!/usr/bin/env tclsh86

package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "curlgetheader.log"

proc main {} {

  set db_name "c:/projecten/Philips/akamai-headers/akamai-headers.db"
  set db [dbwrapper new $db_name]
  $db exec2 "drop table if exists akamai_urls"
  $db exec2 "create table akamai_urls (scriptname, ts_cet, page_seq int, url, urlnoparams)"
  
  set root_dir "c:/projecten/Philips/KNDL"
  set it 0
  foreach subdir [glob -directory $root_dir -type d *] {
    if {![regexp {CN} [file tail $subdir]]} {
      continue
    }
    log info "Handling $subdir"
    incr it
    $db exec2 "attach database '$subdir/keynotelogs.db' as 'kn'"
    set do_insert 0
    set res [$db query "select ts_cet from scriptrun where ts_cet > '2014-04-13' and 1*task_succeed_calc = 1 limit 1"]
    if {[:# $res] == 0} {
      log warn "No good results found in $subdir/keynotelogs.db"
      set res [$db query "select ts_cet from scriptrun where ts_cet > '2014-04-13' limit 1"]
      if {[:# $res] == 0} {
        log warn "No good or error results found in $subdir/keynotelogs.db"
        set do_insert 0
      } else {
        set do_insert 1
      }
    } else {
      set do_insert 1
    }
    if {$do_insert} {
      set ts_cet [:ts_cet [:0 $res]]
      set scriptname [file tail $subdir]
      $db exec2 "insert into akamai_urls (scriptname, ts_cet, page_seq, url, urlnoparams)
                 select '$scriptname', ts_cet, 1*page_seq, url, urlnoparams
                 from pageitem
                 where ts_cet = '$ts_cet'"
    }
    # $db exec2 "detach database kn$it"
    $db exec2 "detach database 'kn'"
    after 3000 ; # wait a little bit
  }
  
  $db close
}  
  
main
