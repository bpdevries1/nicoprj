#!/usr/bin/env tclsh

proc main {argv} {
  set filename "c:/nico/nicoprj/perftools/iptools/ip-locations-br.tsv"  
  set f [open $filename r]
  set fo [open "$filename.sql" w]
  set header [split [gets $f] "\t"]
  while {![eof $f]} {
    set row [split [gets $f] "\t"]
    lassign $row ip z z loc
    if {$ip == ""} {
      continue 
    }
    set iprange [det_iprange $ip]
    puts $fo "insert into location
select distinct ip_address, '$loc'
from pageitem
where ip_address like '$iprange'
and topdomain = 'cloudfront.net';
"
  }
  close $f
  close $fo
}

proc det_iprange {ip} {
  # for now the first 3 parts
  if {[regexp {^(.*\.)[^\.]+$} $ip z range]} {
    return "$range%" 
  } else {
    error "Cannot determine range from: $ip" 
  }
}

main $argv
