#!/usr/bin/env tclsh86

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
  # for use in SQLiteSpy:
  if 0 {
   attach 'c:/projecten/Philips/dns-ip/dnsip.db' as ip;
   attach 'c:/projecten/Philips/AllScripts/daily/daily.db' as al;
   attach 'c:/projecten/Philips/KNDL/slotmeta-domains.db' as meta;
  }
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
             where domain like '%.us' or domain like '%.de' or domain like '%.uk'" -log

  # Facebook not used in China
  $db exec2 "update cq5_domain
             set risk = 0, risc_reason = 'facebook', inscope = 0, notes = 'Facebook not for CN'
             where domain like '%facebook%' or domain like '%fbcdn%'" -log

  # Youtube also not in China
  $db exec2 "update cq5_domain
             set risk = 0, risc_reason = 'youtube', inscope = 0, notes = 'Youtube not for CN'
             where domain like '%youtube%'" -log
  
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
  
  if 0 {
  "ip": "173.194.118.15",
  "hostname": "gru06s09-in-f15.1e100.net",
  "city": "Mountain View",
  "region": "California",
  "country": "US",
  "loc": "37.4192,-122.0574",
  "org": "AS15169 Google Inc.",
  "postal": "94043"  
  
  $db add_tabledef ip.ipinfo {id} {ts_cet filename ip hostname city region country lat long org postal}
  
  
  }
  
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
    set filename [file join $ipinfo_dir "ipinfo-$ip.json"]
    log debug "$it: Exec curl ipinfo.io for ip: $ip"
    exec -ignorestderr [curl_path] --connect-timeout 60 --max-time 120 -o $filename "http://ipinfo.io/$ip"
    if {[file exists $filename]} {
      set json [read_file $filename]
      set dct [json::json2dict $json]
      lassign [split [:loc $dct] ","] lat long
      set ts_cet [clock format [file atime $filename] -format "%Y-%m-%d %H:%M:%S"]
      $db insert ip.ipinfo [dict merge $dct [vars_to_dict lat long filename ts_cet]]
    } else {
      log warn "Outfile not found: $filename"
    }
  }
}

# join kn_agent with ipinfo info to check if agents are located in the right country.
actionproc kn_agent_ipinfo {db} {
  $db exec2 "drop table if exists ip.kn_agent_ipinfo"
  $db exec2 "create table ip.kn_agent_ipinfo as
             select k.agent_loc, i.city, i.region, i.country, i.loc, *
             from ip.kn_agent k left join ip.ipinfo i on i.ip = k.ipnr" -log
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
  
main $argv
