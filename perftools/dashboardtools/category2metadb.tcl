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
    {catfile.arg "c:/nico/nicoprj/perftools/dashboardtools/categories.txt" "Categories file to read"}
    {test "Test the script"}       
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  read_categories $dargv
}

proc read_categories {dargv} {
  set db [get_slotmeta_db [:db $dargv]]
  $db create_tables 0 ; # because added defs

  read_catfile $db [:catfile $dargv]
  correlate_scripts_cats $db
  
  $db close
}

if {0} {
Consumer flows	
	Catalogue browsing (M&CC) - [SCF683 / SCF310 / SCF300 / SCF504 / SCF671]

  $db add_tabledef category {id} {linenr ts_cet catgroup category category_full}
  $db add_tabledef slot_cat {id} {category_id countrycode slot_id slot_alias}
}

proc read_catfile {db catfile} {
  $db exec2 "delete from category" -log
  set f [open $catfile r]
  set catgroup "<none>"
  set linenr 0
  set ts_cet [clock format [file mtime $catfile] -format "%Y-%m-%d %H:%M:%S"]
  while {![eof $f]} {
    gets $f line
    incr linenr
    if {$line == ""} {
      continue
    } elseif {[regexp {^[ \t]} $line]} {
      # category
      set category_full [string trim $line]
      set category [det_category $category_full]
      $db insert category [vars_to_dict linenr ts_cet catgroup category category_full]
    } else {
      # group
      set catgroup [string trim $line]
    }
  }
  close $f
}

# Catalogue browsing (M&CC) - [SCF683 / SCF310 / SCF300 / SCF504 / SCF671] => Catalogue browsing (M&CC)
proc det_category {line} {
  if {[regexp {^(.+) - \[} $line z cat]} {
    return $cat
  } else {
    return $line
  }
}

proc correlate_scripts_cats {db} {
  $db exec2 "delete from slot_cat" -log
  set today [clock format [clock seconds] -format "%Y-%m-%d"]
  set slots [$db query "select slot_id, slot_alias from slot_meta where end_date > '$today'"]
  foreach slot $slots {
    dict_to_vars $slot
    lassign [det_cat_country $db $slot_alias] category_id countrycode
    $db insert slot_cat [vars_to_dict category_id countrycode slot_id slot_alias]
  }
}

# CBF - US (RQ1290) (TxP)[IE] -> US/RQ1290 -> US/8 (id of men's shavers)
# CBF - HealthCare - CN (TxP)[IE] => ???
# CBF-CL-LampsDirect-CN (TxP)[IE] =? ???
# CBF-PL-LED-CN (TxP)[IE] => ???
# CBF-PL-Product-CN (TxP)[IE] => ???
# MBF - CN (CL-Landing)-IPhone (MWP) => ???
# MyPhilips_BR (TxP)[IE] => ???
# Shop Browsing Flow DE(SensoTouch3D) (TxP)[IE] => ???
proc det_cat_country {db slot_alias} {
  set category_id -1
  set countrycode ""
  # breakpoint
  if {[regexp {CBF - (..) \(([^\)]+)\)} $slot_alias z countrycode prodcode]} {
    set category_id [det_category_id $db $prodcode]
  }
  list $category_id $countrycode
}

proc det_category_id {db prodcode} {
  set res [$db query "select id from category where category_full like '%$prodcode%'"]
  if {[llength $res] == 0} {
    return -2
  } elseif {[llength $res] == 1} {
    return [:id [lindex $res 0]]
  } else {
    # error "More than one category found for product: $prodcode"
    if {$prodcode == "RQ12"} {
      set res [$db query "select id from category where category_full like '%$prodcode]%'"]
      if {[llength $res] == 1} {
        return [:id [lindex $res 0]]
      } else {
        error "RQ12: after re-query, don't find exactly one category: $prodcode, $res"
      }
    }
    return -3
  }
}

main $argv

