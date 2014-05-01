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
ndv::source_once ../keynotetools/libslotmeta.tcl
ndv::source_once ../keynotetools/libkeynote.tcl

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {db.arg "c:/projecten/Philips/KNDL/slotmeta-domains.db" "DB to use"}
    {npagesfile.arg "c:/aaa/npages.tsv" "File with npages to write"}
    {test "Test the script"}       
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  write_npages $dargv
}

proc write_npages {dargv} {
  set db [get_slotmeta_db [:db $dargv]]
  set f [open [:npagesfile $dargv] w]
  set countries [list DE FR US BR CN RU NL UK IN JP KO SG]
  puts $f "\t[join $countries "\t"]"
  foreach cat [$db query "select id, category from category order by linenr"] {
    # eerst scriptname printen.
    puts -nonewline $f [:category $cat]
    foreach country $countries {
      puts -nonewline $f "\t[det_script_npages $db [:id $cat] $country]"
    }
    puts $f ""
  }
  close $f
  $db close
}

proc det_script_npages {db category_id country} {
  set res [$db query "select m.npages 
                      from slot_cat s
                        join slot_meta m on m.slot_id = s.slot_id
                      where countrycode = '$country' and category_id = $category_id"]
  if {[llength $res] == 0} {
    return ""
  } else {
    return [:npages [lindex $res 0]]
  }
}

main $argv

