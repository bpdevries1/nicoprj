#!/home/nico/bin/tclsh86

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  set conn [open_db "c:/aaa/akamai.db"]
  # set conn [open_db "~/Dropbox/Philips/Akamai/akamai.db"]
  
  # select all config files which have domains in scope
  foreach rec [db_query $conn "select distinct(configfile) file from scope where status = 'in_scope' order by configfile"] {
    set file [dict get $rec file]
    puts "Config file: $file"
    set in_scope [get_domains $conn $file "in_scope"]
    puts "In scope \n[join $in_scope ", "]."
    set out_of_scope [get_domains $conn $file "out_of_scope"]
    if {[llength $out_of_scope] > 0} {
      puts "Out of scope \n[join $out_of_scope ", "]."
    }
    puts ""
  }
}

proc get_domains {conn file scope} {
  set res {}
  foreach rec [db_query $conn "select domain from scope where configfile='$file' and status='$scope' order by domain"] {
    lappend res [dict get $rec domain] 
  }
  return $res
}

main $argv

