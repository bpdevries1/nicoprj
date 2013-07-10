# libfp.tcl - functional programming in Tcl
# primary goal: make as easy to use as possible, compare Clojure
# secondary goals: make fast, always correct.

# @todo later
# put in separate namespace

# @note heavily based on thing found on wiki.tcl.tk
# @note also based on previous attempts to usable FP methods/procs/functions.
# @note use Tcltest to validate functionality, also usable as documentation.
# @note try to use CLojure function names (and arguments) as basis. 
#       If name conflicts with existing tcl name, use another name, eg if -> ifp 
# @todo find out how to handle closures, some simple things work, and some more elaborate things on the wiki.
# @note ? and - are possible in proc names. ':' also, already used for dict accessors, see libdict.
# @note what to do with lazy handling, eg in if-proc.
# @note use Tcl syntax/formatting and Clojure-like formatting both, most applicable.

##
# @note some easy, helper functions first
proc = {a b} {
  if {$a == $b} {
    return 1
  } else {
    return 0
  }
}

proc not {a} {
 if {$a} {
   return 0 
 } else {
   return 1 
 }
}

proc not= {a b} {
  not {= $a $b}  
}

# @todo maybe a 'proc fn' to create function-objects, lambda's?

proc map {args} {

}

proc filter {args} {

}

proc fold {args} {


}
