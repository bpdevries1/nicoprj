#! /usr/bin/env tclsh

# Run report script on several test log files, to check if DB and report are created ok.
# Goal is to put test files (logs) in repo as well.
# Generated files are created in /tmp, so copy source files to temp as well.

package require ndv
use libtest
# use libfp
use liburl

# set perftools_dir [file normalize [file join \
#                                       [file dirname [info script]] .. .. perftools]]

#set perftools_dir [file normalize ~/nicoprj/perftools]
#source [file join $perftools_dir report read-report-dir.tcl]

proc main {argv} {
  #test_perf_logs
  #tcltest::cleanupTests
  testndv {url-decode "abc"} abc
  testndv {url-decode "01%2F01%2F0001%2000%3A00%3A00"} "01/01/0001 00:00:00"
  testndv {url-encode "01/01/0001 00:00:00"} "01%2f01%2f0001+00%3a00%3a00"

  testndv {url->parts "http://google.nl/sub?a=b&c=d"} {protocol http domain google.nl port {} path sub params {{type namevalue name a value b valuetype xdigit} {type namevalue name c value d valuetype xdigit}}}

  # en ook dict create zelf hier uitvoeren.
  testndv {url->parts "http://google.nl/sub?a=b&c=d"} [dict create protocol http domain google.nl port {} path sub params [list  [dict create type namevalue name a value b valuetype xdigit] [dict create type namevalue name c value d valuetype xdigit]]]

  testndv {url->parts "http://google.nl:80/sub/sub2?a=b&c=d"} [dict create protocol http domain google.nl port 80 path sub/sub2 params [list  [dict create type namevalue name a value b valuetype xdigit] [dict create type namevalue name c value d valuetype xdigit]]]


  cleanupTests
}

main $argv
