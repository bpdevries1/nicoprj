#!/usr/bin/env tclsh86

# metadata2pages.tcl - convert Keynote API slotmetadata.json to table with page-names.

package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

# @todo Dit dan gebruiken om van alle slots wat op te halen, kijken of alles nu te lezen is.

proc main {argv} {
  set options {
    {in.arg "c:/projecten/Philips/KNDL/slotmetadata.json" "Slotmetadata filename"}
    {out.arg "c:/projecten/Philips/KNDL/script-pages.csv" "File with script-pages"}
    {pattern.arg "CBF-CN" "Regexp pattern to use"}
    {sep.arg "\t" "Field separator"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]

  #set slotfilename "c:/projecten/Philips/KNDL/slotmetadata.json"
  #set configname "c:/projecten/Philips/KNDL/config-skeleton.csv"
  set slotfilename [:in $dargv]
  set configname [:out $dargv]
  set json [json::json2dict [read_file $slotfilename]]
  set f [open $configname w]
  set re [:pattern $dargv]
  # puts $f "slot_id;scriptname;page_seq;page_name;page_type"
  puts $f [join {slot_id scriptname page_seq page_name page_type} [:sep $dargv]]
  foreach prd_el [:product $json] {
    log debug "Handle [:name $prd_el]"
    foreach slot [:slot $prd_el] {
      set scriptname [cleanup [:slot_alias $slot]]
      if {[regexp $re $scriptname]} {
        set slot_id [:slot_id $slot]
        set page_seq 0
        foreach page_name [split [:pages $slot] ","] {
          incr page_seq
          set page_type [det_page_type $scriptname $page_seq $page_name]
          puts $f [join [list $slot_id $scriptname $page_seq $page_name $page_type] [:sep $dargv]]
        }
      }
    }
  }
  # dirname;slotids;npages
  #Mobile-landing;1060724,1060726,1138756;1
  # MyPhilips-DE;1129227;3
  # breakpoint
  close $f
}

proc cleanup {alias} {
  foreach re {{\(TxP\)} {\(MWP\)} {\(ApP\)} {\[IE\]}} {
    regsub $re $alias "" alias 
  }
  regsub {MBF} $alias "Mobile" alias
  regsub {\(([^\(\)]+)\)} $alias {-\1} alias
  regsub -all -- { } $alias "-" alias
  regsub -all -- {_} $alias "-" alias
  while {[regsub -all -- {--} $alias "-" alias]} {}
  regsub -- {-$} $alias "" alias
  regsub -- {^-} $alias "" alias
  return [string trim $alias]
}

set dpts {{land 1-landing} {Dec 3-decision} {detail 4-detail} {suppor 5-support} {Search 6-dealerloc} {Categ 2-category}}
proc det_page_type {scriptname page_seq page_name} {
  global dpts
  foreach el $dpts {
    lassign $el re tp
    if {[regexp -nocase $re $page_name]} {
      return $tp 
    }
  }
  return "<unknown>" 
}

main $argv
