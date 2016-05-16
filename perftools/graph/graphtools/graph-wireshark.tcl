#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

set script_dir [file dirname [info script]]
ndv::source_once [file join $script_dir R-wrapper.tcl]

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/CQ5-CN/Author" "Directory to make graphs for/in (in daily/graphs)"}
    {dbname.arg "packets2.db" "DB name within dir to use"}
    {outformat.arg "png" "Output format (all, png or svg)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {keepcmd "Keep R command file with timestamp"}
    {incr "Incremental: only create graphs if they do not exist yet"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  set r [Rwrapper new $dargv]
  $r main {
    graph_possible $r $dargv
  }
}

proc graph_possible {r dargv} {
  $r dbexec "attach database 'c:/projecten/Philips/CQ5-CN/Author/jtldb-v1.db' as jtl"
  # hier geen left join: de niet gekoppelde packets even vergeten nu.
  $r query "select ua.id, pu.useraction, r.ts_req
            from reqresp r 
              join page_url pu on r.url = pu.lb
              join useraction ua on ua.useraction = pu.useraction
            where r.dest_ip in ('10.128.41.62', '46.30.192.137')
            order by r.packetno_req"
  $r qplot title "Wireshark vs User actions" \
            x ts_req y id xlab "Timestamp (relative)" ylab "User action" \
            geom point colour useraction \
            width 11 height 6

  $r query "select ua.id, pu.useraction, r.ts_req
            from reqresp r 
              join page_url pu on r.url = pu.lb
              join useraction ua on ua.useraction = pu.useraction
              join url_npages unp on unp.lb = pu.lb
            where r.dest_ip in ('10.128.41.62', '46.30.192.137')
            and unp.npages = 1
            order by r.packetno_req"
  $r qplot title "Wireshark vs User actions - unique" \
            x ts_req y id xlab "Timestamp (relative)" ylab "User action" \
            geom point colour useraction \
            width 11 height 6

            
  $r dbexec "detach jtl"
}

# @todo mss domain-dynamic gebruiken, en deze er dan juist vanaf trekken. Wil alleen static items.
proc graph_all_cachehit {r dargv} {
  $r dbexec "drop view if exists s7_nitems_all"
  $r dbexec "create view s7_nitems_all as
              select date_cet, sum(avg_nitems) avg_nitems_all from aggr_sub
              where keyvalue = 'images.philips.com'
              and keytype = 'domain'
              group by 1"
  $r dbexec "drop view if exists s7_nitems_fast"
  # Deze 30 msec heb ik wel meer gebruikt, is wel ok.
  $r dbexec "create view s7_nitems_fast as
              select r.date_cet, 1.0*count(i.id)/r.datacount avg_nitems_fast
              from pageitem i join aggr_run r on r.date_cet = i.date_cet
              where i.domain = 'images.philips.com'
              and 1*i.first_packet_delta <= 30
              group by 1"
  $r query "select a.date_cet date, a.avg_nitems_all, f.avg_nitems_fast, 100.0*f.avg_nitems_fast/a.avg_nitems_all cachehit
            from s7_nitems_all a join s7_nitems_fast f on a.date_cet = f.date_cet
            where a.date_cet < date('now')
            order by 1"
  $r qplot title "Scene7 cachehit ratio" \
            x date y cachehit xlab "Date" ylab "Cache hit ratio (%)" \
            geom line \
            width 11 height 6
}

main $argv

