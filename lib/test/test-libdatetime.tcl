#!/usr/bin/env tclsh861

# test-libdatetime.tcl - test functionality of libdatetime.tcl

# @note don't package require libdatetime, but source it, easier to test.

package require tcltest
namespace import -force ::tcltest::*

source [file join [file dirname [info script]] .. libdatetime.tcl]

proc testndv {args} {
  global testndv_index
  incr testndv_index
  test test-$testndv_index test-$testndv_index {*}$args
}

testndv {parse_cet "2016-06-09 15:52:22.096"} 1465480342.096
testndv {parse_cet "2016-06-09 15:52:22"} 1465480342
testndv {parse_cet "abc2016-06-09 15:52:22.096"} -1

cleanupTests