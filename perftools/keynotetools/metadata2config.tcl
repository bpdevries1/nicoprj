#!/usr/bin/env tclsh86

# metadata2config.tcl - convert Keynote API slotmetadata.json to skeleton config.csv

package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

# @todo Dit dan gebruiken om van alle slots wat op te halen, kijken of alles nu te lezen is.

proc main {argv} {
  set options {
    {in.arg "c:/projecten/Philips/KNDL/slotmetadata.json" "Slotmetadata filename"}
    {out.arg "c:/projecten/Philips/KNDL/config-skeleton.csv" "Config file name"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dct_argv [::cmdline::getoptions argv $options $usage]

  #set slotfilename "c:/projecten/Philips/KNDL/slotmetadata.json"
  #set configname "c:/projecten/Philips/KNDL/config-skeleton.csv"
  set slotfilename [:in $dct_argv]
  set configname [:out $dct_argv]
  set json [json::json2dict [read_file $slotfilename]]
  set f [open $configname w]
  puts $f "dirname;slotids;npages"
  foreach prd_el [:product $json] {
    log debug "Handle [:name $prd_el]"
    foreach slot [:slot $prd_el] {
      set npages [llength [split [:pages $slot] ","]]
      if {$npages == 0} {
        set npages 1 ; # sometimes pages field is completely empty, assume 1 page then (is correct for mobile) 
      }
      set dirname [cleanup [:slot_alias $slot]]
      set slot_id [:slot_id $slot]
      puts $f [join [list $dirname $slot_id $npages] ";"]
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

main $argv
