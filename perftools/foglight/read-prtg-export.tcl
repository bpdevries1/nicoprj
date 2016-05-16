#!/usr/bin/env tclsh

# read-prtg-export.tcl

package require ndv
package require tdbc::sqlite3
package require Tclx

source configdata-db.tcl

proc main {} {
  set db [get_config_db "configdata.db"]

  # $db add_tabledef prtginfo {id} {linenr line infotype infovalue}
  $db in_trans {
    $db exec2 "delete from prtginfo"
    set f [open "prtg-export.txt" r]
    set linenr 0
    while {![eof $f]} {
      gets $f line
      incr linenr
      set items [det_infoitems $line]
      foreach item $items {
        set infotype [:infotype $item]
        set infovalue [:infovalue $item]
        $db insert prtginfo [vars_to_dict linenr line infotype infovalue]
      }
    }
    close $f  
    $db exec "delete from prtginfo where infovalue = '127.0.0.1'"
  }
  $db close
}

proc det_infoitems {line} {
  set res {}
  # Mediq Farma DC Oss Probe (10.13.2.211) » ipam.opg.local (IPAM from OSS)
  while {[regexp {^(.*?)(\d+\.\d+\.\d+\.\d+)(.*)$} $line z before ip after]} {
    lappend res [dict create infotype ipnr infovalue $ip]
    set line "$before *** $after"
  }
  while {[regexp {^(.*?)([^ » ]+\.opg\.local)(.*)$} $line z before ip after]} {
    lappend res [dict create infotype ipname infovalue $ip]
    set line "$before *** $after"
  }
  while {[regexp {^(.*?)([^ » ]+\.resource\.intra)(.*)$} $line z before ip after]} {
    lappend res [dict create infotype ipname infovalue $ip]
    set line "$before *** $after"
  }
  return $res 
}

main
