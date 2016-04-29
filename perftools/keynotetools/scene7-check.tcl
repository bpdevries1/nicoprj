#!/usr/bin/env tclsh86

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

ndv::source_once libkeynote.tcl

proc main {argv} {
  # global nerrors
  
  log debug "argv: $argv"
  set options {
    {srcdirmain.arg "c:/projecten/Philips/KNDL" "Directory with keynotelogs.db files"}
    {targetdb.arg "c:/projecten/Philips/Scene7/s7checks.db" "DB with check results"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]

  check_dbs $dargv
}

proc check_dbs {dargv} {
  set dbt [create_s7_db [:targetdb $dargv]]
  foreach dir [glob -directory [:srcdirmain $dargv] -type d *] {
    check_dir $dbt $dir
    # break
  }
  $dbt close
}

proc create_s7_db {targetdb} {
  file mkdir [file dirname $targetdb]
  file delete $targetdb
  set dbt [dbwrapper new $targetdb]
  $dbt add_tabledef s7check {id} {dbpath scriptname page_seq url wid hei size result baseurl}
  $dbt create_tables 0 ; # 0: don't drop tables first.
  $dbt prepare_insert_statements
  return $dbt
}

proc check_dir {dbt dir} {
  log info "Checking dir: $dir"
  set dbpath [file join $dir keynotelogs.db]
  if {![file exists $dbpath]} {
    log warn "DB not found: $dbpath, returning"
    return
  }
  set db [dbwrapper new $dbpath]
  set date [clock format [clock seconds] -format "%Y-%m-%d"]
  $dbt in_trans {
    foreach row [$db query "select distinct scriptname, page_seq, url
                            from pageitem
                            where ts_cet > '$date'
                            and url like 'http://images.philips.com/%'
                            and url like '%jpg%'
                            and not url like '%jsonCallBackImageSet%'
                            and not url like '%&_=13%'
                            and not url like '%header_txt%'
                            and not url like '%callback='"] {
      $dbt insert s7check [dict merge $row [dict create dbpath $dbpath] [check_url [:url $row]] [det_base_url $db $date [:scriptname $row] [:page_seq $row]]]
    }
  }
  $db close
}

# return dict with fields wid, hei, size and result
# result can be ok, wrongsize or other (iff wid, hei, type not determined)
proc check_url {url} {
  lassign [det_wid_hei_size $url] result wid hei size
  if {$result == "check"} {  
    if {($wid > 100) || ($hei > 100)} {
      if {$size == "jpglarge"} {
        set result ok
      } else {
        set result wrongsize
      }
    } else {
      # small image, both wid and hei max 100.
      if {$size == "jpglarge"} {
        set result wrongsize
      } else {
        set result ok
      }
    }
  }
  vars_to_dict wid hei size result
}

proc det_wid_hei_size {url} {
  if {[regexp {\?size=(\d+),(\d+).+\$(jpg[a-z]+)\$} $url z wid hei size]} {
    return [list check $wid $hei $size]
  }
  set wid ""
  set hei ""
  set size ""
  regexp {wid=(\d+)} $url z wid
  regexp {hei=(\d+)} $url z hei
  regexp {\$(jpg[a-z]+)\$} $url z size
  if {($wid != "") && ($hei != "") && ($size != "")} {
    return [list check $wid $hei $size]
  }
  if {($wid != "") || ($hei != "") || ($size != "")} {
    return [list missing $wid $hei $size]
  }
  return [list other "" "" ""]
}

# @todo dit is een goede om memoize te gebruiken, vgl clojure.
# @todo omniture url's evt negeren.
proc det_base_url {db date scriptname page_seq} {
  global base_url
  if {[array get base_url "$scriptname/$page_seq"] != ""} {
    return [dict create baseurl $base_url($scriptname/$page_seq)]
  } else {
    set url [:url [:0 [$db query "select url 
                                  from pageitem
                                  where ts_cet > '$date' and 1*page_seq = $page_seq
                                  and 1*record_seq = (
                                    select min(1*record_seq) 
                                    from pageitem
                                    where ts_cet > '$date' and 1*page_seq = $page_seq
                                    and not domain = 'philips.112.2o7.net'
                                  )
                                  union
                                  select url 
                                  from pageitem
                                  where ts_cet > '$date' and 1*page_seq = $page_seq
                                  and 1*resource_id = (
                                    select min(1*resource_id) 
                                    from pageitem
                                    where ts_cet > '$date' and 1*page_seq = $page_seq
                                    and not domain = 'philips.112.2o7.net'
                                  )
                                  limit 1"]]]
    set base_url($scriptname/$page_seq) $url
    return [dict create baseurl $url]
  }
  # where resource_id = 1 voor mobile.
  # ook voor de rest? en hoe zit het met omniture tags?
  # ook record_seq
  
}

# @todo dit is een goede om memoize te gebruiken, vgl clojure.
# @todo omniture url's evt negeren.
proc det_base_url_old {db date scriptname page_seq} {
  global base_url
  if {[array get base_url "$scriptname/$page_seq"] != ""} {
    return [dict create baseurl $base_url($scriptname/$page_seq)]
  } else {
    set url [:url [:0 [$db query "select url from pageitem 
                                  where ts_cet > '$date' and 1*page_seq = $page_seq and 1*basepage = 1
                                  union
                                  select url 
                                  from pageitem
                                  where ts_cet > '$date' and 1*page_seq = $page_seq
                                  and 1*resource_id = (
                                    select min(1*resource_id) 
                                    from pageitem
                                    where ts_cet > '$date' and 1*page_seq = $page_seq
                                  )
                                  limit 1"]]]
    set base_url($scriptname/$page_seq) $url
    return [dict create baseurl $url]
  }
  # where resource_id = 1 voor mobile.
  # ook voor de rest? en hoe zit het met omniture tags?
  # ook record_seq
  
}




main $argv