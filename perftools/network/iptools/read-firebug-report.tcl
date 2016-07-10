#!/usr/bin/env tclsh86

# read-firebug-report.tcl

package require tdbc::sqlite3
package require Tclx
package require ndv
package require tdom
package require struct::list
package require htmlparse
# htmlparse::mapEscapes $str

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  set conn [open_db "c:/aaa/akamai.db"]
  # set conn [open_db "~/aaa/akamai.db"]
  # set dir "~/Dropbox/Philips/akamai/firebug-report"
  set dir "~/Dropbox/Philips/akamai/firebug"
  # drop nu niet meer doen, evt ook andere dingen inlezen.
  db_eval_try $conn "drop table firebug"
  # eerst geen andere velden als size en reponse time, mss later.
  db_eval_try $conn "create table firebug (ts, reportfile, url, embedded_url, embedded_domain)"
  db_eval $conn "begin transaction"
  set stmt_insert [prepare_insert $conn firebug ts reportfile url embedded_url embedded_domain]
  set ts [det_now]
  foreach reportfile [glob -directory $dir "*.htm*"] {
    log info "reportfile: $reportfile"
    read_report $conn $stmt_insert $ts $reportfile
  }
  db_eval $conn "commit"
  $conn close  
}

proc read_report {conn stmt_insert ts reportfile} {
  if {[already_read $conn $reportfile]} {
    log info "Reportfile already read, continuing: $reportfile"
    return
  }
  set text [read_file $reportfile]
  # inlezen als xml wil niet, tidy erop loslaten ook niet, <canvas> niet begrepen.
  # <td class="url"><a rel="js" href="http://www.philips.nl/philips1/nl/nl/gmm/js/load.js"   
  # onclick="javascript:document.ysview.openLink('http://www.philips.nl/philips1/nl/nl/gmm/js/load.js')
  # >http://www.philips.nl/philips1/nl/nl/gmm/js/load.js</a></td>
  
  regexp {URL:</span><span><a href=\42([^\42]+)\42} $text z url
  set url [htmlparse::mapEscapes $url]
  log info "main_url: $url"
  
  set res [regexp -inline -all { href=\42([^\42]+)\42} $text]
  # log info $res
  foreach {z embedded_url} $res {
    if {[regexp {^javascript:} $embedded_url]} {
      continue ; # geen echte url 
    }
    set embedded_url [htmlparse::mapEscapes $embedded_url]
    set embedded_domain [det_domain $embedded_url]
    log info "Embedded resource: $embedded_url (domain: $embedded_domain)" 
    # breakpoint
    [$stmt_insert execute [vars_to_dict ts reportfile url embedded_url embedded_domain]] close
  }
}

proc already_read {conn reportfile} {
  set res [db_query $conn "select count(*) aantal from firebug where reportfile = '$reportfile'"]
  set rec [lindex $res 0]
  set n [dict get $rec aantal]
  if {$n > 0} {
    return 1 
  } else {
    return 0 
  }
}

proc det_now_old {} {
  clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S" 
}

proc det_domain {url} {
  if {[regexp {://([^/]+)} $url z domain]} {
    return $domain 
  } else {
    return $url 
  }
}

main $argv
