# stukje tcl
proc cons {a lat} {
  concat [list $a] $lat
}

apply {{x y} {expr $x * $y}} 4 6

set multiply {{x y} {expr $x * $y}}
apply $multiply 4 6

proc multiremberco_old {a lat col} {
  if {$lat == {}} {
    puts "col: $col"
    apply $col {} {}
  } elseif {$a == [lindex $lat 0]} {
    multiremberco $a [lrange $lat 1 end] [list [list diff same] [list apply $col $diff [cons $a $same]]]
  } else {
    multiremberco $a [lrange $lat 1 end] [list [list diff same] [list apply $col [cons [lindex $lat 0] $diff] $same]]
  }
}

proc multiremberco {a lat col} {
  if {$lat == {}} {
    puts "apply: $col {} {}"
    apply $col {} {}
  } elseif {$a == [lindex $lat 0]} {
    multiremberco $a [lrange $lat 1 end] "\{diff same\} \{apply \{$col\} \$diff \[cons $a \$same\]\}"
  } else {
    multiremberco $a [lrange $lat 1 end] "\{diff same\} \{apply \{$col\} \[cons [lindex $lat 0] \$diff\] \$same\}"
  }
}


set makelist {{l1 l2} {list $l1 $l2}}

apply $makelist {1 2 3} {4 5 6}

multiremberco a {} $makelist
multiremberco a {a} $makelist

set col $makelist
set lat {a}
# moet string opleveren: [list [list diff same] [list apply $col [cons [lindex $lat 0] $diff] $same]]
set col2 "\{diff same\} \{apply \{$col\} \[cons [lindex $lat 0] \$diff\] \$same\}"

apply $col2 {} {}

% multiremberco a {a} $makelist
apply {diff same} {
  apply {{l1 l2} {
    list $l1 $l2
  } } $diff [cons a $same]
} {} {}
apply =>
  apply {{l1 l2} {
    list $l1 $l2
  } } {} [cons a {}]
eval =>
  apply {{l1 l2} {
    list $l1 $l2
  } } {} {a}
apply =>
    list {} {a}
eval =>
  {{} {a}}

# buitenste loslaten op resultaat van binnenste, binnenste is eerder gemaakt

{} a

% multiremberco a {b} $makelist
col: {diff same} {apply {{l1 l2} {list $l1 $l2}} [cons b $diff] $same}
b {}

% multiremberco a {a b} $makelist
col: {diff same} {apply {{diff same} {apply {{l1 l2} {list $l1 $l2}} $diff [cons a $same]}} [cons b $diff] $same}
b a

% multiremberco a {b c} $makelist
apply {diff same} {
  apply {{diff same} {
    apply {{l1 l2} {
      list $l1 $l2
     }} [cons b $diff] $same
  } } [cons c $diff] $same
} {} {}
apply =>
  apply {{diff same} {
    apply {{l1 l2} {
      list $l1 $l2
     }} [cons b $diff] $same
  } } [cons c {}] {}
eval =>
  apply {{diff same} {
    apply {{l1 l2} {
      list $l1 $l2
     }} [cons b $diff] $same
  } } {c} {}
apply =>
    apply {{l1 l2} {
      list $l1 $l2
     }} [cons b {c}] {}
eval =>
    apply {{l1 l2} {
      list $l1 $l2
     }} {b c} {}
apply => 
      list {b c} {}
eval =>
{{b c} {}}

SICP apply/eval loop wordt zo wel weer wat duidelijker.

Als je eerst alleen alle apply's doet:
apply {diff same} {
  apply {{diff same} {
    apply {{l1 l2} {
      list $l1 $l2
     }} [cons b $diff] $same
  } } [cons c $diff] $same
} {} {}
toepassen =>
  apply {{diff same} {
    apply {{l1 l2} {
      list $l1 $l2
     }} [cons b $diff] $same
  } } [cons c {}] {}
toepassen =>
    apply {{l1 l2} {
      list $l1 $l2
     }} [cons b [cons c {}]] {}
toepassen =>
      list [cons b [cons c {}]] {}
als laatste eval =>
{{b c} {}}

de 'b' als eerste behandeld, zit dus als diepste in een col-functie, maar komt 
uiteindelijk binnenstebuiten als eerste in de eval. 
de 'c' is de laatste, en wordt dan ge-cons-ed aan {} en wordt zo laatste element.

