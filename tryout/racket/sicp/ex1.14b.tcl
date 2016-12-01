#! /usr/bin/env tclsh

# Exercise 1.14 of SICP
#
# draw a node for each function application
# draw arrows from callee to caller with the result as label

# Two ways of drawing
# 1. A single node for more applications with the same parameters, sort-of like memoisation.
# 2. A unique node for each application, so can have duplicates. This is more the actual way it works (without memoisation). Show order of application in nodes.

# TODO
# * pass parent node to callee, to draw, seems less intrusive.
# * Generalise, possibly using a special version of proc.
#   - maybe need to use special 'apply' function, maybe the special procs can 'sense' they call another special proc or are called from it.
#   - Drawing the edges can be done from either the caller or the callee. Maybe callee has preference, only needs to know the caller.
# * Implement in Scheme/Racket (already available?)
# * Call graph already available in Tcl?
#   - see eg. http://wiki.tcl.tk/14471
#   - combination with graphviz not seen.
# * Also use for ex1.15 (calculate sine function).

# keep several (working) versions of this script.

package require ndv

use libfp

proc main {argv} {
  global fd opt
  set options {
    {unique "Draw unique node for each function application"}
    {amount.arg "11" "Amount to split"}
  }
  set opt [getoptions argv $options ""] 
  set amount [:amount $opt]
  if {[count $argv] == 0} {
    set amount 11
  } else {
    lassign $argv amount
  }
  
  set dotfilename ex1.14-amount-$amount.dot
  set pngfilename ex1.14-amount-$amount.png
  set fd [open $dotfilename w]
  write_dot_header $fd BT

  set change [count_change $amount]
  puts "Number of ways to change $amount cents: $change"
  write_dot_footer $fd
  close $fd
  do_dot $dotfilename $pngfilename
}

proc count_change_v1 {amount} {
  first [cc $amount 5]
}

proc count_change {amount} {
  global fd
  set node [application_node count_change $amount]
  set res [cc $amount 5]
  cc_return $node $res
  first $res
}

# create a node for one functional application
proc application_node {args} {
  global fd nodenr opt
  incr nodenr
  if {[:unique $opt]} {
    set node [puts_node_stmt $fd "[join $args " "] \[$nodenr\]" shape rectangle]
  } else {
    set node [puts_node_stmt $fd [join $args " "] shape rectangle]
  }
  return $node
}

# returns a tuple: result, node
# Monad could work here?
proc cc {amount koc} {
  global fd
  # set node [cc_node $amount $koc]
  set node [application_node $amount $koc]
  if {$amount == 0} {
    list 1 $node
  } elseif {($amount < 0) || ($koc == 0)} {
    list 0 $node
  } else {
    set left [cc $amount [expr $koc - 1]]
    set right [cc [expr $amount - [first_denomination $koc]] $koc]
    cc_return $node $left
    cc_return $node $right
    list [expr [first $left] + [first $right]] $node
  }
}

# draw from caller to callee, otherwise graph upside down.
# use option 1, memoisation.
proc cc_return {caller callee} {
  global fd
  # puts $fd [edge_stmt $caller [second $callee] label [first $callee]]
  puts $fd [edge_stmt_once [second $callee] $caller label [first $callee]]
}

proc cc_v1 {amount koc} {
  if {$amount == 0} {
    return 1
  } elseif {($amount < 0) || ($koc == 0)} {
    return 0
  } else {
    expr [cc $amount [expr $koc - 1]] + \
        [cc [expr $amount - [first_denomination $koc]] $koc]
  }
}

proc first_denomination {koc} {
  switch $koc {
    1 {return 1}
    2 {return 5}
    3 {return 10}
    4 {return 25}
    5 {return 50}
  }
}

main $argv

