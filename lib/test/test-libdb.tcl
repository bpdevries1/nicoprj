#!/usr/bin/env tclsh86

# test-libfp.tcl - test functionality of libfp.tcl

# @note don't package require libfp, but source it, easier to test.


package require tcltest
namespace import -force ::tcltest::*

# source ../libfp.tcl

# TODO: zo te zien hebben libs nogal wat onderlinge afhankelijkheden. Oplosbaar?
source [file join [file dirname [info script]] .. libfp.tcl]
source [file join [file dirname [info script]] .. libdict.tcl]
source [file join [file dirname [info script]] .. CLogger.tcl]
source [file join [file dirname [info script]] .. generallib.tcl]

source [file join [file dirname [info script]] .. libdb.tcl]

set_log_global info

log debug "Starting the tests"

proc testndv {args} {
  global testndv_index
  incr testndv_index
  test test-$testndv_index test-$testndv_index {*}$args
}

proc pi {args} {
  return 3.14159
}

proc iden {args} {
  return $args
}

testndv {pi} 3.14159
testndv {iden 1 2 3} {1 2 3}

# Nu 1x de setup
set dbname "/tmp/test-libdb.db"
file delete $dbname
set db [dbwrapper new $dbname]
set conn [$db get_conn]
set handle [$conn getDBhandle]
$handle function pi pi
$handle function iden iden

# enable loading C extensions with load_extension()
$handle enable_load_extension 1

# load_extension(X,Y) dan een .dll of .so nodig? Maar ook vraag of aggregates dan kunnen.
$db exec "create table testtbl (val integer)"
foreach val {11 12 13 14 15} {
  $db exec "insert into testtbl values ($val)"
}

testndv {
  global db handle
  set res [$db query "select val, pi(val) pi from testtbl where val=11"]
  set qpi [:pi [:0 $res]]
  = $qpi [pi]
} 1

# vraag of function ook met group by etc kan werken.
# zgn aggregate function
# [2016-05-27 20:59] dit werkt niet, iden(val) geeft hier 15, val van de laatste.
if 0 {
  testndv {
    global db handle
    set query "select count(*) cnt, pi(*) pi, iden(val) iden from testtbl"
    set res [$db query $query]
    log info "res: $res"
    return 1
  } 1
}

# [2016-05-27 20:59] gecompileerde c library zou wel moeten lukken, en is er zowaar al voor percentile functie. Compileren op Linux ging heel gemakkelijk, zie ~/prj/sqlite-functions.

testndv {
  global db
  # TODO: kijk of je dummy table hebt, met name voor config van c functions.
  set res [$db query "select 1 value from testtbl where val=11"]
  log debug "res of select 1: $res"
  return 1
} 1

# TODO: cross compile naar windows mogelijk op linux?
testndv {
  global db
  # TODO: kijk of je dummy table hebt, met name voor config van c functions.
  # TODO: ook kijken of het werkt als je val is null zegt. Zonder where clause faalt 'ie'
  set res [$db query "select load_extension('/home/nico/nicoprj/lib/sqlite-functions/percentile.so') value from testtbl where val=11"]
  log debug "res of select 1: $res"
  return 1
} 1

# percentile() works with interpolation between closest values.
testndv {
  global db
  set query "select count(*) cnt, percentile(val, 95) perc from testtbl"
  set res [$db query $query]
  log debug "res of percentile: $res"
  # return 1
  # :perc [:0 $res] => don't use other libs here.
  dict get [lindex $res 0] perc
} 14.8

$db close
file delete $dbname


# en na de test de breakdown


cleanupTests
