#!/usr/bin/env tclsh86

package require ndv

proc main {argv} {
  puts "args: $argv"
  set root "c:/projecten/Philips/KN-Analysis"
  do_queries $root "MyPhilips-CN"
  do_queries $root "MyPhilips-DE"
  do_queries $root "MyPhilips-FR"
  do_queries $root "MyPhilips-RU"
  do_queries $root "MyPhilips-UK"
  do_queries $root "MyPhilips-US"
}

proc do_queries {root sub} {
  set db_name [file join $root $sub "keynotelogs.db"]
  set db [dbwrapper new $db_name]
  set query "update pageitem
              set scontent_type = substr(url, 1, instr(url, '?'))
              where url like '%?%'
              and scontent_type is null"
  puts "Exec query: $query"
  $db exec $query
  $db close
}

main $argv
