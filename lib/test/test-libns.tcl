#!/usr/bin/env tclsh861

package require tcltest
namespace import -force ::tcltest::*

source [file join [file dirname [info script]] .. libns.tcl]

namespace eval ::libtestns {

  namespace export now

  proc now {} {
    return "now"
  }

}

proc testndv {args} {
  global testndv_index
  incr testndv_index
  test test-$testndv_index test-$testndv_index {*}$args
}

namespace forget now
use libtestns
testndv {now} "now"

namespace forget now
require libtestns t
testndv {t/now} "now"


cleanupTests

