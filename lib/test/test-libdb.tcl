#!/usr/bin/env tclsh86

# test-libdb.tcl - test functionality of libdb.tcl, especially user defined functions in sqlite.

package require tcltest
namespace import -force ::tcltest::*

# TODO: zo te zien hebben libs nogal wat onderlinge afhankelijkheden. Oplosbaar?
# mogelijk bij een lib te checken of de log functie beschikbaar is. Zo niet, dan zelf een kleine versie maken, evt een no-op.
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

# one time setup
set dbname "/tmp/test-libdb.db"
file delete $dbname
set db [dbwrapper new $dbname]
set conn [$db get_conn]
set handle [$conn getDBhandle]
$handle function pi pi
$handle function iden iden

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

# Tcl functions in DB don't work as aggregate functions.
# [2016-05-27 20:59] this does not work, iden(val) gives 15, val of the last record.
if 0 {
  testndv {
    global db handle
    set query "select count(*) cnt, pi(*) pi, iden(val) iden from testtbl"
    set res [$db query $query]
    log info "res: $res"
    return 1
  } 1
}

# [2016-05-27 20:59] Compiled C library does work, percentile function already available. Compilation on Linux is straighforward, see compile.sh. On Windows
# also fairly easy with Visual Studio 2013, but use a special dev command prompt.
testndv {
  global db
  set res [$db query "select 1 value from testtbl where val=11"]
  log debug "res of select 1: $res"
  return 1
} 1

# [2016-05-28 12:17:00] Using relative path and no extension (.so/.dll) this works on both Linux and Windows.
testndv {
  global db handle
  $handle enable_load_extension 1
  set res [$db query "select load_extension('../sqlite-functions/percentile')"]
  log debug "res of select 1: $res"
  return 1
} 1

# percentile() works with interpolation between closest values.
testndv {
  global db
  set query "select count(*) cnt, percentile(val, 95) perc from testtbl"
  set res [$db query $query]
  log debug "res of percentile: $res"
  dict get [lindex $res 0] perc
} 14.8

$db close
file delete $dbname

cleanupTests
