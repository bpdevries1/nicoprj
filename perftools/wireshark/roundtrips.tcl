#!/home/nico/bin/tclsh

package require Tclx
package require sqlite3
package require tdom

# own package
package require ndv

#::ndv::source_once "platform-$tcl_platform(platform).tcl" ; # load platform specific functions. 
#::ndv::source_once "graphdata-lib.tcl" "find-overlaps.tcl"

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set log [::ndv::CLogger::new_logger [file tail [info script]] info]

proc log {args} {
  global log
  $log {*}$args
}

proc main {argv} {
  set filename [lindex $argv 0]
  sqlite3 db [det_db_name $filename]
  det_roundtrips
  db close
}

# @pre: filename has path info
proc det_db_name {filename} {
  return "[file rootname $filename].db"
}  
  

proc make_db {tmp_db} {
  # sqlite3 db "server3-extra.db"
  sqlite3 db $tmp_db
  db eval "drop table if exists packet"
  db eval "create table packet (packetnum integer primary key, 
            packetsize integer, timestamp float, tsfmt string, ipsrc string, ipdst string,
            portsrc integer, portdst integer, tcpstream integer, tcpflags string, protocols string,
            details, notes string, reqresp string, outerreqresp string)"
  db eval "delete from packet"

  db eval "create index idx_packet_num on packet (packetnum)"
  db eval "create index idx_packet_stream on packet (tcpstream)"

  
  db eval "drop table if exists tcpstream"
  db eval "create table tcpstream (tcpstream integer primary key, first float, last float,
              ipsrc string, ipdst string, portsrc integer, portdst integer)"
  db eval "delete from tcpstream"
  
  db eval "drop table if exists roundtrip"
  db eval "create table roundtrip (req_num integer, resp_num integer, stream integer)"
  db eval "delete from roundtrip"
}

proc read_data {filename} {
  log info "Reading $filename"
  set f [open $filename r]
  set nread 0
  db eval "begin transaction"
  while {![eof $f]} {
    gets $f line
    if {[regexp {<packet>} $line]} {
      set chunk $line 
    } elseif {[regexp {</packet>} $line]} {
      append chunk "\n$line"
      handle_chunk $chunk
      incr nread
      if {$nread % 100 == 0} {
        log info "#read: $nread"
        db eval "commit"
        db eval "begin transaction"
      }
    } else {
      append chunk "\n$line" 
    }
  } 
  db eval "commit"
  close $f  
  log info "Reading $filename: finished"
  
}

proc handle_chunk {chunk} {
  set doc [dom parse $chunk]
  set root [$doc documentElement]
  # log info "Start handling packets"
  # $root nodeName
  set packets [$root selectNodes {/packet}]
  foreach packet $packets {
    handle_packet $packet
    $packet delete
  }
  # $root delete
  $doc delete
}

proc read_data_old {filename} {
  log info "Reading $filename"
  set f [open $filename r]
  set doc [dom parse -channel $f]
  set root [$doc documentElement]
  log info "Start handling packets"
  # $root nodeName
  db eval "begin transaction"
  set packets [$root selectNodes {/pdml/packet}]
  set nread 0
  foreach packet $packets {
    handle_packet $packet
    incr nread
    if {$nread % 100 == 0} {
      log info "#read: $nread" 
    }
  }
  close $f
  db eval "commit"
  log info "Reading $filename: finished"
}

proc handle_packet {packet} {
  log debug "Handling packet: $packet"
  if {![regexp {:tcp} [get_node_attr $packet {proto[@name='frame']/field[@name='frame.protocols']} show]]} {
    # continue
    return
  }
  set num [$packet selectNodes {proto[@name='geninfo']/field[@name='num']}]
  log debug "num: $num"
  set packetnum [$num getAttribute show]
  set packetsize [$num getAttribute size]
  set timestamp [[$packet selectNode {proto[@name='geninfo']/field[@name='timestamp']}] getAttribute value]
  log debug "timestamp: $timestamp"
  set tsfmt [clock format [expr int($timestamp)] -format "%Y-%m-%d %H:%M:%S"][string range [format %.6f [expr $timestamp-int($timestamp)]] 1 end]
  log debug "timestamp_f: $tsfmt"
  # breakpoint
  # [$req @class none]
  set ipsrc [get_node_attr $packet {proto[@name='ip']/field[@name='ip.src']} show]
  set ipdst [get_node_attr $packet {proto[@name='ip']/field[@name='ip.dst']} show]
  # set portsrc [[$packet selectNode {proto[@name='tcp']/field[@name='tcp.srcport']}] getAttribute show]
  set portsrc [get_node_attr $packet {proto[@name='tcp']/field[@name='tcp.srcport']} show]
  # set portdst [[$packet selectNode {proto[@name='tcp']/field[@name='tcp.dstport']}] getAttribute show]
  set portdst [get_node_attr $packet {proto[@name='tcp']/field[@name='tcp.dstport']} show]
  log debug "$ipsrc:$portsrc -> $ipdst:$portdst"
  # set tcpstream [[$packet selectNode {proto[@name='tcp']/field[@name='tcp.stream']}] getAttribute show]
  set tcpstream [get_node_attr $packet {proto[@name='tcp']/field[@name='tcp.stream']} show]
  # breakpoint
  #set syn [[$packet selectNode  {.//field[@name='tcp.flags.syn']}] getAttribute value]
  #set reset [[$packet selectNode {.//field[@name='tcp.flags.reset']}] getAttribute value]
  #set fin [[$packet selectNode {.//field[@name='tcp.flags.fin']}] getAttribute value]
  #log debug "syn: $syn, reset: $reset, fin: $fin"
  # set tcpflags [[$packet selectNode {.//field[@name='tcp.flags']}] getAttribute showname]
  set tcpflags [get_node_attr $packet {.//field[@name='tcp.flags']} showname]
  set protocols [get_node_attr $packet {proto[@name='frame']/field[@name='frame.protocols']} show]
  if {[regexp http $protocols]} {
    set details [det_http_details $packet] 
  } else {
    set details "" 
  }
  log debug "tcp.flags: $tcpflags"
  db eval {insert into packet (packetnum, packetsize, timestamp, tsfmt, ipsrc, ipdst,
          portsrc, portdst, tcpstream, tcpflags, protocols, details) 
          values ($packetnum, $packetsize, $timestamp, $tsfmt,
          $ipsrc, $ipdst, $portsrc, $portdst, $tcpstream, $tcpflags, $protocols, $details)}
  
}

proc get_node_attr {parent xpath attrname} {
  set node [$parent selectNode $xpath]
  if {[llength $node] > 1} {
    # breakpoint
    log warn "More than 1 element found for $parent, $xpath, $attrname => $node, selecting first"
    set node [lindex $node 0]
  }
  if {$node != ""} {
    $node getAttribute $attrname 
  } else {
    return "" 
  }
}

# set notes-field to 'first' or 'last', if the packet is the first/last in the tcp.stream
proc set_first_last_packet {} {
  
  log info "set_first_last_packet: start"
  db eval "update packet
  set notes = 'first'
  where not exists (
    select 1 from packet p2
    where packet.tcpstream = p2.tcpstream
    and p2.packetnum < packet.packetnum
  )"
  
  log info "set packet-last"
  db eval "update packet
  set notes = 'last'
  where not exists (
    select 1 from packet p2
    where packet.tcpstream = p2.tcpstream
    and p2.packetnum > packet.packetnum
  )
  and notes is null"
  
  if {0} {
  
  # take 2
  db eval "create index packet_stream_num on packet (tcpstream, packetnum)"
  
  db eval "update packet
  set notes = 'last'
  where notes is null 
  and not exists (
    select 1 from packet p2
    where packet.tcpstream = p2.tcpstream
    and p2.packetnum > packet.packetnum
  )"
  }

  log info "set packet-first-last"
  db eval "update packet
  set notes = 'first-last'
  where notes = 'first'
  and not exists (
    select 1 from packet p2
    where packet.tcpstream = p2.tcpstream
    and p2.packetnum > packet.packetnum
  )"

# create table tcpstream (tcpstream integer primary key, first float, last float,
#              ipsrc string, ipdst string, portsrc integer, portdst integer)

  log info "insert into tcpstream"
  db eval "insert into tcpstream (tcpstream, first, last, ipsrc, ipdst, portsrc, portdst)
           select f.tcpstream, f.timestamp, l.timestamp, f.ipsrc, f.ipdst, f.portsrc, f.portdst
           from packet f, packet l
           where f.notes like 'first%'
           and l.notes like '%last'
           and f.tcpstream = l.tcpstream"

  # tijdelijk: alles weg wat niet van/naar mijn ip gaat, mogelijk met een hub te maken.
  # db eval "delete from tcpstream where ipsrc != '10.16.16.205' and ipdst != '10.16.16.205'"
  log info "set_first_last_packet: finished"

}

proc det_roundtrips {} {
  log info "det_roundtrips"
  
  # first clean up
  db eval "update packet set reqresp = null"
  db eval "drop table if exists rt_temp"
  db eval "delete from roundtrip"
  
  db eval "update packet set reqresp = 'REQ'
           where protocols like '%http%' 
           and (details like 'GET%' or details like 'POST%' or details like '\[truncated\] POST%')"
  db eval "update packet set reqresp = 'RESP'
           where protocols like '%http%' 
           and details like 'HTTP/%'"
  
  # rt_temp: combi's of resp of previous roundtrip and the req of the current one: no reqs/resps in between those 2.
  db eval "create table rt_temp (resp_num, req_num, stream)"
  db eval "insert into rt_temp (resp_num, req_num, stream)
            select presp.packetnum, preq.packetnum, presp.tcpstream
            from packet presp, packet preq
            where presp.tcpstream = preq.tcpstream
            and presp.reqresp = 'RESP'
            and preq.reqresp = 'REQ'
            and presp.packetnum < preq.packetnum
            and not exists (
              select 1
              from packet p3
              where p3.tcpstream = presp.tcpstream
              and p3.packetnum between presp.packetnum + 1 and preq.packetnum - 1
              and p3.reqresp is not null 
            )"

  # update main table with this info
  db eval "update packet set outerreqresp = 'OUTERREQ'
           where packetnum in (select req_num from rt_temp)"
  db eval "update packet set outerreqresp = 'OUTERRESP'
           where packetnum in (select resp_num from rt_temp)"
  # also the first REQ and last RESP of each stream:
  db eval "update packet set outerreqresp = 'OUTERREQ'
           where reqresp = 'REQ'
           and not exists (
             select 1
             from packet p2
             where p2.tcpstream = packet.tcpstream
             and p2.packetnum < packet.packetnum
             and p2.reqresp = 'REQ'
           )"
  db eval "update packet set outerreqresp = 'OUTERRESP'
           where reqresp = 'RESP'
           and not exists (
             select 1
             from packet p2
             where p2.tcpstream = packet.tcpstream
             and p2.packetnum > packet.packetnum
             and p2.reqresp = 'RESP'
           )"              
  
  # db eval "create index rt_temp1 on rt_temp ..."
  db eval "insert into roundtrip
           select p1.packetnum, p2.packetnum, p1.tcpstream
           from packet p1, packet p2
           where p1.tcpstream = p2.tcpstream
           and p1.packetnum < p2.packetnum
           and p1.outerreqresp = 'OUTERREQ'
           and p2.outerreqresp = 'OUTERRESP'
           and not exists (
             select 1
             from packet p3
             where p3.tcpstream = p1.tcpstream
             and p3.packetnum between p1.packetnum + 1 and p2.packetnum - 1
             and p3.outerreqresp is not null
           )"
}

# @return: GET/POST or HTTP 200 ok 
proc det_http_details {packet} {
  set num [$packet selectNodes {proto[@name='geninfo']/field[@name='num']}]
  set packetnum [$num getAttribute show]
     
  set res [get_node_attr $packet {proto[@name='http']/field[@name='']} show]
  if {$res == ""} {
    set res "" ; # request and response set something in the above field. 
  }
  
  if {$packetnum == 1156} {
    # breakpoint 
  }
  # zag nu alleen bij http:data dat de details leeg zijn.
  
  return $res
}

proc check_req_resp {} {
  # check whether no 2 reqs or responses occur after one another in 1 tcpstream, should always be req-resp-res-resp etc.
  # @todo ook naar http kijken!
  select p1.tcpstream, p1.packetnum, p2.packetnum, p1.details, p2.details
  from packet p1, packet p2
  where p1.tcpstream = p2.tcpstream
  and p1.packetnum < p2.packetnum
  and p1.protocols like '%http%'
  and p2.protocols like '%http%'
  and p1.details != ''
  and not exists (
    select 1
    from packet p3
    where p3.tcpstream = p1.tcpstream
    and p3.protocols like '%http%'
    and p3.packetnum between p1.packetnum+1 and p2.packetnum-1
  )
  and p1.ipsrc = p2.ipsrc
  limit 10
  
  # lijkt niet voor te komen...
  
select p1.tcpstream, p1.packetnum, p2.packetnum, p1.details, p2.details
  from packet p1, packet p2
  where p1.tcpstream = p2.tcpstream
  and p1.packetnum < p2.packetnum
  and not exists (
    select 1
    from packet p3
    where p3.tcpstream = p1.tcpstream
    and p3.packetnum between p1.packetnum and p2.packetnum
  )
  and p1.ipsrc != p2.ipsrc
  limit 10
  # vindt ook niets :-(

  select p1.tcpstream, p1.packetnum, p2.packetnum, p1.details, p2.details
  from packet p1, packet p2
  where p1.tcpstream = p2.tcpstream
  and p1.tcpstream = 28
  and p1.protocols like '%http%'
  and p2.protocols like '%http%'
  and p1.packetnum < p2.packetnum
  and not exists (
    select 1
    from packet p3
    where p3.tcpstream = p1.tcpstream
    and p3.packetnum between p1.packetnum+1 and p2.packetnum-1
    and p3.protocols like '%http%'
  )
  limit 10

select p1.tcpstream, p1.packetnum, p2.packetnum, p1.details, p2.details
  from packet p1, packet p2
  where p1.tcpstream = p2.tcpstream
  and p1.tcpstream = 28
  and p1.protocols like '%http%'
  and p2.protocols like '%http%'
  and p1.packetnum < p2.packetnum
  and exists (
    select 1
    from packet p3
    where p3.tcpstream = p1.tcpstream
    and p3.packetnum between p1.packetnum and p2.packetnum
    and p3.protocols like '%http%'
  )
  limit 10  

select p1.tcpstream, p1.packetnum, p2.packetnum, p1.details, p2.details, p3.packetnum
  from packet p1, packet p2, packet p3
  where p1.tcpstream = p2.tcpstream
  and p1.tcpstream = 28
  and p1.protocols like '%http%'
  and p2.protocols like '%http%'
  and p1.packetnum < p2.packetnum
  and p3.tcpstream = p1.tcpstream
  and p3.packetnum between p1.packetnum + 1 and p2.packetnum - 1
  and p3.protocols like '%http%'
  limit 10  


  
  select p1.tcpstream, p1.packetnum, p2.packetnum, p1.details, p2.details
  from packet p1, packet p2
  where p1.tcpstream = p2.tcpstream
  and p1.tcpstream = 28
  and p1.packetnum < p2.packetnum
  and p1.protocols like '%http%'
  and p2.protocols like '%http%'
  limit 10
  
  
  
}

main $argv

