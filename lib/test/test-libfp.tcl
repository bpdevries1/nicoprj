#!/usr/bin/env tclsh86

# test-libfp.tcl - test functionality of libfp.tcl

# @note don't package require libfp, but source it, easier to test.


package require tcltest
namespace import -force ::tcltest::*

source ../libfp.tcl

## test easy, basic functions
# test add-1 {simple addition} {add 3 4} 7
test eq-1 {equals 1} {= 1 1} 1
test eq-2 {equals 2} {= abc abc} 1
test eq-3 {equals 3} {= {abc def} [list abc def]} 1

test eq-4 {equals 4} {= 1 2} 0
test eq-5 {equals 5} {= abc abcd} 0
test eq-6 {equals 6} {= {abc def ghi} [list abc def]} 0

# should = handle or less than 2 arguments?
#test eq-7 {equals 7} {=} 0
#test eq-7 {equals 7} {=} -returnCodes error -result {wrong # args}
#test eq-8 {equals 8} {= 1} 1
#test eq-9 {equals 9} {= 1 1 1} 1
#test eq-10 {equals 10} {= 1 1 2} 0
# for now, those calls should return an error
# @note these tests are being skipped, why?
test eq-7 {equals 7} -body {=} -returnCodes error -result {wrong # args: should be "= a b"}
test eq-8 {equals 8} -body {= 1} -returnCodes error -result {wrong # args: should be "= a b"}
test eq-9 {equals 9} -body {= 1 1 1} -returnCodes error -result {wrong # args: should be "= a b"}
test eq-10 {equals 10} -body {= 1 1 13} -returnCodes error -result {wrong # args: should be "= a b"}

## test map ##



## test filter ##



## test fold ##


## test curry ##

## test iden ##

## test str ##

## later: logging around procs

## later: tdbc::sqlite connection which handles transactions automatically,
# every 1000 (or 10000) statements. How to test?

cleanupTests
