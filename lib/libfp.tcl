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

proc != {a b} {
  expr ![= $a $b]
}

# deze leuk bedacht, recursief, maar uplevel zou dan ook mee moeten.
proc and_old {exp1 args} {
  if {[uplevel 1 [list expr $exp1]]} {
    if {$args != {}} {
      and {*}$args  
    } else {
      return 1
    }
  } else {
    return 0
  }
}

proc and {args} {
  foreach exp $args {
    if {![uplevel 1 [list expr $exp]]} {
      return 0
    }
  }
  return 1
}

proc or {args} {
  foreach exp $args {
    if {[uplevel 1 [list expr $exp]]} {
      return 1
    }
  }
  return 0
}

# some mathematical functions
proc max {args} {
  if {[llength $args] == 1} {
    set lst [lindex $args 0]
  } else {
    set lst $args
  }
  set res [lindex $lst 0]
  foreach el $lst {
    if {$el > $res} {
      set res $el
    }
  }
  return $res
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

# @todo functies om een lambda naar een proc om te zetten en vice versa
# deze ook functioneel kunnen inzetten, ofwel return value moet direct bruikbaar zijn.
proc proc_to_lambda {procname} {
  list args "$procname {*}\$args"
}

# resultaat van lambda_to_proc mee te geven aan struct::list map en filter bv.
# eerst even simpel met een counter
# vb: struct::list map {1 2 3 4} [lambda_to_proc {x {expr $x * 3}}] => {3 6 9 12}
# vb: struct::list filter {1 2 3 4} [lambda_to_proc {x {expr $x >= 3}}]
set proc_counter 0
proc lambda_to_proc_fout {lambda} {
  global proc_counter
  incr proc_counter
  set procname "zzlambda$proc_counter"
  # proc $procname {*}$lambda ; # combi van args en body
  lassign $lambda largs lbody
  # deze werkt wel als er idd expr voor zou moeten staan, maar niet voor andere dingen.
  # dus bepalen of het moet, of andere lambda_to_proc versie? En deze dan in filter aanroepen.
  # maar ook bij filter optie om via proc of expr aan te roepen.

  # string is expression?
  # of eval?
  
  proc $procname $largs "expr $lbody"
  return $procname
}

proc lambda_to_proc {lambda} {
  global proc_counter
  incr proc_counter
  set procname "zzlambda$proc_counter"
  proc $procname {*}$lambda ; # combi van args en body
  return $procname
}

# anonymous function
proc fn_ff {params body} {
  lambda_to_proc [list $params $body]
}

# anonymous functie with closures eval-ed.
proc fn {params body} {
  lambda_to_proc [list $params [eval_closure $params $body]]
}

# eval vars in closure of the proc, leave params alone.
# first find all occurences of $var and replace by actual value in uplevel, iff
# var does not occur in params.
# TODO: check ${var}, maybe also [set var]
# TODO: check if resulting value should be surrounded by quotes or braces. [2016-07-21 20:56] for now seems ok.
# TODO: This probably fails if body is more complicated, and contains another method call with closure.
proc eval_closure {params body} {
  # want to use regsub which replaces elements with function call. Done this before with
  # FB VuGen scripts, first simpler here.
  # first only change one var.
  # could also use regexp -all -indices and work from there.
  set indices [regexp -all -indices -inline {\$([a-z0-9_]+)} $body]
  # begin at the end, so when changing parts at the end, the indices at the start stay the same.
  foreach {range_name range_total} [lreverse $indices] {
    set varname [string range $body {*}$range_name]
    if {[lsearch -exact $params $varname] < 0} {
      upvar 2 $varname value
      set body [string replace $body {*}$range_total $value]
      # breakpoint
    }
  }
  return $body
  # breakpoint
}

# @todo maybe a 'proc fn' to create function-objects, lambda's?

# @todo handle more than one map-var, for traversing more than one map at the same time?
# @note should handle 2 forms:
# (map var list expression-with-var)
# (map lambda list), where lambda is {var expr-with-var}
proc map_old {args} {
  lmap {*}$args
  # note idea is to use cond to test for 2 or 3 arguments: 2 is with lambda, 3 is with var, list, expr
}

proc map {args} {
  if {[llength $args] == 2} {
    lassign $args arg1 arg2
    if {[info proc $arg1] != {}} {
      set res {}
      foreach el $arg2 {
        lappend res [$arg1 $el]
      }
      return $res
    } else {
      # assume lambda with 2 elements
      map [lambda_to_proc $arg1] $arg2
    }
  } elseif {[llength $args] == 3} {
    # [2016-07-16 12:48] TODO: maybe should not support this, to stay similar to reduce
    # function, which has optional start parameter.
    lassign $args arg1 arg2 arg3
    map [lambda_to_proc [list $arg1 $arg2]] $arg3
  } else {
    error "No 2 or 3 args: $args"
  }
}

# filter is vergelijkbaar aan map, toch soort van dubbele code, voorlopig ok.
proc filter {args} {
  # puts "filter called: $args"
  if {[llength $args] == 2} {
    lassign $args arg1 arg2
    if {[info proc $arg1] != {}} {
      # puts "body: [info body $arg1]"
      set res {}
      foreach el $arg2 {
        if {[$arg1 $el]} {
          lappend res $el
        }
      }
      return $res
    } else {
      # assume lambda with 2 elements
      filter [lambda_to_proc $arg1] $arg2
    }
  } elseif {[llength $args] == 3} {
    lassign $args arg1 arg2 arg3
    filter [lambda_to_proc [list $arg1 $arg2]] $arg3
  } else {
    error "No 2 or 3 args: $args"
  }
}


# @todo use det_fields in apidata2dashboarddb.tcl as another testcase.
# @param args: same as lmap: el list statement
proc filter_old {args} {
  lassign $args var l cmd
  set res {}
  foreach $var $l bool [lmap {*}$args] {
    if {$bool} {
      lappend res [set $var] 
    }
  }
  return $res
}

# first only with fn and list, later also with start value
proc reduce {args} {
  if {[llength $args] == 2} {
    lassign $args fn lst
    if {[info proc $fn] != {}} {
      # TODO: [2016-07-16 12:51] fill in, but not needed now
    } else {
      reduce [lambda_to_proc $fn] $lst
    }
  } else {
    error "!= 2 args not supported: $args"
  }

}

# lib function, could also use struct::list repeat
proc repeat {n x} {
  set res {}
  for {set i 0} {$i < $n} {incr i} {
    lappend res $x 
  }
  return $res
}

# Returns a list of nums from start (inclusive) to end
# (exclusive), by step, where step defaults to 1
# also copied from clojure def.
proc range {start end {step 1}} {
  set res {}
  for {set i $start} {$i < $end} {incr i $step} {
    lappend res $i 
  }
  return $res
}

