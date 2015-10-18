#!/usr/bin/env tclsh86

# get-ALM-PC-tests.tcl - Get test definitions (scenario's) from ALM/PC and put in DB.
# (maybe also perform checks? or separate script)

# notes:
# namespaces are not used.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require tdom
package require textutil

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

ndv::source_once almdb.tcl 

# ndv::source_once libslotmeta.tcl download-metadata.tcl
#ndv::source_once libslotmeta.tcl
#ndv::source_once libkeynote.tcl

# main DB is in <dir>/almpc.db

proc main {argv} {
  set options {
    {dir.arg "c:/PCC/Nico/ALMdata" "Main directory to put downloaded ALM files"}
    {download "Download new files from ALM (otherwise use previously downloaded files)"}
    {config.arg "c:/PCC/Nico/config/ALM.config" "Config file with project name and credentials"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]

  set config [read_config [:config $dargv]]
  set dir [:dir $dargv]
  if {[:download $dargv]} {
    set almfilename [download_alm $dir $config]
  } else {
    set almfilename [det_latest_almfile $dir]
  }

  set dbname [file join $dir "almpc.db"]
  set db [det_db $dbname]
  
  if 0 {
    set filename "c:/PCC/Nico/aaa/test172c.xml"
    read_test_file $filename
  }
  
  set filename "c:/PCC/Nico/aaa/tests.xml"
  read_tests_file $filename
  # handle_pc_errors ""
}

proc read_tests_file {filename db} {
  set text [read_file $filename]
  log debug "text100: [string range $text 0 100]"
  # set doc [dom parse $text]
  set doc [dom parse -simple $text]
  set root [$doc documentElement]
  log debug "root node: [$root nodeName]"
  log debug "#tests: [$root @TotalResults]"
  foreach node [$root selectNodes {/Entities/Entity}] {
    handle_test_entity $node
  }
}


proc read_tests_file_old {filename} {
  set text [read_file $filename]
  log debug "text100: [string range $text 0 100]"
  # set doc [dom parse $text]
  set doc [dom parse -simple $text]
  set root [$doc documentElement]
  log debug "root node: [$root nodeName]"
  log debug "#tests: [$root @TotalResults]"
  foreach node [$root selectNodes {/Entities/Entity}] {
    handle_test_entity $node
  }
}

proc read_test_file {filename} {
  set text [read_file $filename]
  log debug "text100: [string range $text 0 100]"
  # set doc [dom parse $text]
  set doc [dom parse -simple $text]
  set root [$doc documentElement]
  log debug "root node: [$root nodeName]"
  
  handle_test_entity $root
  
  if 0 {
    # hoofdniveau: id, name, creation-time, last-modified, pc-total-vusers
    # set field_nodes [$root selectNodes {/Entity/Fields/Field}]
    set field_nodes [$root selectNodes {Entity/Fields/Field}]
    log debug "#field_nodes: [:# $field_nodes]"
    foreach field_node $field_nodes {
      set name [$field_node @Name]
      # log debug "name: $name"
      set value_node [$field_node selectNodes {Value}]
      if {$value_node != {}} {
        set value [$value_node text]
      } else {
        set value "<empty>"
      }
      
      # set value [[$field_node selectNodes {Value}] text]
      log debug "Field $name = [string range $value 0 80]"
    }
    
    set pc_errors_node [$root selectNode {/Entity/Fields/Field[@Name='pc-errors']}]
    set pc_errors_text [[$pc_errors_node selectNode Value] text]
    log debug "pc_errors_node: $pc_errors_node"
    log debug "pc_errors_text: $pc_errors_text"
    
    handle_pc_errors $pc_errors_text
    handle_pc_blob [$root selectNode {/Entity/Fields/Field[@Name='pc-blob']/Value}]
  
  
  }
}

proc handle_test_entity {node} {
  # hoofdniveau: id, name, creation-time, last-modified, pc-total-vusers
  set scen_name [get_field_text [$node selectNode {Fields/Field[@Name='name']}] Value]
  log debug "**********************************************"
  log debug "Scenario name: $scen_name"
  
  set field_nodes [$node selectNodes {Entity/Fields/Field}]
  log debug "#field_nodes: [:# $field_nodes]"
  foreach field_node $field_nodes {
    set name [$field_node @Name]
    # log debug "name: $name"
    set value_node [$field_node selectNodes {Value}]
    if {$value_node != {}} {
      set value [$value_node text]
    } else {
      set value "<empty>"
    }
    
    # set value [[$field_node selectNodes {Value}] text]
    log debug "Field $name = [string range $value 0 80]"
  }
  
  set pc_errors_node [$node selectNode {/Entity/Fields/Field[@Name='pc-errors']}]
  # set pc_errors_text [[$pc_errors_node selectNode Value] text]
  set pc_errors_text [get_field_text $pc_errors_node Value]
  
  log debug "pc_errors_node: $pc_errors_node"
  log debug "pc_errors_text: $pc_errors_text"
  
  handle_pc_errors $pc_errors_text
  # handle_pc_blob [$node selectNode {/Entity/Fields/Field[@Name='pc-blob']/Value}]
  handle_pc_blob [$node selectNode {Fields/Field[@Name='pc-blob']/Value}]
}

proc handle_pc_errors {text} {
  # set filename "c:/PCC/Nico/aaa/test172c-pc-errors.xml"
  #set f [open $filename w]
  #puts $f $text
  #close $f
  # set text [read_file $filename]
  
  
  log debug "handle_pc_errors: start"
  if {![is_empty $text]} {
    set doc [dom parse -simple $text]
    set root [$doc documentElement]
    log debug "root node: [$root nodeName]"
    
    set id [[$root selectNode {/ErrorsPersistenceModel/ID}] text]
    set name [[$root selectNode {/ErrorsPersistenceModel/Name}] text]

    log debug "ID: $id, name: $name"
  } else {
    log debug "Empty text for pc_errors, returning."
  }
  
  log debug "handle_pc_errors: finished"
}

proc is_empty {text} {
  if {$text == ""} {
    return 1
  }
  if {$text == "<empty>"} {
    return 1
  }
  return 0
}

proc handle_pc_blob {node} {
  log debug "handle_pc_blob: start"
  log debug "node: $node"
  
  if {$node == {}} {
    log debug "Empty pc_blob node."
    return
  }
  
  set text [$node text]
  if {$text == ""} {
    log debug "Empty text in pc_blob node"
    return
  }
  
  #set filename "c:/PCC/Nico/aaa/test172c-pc-blob.xml"
  #set f [open $filename w]
  #puts $f $text
  #close $f
  
  try_eval {
    set doc [dom parse -simple $text]
  } {
    log debug "dom parse failed, see text:"
    log debug [string range $text 0 80]
    breakpoint
  }
  
  set root [$doc documentElement]
  log debug "root node: [$root nodeName]"

  # 13-10-2015 NdV vraag of deze host nodes zinvol zijn, want deel van de info ook binnen groep (=script) beschikbaar.
  set host_nodes [$root selectNodes {/loadTest/Hosts/HostBase}]
  log debug "Hosts:"
  foreach host_node $host_nodes {
    log debug "id: [get_field_text $host_node ID], name: [get_field_text $host_node Name], location: [get_field_text $host_node Location]"
  }
  
  set sched_text [get_field_text [$root selectNode {/loadTest/Scheduler}] Data]
  set filename "c:/PCC/Nico/aaa/test172c-sched.xml"
  set f [open $filename w]
  puts $f $sched_text
  close $f
  
  set sched_root [[dom parse -simple $sched_text] documentElement]
  log debug "start mode type: [get_field_text [$sched_root selectNode {/LoadTest/Schedulers/StartMode}] StartModeType]"
  
  foreach grp_sch_node [$sched_root selectNodes {/LoadTest/Schedulers/Scheduler/Manual/Groups/GroupScheduler}] {
    log debug "schedule group name: [get_field_text $grp_sch_node GroupName]"
    
    # mogelijk hier nog meer mee dan als scenario pas na een tijdje moet starten.
    set mode [[$grp_sch_node selectNode {StartupMode/*}] nodeName]
    log debug "startup mode: $mode"
    
    set dyn_sched_node [$grp_sch_node selectNode {Scheduling/DynamicScheduling}]
    if {$dyn_sched_node != {}} {
      set interval [get_field_text [$dyn_sched_node selectNode {RampUpAll/Batch}] Interval]
      log debug "rampup [get_field_text [$dyn_sched_node selectNode {RampUpAll/Batch}] Count] users every $interval seconds"
      log debug "duration: [get_field_text [$dyn_sched_node selectNode {Duration}] RunFor] seconds"
    } else {
      log debug "No Scheduling/DynamicScheduling node found."
    }
  }
  
  log debug "=========================================="
  log debug "Groups:"
  set group_nodes [$root selectNodes {/loadTest/Groups/Group}]
  foreach grp_node $group_nodes {
    log debug "Name: [get_field_text $grp_node Name]"
    foreach field {ScriptUniqueID ScriptName VUsersNumber CommandLine RunTimeSettings RunLogic} {
      log debug "$field: [string range [get_field_text $grp_node $field] 0 80]"
    }
    set host_nodes [$grp_node selectNodes {Hosts/HostBase}]
    log debug "Hosts:"
    foreach host_node $host_nodes {
      log debug "host within group: id: [get_field_text $host_node ID], name: [get_field_text $host_node Name], location: [get_field_text $host_node Location]"
    }
    
    set runlogic [get_field_text $grp_node RunLogic]
    set rts [get_field_text $grp_node RunTimeSettings]
    
    handle_settings runlogic $runlogic
    handle_settings rts $rts
  }
  
  #RunLogic en RuntimeSettings: text als geheel al goed opgehaald.
  
  
  
  
  log debug "handle_pc_blob: finished"
}

proc handle_settings {name text} {
  #log debug "handle_settings: $name"
  #log debug "text: [string range $text 0 100]"
  set l [::textutil::split::splitx $text {!@##@!}]
  set group "<none>"
  foreach el $l {
    # log debug "item: $el"
    if {[regexp {^\[(.+)\]$} $el z grp]} {
      set group $grp
    } else {
      lassign [split $el "="] elname elvalue
      if {$elname != ""} {
        log debug "$name.$group.$elname = $elvalue"
      }
    }
  }
}

proc get_field_text {node field} {
  if {$node == {}} {
    return "<empty>"
  }
  if {[llength $node] > 1} {
    log warn "More than one node: $node"
    return "<more-than-one>"
  }
  
  set node2 [$node selectNode $field]
  if {$node2 != {}} {
    $node2 text
  } else {
    return "<empty>"
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

main $argv

