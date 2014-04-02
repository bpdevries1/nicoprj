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
  puts stderr "All actions: [join $action_procs ", "]"
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
  $db add_tabledef ip.agent_phys_loc {id} {agent_name phys_loc phys_loc_type}
  $db add_tabledef ip.kn_agent {id} {agent_loc city backbones ipnr}
  $db add_tabledef ip.ipinfo {id} {ts_cet filename ip hostname city region country loc lat long org postal}
  $db add_tabledef ip.pingresult {id} {ts_cet filename agent_ip dest_ip agent_name contents {ping_min_msec int} {ping_max_msec int} {ping_avg_msec int}}
  $db add_tabledef ip.city_loc {id} {city country {lat real} {long real}}
  $db add_tabledef ip.kn_agent_ok {id} {agent_loc city region country backbones ipnr org {lat real} {long real}}
  
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
  lappend action_procs $procname
  proc $procname {*}$args
}

# fill currently used domains for CN and CQ5.
# @todo do something with temp scripts for eg P4C and search? then use end-date of script also with current date.
# temp-script may have stopped running already.
# wrt goal: not really necessary: if temp script was created, it was already clear that the domains in here are important.
actionproc fill_current {db} {
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
  # $db add_tabledef agent_phys_loc {id} {agent_name phys_loc phys_loc_type}
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
  if {[lsearch -exact {Seoul Singapore Tokyo} $phys_loc] >= 0} {return "near"}
  return "far"
}

# has_cdn op 1 zetten als vanaf verschillende lokaties de ip adressen van een domein echt anders worden.
# andere optie is akamai headers mee te sturen met een request en te kijken of dit ook in response headers zit.


actionproc fill_cq5_domain_phys_loc {db} {
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
      $db exec2 "update cq5_domain set phys_loc = '[format %.0f [:min_msec $row]]ms from CN', phys_loc_type = 'near'
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

# for domains that are marked as 'ignore' in KN scripts -> mark here as both out-of-scope and risk = 0, with a note.
actionproc update_ignored {db} {
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
  $db exec2 "drop table if exists ip.kn_agent_ipinfo"
  $db exec2 "create table ip.kn_agent_ipinfo as
             select k.agent_loc, k.city, i.region, i.country, i.loc, i.city city2, *
             from ip.kn_agent k left join ip.ipinfo i on i.ip = k.ipnr" -log
}

actionproc fill_city_loc {db} {
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

actionproc fill_kn_agent_ok {db} {
  $db exec2 "delete from ip.kn_agent_ok"
  
  $db exec2 "insert into ip.kn_agent_ok (agent_loc, city, region, country, backbones, ipnr, org, lat, long)
             select agent_loc, city, region, country, backbones, ip, org, lat, long
             from ip.kn_agent_ipinfo
             where country not in ('US','CN')"
  $db exec2 "insert into ip.kn_agent_ok (agent_loc, city, region, country, backbones, ipnr, org, lat, long)
             select i.agent_loc, i.city, i.region, i.country, i.backbones, i.ip, i.org, c.lat, c.long
             from ip.kn_agent_ipinfo i
               join city_loc c on i.city = c.city and i.country = c.country
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

actionproc read_ping_results {db} {
  global dargv
  set pingdir [file join [:dnsipdir $dargv] pingresults]
  # $db add_tabledef ip.pingresult {id} {ts_cet filename client_ip dest_ip agent_name contents ping_min_msec ping_max_msec ping_avg_msec}  
  $db in_trans {
    $db exec2 "delete from ip.pingresult"
    set it 0
    foreach filename [glob -directory $pingdir ping-*.html] {
      incr it
      log debug "$it: handling: $filename"
      set contents [read_file $filename]
      set ts_cet [clock format [file atime $filename] -format "%Y-%m-%d %H:%M:%S"]
      lassign [det_agent_dest_ip $filename] agent_ip dest_ip
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
      $db insert ip.pingresult [vars_to_dict ts_cet filename agent_ip dest_ip agent_name contents ping_min_msec ping_max_msec ping_avg_msec]
    }
  }
}
  
proc det_agent_dest_ip {filename} {
  # agent_ip dest_ip  
  # ping-103.245.222.184-111.87.38.15.html (dest_ip - agent_ip)
  if {[regexp {ping-([^\-]+)-([^\-]+)\.html} [file tail $filename] z dest_ip agent_ip]} {
    list $agent_ip $dest_ip
  } else {
    error "Cannot parse client and dest ip from: $filename"
  }
} 

actionproc ipinfo_cq5_domain {db} {
  global dargv
  # foreach ip in kn_agent that has no record yet in ipinfo:
  # do curl to ipinfo.io: curl -o ipinfo.json http://ipinfo.io/173.194.118.15
  #   output in main/ipinfo/ipinfo-<ip>.json
  # parse json and put in DB: no db_trans needed.
  set ipinfo_dir [file join [:dnsipdir $dargv] ipinfo]
  file mkdir $ipinfo_dir
  set rows [$db query "select domain, ip_address, random() rnd, src_type
                       from cq5_domain_ip
                       where not ip_address in (select ip from ip.ipinfo)
                       order by 1, 3"]
  log info "Total rows to handle (ipinfo): [:# $rows]"
  set it 0
  set it_handled 0
  set prev_domain "<none>"
  foreach row $rows {
    incr it
    set ip [:ip_address $row]
    if {($prev_domain != [:domain $row]) || ([:src_type $row] == "kn-nslookup")} {
      log debug "$it: Exec curl ipinfo.io for ip: $ip"
      set res [curl_ipinfo $db $ipinfo_dir $ip]
      if {[lsearch {ok IPv6} $res] < 0} {
        log warn "curl_ipinfo did not return ok/IPv6, so break and return"
        break
      }
      incr it_handled
    } else {
      log debug "Domain same as previous, don't do ipinfo for this ip now: $ip"
    }
    set prev_domain [:domain $row]
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

actionproc make_curl_ping {db} {
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

proc puts_curl_pings_old {fo ip_address dargv} {
  puts $fo "# pinging $ip_address from several locations"
  dict_to_vars [json::json2dict [read_file [:config $dargv]]]
   
  foreach host_ip $ping_ips {
    puts $fo "curl -o ping-$ip_address-$host_ip.html \"http://${host_ip}/scripts/diag2.plx?function=ping&target=${ip_address}&ts=$ts\""
  }
  puts $fo ""
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
  
main $argv
