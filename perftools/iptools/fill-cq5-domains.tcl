#!/usr/bin/env tclsh86

# for use in SQLiteSpy:
if 0 {
 attach 'c:/projecten/Philips/dns-ip/dnsip.db' as ip;
 attach 'c:/projecten/Philips/AllScripts/daily/daily.db' as al;
 attach 'c:/projecten/Philips/KNDL/slotmeta-domains.db' as meta;
}

package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

set script_dir [file dirname [info script]]
ndv::source_once ../keynotetools/libkeynote.tcl

proc main {argv} {
  global dargv
  log debug "argv: $argv"
  set options {
    {cq5db.arg "c:/projecten/Philips/CQ5-CN/cq5-cn-domains.db" "Main CQ5 info DB"}
    {ipdb.arg "c:/projecten/Philips/dns-ip/dnsip.db" "DNS/IP specific data"}
    {alldb.arg "c:/projecten/Philips/AllScripts/daily/daily.db" "AllScripts DB"}
    {metadb.arg "c:/projecten/Philips/KNDL/slotmeta-domains.db" "Meta DB"}
    {dnsipdir.arg "c:/projecten/Philips/dns-ip" "Dir with DNS/IP specific files/db's"}
    {config.arg "~/.config/keynote/nslookup.json" "File with Keynote specific config"}
    {actions.arg "all" "Actions to execute"}
    {h "Show help, including all actions"}
    {loglevel.arg "debug" "Log level (debug, info, warn)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  if {[:h $dargv]} {
    show_help $options $dargv
    exit 1
  }
  fill_cq5_domains $dargv
}

proc show_help {options dargv} {
  global action_procs
  # puts stderr "All actions: [join $action_procs ", "]"
  puts stderr "All actions: "
  foreach el $action_procs {
    puts "[format "%-25s - %s" [:name $el] [:desc $el]]"
  }
  # @todo other options, syntax, like when an unknown option is used.
}

proc fill_cq5_domains {dargv} {
  global action_procs
  set db [dbwrapper new [:cq5db $dargv]]
  # $db exec2 "attach 'c:/projecten/Philips/KNDL/slotmeta-domains.db' as meta"
  $db exec2 "attach '[:ipdb $dargv]' as ip"
  $db exec2 "attach '[:alldb $dargv]' as al" ; # all is a keyword in SQLite.
  $db exec2 "attach '[:metadb $dargv]' as meta"
  prepare_db $db
  
  if {[:actions $dargv] == "all"} {
    set actions $action_procs
  } else {
    set actions [listc {[string trim $el]} el <- [split [:actions $dargv] ","]]
  }
  foreach action $actions {
    $action $db
  }
  
  $db exec2 "detach meta"
  $db exec2 "detach al"
  $db exec2 "detach ip"
  $db close
}

proc prepare_db {db} {
  # @todo check if attached-db works here.
  
  # cq5_cn database
  $db add_tabledef cq5_domain_ip_oct3 {id} {domain ip_oct3 phys_loc phys_loc_type {confidence real} notes}
  
  # ip database
  $db add_tabledef ip.agent_phys_loc {id} {agent_name phys_loc phys_loc_type}
  $db add_tabledef ip.kn_agent {id} {agent_loc city backbones ipnr}
  $db add_tabledef ip.ipinfo {id} {ts_cet filename ip hostname city region country loc lat long org postal}
  $db add_tabledef ip.pingresult {id} {ts_cet filename agent_ip dest_ip dest_ip_oct3 agent_name contents {ping_min_msec int} {ping_max_msec int} {ping_avg_msec int}}
  $db add_tabledef ip.notping {id} {ip_address ip_oct3}
  $db add_tabledef ip.city_loc {id} {city country {lat real} {long real}}
  $db add_tabledef ip.kn_agent_ok {id} {agent_loc city region country backbones ipnr org {lat real} {long real}}
  $db add_tabledef ip.key_city {id} {city}
  $db add_tabledef ip.ip_phys_loc {id} {domain ip_address ip_oct3 source phys_loc_type city country {lat real} {long real} {msec int} {dist_cn_km real} {confidence real}}
  
  $db create_tables 0
  $db prepare_insert_statements
}

# define a proc, add its name to global actions_procs
# @todo also do something with dependencies? Only if cmdline params request this.
# this could work both ways:
# procA is requested; procB is dependent on results of procA, so should also be done.
# procB is requested; procB is dependent on results of procA, so procA should be done first (like make).
# @todo: record how long the action took, and when it was run.
proc actionproc {procname args} {
  global action_procs
  if {[:# $args] == 2} {
    # normal args, body
    lappend action_procs [dict create name $procname desc ""]
    proc $procname {*}$args
  } elseif {[:# $args] == 3} {
    # description of procedure before args, compare Clojure
    lappend action_procs [dict create name $procname desc [:0 $args]]
    proc $procname {*}[lrange $args 1 end]
  }
}

# fill currently used domains for CN and CQ5.
# @todo do something with temp scripts for eg P4C and search? then use end-date of script also with current date.
# temp-script may have stopped running already.
# wrt goal: not really necessary: if temp script was created, it was already clear that the domains in here are important.
actionproc fill_current "fill currently used domains for CN and CQ5." {db} {
  $db exec2 "drop table if exists cn_curr_domains"
  $db exec2 "create table cn_curr_domains as
              select distinct s.scriptname, s.keyvalue domain, s.date_cet
              from al.aggr_sub s 
                join meta.slot_download md on s.scriptname = md.dirname
                join meta.slot_meta mt on md.slot_id = mt.slot_id
              where s.keytype = 'domain'
              and (mt.agent_name like '%Beijing%' or mt.agent_name like '%Mainland China%')
              and s.date_cet >= date('now', '-2 days')" -log
  # => duurde 47sec, 42 domains.

  $db exec2 "drop table if exists cq5_curr_domains"
  $db exec2 "create table cq5_curr_domains as
              select distinct s.scriptname, s.keyvalue domain, s.date_cet
              from al.aggr_sub s 
              where s.keytype = 'domain'
              and (s.scriptname like 'CBF-US%' or s.scriptname like 'CBF-UK%' or s.scriptname like 'CBF-DE%')
              and s.date_cet >= date('now', '-2 days')" -log
  # => 7 sec, 62 domains.
}

actionproc create_cq5_domain {db} {
  $db exec2 "drop table if exists cq5_domain"
  $db exec2 "create table cq5_domain (domain, cn_curr int, cq5_curr int, 
                                      risk int, risc_reason, inscope int, phys_loc, phys_loc_type, has_cdn int, cdnloc, originloc, dynamic, usage, notes)"
  $db exec2 "insert into cq5_domain (domain, cn_curr, cq5_curr)
             select distinct cn.domain, 1, 1
             from cn_curr_domains cn
                join cq5_curr_domains cq5 on cn.domain = cq5.domain
             where cn.domain != ':'" -log
  $db exec2 "insert into cq5_domain (domain, cn_curr, cq5_curr)
             select distinct cn.domain, 1, 0
             from cn_curr_domains cn
             where not cn.domain in (
               select distinct domain from cq5_curr_domains
             )" -log
  $db exec2 "insert into cq5_domain (domain, cn_curr, cq5_curr)
             select distinct cq5.domain, 0, 1
             from cq5_curr_domains cq5
             where not cq5.domain in (
               select distinct domain from cn_curr_domains
             )" -log

}

actionproc fill_ip_min_connect {db} {
  # aggr_connect_time - filled by extra_aggr_connect in scatter2db.tcl
  $db exec2 "drop table if exists ip.min_min_conn"
  $db exec2 "create table ip.min_min_conn as
              select a.date_cet date_cet, a.ip_address ip_address, 
                     a.topdomain topdomain, a.domain domain, min(a.min_conn_msec) min_min_msec
              from al.aggr_connect_time a
              where a.date_cet >= date('now', '-2 days')
              and a.ip_address <> '0.0.0.0'
              group by 1,2,3,4" -log
  
  $db exec2 "drop table if exists ip.ip_min_connect"
  $db exec2 "create table ip.ip_min_connect as
              select mc.date_cet date_cet, mc.ip_address ip_address, mc.topdomain topdomain, 
                     mc.domain domain, mc.min_min_msec min_min_msec, 
                     a.scriptname scriptname, mt.agent_name agent_name
              from ip.min_min_conn mc 
                join al.aggr_connect_time a on a.date_cet = mc.date_cet and a.ip_address = mc.ip_address and a.topdomain = mc.topdomain and a.domain = mc.domain
                join meta.slot_download md on a.scriptname = md.dirname
                join meta.slot_meta mt on md.slot_id = mt.slot_id
              where mc.min_min_msec = a.min_conn_msec
              and mc.date_cet >= date('now', '-2 days')" -log
}

actionproc create_agent_phys_loc {db} {
  $db in_trans {
    $db exec2 "delete from ip.agent_phys_loc"
    foreach row [$db query "select distinct agent_name from ip.ip_min_connect"] {
      set agent_name [:agent_name $row]
      set phys_loc [det_phys_loc $agent_name]
      set phys_loc_type [det_phys_loc_type $phys_loc]
        $db insert ip.agent_phys_loc [vars_to_dict agent_name phys_loc phys_loc_type]
      }  
  }
}

proc det_phys_loc {agent_name} {
  if {$agent_name == "HF Trans Mainland China"} {return "Beijing"}
  if {[regexp -- {-SG-} $agent_name]} {return "Singapore"}
  foreach city {Amsterdam Beijing Berlin Chennai London Moscow "New York" Paris "Sao Paulo" Seoul Tokyo Warsaw} {
    if {[regexp $city $agent_name]} {return $city}
  }
  return "TODO"
}

proc det_phys_loc_type {phys_loc} {
  if {$phys_loc == "Beijing"} {return "CN"}
  if {[lsearch -exact {"Hong Kong" Seoul Singapore Tokyo} $phys_loc] >= 0} {return "near"}
  return "far"
}

# has_cdn op 1 zetten als vanaf verschillende lokaties de ip adressen van een domein echt anders worden.
# andere optie is akamai headers mee te sturen met een request en te kijken of dit ook in response headers zit.


actionproc fill_cq5_domain_phys_loc_old "Fill cq5_domain.phys_loc(_type) \[OLD\]" {db} {
# bij alle .cn domains zou je kunnen zeggen dat deze in CN zitten.
# beter om toch minimum connect times vanuit CN te checken.

# wanneer in CN: als de minimum connect vanuit een CN lokatie minder dan 10 msec is.

# wanneer near CN: als de minimum connect vanuit een near-CN lokatie minder dan 10 msec is (en niet al in CN).
# phys_loc, phys_loc_type ook in cq5_domain als velden toegevoegd, deze vullen obv ip_min_connect.
  $db in_trans {
    # kan dit (dacht ik) niet voor 'far' doen, omdat een korte conn-tijd vanaf bv London niet alles zegt, dit kan nog een ander IP adres zijn, dus dan alleen IP adressen beschouwen die vanuit CN worden gebruikt.
    # eigenlijk geldt dit ook voor 'near' adressen.
    foreach loctype {CN near} {
      foreach row [$db query "select distinct i.domain, a.phys_loc
                              from ip.ip_min_connect i join ip.agent_phys_loc a on i.agent_name = a.agent_name  
                              where a.phys_loc_type = '$loctype'
                              and i.min_min_msec < 10"] {
        $db exec2 "update cq5_domain set phys_loc = '[:phys_loc $row]', phys_loc_type = '$loctype'
                   where phys_loc is null
                   and domain = '[:domain $row]'"
      }
    }
    # als loctype is CN, en min_min_msec < 30, dan kan je 'em ook op 'near' zetten, alleen is location dan unknown (of <30msec from Beijing, of <nn>msec from Beijing)
    foreach row [$db query "select i.domain, min(min_min_msec) min_msec
                            from ip.ip_min_connect i join ip.agent_phys_loc a on i.agent_name = a.agent_name  
                            where a.phys_loc_type = 'CN'
                            and i.min_min_msec < 30
                            group by 1"] {
      $db exec2 "update cq5_domain set phys_loc = '[format %.0f [:min_msec $row]]ms from Beijing', phys_loc_type = 'near'
                 where phys_loc is null
                 and domain = '[:domain $row]'"
    }

    # @todo
    # voor alle domains die cn_curr = 0 hebben -> bepaal (al gedaan?) wat het IP adres vanuit CN is; kijk hierna
    # of dit IP adres al ergens voorkomt met een snelle connectie tijd. If so, dan is 'ie 'far'.
    # ook als cn_curr = 1: kijk of IP adres al ergens voorkomt. Als voor alle ip-adressen geldt dat ze 'far' zijn, 
    # is het hele domain 'far'.
  }
}

# result: CN, near, far
proc country2loctype {country} {
  if {$country == "CN"} {
    return "CN"
  } elseif {[lsearch {HK JP KR SG TW} $country] >= 0} {
    return "near"
  } else {
    return "far"
  }
}

actionproc update_ignored "for domains that are marked as 'ignore' in KN scripts -> mark here as both out-of-scope and risk = 0, with a note." {db} {
  $db exec2 "update cq5_domain
             set risk = 0, risc_reason = 'ignored domain', inscope = 0, notes = 'ignored domain in Keynote'
             where domain in (
                select distinct domain
                from al.aggr_connect_time a
                where a.date_cet >= date('now', '-2 days')
                and a.ip_address = '0.0.0.0'             
             )" -log
             
  $db exec2 "update cq5_domain
             set risk = 0, risc_reason = 'other country', inscope = 0, notes = 'Other country, not for CN'
             where domain like '%.us' or domain like '%.de' or domain like '%.uk' or domain like '%.usa.philips.%'" -log

  # Facebook not used in China
  $db exec2 "update cq5_domain
             set risk = 0, risc_reason = 'facebook', inscope = 0, notes = 'Facebook not for CN'
             where domain like '%facebook%' or domain like '%fbcdn%'" -log

  # Youtube also not in China
  $db exec2 "update cq5_domain
             set risk = 0, risc_reason = 'youtube', inscope = 0, notes = 'Youtube not for CN'
             where domain like '%youtube%'" -log

  # Twitter also not in China
  $db exec2 "update cq5_domain
             set risk = 0, risc_reason = 'twitter', inscope = 0, notes = 'Twitter not for CN'
             where domain like '%twitter%' or domain like '%twimg%'" -log
  
  # one domain ends with .netNA (cloudfront)
  $db exec2 "update cq5_domain
             set risk = 0, risc_reason = 'invalid', inscope = 0, notes = 'Invalid domain'
             where domain like '%.netNA'" -log
  
             
}


actionproc domain_use_details {db} {
  log info "domain_use_details: start"
  $db exec2 "drop table if exists dom_use_details"
  $db exec2 "create table dom_use_details (scripttype, date_cet, scriptname, page_seq INT, keytype, keyvalue,
               avg_time_sec REAL, avg_nkbytes REAL, avg_nitems REAL)"
  foreach keytype {domain domain_dynamic} {
    foreach table {cn_curr_domains cq5_curr_domains} scripttype {cn cq5} {
      log info "$keytype - $table - $scripttype"
      $db exec2 "insert into dom_use_details (scripttype, date_cet, scriptname, page_seq, keytype, keyvalue,
                     avg_time_sec, avg_nkbytes, avg_nitems)
                 select '$scripttype', date_cet, scriptname, page_seq, keytype, keyvalue,
                       avg_time_sec, avg_nkbytes, avg_nitems
                 from aggr_sub
                 where keytype = '$keytype'
                 and date_cet >= date('now', '-2 days')
                 and scriptname in (
                   select distinct scriptname
                   from $table
                 )" -log
    }
  }
  log info "domain_use_details: finished"
}

proc str_pages {pages} {
  # set pages "pg [join [listc {[:page_seq $el]} el <- $res] ","]"
  
  set str ""
  set prev ""
  set first ""
  foreach pg $pages {
    if {$prev == ""} {
      append str $pg
      set prev $pg
      set first $pg
    } elseif {[expr $prev + 1] == $pg} {
      # extension of current range
      set prev $pg
    } else {
      # new range
      if {$first != ""} {
        if {$prev > $first} {
          append str "-$prev"
        }
      }
      append str ",$pg"
      set first $pg
      set prev $pg
    }
  }
  # finalise?
  if {$first != ""} {
    if {$prev > $first} {
      append str "-$prev"
    }
  }
  return "pg $str"
}

# als alleen static (non-dynamic) content van een domein komt, en phys_loc is CN, maakt het niet uit waar origin zit.
actionproc read_keynote_ips {db} {
  set filename "c:/projecten/Philips/dns-ip/keynote-agents-ips.txt"
  $db in_trans {
    # Agent Location	City	Backbones	Diagnostic Center
    # $db exec2 "create table kn_agent (agent_loc, city, backbones, ipnr)"
    $db exec2 "delete from ip.kn_agent"
    set f [open $filename r]
    gets $f headerline
    while {![eof $f]} {
      set l [split [gets $f] "\t"]
      if {[:# $l] == 4} {
        lassign $l agent_loc city backbones ipnr
        $db insert ip.kn_agent [vars_to_dict agent_loc city backbones ipnr]  
      }
    }
    close $f
  }
}

actionproc ipinfo_kn {db} {
  global dargv
  # foreach ip in kn_agent that has no record yet in ipinfo:
  # do curl to ipinfo.io: curl -o ipinfo.json http://ipinfo.io/173.194.118.15
  #   output in main/ipinfo/ipinfo-<ip>.json
  # parse json and put in DB: no db_trans needed.
  set ipinfo_dir [file join [:dnsipdir $dargv] ipinfo]
  file mkdir $ipinfo_dir
  set rows [$db query "select ipnr from ip.kn_agent where not ipnr in (select ip from ip.ipinfo)"]
  log info "Total rows to handle (ipinfo): [:# $rows]"
  set it 0
  foreach row $rows {
    incr it
    set ip [:ipnr $row]
    log debug "$it: Exec curl ipinfo.io for ip: $ip"
    if {[curl_ipinfo $db $ipinfo_dir $ip] != "ok"} {
      log warn "curl_ipinfo did not return ok, so break and return"
      break
    }
  }
}

proc curl_ipinfo {db ipinfo_dir ip} {
  # only handle IPv4 for now.
  if {[det_iptype $ip] == "IPv6"} {
    log warn "IPv6 address, don't handle, return"
    return "IPv6"
  }
  set filename [file join $ipinfo_dir "ipinfo-$ip.json"]
  # log debug "$it: Exec curl ipinfo.io for ip: $ip"
  exec -ignorestderr [curl_path] --connect-timeout 60 --max-time 120 -o $filename "http://ipinfo.io/$ip"
  if {[file exists $filename]} {
    set json [read_file $filename]
    set dct [json::json2dict $json]
    set lat ""; set long ""
    lassign [split [:loc $dct] ","] lat long
    if {($lat != "") && ($long != "")} {
      set ts_cet [clock format [file atime $filename] -format "%Y-%m-%d %H:%M:%S"]
      $db insert ip.ipinfo [dict merge $dct [vars_to_dict lat long filename ts_cet]]
      return "ok"
    } else {
      log warn "long/lat not found in response json, possibly quata used, so return"
      return "empty"
    }
  } else {
    log warn "Outfile not found: $filename"
  }
}
  
proc det_iptype {ip} {
  if {[regexp {:} $ip]} {
    return "IPv6"
  } elseif {[:# [split $ip "."]] == 4} {
    return "IPv4"
  } else {
    error "Don't know how to determine iptype of ip: $ip"
  }
}

# join kn_agent with ipinfo info to check if agents are located in the right country.
actionproc kn_agent_ipinfo {db} {
  $db function earth_distance
  $db exec2 "drop table if exists ip.kn_agent_ipinfo"
  $db exec2 "create table ip.kn_agent_ipinfo as
             select k.agent_loc, k.city, i.region, i.country, i.loc, i.city city2, 
             round(earth_distance(i.lat, i.long, 39.9, 116.4)) dist_beijing, *
             from ip.kn_agent k left join ip.ipinfo i on i.ip = k.ipnr" -log
}

actionproc fill_city_loc "Fill GPS coordinates for certain cities in CN and US" {db} {
  # $db add_tabledef ip.city_loc {id} {city country {lat real} {long real}}
  $db exec "delete from ip.city_loc"
  
  $db insert ip.city_loc [dict create city Beijing country CN lat 39.9 long 116.4]
  $db insert ip.city_loc [dict create city Shanghai country CN lat 31.2 long 121.5]
  $db insert ip.city_loc [dict create city Tianjin country CN lat 39.1 long 117.2]
  $db insert ip.city_loc [dict create city Wuhan country CN lat 30.6 long 114.3]

  $db insert ip.city_loc [dict create city "Los Angeles" country US lat 37.555 long -122.2867]
  $db insert ip.city_loc [dict create city "New York" country US lat 40.7 long -74.0]
  $db insert ip.city_loc [dict create city "Pittsburgh" country US lat 40.44 long -80.0]
  $db insert ip.city_loc [dict create city "San Francisco" country US lat 37.775 long -122.4194]
  $db insert ip.city_loc [dict create city "Washington D.C." country US lat 38.9 long -77.0]
  $db insert ip.city_loc [dict create city "Washington" country US lat 38.9 long -77.0]
}

actionproc choose_key_cities "Choose 15 important cities to measure from" {db} {
  # use all 4 Chinese agents.
  $db in_trans {
    $db exec2 "delete from ip.key_city"
    foreach city {Bangalore Beijing "Hong Kong" Johannesburg London "Los Angeles" Moscow "New York" "Sao Paulo" Seoul Shanghai Singapore Tianjin Sydney Taipei Tokyo Wuhan} {
      $db insert ip.key_city [dict create city $city]
    }
  }
}

actionproc fill_kn_agent_ok {db} {
  $db exec2 "delete from ip.kn_agent_ok"
  
  $db exec2 "insert into ip.kn_agent_ok (agent_loc, city, region, country, backbones, ipnr, org, lat, long)
             select agent_loc, city, region, country, backbones, ip, org, lat, long
             from ip.kn_agent_ipinfo
             where country not in ('US','CN')"
  $db exec2 "insert into ip.kn_agent_ok (agent_loc, city, region, country, backbones, ipnr, org, lat, long)
             select i.agent_loc, i.city, i.region, i.country, i.backbones, i.ip, i.org, c.lat, c.long
             from ip.kn_agent_ipinfo i
               join ip.city_loc c on i.city = c.city and i.country = c.country
             where i.country in ('CN', 'US')"
}

# fill from both KN script usage and NSLookup from KN agent (in Beijing)
actionproc fill_cq5_domain_ip {db} {
  $db exec2 "drop table if exists cq5_domain_ip"
  
  $db exec2 "create table cq5_domain_ip (domain, src_type, client_loc, ts_cet, ip_address)"
  
  # first from script usage
  $db exec2 "insert into cq5_domain_ip (domain, src_type, client_loc, ts_cet, ip_address)
             select distinct a.domain, 'script', i.phys_loc, datetime('now'), a.ip_address
             from cq5_domain cq
                join al.aggr_connect_time a on a.domain = cq.domain
                join meta.slot_download md on a.scriptname = md.dirname
                join meta.slot_meta mt on md.slot_id = mt.slot_id
                join ip.agent_phys_loc i on i.agent_name = mt.agent_name
             where a.date_cet >= date('now', '-5 days')
             and (mt.agent_name like '%Beijing%' or mt.agent_name like '%Mainland China%')
             and a.ip_address <> '0.0.0.0'" -log         
  
  # then from DNS queries.  
  $db exec2 "insert into cq5_domain_ip (domain, src_type, client_loc, ts_cet, ip_address)
             select distinct cq.domain, 'kn-nslookup', d.dnsserver, d.ts_cet, d.ip_address
             from cq5_domain cq
               join domainip d on cq.domain = d.domain
             where d.dnsserver like '%-BJ-CNC'" -log
             
}

actionproc read_ping_results "Read all ping results (again) from pingresults dir" {db} {
  global dargv
  set pingdir [file join [:dnsipdir $dargv] pingresults]
  # $db add_tabledef ip.pingresult {id} {ts_cet filename client_ip dest_ip dest_ip_oct3 agent_name contents ping_min_msec ping_max_msec ping_avg_msec}  
  $db in_trans {
    $db exec2 "delete from ip.pingresult"
    set it 0
    foreach filename [glob -directory $pingdir ping-*.html] {
      incr it
      log debug "$it: handling: $filename"
      set contents [read_file $filename]
      set ts_cet [clock format [file atime $filename] -format "%Y-%m-%d %H:%M:%S"]
      lassign [det_agent_dest_ip $filename] agent_ip dest_ip
      set dest_ip_oct3 [ip2oct3 $dest_ip]
      if {[regexp {Keynote Diagnostic Center -- ([^\n]+)\n} $contents z ag]} {
        set agent_name $ag
      } else {
        set agent_name "<unknown>"
      }
      if {![regexp {Minimum = (\d+)ms, Maximum = (\d+)ms, Average = (\d+)ms} $contents z ping_min_msec ping_max_msec ping_avg_msec]} {
        set ping_min_msec ""
        set ping_max_msec ""
        set ping_avg_msec ""
      }
      $db insert ip.pingresult [vars_to_dict ts_cet filename agent_ip dest_ip dest_ip_oct3 agent_name contents ping_min_msec ping_max_msec ping_avg_msec]
    }
  }
}
  
proc det_agent_dest_ip {filename} {
  # agent_ip dest_ip  
  # ping-103.245.222.184-111.87.38.15.html (dest_ip - agent_ip)
  if {[regexp {ping-([^\-]+)-([^\-]+).*\.html} [file tail $filename] z dest_ip agent_ip]} {
    list $agent_ip $dest_ip
  } else {
    error "Cannot parse client and dest ip from: $filename"
  }
} 

actionproc fill_notping "Fill notping table" {db} {
  $db exec2 "delete from ip.notping"
  $db exec2 "insert into ip.notping (ip_address, ip_oct3)
             select distinct p.dest_ip, p.dest_ip_oct3
             from ip.pingresult p
             where (ping_min_msec is null or ping_min_msec = '')
             and not p.dest_ip in (
               select p2.dest_ip
               from ip.pingresult p2
               where ping_min_msec >= 0
               and ping_min_msec is not null
               and ping_min_msec <> ''
             )" -log
}

actionproc ipinfo_cq5_domain {db} {
  global dargv
  # foreach ip in kn_agent that has no record yet in ipinfo:
  # do curl to ipinfo.io: curl -o ipinfo.json http://ipinfo.io/173.194.118.15
  #   output in main/ipinfo/ipinfo-<ip>.json
  # parse json and put in DB: no db_trans needed.
  $db function ip2oct3
  set ipinfo_dir [file join [:dnsipdir $dargv] ipinfo]
  file mkdir $ipinfo_dir
  set rows [$db query "select domain, ip_address, random() rnd, src_type, ip2oct3(ip_address) ip_oct3
                       from cq5_domain_ip
                       where not ip_address in (select ip from ip.ipinfo)
                       order by 5, 3"]
  log info "Total rows to handle (ipinfo): [:# $rows]"
  set it 0
  set it_handled 0
  set prev_domain "<none>"
  set prev_oct3 "<none>"
  foreach row $rows {
    incr it
    set ip [:ip_address $row]
    if {($prev_oct3 != [:ip_oct3 $row]) || ([:src_type $row] == "kn-nslookup")} {
      log debug "$it: Exec curl ipinfo.io for ip: $ip"
      set res [curl_ipinfo $db $ipinfo_dir $ip]
      if {[lsearch {ok IPv6} $res] < 0} {
        log warn "curl_ipinfo did not return ok/IPv6, so break and return"
        break
      }
      incr it_handled
      
      if {$it_handled >= 100} {
        log warn "Handled 100 items, break now"
        break
      }
    } else {
      log debug "IP_oct3 same as previous, don't do ipinfo for this ip now: $ip"
    }
    set prev_domain [:domain $row]
    set prev_oct3 [:ip_oct3 $row]
  }
  log info "Total ip's to consider: $it"
  log info "Total ip's handled: $it_handled"
}

actionproc test_distance {db} {
  $db function earth_distance
  set res [$db query "select earth_distance(49.2000, -98.1000, 35.9939, -78.8989) dist"]
  log info "Result of distance: [:dist [:0 $res]]"
  
  # find closest agent to 173.194.43.15
  set res [$db query "select i.city srv_city, k.city kn_city, earth_distance(i.lat, i.long, k.lat, k.long) dist
                      from ip.kn_agent_ok k join ip.ipinfo i
                      where i.ip = '173.194.43.15'
                      order by 3
                      limit 10"]
  foreach row $res {
    log info $row
  }  
}

actionproc make_curl_ping "Make ping shell file for each IP in cq5_domain_ip/ipinfo for nearest KN agent." {db} {
  global dargv
  dict_to_vars [json::json2dict [read_file [:config $dargv]]] ; # ts var among others.
  set outdir [file join [:dnsipdir $dargv] pingresults]
  set dt [clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]
  $db function earth_distance
  #First only cq5_domain_ip.src_type = kn-nslookup
  #164, with a few IPv6 to ignore for now.
  # query in random order, so similar IP's will not be done around the same time and to the same KN agent.
  set res [$db query "select c.ip_address, i.lat, i.long, i.city, i.country, random() rnd
                      from cq5_domain_ip c
                      join ip.ipinfo i on i.ip = c.ip_address
                      where c.src_type = 'kn-nslookup'
                      order by rnd"]
  set fo [open [file join $outdir "do-pings-$dt.sh"] w]                      
  fconfigure $fo -translation lf
  # puts $fo "@echo off" ; # no, it's a shell script.
  set it 0
  foreach row $res {
    incr it
    dict_to_vars $row
    if {[det_iptype $ip_address] != "IPv4"} {
      puts $fo "echo \"$it: IP is not IPv4: $ip_address\""
      continue
    }
    puts $fo "echo \"$it: Ping $ip_address ($city in $country, $lat/$long) from nearest KN agent\""
    set res2 [$db query "select k.city kn_city, k.country kn_country, k.ipnr kn_ip,
                                round(earth_distance($lat, $long, k.lat, k.long),0) dist, k.lat kn_lat, k.long kn_long
                      from ip.kn_agent_ok k
                      order by dist
                      limit 1"]
    if {[:# $res2] == 1} {
      dict_to_vars [:0 $res2]
      puts $fo "echo \"closest agent: $kn_ip ($kn_city in $kn_country, $kn_lat, $kn_long), dist=$dist km, min. roundtrip=[format %.0f [expr 2.0*$dist/300]]msec\""
      puts $fo "curl -o ping-$ip_address-$kn_ip-$dt.html \"http://${kn_ip}/scripts/diag2.plx?function=ping&target=${ip_address}&ts=$ts\""
    } else {
      puts $fo "echo \"No Keynote agent found, probably error in code\""
    }
  
  }                   
  close $fo                        
}

actionproc make_ping_key_cities \
  "Make curl ping cmds for key (#15) cities for IP's with long ping times" {db} {
  # different here from make_curl_ping:
  # - which IP's: already pingtime available (not null, empty), longer than 10 msec.
  # - which agents: from 15 cities in key_city
  # - not already a ping done from this location: check ping_result.agent_name does not contain city.
  #
  # options:
  # - either this is the main function, and calls helper functions. -> first try this one.
  # - directly call a 'framework' function, with some params possibly including callbacks.
  global dargv
  dict_to_vars [json::json2dict [read_file [:config $dargv]]] ; # ts var among others.
  set dt [clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]
  set fo [ping_file_open $dt]
  # @todo query in random order, so similar IP's will not be done around the same time and to the same KN agent.
  set key_cities [det_key_cities $db]
  # @note 13-4-2014 part after union: after cq5_domain is updated with all ping results etc, for some 15 domains no info yet, so do the ping (provided not in the (much shorter, #38) notping table)
  set res [$db query "select distinct c.ip_address ip_address, '15' pingtype
                      from cq5_domain_ip c
                        join ip.pingresult p on c.ip_address = p.dest_ip
                      where c.src_type = 'kn-nslookup'
                      and 1*p.ping_min_msec > 10
                      and not c.ip_address in (
                        select p2.dest_ip
                        from ip.pingresult p2
                        where 1*p2.ping_min_msec <= 10
                      )
                      union
                      select distinct c.ip_address ip_address, '1' pingtype
                      from cq5_domain_ip c
                        join cq5_domain cd on cd.domain = c.domain
                      where cd.phys_loc is null
                      and cd.inscope is null 
                      and not c.ip_address in (select ip_address from ip.notping)
                      and not c.ip_address in (select dest_ip from ip.pingresult where ping_min_msec >= 0 and ping_min_msec <> '')
                      order by 1"]  
  log info "FOUND some IP's to make ping script for, check for some specifics"
  # breakpoint
  foreach row $res {
    puts $fo "# Handling $row"
    if {[:pingtype $row] == "15"} {
      foreach city $key_cities {
        if {[ping_already_done $db $city [:ip_address $row]]} {
          # already did this, continue
          continue
        }
        set agent_ip [det_random_agent $db $city]
        puts $fo "# writing cmd for $city (agent_ip=$agent_ip)"
        ping_file_write $fo [:ip_address $row] $agent_ip $dt $ts
      }
    } else {
      # first try with just one, maybe this one cannot be pinged, no need to check ping_already_done
      set city "Amsterdam"
      set agent_ip [det_random_agent $db $city]
      # breakpoint
      ping_file_write $fo [:ip_address $row] $agent_ip $dt $ts
    }
  }  
  close $fo
}

proc ping_already_done {db city ip} {
  if {$city == "Shanghai"} {
    set res [$db query "select id from pingresult where agent_name like '%Master Server%' and dest_ip = '$ip'"]
  } else {
    set res [$db query "select id from pingresult where agent_name like '%$city%' and dest_ip = '$ip'"]
  }
  if {[:# $res] > 0} {
    return 1
  } else {
    return 0
  }
}

proc det_key_cities {db} {
  set res [$db query "select city from ip.key_city"]
  listc {[:city $el]} el <- $res
}

proc det_random_agent {db city} {
  :ipnr [:0 [$db query "select ipnr, random() rnd from ip.kn_agent_ok where city='$city' order by rnd limit 1"]]
}

proc ping_file_open {dt} {
  global dargv
  set outdir [file join [:dnsipdir $dargv] pingresults]
  set fo [open [file join $outdir "do-pings-$dt.sh"] w]   
  fconfigure $fo -translation lf  
  return $fo
}

proc ping_file_write {fo ip_address kn_ip dt ts} {
  puts $fo "curl -o ping-$ip_address-$kn_ip-$dt.html \"http://${kn_ip}/scripts/diag2.plx?function=ping&target=${ip_address}&ts=$ts\""
}

# @todo deze wellicht verplaatsen naar beneden, kan pas als o.a. pingresults verwerkt zijn.
# @todo sowieso is actions=all run nog lastig, want je make_ping_key_cities en read_ping_results, met andere actie ertussen.
actionproc fill_ip_phys_loc "Fill ip_phys_loc based on multiple sources" {db} {
  # $db add_tabledef ip.ip_phys_loc {id} {domain ip_address source phys_loc_type city country {lat real} {long real} {msec int} {dist_cn_km real}}
  # fill table based on different sources, no check here if sources conflict, this is done later.
  
  # Sources
  # global: cq5_domain_ip - for which IP's do I want the info/data?
  
  $db exec2 "delete from ip.ip_phys_loc"
  $db function earth_distance
  $db function country2loctype
  $db function ip2oct3
  $db function ping2conf
  
  # ip.ip_min_connect (as before)
  # @note 12-4-2014 if loc_type = 'far' and time <= 10 msec, the location is far (away).
  $db exec2 "insert into ip.ip_phys_loc (domain, ip_address, ip_oct3, source, phys_loc_type, city, msec, confidence)
             select c.domain, c.ip_address, ip2oct3(c.ip_address), 'kn_min_connect', a.phys_loc_type,
                    a.phys_loc city, min(i.min_min_msec) msec, ping2conf(min(i.min_min_msec))
             from cq5_domain_ip c
               join ip.ip_min_connect i on c.ip_address = i.ip_address
               join ip.agent_phys_loc a on i.agent_name = a.agent_name
             where a.phys_loc_type in ('CN', 'near', 'far')
             and i.min_min_msec <= 10
             group by 1,2,3,4,5,6" -log
             
  $db exec2 "insert into ip.ip_phys_loc (domain, ip_address, ip_oct3, source, phys_loc_type, city, msec, confidence)
             select c.domain, c.ip_address, ip2oct3(c.ip_address), 'kn_min_connect_cn_near', 'near' phys_loc_type,
                    cast(min(i.min_min_msec) as integer) || 'msec from Beijing' city, min(i.min_min_msec),
                    ping2conf(min(i.min_min_msec))
             from cq5_domain_ip c
               join ip.ip_min_connect i on c.ip_address = i.ip_address
               join ip.agent_phys_loc a on i.agent_name = a.agent_name
             where a.phys_loc_type in ('CN')
             and i.min_min_msec > 10
             and i.min_min_msec <= 30
             group by 1,2,3,4,5" -log

  # # @todo als min connection time > 10 msec, dan kan het nog steeds boeiend zijn.             
  # 50 msec is 25 msec one-way => 25*300 = 7.500 km, quite a long way.
  $db in_trans { 
    set prev_domain "<none>"
    set prev_ip "<none>"
    
    # @note soort pattern: wil met foreach een lijst door, maar ook bij elk element de gegevens van de vorige row hebben. Lijkt met clojure en lazy lists goed te doen.
    # @note mss wel iets als: set res [query]; foreach el $res el_prev [cons "<none>" $res] {actions}
    set source "kn_min_connect_far"
    set phys_loc_type "far"
    foreach row [$db query "select c.domain, c.ip_address, i.min_min_msec msec, k.lat, k.long, 
                              ip2oct3(c.ip_address) ip_oct3, ping2conf(i.min_min_msec) confidence
                            from cq5_domain_ip c
                              join ip.ip_min_connect i on c.ip_address = i.ip_address
                              join ip.agent_phys_loc a on i.agent_name = a.agent_name  
                              join ip.kn_agent_ok k on k.city = a.phys_loc
                            and i.min_min_msec > 10
                            and i.min_min_msec < 50
                            order by 1,2,3"] {
      dict_to_vars $row
      if {($domain == $prev_domain) && ($ip_address == $prev_ip)} {
        # just want agent with min connect time to ip_address, just need lat/long with it.
        continue
      }
      set dist_agent_bj [earth_distance $lat $long 39.9 116.4] ; #coordinates of Beijing.
      set ping_km [expr $msec * 0.5 * 300]
      set min_server_dist [expr $dist_agent_bj - $ping_km]
      if {$min_server_dist > 5000} {
        # mark server as far away
        $db insert ip.ip_phys_loc [vars_to_dict domain ip_address ip_oct3 source phys_loc_type \
                                   msec confidence lat long]
      }
      set prev_domain $domain
      set prev_ip $ip_address
    }                            
  }

  
  # ip.ipinfo - just as a fallback, if nothing else available.
  $db exec2 "insert into ip.ip_phys_loc (domain, ip_address, ip_oct3, source, phys_loc_type, city, country, lat, long, confidence)
             select distinct c.domain, c.ip_address, ip2oct3(c.ip_address), 'ipinfo', country2loctype(country), city, country, lat, long, 0.2
             from cq5_domain_ip c
               join ip.ipinfo i on c.ip_address = i.ip"
  
  # ip.notping - not really info, but might help to determine what is possible.
  $db exec2 "insert into ip.ip_phys_loc (domain, ip_address, ip_oct3, source, phys_loc_type, confidence)
             select distinct c.domain, c.ip_address, ip2oct3(c.ip_address), 'notping', '?', 0.0
             from cq5_domain_ip c
               join ip.notping n on n.ip_address = c.ip_address"
  
  
  # ip.pingresult - two ways:
  # - minimum pingtime. If more than 1, take closest to Beijing.
  # - all pingtimes <= 10 msec. If more than 1, take closest to Beijing.
  
  # simpel beginnen
  # @todo onderscheid ping_min en ping_10ms.
  # @todo closest to beijing verhaal.
  set res [:0 [$db query "select lat, long from city_loc where city='Beijing'"]]
  set cn_lat [:lat $res]
  set cn_long [:long $res]
  
  # take 2 : ping_10ms 
  # alleen deze? eerst wel, hierna ook op min_msec sorteren en distance)
  # @todo sorteren op msec, dan min_distance. Lijkt wel lastiger met alleen query, zou in theory wel moeten lukken, mss dan nog een view of subselect.
  # ipv || constructor ook een view kunnen maken met minimale waarden, en dan een join hierop. Vervolgens evt weer de view inlinen.
  $db exec2 "insert into ip.ip_phys_loc (domain, ip_address, ip_oct3, source, phys_loc_type, city, country, lat, long, msec, dist_cn_km, confidence)
             select distinct c.domain, c.ip_address, ip2oct3(c.ip_address), 'ping_10ms',
               country2loctype(a.country), a.city, a.country, a.lat, a.long, min(p.ping_min_msec),
               round(earth_distance(a.lat, a.long, $cn_lat, $cn_long)) dist_cn_km,
               ping2conf(min(p.ping_min_msec))
             from cq5_domain_ip c
               join ip.pingresult p on p.dest_ip = c.ip_address
               join ip.kn_agent_ok a on p.agent_ip = a.ipnr
             where p.ping_min_msec <= 10 
             and c.domain||c.ip_address||dist_cn_km in (
               select c2.domain||c2.ip_address||min(round(earth_distance(a2.lat, a2.long, $cn_lat, $cn_long)))
               from cq5_domain_ip c2
               join ip.pingresult p2 on p2.dest_ip = c2.ip_address
               join ip.kn_agent_ok a2 on p2.agent_ip = a2.ipnr
               where p2.ping_min_msec <= 10 
               group by c2.domain, c2.ip_address
             )
             group by 1,2,3,4,5,6,7,8,9,11" -log

  # @todo als min ping result > 10 msec, dan kan het nog steeds boeiend zijn.
  # 50 msec is 25 msec one-way => 25*300 = 7.500 km, quite a long way.
  # alleen query en source zijn anders dan hierboven?
  $db in_trans { 
    set prev_domain "<none>"
    set prev_ip "<none>"
    
    # @note soort pattern: wil met foreach een lijst door, maar ook bij elk element de gegevens van de vorige row hebben. Lijkt met clojure en lazy lists goed te doen.
    # @note mss wel iets als: set res [query]; foreach el $res el_prev [cons "<none>" $res] {actions}
    set source "ping_far"
    set phys_loc_type "far"
    foreach row [$db query "select c.domain, c.ip_address, p.ping_min_msec msec, k.lat, k.long, 
                              ip2oct3(c.ip_address) ip_oct3, ping2conf(p.ping_min_msec) confidence
                            from cq5_domain_ip c
                              join ip.pingresult p on c.ip_address = p.dest_ip
                              join ip.kn_agent_ok k on k.ipnr = p.agent_ip
                            and p.ping_min_msec > 10
                            and p.ping_min_msec < 50
                            order by 1,2,3"] {
      dict_to_vars $row
      if {($domain == $prev_domain) && ($ip_address == $prev_ip)} {
        # just want agent with min connect time to ip_address, just need lat/long with it.
        continue
      }
      set dist_agent_bj [earth_distance $lat $long 39.9 116.4] ; #coordinates of Beijing.
      set ping_km [expr $msec * 0.5 * 300]
      set min_server_dist [expr $dist_agent_bj - $ping_km]
      if {$min_server_dist > 5000} {
        # mark server as far away
        $db insert ip.ip_phys_loc [vars_to_dict domain ip_address ip_oct3 source phys_loc_type \
                                   msec confidence lat long]
      }
      set prev_domain $domain
      set prev_ip $ip_address
    }                            
  }
             
  # check - combi of domain, ip, source should be unique, like a PK.
  log info "Combinations of domain, ip, source with more than 1 row:"
  foreach row [$db query "select domain, ip_address, source, count(*) nr
                          from ip.ip_phys_loc
                          group by 1,2,3
                          having count(*) > 1"] {
    dict_to_vars $row
    puts "$domain, $ip_address, $source => $nr:"
    foreach row2 [$db query "select *
                            from ip.ip_phys_loc
                            where domain = '$domain'
                            and ip_address = '$ip_address'
                            and source = '$source'"] {
      set country ""
      set city ""
      set lat ""
      set long ""
      set dist_cn_km ""
      set msec ""
      dict_to_vars $row2
      # log debug "row2: $row2"
      # log info "  $phys_loc_type, $city, $country, $lat, $long, $msec"
      puts "  $phys_loc_type, $city, $country, $lat, $long, $msec msec, $dist_cn_km km, $confidence conf"
    }                            
  }                          
}

actionproc fill_cq5_domain_ip_oct3 "Summarise results on ip_oct3 level" {db} {
  $db function ip2oct3
  
  $db exec2 "delete from cq5_domain_ip_oct3"

  $db in_trans {
    # don't handle IPv6 addresses.
    foreach row [$db query "select distinct domain, ip_oct3 from ip.ip_phys_loc where not ip_oct3 like '%:%' order by 1,2"] {
      dict_to_vars $row
      # check only on same ip_oct3, could be different domain. A check on this (par 7.8.1) has not revealed inconstencies, still it's a bit tricky
      set res [$db query "select distinct confidence, phys_loc_type, city, country
                          from ip.ip_phys_loc
                          where ip_oct3 = '$ip_oct3'
                          order by 1 desc, 2, 3"]

      check_cq5_domain_ip_oct_result $res

      set row0 [:0 $res]
      # @todo row in res probably has no vars for null-valued columns, so first set them to blanks.
      
      set city ""; set country ""; set confidence ""; set phys_loc_type ""
      dict_to_vars $row0
      set phys_loc "$city/$country"
      $db insert cq5_domain_ip_oct3 [vars_to_dict domain ip_oct3 phys_loc_type phys_loc confidence]
    }
  }
  
  # check if complete from cq5_domain_ip
  log info "domain/ip's in cq5_domain that do not occur in cq5_domain_ip_oct:"
  foreach row [$db query "select * from cq5_domain_ip c
                          where not ip_address like '%:%'
                          and not exists (
                            select 1
                            from cq5_domain_ip_oct3 o
                            where o.domain = c.domain
                            and o.ip_oct3 = ip2oct3(c.ip_address)
                          )"] {
    dict_to_vars $row
    puts "$domain, $ip_address"
  }                          
}

proc check_cq5_domain_ip_oct_result {res} {
  if {[:# $res] < 1} {
    error "Query did not produce results for $domain, $ip_oct3"
  }
  # @todo test: 2 items with same highest confidence, but with different phys_loc_type?
  set conf [:confidence [:0 $res]]
  set loc_type [:phys_loc_type [:0 $res]]
  foreach row $res {
    if {[:confidence $row] >= $conf} {
      if {[:phys_loc_type $row] != $loc_type} {
        error "Different phys_loc_types with same confidence in result: $res"
      }
    } else {
      break ; # reached lower confidences, don't check.
    }
  }
}

# @param loc_types: list of location types (CN, near, far)/
# @return CN if this one occurs, near if that one occurs, otherwise far.
proc det_nearest_loc_type {loc_types} {
  foreach loc_type {CN near far} {
    if {[lsearch $loc_types $loc_type] >= 0} {
      return $loc_type
    }
  }
  return "Unknown"
}

actionproc update_cq5_domain_with_oct3 "Update table cq5_domain based on cq5_domain_ip_oct3" {db} {
  # just update items that have in_scope != 0 (or empty) and don't have phys_loc(_type) set.
  $db in_trans {
    foreach row [$db query "select domain from cq5_domain
                            where (phys_loc is null or phys_loc like '%ms from CN%')"] {
      dict_to_vars $row ; # domain set
      set res2 [$db query "select * from cq5_domain_ip_oct3
                           where domain = '$domain'
                           and confidence > 0.5
                           order by confidence desc"]
      if {[:# $res2] > 0} {
        #check_cq5_domain_ip_oct3_update_result $res2                           
        #set loc_type [:phys_loc_type [:0 $res2]]
        #set row0 [:0 $res2]
        lassign [det_cq5_domain_ip_oct3_locs $res2] phys_loc phys_loc_type
        $db exec2 "update cq5_domain set phys_loc = '$phys_loc', 
                                         phys_loc_type = '$phys_loc_type'
                   where domain = '$domain'" -log
      } else {
        log info "Query did not produce results for $domain, check for some/only notping results"
        # first some
        set res3 [$db query "select 1
                             from cq5_domain_ip c
                               join ip.notping n on n.ip_address = c.ip_address
                             where domain='$domain'"]
        if {[:# $res3] > 0} {
          set some_notping 1
          # look further for all-notping
          set res4 [$db query "select ip_address
                               from cq5_domain_ip c
                               where domain='$domain'
                               and not c.ip_address in (
                                 select n.ip_address
                                 from ip.notping n
                               )"]
          if {[:# $res4] > 0} {
             # some ip_addressen in cq5_domain_ip are not in notping, so should be pingable and therefore work to do
             $db exec2 "update cq5_domain set notes = 'Some IPs not pingable for this domain'
                        where domain = '$domain'" -log
          } else {
             # all not pingable, note in cq5_domain
             $db exec2 "update cq5_domain set notes = 'ALL IPs not pingable for this domain'
                        where domain = '$domain'" -log
          }          

        } else {
          # notping not applicable here, should find another reason.
        }
      }                 
    }                            
  }
}

proc det_cq5_domain_ip_oct3_locs {res} {
  # for all location types (CN, near, far), find the first row and add the row to the results.
  foreach loc_type {CN near far} {set done($loc_type) 0}
  set locs {}
  set loctypes {}
  foreach row $res {
    set loc_type [:phys_loc_type $row]
    if {!$done($loc_type)} {
      lappend locs [:phys_loc $row]
      lappend loctypes $loc_type
      set done($loc_type) 1
    }
  }
  list [join $locs "+"] [join $loctypes "+"]
} 


proc check_cq5_domain_ip_oct3_update_result_old {res} {
  # check if there are rows in res with another loc_type than the first one wiht the highest confidence
  if {[:# $res] < 1} {
    log info "Query did not produce results for $domain"
    return
  }
  # @todo test: 2 items with same highest confidence, but with different phys_loc_type?
  set conf [:confidence [:0 $res]]
  set loc_type [:phys_loc_type [:0 $res]]
  foreach row $res {
    if {[:phys_loc_type $row] != $loc_type} {
      error "Different phys_loc_types with both high confidence in result: $res"
    }
  }
}

# take data from dom_use_details per domain, summarise and put result in cq5_domain.usage and .dynamic
actionproc summarise_dom_use_details {db} {
  $db in_trans {
    $db exec2 "update cq5_domain set dynamic = null, usage = null" -log
    foreach tofield {dynamic usage} keytype {domain_dynamic domain} {
      foreach row [$db query "select distinct keyvalue domain from dom_use_details where keytype = '$keytype'"] {
        set domain [:domain $row]
        set lst_use {}
        foreach scripttype {cn cq5} {
          set use ""
          set res [$db query "select distinct page_seq from dom_use_details 
                              where keytype = '$keytype' and keyvalue = '$domain'
                              and scripttype = '$scripttype'
                              order by 1*page_seq"]
          if {$res != {}} {
            # set pages "pg [join [listc {[:page_seq $el]} el <- $res] ","]"
            set pages [str_pages [listc {[:page_seq $el]} el <- $res]]
            append use $pages
            set res [$db query "select round(avg(avg_time_sec),1) avg_time_sec,
                                       cast(round(avg(avg_nitems)) as integer) avg_nitems,
                                       cast(round(avg(avg_nkbytes)) as integer) avg_nkbytes
                                from dom_use_details 
                                where keytype = '$keytype' and keyvalue = '$domain'
                                and scripttype = '$scripttype'"]
            dict_to_vars [:0 $res] ; # => avg_time_sec, avg_nitems, avg_nkbytes
            append use " - LT=${avg_time_sec}s"
            # 10
            if {$avg_nitems >= 20} {
              append use " - #=$avg_nitems"
            }
            # 200
            if {$avg_nkbytes >= 100} {
              append use " - KB=$avg_nkbytes"
            }
          }
          if {$use != ""} {
            lappend lst_use "$scripttype: $use"
          }
        }
        if {$lst_use != {}} {
          $db exec2 "update cq5_domain set $tofield = '[join $lst_use "; "]' where domain = '$domain'" -log
        }
      }
    }  
  }
}

# @param all in degrees
# ex: earth_distance 49.2000 -98.1000 35.9939 -78.8989 => 2139.4282703766235
proc earth_distance {lat1 long1 lat2 long2} {
  foreach varname {lat1 long1 lat2 long2} {
    set $varname [expr [set $varname] * 3.141592653589793/180]
  }
  set earth_radius 6371.009
  expr $earth_radius * acos(sin($lat1)*sin($lat2) + cos($lat1)*cos($lat2)*cos($long1-$long2))
}
  
proc ip2oct3 {ip} {
  join [lrange [split $ip "."] 0 2] "."
}  
 
# convert pingtime in msec to confidence value from 0 to 1. 
proc ping2conf {msec} {
  if {$msec == ""} {
    return 0.0
  } else {
    if {$msec <= 100} {
      return [format %.2f [expr 1 - 0.01*$msec]]
    } else {
      return 0.0
    }
  }
}  
  
main $argv
