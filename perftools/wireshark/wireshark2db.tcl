#!/usr/bin/env tclsh86

package require Tclx
package require ndv
package require csv
package require sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] info]

proc main {argv} {
  # global nerrors
  
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/CQ5-CN/Author" "Directory to handle"}
    {pattern.arg "packets2.csv" "Pattern of filenames to read"}
    {loglevel.arg "debug" "Log level (debug, info, warn)"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  read_files $dargv
  
}

proc read_files {dargv} {
  foreach filename [glob -directory [:dir $dargv] [:pattern $dargv]] {
    read_file $filename
    check_parallel $filename
  }
}

proc check_parallel {filename} {
  set dbname [det_dbname $filename]
  set db [dbwrapper new $dbname]
  set open_reqs {}
  set fo [open $filename.checkpar w]
  puts $fo [join [list ts_req ts_resp nconc] "\t"]
  foreach row [$db query "select ts_req, ts_respl from reqresp where dest_ip = '10.128.41.62' order by ts_req"] {
    dict_to_vars $row
    # breakpoint
    # set open_reqs [listc {$i} i <- $open_reqs {$i > $ts_req}]
    set open_reqs [listc {$i} i <- $open_reqs "\$i > $ts_req"]
    lappend open_reqs $ts_respl
    puts $fo [join [list $ts_req $ts_respl [llength $open_reqs]] "\t"]
  }
  close $fo
  $db close
}

proc read_file {filename} {
  set dbname [det_dbname $filename]
  file delete $dbname
  set db [dbwrapper new $dbname]
  create_tables $db
  set f [open $filename r]
  gets $f headerline
  $db in_trans {
    while {![eof $f]} {
      gets $f line
      if {[csv::iscomplete $line]} {
        # in csv nu dest_port eerst en dan src_port
        set packetno ""
        lassign [csv::split $line] packetno ts src_ip dest_ip protocol length info src_port dest_port
        if {$packetno != ""} {
          $db insert packet [vars_to_dict packetno ts src_ip dest_ip protocol length info src_port dest_port]
        }
      } else {
        log warn "Incomplete line: $line"
      }
    }
  }  
  close $f
  create_indexes $db
  post_process $db
  $db close
}

proc det_dbname {filename} {
  return "[file rootname $filename].db"
}

proc create_tables {db} {
  $db add_tabledef packet {id} {{packetno int} {ts real} src_ip dest_ip protocol {length int} info {src_port int} {dest_port int}}
  $db add_tabledef req {id} {{packetno int} {ts real} src_ip dest_ip protocol {length int} info {src_port int} {dest_port int}}
  $db add_tabledef reqresp {id} {{packetno_req int} {ts_req real} src_ip dest_ip protocol info url {src_port int} {dest_port int}
                                 {packetno_respf int} {ts_respf real} {ttfb real}
                                 {packetno_respl int} {ts_respl real} {ttlb real}}
  $db add_tabledef nextreq {id} {{packetno int} {ts_nextreq real}}
  $db create_tables 0 ; # 0: don't drop tables first.
  $db prepare_insert_statements
}

proc create_indexes {db} {
  $db exec2 "create index ix_packet on packet (ts)"
  $db exec2 "create index ix_req on req (ts)"
}

# determine HTTP REQ/RESP based on packets.
proc post_process {db} {
  log info "Post_process: start"
  $db exec2 "insert into req select * from packet where info like 'GET%' or info like 'POST%'" -log
  
  $db exec2 "insert into nextreq (packetno, ts_nextreq)
             select r.packetno, min(r2.ts)
             from req r join req r2 on r2.ts > r.ts
                         and r2.src_ip = r.src_ip
                         and r2.dest_ip = r.dest_ip
                         and r2.src_port = r.src_port
                         and r2.dest_port = r.dest_port
             where r2.ts > r.ts
             group by 1" -log
  
  # @note alleen ts van first en last byte, dan min() en max() te gebruiken. By lastbyte ook checken of ts niet na volgende request ligt, want
  # 'echte' respons niet altijd te zien. Maar volgende request hoeft er niet te zijn.
  # nu even niet:              and l.info like '%HTTP/1.1 %'
  $db function info2url
  $db exec2 "insert into reqresp (packetno_req, ts_req, src_ip, dest_ip, protocol, info, url, src_port, dest_port,
                                  ts_respf, ttfb,
                                  ts_respl, ttlb)
             select r.packetno, r.ts, r.src_ip, r.dest_ip, r.protocol, r.info, info2url(r.info), r.src_port, r.dest_port,
                    min(f.ts) ts_respf, round(min(f.ts)-r.ts, 6),
                    max(l.ts) ts_respf, round(max(l.ts)-r.ts, 6)
             from req r 
               left join packet f on f.src_ip = r.dest_ip and f.dest_ip = r.src_ip and f.src_port = r.dest_port and f.dest_port = r.src_port
               left join packet l on l.src_ip = r.dest_ip and l.dest_ip = r.src_ip and l.src_port = r.dest_port and l.dest_port = r.src_port
               left join nextreq nr on nr.packetno = r.packetno
             where f.ts >= r.ts
             and l.ts >= r.ts
             and (l.ts < nr.ts_nextreq or nr.ts_nextreq is null)
             group by 1,2,3,4,5,6,7,8" -log
             
  log info "Post_process: finished"             
}

proc info2url {info} {
  if {[regexp {(GET|POST) ([^ ]+) } $info z z url]} {
    return $url
  } else {
    return ""
  }
}

proc do_checks {db} {
  # reqresp moet dezelfde records hebben als req: dezelfde aantallen. Als record in 1 voorkomt, moet het ook in de ander.
  # -> klopt bij deze.
  
  # ttfb en ttlb moeten non-negative zijn. -> ok.
  
  # ttlb >= ttfb. -> ok
  
  # geen overlap tussen requests op dezelfde client-port; firstbyte en lastbyte horen bij de goede request.
  # 2 reqresp's op dezelfde src-port die elkaar overlappen.
  
  select *
from reqresp r1 join reqresp r2 on r1.src_ip = r2.src_ip and r1.dest_ip = r2.dest_ip and r1.src_port = r2.src_port and r1.dest_port = r2.dest_port
where r1.packetno_req < r2.packetno_req
and r1.ts_respl >= r2.ts_req;
-> komt idd voor, helaas, 21x.

packet 272 and 439 op src_port 60294
maar 2 gets: jquery.js en groot bg plaatje.

ts_lb = 9.778951
ts_lb = 9.778951, dus dezelfde, wel logisch.

first byte gaat wel goed, alleen lastbyte nog extra check: geen andere req hiervoor. Kijken of dit performt.


}

main $argv
