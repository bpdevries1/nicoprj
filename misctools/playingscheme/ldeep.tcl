# lreplace function to replace a deep part of a list, compare lindex.

package require control

# @params l <index level 0> <index level 1> .. <index level n-1> {<start level n> <end level n>} {replace by values)
proc ldeepreplace {l args} {
  if {[llength $args] == 2} {
    return [lreplace $l {*}[lindex $args 0] {*}[lindex $args 1]]
  } else {
    lset l {*}[lrange $args 0 end-2] [lreplace [lindex $l {*}[lrange $args 0 end-2]] {*}[lindex $args end-1] {*}[lindex $args end]]
    return $l
  }
}

# @params l <index level 0> <index level 1> .. <index level n-1> {<start level n> <end level n>} {replace by values)
proc ldeepreplace2 {l args} {
  # puts "ldeepreplace: l=$l (#[llength $l]), args=$args"
  if {[llength $args] == 2} {
    # return [lreplace $l {*}[lindex $args 0] {*}[lindex $args 1]]
    #set res [lreplace $l {*}[lindex $args 0] {*}[lindex $args 1]]
    #puts "res: $res"
    #return $res
    return [lreplace $l {*}[lindex $args 0] {*}[lindex $args 1]]
  } else {
    # alleen laatste stuk kan een echte range zijn, daarvoor alleen indexen, dus first en last moeten hetzelfde zijn.
    # lrange houdt 'em op hetzelfde niveau, lindex gaat wel niveau dieper.
    # set res [lreplace $l {*}[lindex $args 0] [ldeepreplace [lrange $l {*}[lindex $args 0]] {*}[lrange $args 1 end]]]
    # set res [lreplace $l {*}[lindex $args 0] [ldeepreplace [lindex $l [lindex $args 0 0]] {*}[lrange $args 1 end]]]
    # set res [lreplace $l [lindex $args 0] [lindex $args 0] [ldeepreplace [lindex $l [lindex $args 0]] {*}[lrange $args 1 end]]]
    # puts "Returning recursive: $res"
    # return $res
    return [lreplace $l [lindex $args 0] [lindex $args 0] [ldeepreplace [lindex $l [lindex $args 0]] {*}[lrange $args 1 end]]]
  }
}

# # @params l <index level 0> <index level 1> .. <index level n-1> {<start level n> <end level n>} 
# ldeeprange $sol 0 0 {2 3} => {H1 D1}
# vgl ldeepreplace, evt hergebruik?
proc ldeeprange {l args} {
  # puts "ldr: args: $args"
  if {[llength $args] == 1} {
    # puts "ldr: [lindex $args 0] (#[llength [lindex $args 0]])" 
    return [lrange $l {*}[lindex $args 0]]
  } else {
    # puts "rec: [lindex $args 0]"
    # return [ldeeprange [lindex $l [lindex $args 0]] {*}[lrange $args 1 end]]
    return [lrange [lindex $l {*}[lrange $args 0 end-1]] {*}[lindex $args end]]
  }
}

# # @params l <index level 0> <index level 1> .. <index level n-1> {<start level n> <end level n>} 
proc ldeeprange2 {l args} {
  # puts "ldr: args: $args"
  if {[llength $args] == 1} {
    # puts "ldr: [lindex $args 0] (#[llength [lindex $args 0]])" 
    return [lrange $l {*}[lindex $args 0]]
  } else {
    # puts "rec: [lindex $args 0]"
    return [ldeeprange [lindex $l [lindex $args 0]] {*}[lrange $args 1 end]] 
  }
}

# # @params l {<index level 0> <index level 1> .. <index level n-1> {<start level n> <end level n>}} {same for second element/range} 
# ldeepswap $sol1 {0 0 {2 3}} {1 0 {0 1}}
proc ldeepswap {l ind1 ind2} {
  set t1 [ldeeprange $l {*}$ind1]
  set t2 [ldeeprange $l {*}$ind2]
  lset l {*}[lrange $ind1 0 end-1] [lreplace [lindex $l {*}[lrange $ind1 0 end-1]] {*}[lindex $ind1 end] {*}$t2]
  lset l {*}[lrange $ind2 0 end-1] [lreplace [lindex $l {*}[lrange $ind2 0 end-1]] {*}[lindex $ind2 end] {*}$t1]
  return $l  
}


proc testset {} {
  ::control::control assert enabled 1
  
  # set l {{a b e f} {c d}}
  set l [list [list a b e f] [list c d]]
  puts "l: $l"
  # test {[ldeepreplace $l {0 0} {g h}]} {{g h} {c d}}
  puts "1: [ldeepreplace $l {0 0} {g h}]"
  control::assert {[ldeepreplace $l {0 0} {g h}] == {g h {c d}}}
  puts "---"
  puts "2: [ldeepreplace $l {0 0} {{g h}}]"
  control::assert {[ldeepreplace $l {0 0} {{g h}}] == {{g h} {c d}}}
  puts "---"
  puts "3: [ldeepreplace $l {0 0} {{g h} {i j}}]"
  control::assert {[ldeepreplace $l {0 0} {{g h} {i j}}] == {{g h} {i j} {c d}}}
  puts "---"
  puts "4: [ldeepreplace $l {0 end} {{g h} {i j}}]"
  control::assert {[ldeepreplace $l {0 end} {{g h} {i j}}] == {{g h} {i j}}}
  puts "---"
  puts "5: l before: $l"
  puts "5: [ldeepreplace $l 0 {0 1} {g h}]"
  control::assert {[ldeepreplace $l 0 {0 1} {g h}] == {{g h e f} {c d}}}
  puts "5: l after: $l"
  puts "---"
  
  control::assert {[ldeepreplace $l {0 0} {g h}] == {g h {c d}}}
  control::assert {[ldeepreplace $l {0 1} {g h}] == {g h}}
  control::assert {[ldeepreplace $l 0 {0 1} {g h}] == {{g h e f} {c d}}}  
  
  set gm1 [list H1 D1 H2 D2]
  set gm2 [list H3 D3 H4 D4]
  set rn1 [list $gm1]
  set rn2 [list $gm2]
  set sol1 [list $rn1 $rn2]
  set gm1a [list H1 D1 H5 D5]
  set rn1a [list $gm1a]
  set sol2 [list $rn1a $rn2]
  
  puts "6: sol1: $sol1"
  puts "6: sol2: $sol2"
  puts "6: sol1.replace => sol2: [ldeepreplace $sol1 0 0 {2 3} {H5 D5}]"
  control::assert {[ldeepreplace $sol1 0 0 {2 3} {H5 D5}] == $sol2}
  
  # en hoe nu een swap te doen van het ene team in een ronde met een ander team in een andere ronde?
  # evt gewoon de swap uitvoeren, en bij bepalen fitness checken of het een valide oplossing is, of dat een speler 2x speelt in een ronde (tegen zichzelf?)
  
  puts "7: sol1: $sol1"
  puts "7: [ldeeprange $sol1 0 0 {2 3}]"
  control::assert {[ldeeprange $sol1 0 0 {2 3}] == {H2 D2}} 
  
  # ldeepswap $sol1 {0 0 {2 3}} {1 0 {0 1}}
  # sol1:  {{H1 D1 H2 D2}} {{H3 D3 H4 D4}}
  puts "8: sol1: $sol1"
  puts "8: [ldeepswap $sol1 {0 0 {2 3}} {1 0 {0 1}}]"
  control::assert {[ldeepswap $sol1 {0 0 {2 3}} {1 0 {0 1}}] == {{{H1 D1 H3 D3}} {{H2 D2 H4 D4}}}} 
  puts "8: sol1 after: $sol1"
  
  # control::assert {0 == 1}
}

# testset
