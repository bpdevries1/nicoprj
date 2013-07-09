#!/usr/bin/env tclsh86

# ak-staging.tcl - determine staging ip(s) of 1 domain.

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# $log set_file "curlgetheader.log"

proc main {argv} {
  lassign $argv domain
  set res1 [nslookup $domain]
  lassign [det_nslookup_ips $res1] prod_ip prod_ip2
  set staging_name [det_staging_name $res1]
  if {$staging_name != "<none>"} {
    set res2 [nslookup $staging_name]
    lassign [det_nslookup_ips $res2] staging_ip staging_ip2
  } else {
    set res2 "<none>"
    set staging_ip "<none>"
    set staging_ip2 "<none>"
  }
  # don't check ip2, mostly (always?) <none>
  if {$prod_ip == $staging_ip} {
    log warn "Production IP == Staging IP"
    log warn "Are you connected to WLAN-PHI? Please try WLAN-PUB"
    # breakpoint
  } 
  # scope ts domain res1 prod_ip prod_ip2 staging_name res2 staging_ip staging_ip2]
  
  puts $res1
  puts "==============================="
  puts $res2
  puts "==============================="
  puts "production_ip: $prod_ip"
  puts "production_ip2: $prod_ip2"
  puts "staging_ip: $staging_ip"
  puts "staging_ip2: $staging_ip2"
  
}

proc nslookup {domain} {
  # @note on windows some part of output is sent to stderr, so redirect.
  set res [exec -ignorestderr nslookup $domain 2>@1]
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
# @note 4-6-2013 NdV first check (wrt China) on akamai(edge).net
#
# Aliases:  secure.philips.nl
#          secure2.philips.com.edgekey.net
proc det_staging_name {res} {
  if {[regexp {www.usa.philips.com} $res]} {
    # breakpoint 
  }
  if {[regexp {([^ \t:\n]+)\.akamai.net} $res z prefix]} {
    return "$prefix.akamai-staging.net"
  } elseif {[regexp {([^ \t:\n]+)\.akamaiedge.net} $res z prefix]} {
    return "$prefix.akamaiedge-staging.net" 
  } elseif {[regexp {([^ \t:\n]+)\.edgesuite.net} $res z prefix]} {
    return "$prefix.edgesuite-staging.net" 
  } elseif {[regexp {([^ \t:\n]+)\.edgekey.net} $res z prefix]} {
    return "$prefix.edgekey-staging.net"
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
#
# @note antwoord iig na "answer:"
proc det_nslookup_ips {res} {
  if {[regexp {answer:.*Address(es)?: +([0-9.]+)} $res z z ip]} {
    return [list $ip "<none>"] 
  } else {
    breakpoint
    return [list "<none>" "<none>"] 
  }
}

main $argv

