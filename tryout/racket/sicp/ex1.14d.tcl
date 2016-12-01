#! /usr/bin/env tclsh

# Exercise 1.14 of SICP
#
# draw a node for each function application
# draw arrows from callee to caller with the result as label

# Two ways of drawing
# 1. A single node for more applications with the same parameters, sort-of like memoisation.
# 2. A unique node for each application, so can have duplicates. This is more the actual way it works (without memoisation). Show order of application in nodes.

# This is version c, with passing parent node to callees.

# TODO
# * Generalise, possibly using a special version of proc.
#   - maybe need to use special 'apply' function, maybe the special procs can 'sense' they call another special proc or are called from it.
# * Implement in Scheme/Racket (already available?)
# * Call graph already available in Tcl?
#   - see eg. http://wiki.tcl.tk/14471
#   - combination with graphviz not seen.
# * Also use for ex1.15 (calculate sine function).

# keep several (working) versions of this script.

if 0 {
  uitgangspunten bij generalise:
  * niet nodig om appl_node en appl_result zelf aan te roepen in je functies.

  opties:
  * proc-def met speciale proc proc, bv nodeproc
  * vraag hoe calls dan moeten, zou niet nodig moeten zijn iets als nodecall te doen.
  * mss wel nodig procs dan in goede volgorde te definieren, zodat je calls kunt herkennen, en evt kan aanpassen.
  * dan wel ook recursief, dus als je al met een proc-def bent begonnen.
  * kan eerst wel expliciet de call doen, of de $node nog meegeven. Ofwel in stukjes omzetten.


}

package require ndv

use libfp
use libmacro

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

proc count_change {amount} {
  global fd
  set node [appl_node count_change $amount]
  set res [cc $node $amount 5]
  return $res
}

proc nodeproc {name arguments body} {
  set arguments2 [list \$amount \$koc]
  proc $name [concat callernode $arguments] [syntax_quote {
    global fd
    # set node [appl_node ~$name ~@$arguments]
    set node [appl_node ~$name $amount $koc]

    # TODO: onderstaande werkt niet, wil resultaat van syntax_quote zien, vgl
    # macroexpand-1. Maar moet echt naar Clojure overstappen!
    # set node [appl_node ~$name ~@$arguments2]

    ~@$body

    appl_result $callernode $node $res
    return $res

  }]
}

# looks more and more like I need a real macro system, so switch to clojure or racket. Maybe first Clojure.
proc nodereturn {args} {
  # nothing for now.
}

# returns just result now
nodeproc cc {amount koc} {
  #global fd
  #set node [appl_node cc $amount $koc]
  if {$amount == 0} {
    set res 1
    # nodereturn 1
  } elseif {($amount < 0) || ($koc == 0)} {
    set res 0
  } else {
    set res [expr [cc $node $amount [expr $koc - 1]] + \
                 [cc $node [expr $amount - [first_denomination $koc]] $koc]]
  }
  # appl_result $callernode $node $res
  # return $res ; # TODO: want to be able to keep this one. Maybe use a special
  # nodereturn proc?
  nodereturn $res
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

# create a node for one functional application
proc appl_node {args} {
  global fd nodenr opt
  incr nodenr
  if {[:unique $opt]} {
    set node [puts_node_stmt $fd "[join $args " "] \[$nodenr\]" shape rectangle]
  } else {
    set node [puts_node_stmt $fd [join $args " "] shape rectangle]
  }
  return $node
}

# draw from caller to callee, otherwise graph upside down.
# use option 1, memoisation.
proc appl_result {caller callee res} {
  global fd
  puts $fd [edge_stmt_once $callee $caller label $res]
}

main $argv

