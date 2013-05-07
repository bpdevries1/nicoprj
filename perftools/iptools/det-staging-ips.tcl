#!/usr/bin/env tclsh86

# det-staging-ips.tcl

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "curlgetheader.log"

proc main {argv} {
  set root_folder [det_root_folder] ; # based on OS.
  # 6-5-2013 NdV niet met 2 processen tegelijk op 1 database!
  set db_name [file join $root_folder "aaa/akamai2.db"]
  log info "Opening database: $db_name"
  set conn [open_db $db_name]

  # set conn [open_db "~/Dropbox/Philips/Akamai/akamai.db"]
  # @note 6-5-2013 NdV even curlgetheader2, want loopt thuis ook nog, weer mergen morgen.
  set table_def [make_table_def staging2 ts domain res1 staging_name res2 staging_ip staging_ip2]
  create_table $conn $table_def 0 ; # 1: first drop the table.
   
  # lookup_entries $conn $table_def "firebug" $wait_after
  lookup_entries $conn $table_def
}

proc lookup_entries {conn table_def} {
  dict_to_vars $table_def
  set stmt_insert [prepare_insert $conn $table {*}$fields]
  set query "select domain from scope where status='in_scope' order by domain"
  foreach row [db_query $conn $query] {
    set ts [det_now]
    set domain [dict get $row domain]
    log info "Finding staging info for: $domain"
    set res1 [nslookup $domain]
    set staging_name [det_staging_name $res1]
    if {$staging_name != "<none>"} {
      set res2 [nslookup $staging_name]
      lassign [det_staging_ips $res2] staging_ip staging_ip2
    } else {
      set res2 "<none>"
      set staging_ip "<none>"
      set staging_ip2 "<none>"
    }
    set dct_insert [vars_to_dict ts domain res1 staging_name res2 staging_ip staging_ip2]
    stmt_exec $conn $stmt_insert $dct_insert
  }
}

proc nslookup {domain} {
  set res [exec -ignorestderr nslookup $domain]
  return $res
}

# @return: staging name as string.
# Server:  htc02.htc.nl.philips.com
# Address:  130.145.128.20
# 
# Non-authoritative answer:
# Name:    a1177.r.akamai.net
# Addresses:  77.67.4.64
#           77.67.4.9
# Aliases:  www.philips.nl
#           www.countries.philips.com.edgesuite.net
# 
proc det_staging_name {res} {
  if {[regexp {([^ ]+)\.edgesuite.net} $res z prefix]} {
    return "$prefix.edgesuite-staging.net" 
  } elseif {[regexp {([^ ]+)\.edgekey.net} $res z prefix]} {
    return "$prefix.edgekey-staging.net"
  } elseif {[regexp {([^ ]+)\.akamai.net} $res z prefix]} {
    return "$prefix.akamai-staging.net" 
  } else {
    return "<none>"
  }
}

# @return: staging ips (max 2) as list.
# Server:  htc02.htc.nl.philips.com
# Address:  130.145.128.20
# 
# Non-authoritative answer:
# Name:    a1177.r.akamai-staging.net
# Addresses:  165.254.92.139
#           165.254.92.145
# Aliases:  www.countries.philips.com.edgesuite-staging.net
proc det_staging_ips {res} {
  if {[regexp {Addresses: +([0-9.]+)} $res z ip]} {
    return [list $ip "<none>"] 
  } else {
    return [list "<none>" "<none>"] 
  }
}

# c:/aaa on windows, ~/aaa on linux
proc det_root_folder {} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    return "c:/" 
  } else {
    return "~/" 
  }
}
  
main $argv

