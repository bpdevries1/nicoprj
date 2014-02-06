#!/usr/bin/env tclsh86

# meta-domains.tcl - Determine excluded domains in Keynote scripts and compare with domains that should be excluded.
# examples: livecom, omniture, eloqua

package require tdbc::sqlite3
package require Tclx
package require ndv
package require tdom

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

# ndv::source_once libslotmeta.tcl download-metadata.tcl
ndv::source_once libslotmeta.tcl
ndv::source_once libkeynote.tcl

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {db.arg "c:/projecten/Philips/KNDL/slotmeta-domains.db" "DB to use"}
    {useddb.arg "c:/projecten/Philips/AllScripts/daily/daily.db" "DB with aggregate data with usage to use"}
    {test "Test the script"}       
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  meta_domains $dargv
}

proc meta_domains {dargv} {
  set db [get_slotmeta_db [:db $dargv]]

  # temp
  # $db exec2 "drop table if exists domainused" -log -try
  
  $db create_tables 0 ; # because added defs
  slotmeta_create_indexes $db
  
  fill_domaindisabled $db
  fill_domainused $db $dargv
  fill_aggregates $db
  fill_domaincontract $db
  update_domaincontract $db
  create_views $db
  $db close
}

# read script texts, determine which domains are disabled in script and fill domaindisabled table with this
proc fill_domaindisabled {db} {
  # @todo later alleen incremental uitvoeren.
  $db exec2 "delete from domaindisabled" -log
  
  set res [$db query "select id script_id, slot_id, ts_cet script_ts_cet, contents
                      from script
                      where filesize > 0"]
  $db in_trans {
    foreach row $res {
      dict_to_vars $row
      log info "Handle: $slot_id"
      # set disabled_domains [det_disabled_domains [:contents $row]]
      set disabled_domains [det_disabled_domains $contents]
      foreach d $disabled_domains {
        $db insert domaindisabled [dict merge [vars_to_dict script_id slot_id script_ts_cet] $d]
      }
    }
  }
}

# @return list of dictionaries. Per dict: domainspec, topdomain, domainspectype, ipaddress
proc det_disabled_domains {contents} {
  set doc [dom parse $contents]
  set root [$doc documentElement]
  if {[$root nodeName] != "script"} {
    log warn "Root name != script, return: [$root nodeName]"
    return {}
  }
  set hosts [$root selectNodes -namespaces [list d [$root @xmlns]] {/d:script/d:hosts/d:host}]
  set res {}
  foreach host $hosts {
    try_eval {
      lappend res [det_host_ip_type $host [$root @xmlns]]
    } {
      log warn "Error while parsing host element: $errorResult"
      log warn "Element: [$host asXML]"
    }
  }
  return $res
}

# several ways the host exclusion may be defined.
# return dictionary with domainspec, topdomain, domainspectype and ipaddress
proc det_host_ip_type {host ns} {
  set name [$host @name]
  # set elt [$host selectNodes -namespaces [list d [$root @xmlns]] {d:parameter/d:variable}]
  set elt [$host selectNodes -namespaces [list d $ns] {d:parameter/d:variable}]
  if {[$host hasAttribute ipaddress]} {
    set ipaddress [$host @ipaddress]
  } else {
    if {$elt != ""} {
      set ipaddress [$elt text]
    } else {
      set ipaddress ""
    }
  }
  
  set type ""
  if {[$host hasAttribute RegEx]} {
    set regex [$host @RegEx]
    if {$regex} {
      set type "RegEx"
    }
  }

  if {$type == ""} {
    if {$elt != ""} {
      if {[$elt hasAttribute type]} {
        set type [$elt @type]
      }
    }  
  }
      
  dict create domainspec $name topdomain [det_topdomain $name] domainspectype $type ipaddress $ipaddress
}

proc fill_domainused {db dargv} {
  set srcdbname [:useddb $dargv]
  # test with CN for now:
  # set srcdbname "c:/projecten/Philips/CBF-CN/daily/daily.db" 
  
  # @todo later alleen incremental doen.
  $db exec2 "delete from domainused" -log  
  
  $db exec2 "attach database '$srcdbname' as fromDB"
  # $db add_tabledef domainused {id} {scriptname slot_id domain topdomain date_cet {number real} {sum_nkbytes real} {page_time_sec real}}
  # vb s.scriptname: CBF-CN-AC4076
  # and s.avg_nkbytes > 0 => nu niet, ook checken als nbytes 0 (dus disabled) de tijd ook ongeveer 0 is.
  $db exec2 "insert into domainused (scriptname, slot_id, topdomain, date_cet, number, sum_nkbytes, page_time_sec)
             select s.scriptname, d.slot_id, s.keyvalue, s.date_cet, sum(s.avg_nitems), sum(s.avg_nkbytes), round(sum(s.avg_time_sec)/r.npages,3)
             from fromDB.aggr_sub s 
               join fromDB.aggr_run r on s.date_cet = r.date_cet and s.scriptname = r.scriptname
               join slot_download d on d.dirname = s.scriptname
             where s.keytype = 'topdomain'
             group by 1,2,3,4" -log
  
  $db exec2 "detach fromDB"
}

if {0} {
        select *
        from domainused u join domaindisabled d on u.topdomain = d.topdomain
        where u.date_cet >= '2014-01-28'
        and sum_nkbytes > 0
        and page_time_sec > 0.05
        limit 100;
- notes
  
3 mogelijkheden:
- komt alleen voor in disabled tabel.
  - kleine kans.
  - dan disabled_ist op 1
  - en ook disabled_soll op 1
  - domaintype op 'tracking' zetten als default (?)
  - notes op 'only occurs in disabled'
- komt alleen voor in used tabel.
  - grote kans, bv alle std philips domains.
  - dan disabled_ist op 0
  (- en disabled_soll op 0 -> nee, want dingen als eloqua en mss anderen moeten nog disabled.)
  - domaintype: bv op 'countrypage' als dit van toepassing is.
  - notes 'only occurs in used 2014-01-28'
- komt in beide voor.  
  - komt voor, heb gezien.
  - notes 'occurs in both used 2014-01-28 and disabled'
  - disabled_ist dan op 0.5 -> deels.
  - disabled_soll op 1 -> vanwege uitgangspunt.
  
Kan 3 losse queries doen om te vullen, met 3 distinct row-sets. Dan later checken of domains niet dubbel voorkomen in de doeltabel.

mss eerst disabled_aggr en used_aggr vullen.

disabled_aggr:
- topdomain
- last_script_ts_cet (min of max?) zou zeggen max: zo kort geleden was het nog disabled.

used_aggr:
- topdomain
- date_cet (first 2014-01-28)

  $db add_tabledef domaindisabled_aggr {} {topdomain last_script_ts_cet}
  $db add_tabledef domainused_aggr {} {topdomain date_cet}
  
        select *
        from domainused u join domaindisabled d on u.topdomain = d.topdomain
        where u.date_cet >= '2014-01-28'
        and sum_nkbytes > 0
        and page_time_sec > 0.05
        limit 100;
}
        
proc fill_aggregates {db} {
  $db exec2 "delete from domaindisabled_aggr" -log
  $db exec2 "delete from domainused_aggr" -log
  $db exec2 "insert into domaindisabled_aggr (topdomain, last_script_ts_cet)
             select topdomain, max(script_ts_cet)
             from domaindisabled
             group by 1" -log
  $db exec2 "insert into domainused_aggr (topdomain, date_cet)
             select topdomain, max(date_cet)
             from domainused
             where date_cet >= '2014-01-28'
             and sum_nkbytes > 0
             and page_time_sec > 0.05
             group by 1" -log

}

# $db add_tabledef domaincontract {id} {domain topdomain contractparty domaintype disable_soll disable_ist notes}
proc fill_domaincontract {db} {
  # fill in three stages, based on the possibilies (Venn diagram):
  $db exec2 "delete from domaincontract"
  
  # only in disabled table.
  $db exec2 "insert into domaincontract (topdomain, domaintype, disable_soll, disable_ist, notes)
             select d.topdomain, 'tracking', 1, 1, 'only occurs in disabled ' || d.last_script_ts_cet
             from domaindisabled_aggr d
             where not d.topdomain in (
               select topdomain from domainused_aggr
             )" -log
  
  # only in used table.
  $db exec2 "insert into domaincontract (topdomain, disable_ist, notes)
             select u.topdomain, 0, 'only occurs in used ' || u.date_cet
             from domainused_aggr u
             where not u.topdomain in (
               select topdomain from domaindisabled_aggr
             )" -log

  # occurs in both
  $db exec2 "insert into domaincontract (topdomain, disable_soll, disable_ist, notes)
             select d.topdomain, 1, 0.5, 'occurs in both used and disabled ' || d.last_script_ts_cet
             from domaindisabled_aggr d join domainused_aggr u on d.topdomain = u.topdomain" -log
  
}

proc update_domaincontract {db} {
  $db exec2 "update domaincontract
             set contractparty = 'Error', domaintype = 'Error', notes = 'Error, change script'
             where topdomain = 'http(s|)\:\/\/\:\/ '" -log
  $db exec2 "update domaincontract
             set contractparty = 'Error', domaintype = 'Error', notes = 'Error (space in domainname), change script'
             where topdomain like '% %'" -log
  $db exec2 "update domaincontract
             set contractparty = 'Philips', domaintype = 'Main site', notes = 'Main Philips page'
             where topdomain like '%philips%'" -log
  $db exec2 "update domaincontract
             set contractparty = 'Google', domaintype = '?'
             where topdomain like '%google%' or topdomain like '%gstatic%'" -log
  $db exec2 "update domaincontract
             set contractparty = 'Eloqua', domaintype = 'tracking', notes = 'Should disable', disable_soll = 1
             where topdomain like '%eloqua%' or topdomain = 'en25.com'" -log
  $db exec2 "update domaincontract
             set contractparty = 'Facebook', domaintype = '?', notes = 'Contract with Facebook?'
             where topdomain like '%facebook%' or topdomain = 'fbcdn.net'" -log
             
  mark_contract $db "scene7" "Scene 7" "Images" "images.philips.com"
  mark_contract $db "scene7.com" "Scene 7" "?" "scene7.com should not be used (?)"
  mark_contract $db "addthis.com" "?" "tracking?" "Should disable?"
  mark_contract $db "akamai.net" "Akamai/Scene 7" "images?" "Secure Scene 7 images, should change to images.philips.com"
  mark_contract $db "bazaarvoice.com" "BazaarVoice" "reviews" "Leave as is?"
  mark_contract $db "channelintelligence.com" "Channel Intelligence" "tracking and where-to-buy" "Disable tracking part? cts-log.channelintelligence.com"
  mark_contract $db "cloudfront.net" "Janrain" "Mostly static content" "CDN for Janrain, leave as is."
  #mark_contract $db "igodigital.com" "" "" ""
  #mark_contract $db "ihelpu.nl" "" "" ""
  #mark_contract $db "itnode.cn" "" "" ""
  mark_contract $db "janraincapture.com" "Janrain" "Dynamic MyPhilips/Shop" "Janrain, leave as is."
  #mark_contract $db "mixi.jp" "" "" ""
  #mark_contract $db "netmng.com" "" "" ""
  #mark_contract $db "pinterest.com" "" "" ""
  #mark_contract $db "renren.com" "" "" ""
  mark_contract $db "sharethis.com" "?" "tracker?" "Disable?"
  mark_contract $db "sinajs.cn" "?" "tracker?" "Disable?"
  mark_contract $db "twitter.com" "Twitter" "?" "Contract with Twitter?"
  #mark_contract $db "windows.net" "" "" ""
  mark_contract $db "worldpay.com" "WorldPay?" "payment" "Used in Shop, leave as is?"
  #mark_contract $db "wtp101.com" "" "" ""
  #mark_contract $db "youku.com" "" "" ""
  mark_contract $db "youtube.com" "Google" "video" "Contract with Google?"
  #mark_contract $db "youxiangke.com" "" "" ""
  #mark_contract $db "ytimg.com" "" "" ""
}

proc mark_contract {db topdomain contractparty domaintype notes} {
  $db exec2 "update domaincontract
             set contractparty = '$contractparty', domaintype = '$domaintype', notes = '$notes'
             where topdomain = '$topdomain'" -log
}

proc create_views {db} {
  $db exec2 "drop view if exists domaindisabled_view" -log
  $db exec2 "create view domaindisabled_view as
             select m.slot_alias, d.*
             from domaindisabled d join slot_meta m on m.slot_id = d.slot_id" -log

  $db exec2 "drop view if exists domainused_view" -log
  $db exec2 "create view domainused_view as
             select m.slot_alias, u.*
             from domainused u join slot_meta m on m.slot_id = u.slot_id" -log
}

main $argv

