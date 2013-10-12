# libfp.tcl - functional programming in Tcl
# primary goal: make as easy to use as possible, compare Clojure
# secondary goals: make fast, always correct.

# @todo later
# put in separate namespace

# @note heavily based on things found on wiki.tcl.tk
# @note also based on previous attempts to usable FP methods/procs/functions.
# @note use Tcltest to validate functionality, also usable as documentation.
# @note try to use CLojure function names (and arguments) as basis. 
#       If name conflicts with existing tcl name, use another name, eg if -> ifp 
# @todo find out how to handle closures, some simple things work, and some more elaborate things on the wiki.
# @note ? and - are possible in proc names. ':' also, already used for dict accessors, see libdict.
# @note what to do with lazy handling, eg in if-proc.
# @note use Tcl syntax/formatting and Clojure-like formatting both, most applicable.
# @note order is as in clojure: if a function A uses another function B, B should be defined before A.

##
# @note some easy, helper functions first
proc = {a b} {
  if {$a == $b} {
    return 1
  } else {
    return 0
  }
}

# this is the if from clojure, don't want to override the std Tcl def.
# @todo handle expressions as first argument? Or should have been evaluated before?
# how to handle nil or empty list?
# 0 is truthy in clojure, but would not be handy in Tcl.
# nil is falsy, but '() and [] are seen as truthy, seq function used to convert '() to nil.
# @note 'yes' and 'no' will be evaluated lazily, only when condition is met.
# @note therefore the yes and no values should be enclosed in {}.
# @note OTOH this makes function less handy to use, and would violate a starting point.
# @note so should either use the standard if (which is 'lazy') or create own other variant.
# @note or find a way to distinguish between expression and value: is this possible? how handled in clojure? (probably special form/macro with if)
proc ifp {test yes no} {
  if {$test == "nil"} {
    return $no
    # eval $no
    # uplevel 1 $no - default is level 1
    # uplevel $no
  } elseif {$test} {
    return $yes
    # eval $yes
  } else {
    return $no
    # eval $no
  }
}

# @note seq for now just to translate empty list to nil, and this becomes falsy in [not] and [ifp]
proc seq {l} {
  ifp [= [string length $l] 0] nil $l
}

proc empty? {l} {
  ifp [= [seq $l] nil] 1 0  
}

proc cond_1 {args} {
  lassign $args test result rest
  puts "cond called with $args"
  # ifp [empty? $args] 0 [ifp $test $result [cond {*}$rest]]
  ifp [empty? $args] 0 {[ifp $test $result [cond {*}$rest]]}
}

# @note ifp not usable, as it is not lazy.
proc cond {args} {
  set rest [lassign $args test result]
  # puts "cond called with $args"
  # ifp [empty? $args] 0 [ifp $test $result [cond {*}$rest]]
  # ifp [empty? $args] 0 {[ifp $test $result [cond {*}$rest]]}
  if {[expr [llength $args] % 2] == 1} {
    error "cond should be called with an even number of arguments, got $args" 
  }
  if {[empty? $args]} {
    return 0 
  } elseif {$test} {
    return $result 
  } else {
    cond {*}$rest 
  }
}


proc not {a} {
  ifp $a 0 1
}

proc not= {a b} {
  # @todo not {= $a $b} should also work?
  not [= $a $b]  
}

proc str {args} {
  join $args ""
}

# clj fn is also called identity, not iden or id
proc identity {a} {
  return $a 
}


# @todo maybe a 'proc fn' to create function-objects, lambda's?

# @todo handle more than one map-var, for traversing more than one map at the same time?
# @note should handle 2 forms:
# (map var list expression-with-var)
# (map lambda list), where lambda is {var expr-with-var}
proc map {args} {
  lmap {*}$args
  # note idea is to use cond to test for 2 or 3 arguments: 2 is with lambda, 3 is with var, list, expr
}

# @todo use det_fields in apidata2dashboarddb.tcl as another testcase.
proc filter {args} {

}

proc fold {args} {


}
