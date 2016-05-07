#!/usr/bin/env tclsh86

# test-libfp.tcl - test functionality of libfp.tcl

# @note don't package require libfp, but source it, easier to test.


package require tcltest
namespace import -force ::tcltest::*

# source ../libfp.tcl
source [file join [file dirname [info script]] .. libfp.tcl]

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

## test map ##
# set fields [map x [:fields $table] {ifp [eq $x "id"] "id integer primary key autoincrement" $x}]
# test map-1 {map 1} {map x {id field1 field2} \
  {ifp [= $x "id"] "id integer primary key autoincrement" $x}} \
  {{id integer primary key autoincrement} field1 field2}


# 16-1-2016 hieronder de voor mij meest handige manieren om map/filter te gebruiken, deze moeten werken dus.
proc testndv {args} {
  global testndv_index
  incr testndv_index
  test test-$testndv_index test-$testndv_index {*}$args
}

# test eq-1 {equals 1} {= 1 1} 1
testndv {= 1 1} 1
testndv {!= 1 1} 0
testndv {!= {a 1} {a 2}} 1

testndv {and 1 1} 1
testndv {and 1 0} 0
testndv {and {1==1} {1==2}} 0
testndv {and {1==1} {2==2}} 1

testndv {or 0 1} 1
testndv {or 0 0 0} 0
testndv {or {1==0} {1==1}} 1
testndv {or {0==1} {1==0}} 0

testndv {cond 0 2 1 42} 42
# testndv {cond 0 2 1 42} 43

# lambda_to_proc: faalt, f niet gevonden, iets met scoping dus.
# set f [lambda_to_proc {x {expr $x * 2}}]
# testndv {$f 12} 24

# in 1 stap, gaat goed.
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

proc * {args} {
  set res 1
  foreach arg $args {
    set res [expr $res * $arg]
  }
  return $res
}

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

#puts "Start with filter \$x > 3"
#testndv {filter x {$x >= 3} {1 2 3 4 5}} {3 4 5}
#puts "Finished with filter \$x > 3"

# testndv {filter {x {$x >= 3}} {1 2 3 4 5}} {3 4 5}

## test fold ##


## test curry/partial ##

## test iden ##

## test str ##

## later: logging around procs

## later: tdbc::sqlite connection which handles transactions automatically,
# every 1000 (or 10000) statements. How to test?

cleanupTests
