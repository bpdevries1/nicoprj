#!/usr/bin/env tclsh861

# test-libfp.tcl - test functionality of libfp.tcl

# @note don't package require libfp, but source it, easier to test.

# this one could interfere with the source-cmd below.
# [2016-07-21 20:54] but it does seem to work
# package require ndv

package require tcltest
namespace import -force ::tcltest::*

source [file join [file dirname [info script]] .. libns.tcl]

# source ../libfp.tcl
source [file join [file dirname [info script]] .. libfp.tcl]

# sometimes useful for debugging.
source [file join [file dirname [info script]] .. breakpoint.tcl]

use libfp ; # all libfp functions now in namespace
use libfp ; # should be idempotent.

## test easy, basic functions
# test add-1 {simple addition} {add 3 4} 7
test eq-1 {equals 1} {= 1 1} 1
test eq-2 {equals 2} {= abc abc} 1
test eq-3 {equals 3} {= {abc def} [list abc def]} 1

test eq-4 {equals 4} {= 1 2} 0
test eq-5 {equals 5} {= abc abcd} 0
test eq-6 {equals 6} {= {abc def ghi} [list abc def]} 0

# should = handle or less than 2 arguments?
test eq-7 {equals 7} -body {=} -returnCodes error -result {wrong # args: should be "= a b"}
test eq-8 {equals 8} -body {= 1} -returnCodes error -result {wrong # args: should be "= a b"}
test eq-9 {equals 9} -body {= 1 1 1} -returnCodes error -result {wrong # args: should be "= a b"}
test eq-10 {equals 10} -body {= 1 1 13} -returnCodes error -result {wrong # args: should be "= a b"}

test not-1 {not 1} {not 1} 0
test not-2 {not 2} {not 0} 1
test not-3 {not 3} {not nil} 1

test not-eq-1 {not equals 1} {not= 0 0} 0
test not-eq-1 {not equals 1} {not= 0 1} 1

test str-1 {str 1} {str a b} ab
test str-2 {str 2} {str} ""
test str-3 {str 3} {str "abc"} "abc"
test str-4 {str 4} {str 12 "abc" 3} "12abc3"

test iden-1 {iden 1} {identity 42} 42
test iden-2 {iden 2} {identity {}} {}
test iden-3 {iden 3} {identity ""} ""

test ifp-1 {ifp 1} {ifp 0 1 2} 2
test ifp-1 {ifp 1} {ifp 1 1 2} 1
test ifp-1 {ifp 1} {ifp nil 1 2} 2

test seq-1 {seq 1} {seq {}} nil
test seq-2 {seq 2} {seq {a b c}} {a b c}

test empty-1 {empty 1} {empty? nil} 1
test empty-2 {empty 2} {empty? {}} 1
test empty-3 {empty 3} {empty? {a b}} 0

test cond-1 {cond 1} {cond} 0
test cond-3 {cond 3} {cond 1 2} 2
test cond-4 {cond 4} {cond 0 2} 0
test cond-5 {cond 5} {cond 1 2 3 4} 2
test cond-6 {cond 6} {cond 0 2 3 4} 4
test cond-2 {cond 2} -body {cond 1} -returnCodes error -result {cond should be called with an even number of arguments, got 1}

# [2016-07-22 10:13] Two arguments to the test function should be enough: expression and expected result.
proc testndv {args} {
  global testndv_index
  incr testndv_index
  test test-$testndv_index test-$testndv_index {*}$args
}

testndv {= 1 1} 1
testndv {!= 1 1} 0
testndv {!= {a 1} {a 2}} 1

# [2016-07-16 12:42] some math functions
testndv {max 1 2 3} 3
testndv {max 2} 2
testndv {max {1 2 3}} 3
testndv {max {1}} 1

testndv {max [map {x {string length $x}} {"a" "abc" "-" "ab"}]} 3

testndv {and 1 1} 1
testndv {and 1 0} 0
testndv {and {1==1} {1==2}} 0
testndv {and {1==1} {2==2}} 1

testndv {set s1 1; set s2 2; and {$s1 != {}} {$s2 != {}} {$s1 != $s2}} 1
testndv {set s1 1; set s2 2; and [!= $s1 {}] [!= $s2 {}] [!= $s1 $s2]} 1

testndv {or 0 1} 1
testndv {or 0 0 0} 0
testndv {or {1==0} {1==1}} 1
testndv {or {0==1} {1==0}} 0

testndv {cond 0 2 1 42} 42

set f [lambda_to_proc {x {expr $x * 2}}]
testndv {global f; $f 12} 24

testndv {[lambda_to_proc {x {expr $x * 2}}] 12} 24

# 2 params, first is a proc, second a list
proc plus1 {x} {expr $x + 1}
testndv {map plus1 {1 2 3}} {2 3 4}

# 3 params, first is a var(list), second a body, 3rd a list
testndv {map x {expr $x * 2} {1 2 3}} {2 4 6}

# 2 params, first is a lambda (?), second a list.
testndv {map {x {expr $x * 2}} {1 2 3}} {2 4 6}

# 7-5-2016 map in combi with fn/lambda_to_proc
testndv {map [fn x {expr $x * 2}] {1 2 3}} {2 4 6}

testndv {* 1 2 3} 6

testndv {map [fn x {* $x 2}] {1 2 3}} {2 4 6}

# iets met apply/lambda, nu 16-1-2016 wel vaag.
# @note more tests with lambda, use with apply?  
  
## test filter ##
proc is_ok {x} {regexp {ok} $x}
testndv {filter is_ok {ok false not_ok yes}} {ok not_ok}

# 3 params, first is a var(list), second a body, 3rd a list
testndv {filter x {regexp {ok} $x} {ok false not_ok yes}} {ok not_ok}

# 2 params, first is a lambda (?), second a list.
testndv {filter {x {regexp {ok} $x}} {ok false not_ok yes}} {ok not_ok}

proc is_gt3 {x} {expr $x > 3}
testndv {is_gt3 2} 0
testndv {is_gt3 5} 1

testndv {filter is_gt3 {1 2 3 4 5}} {4 5}

testndv {filter x {expr $x >= 3} {1 2 3 4 5}} {3 4 5}

proc > {x y} {expr $x > $y}
testndv {> 3 4} 0
testndv {> 4 3} 1

testndv {filter x {> $x 3} {1 2 3 4 5}} {4 5}

# One with a closure:
# first test with a specific version of fn
proc find_items {items re} {
  filter [fn x {regexp $re $x}] $items
}

testndv {find_items {abc ab abd ac gh baab} ab} {abc ab abd baab}
testndv {find_items {abc ab abd ac gh baab} {ab}} {abc ab abd baab}

## test fold ##


## test curry/partial ##

## test iden ##

## test str ##

## later: logging around procs

## test lstride, also in fp, could/should be in a list package.
testndv {lstride {a b c d e f g h i} 3} {{a b c} {d e f} {g h i}}
testndv {lstride {{0 2} {1 2} {5 7} {6 7}} 2} {{{0 2} {1 2}} {{5 7} {6 7}}}

# if n == 1, should put all items in a list of their own:
testndv {lstride {{0 2} {1 2} {5 7} {6 7}} 1} {{{0 2}} {{1 2}} {{5 7}} {{6 7}}}

# regsub_fn uses math operators as first class procs (using tcl::mathop)
# just a few tests
testndv {+ 1 2} 3
testndv {+ 4 5 6} 15
testndv {+ 1} 1
testndv {+} 0

# matches should not overlap, so this one returns 2 groups of 3 items each:
testndv {regexp -all -indices -inline {.(.)(.)} "abcdefgh"} \
    {{0 2} {1 1} {2 2} {3 5} {4 4} {5 5}}

# test regsub_fn, to regsub using functions on parameters
# also some form of closure needed, use [fn ]
# replace all series of a's with a<length>
testndv {regsub_fn {a+} "aaa b djjd a jdu aa kj" \
             [fn x {identity "a[string length $x]"}]} \
    "a3 b djjd a1 jdu a2 kj"

# one with a closure/proc handling the replace
proc sub_value {val} {
  if {$val == "a"} {
    return "z"
  } elseif {$val == "z"} {
    return "y"
  } else {
    return $val
  }
}

testndv {regsub_fn {.} "abcxyz" sub_value} "zbcxyy"

# Another one with matching groups in regexp
proc sub_value_grp {whole part1 part2} {
  return "=$part1="
}

testndv {regsub_fn {.(.)(.)} "abcdefgh" sub_value_grp} "=b==e=gh"

# just replace a subgroup:
testndv {regsub_fn {.(.)(.)} "abcdefgh" sub_value_grp 1} "a=b=cd=e=fgh"

# also test if this one still works when no subgroups are given
testndv {regsub_fn {.{1,3}} "abcdefgh" [fn x {string length $x}]} "332"

cleanupTests
