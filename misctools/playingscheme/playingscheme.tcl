#!/home/nico/bin/tclsh

# make playing schema for king/queen beachvolleyball etc.

# Versions
# 11-04-2010 NdV refactor to use dic(ionary)s, instead of struct::record. Motivation: garbage collection, struct::record is slow.
# 15-04-2010 NdV new strategy-list with apply. Old procs removed.

# maybe should only generate solution where total_diff_partners already the maximum. It is the second criterium, after the number of games played.
# min_played and max_played should be the same.
# for the mutation: if min-played and max-played not the same, then player can be changed with the bench (non-playing), otherwise only with playing.
# fitness can also improve if the order of the games is better. But leave this for later.

package require ndv
package require Tclx
package require struct::list
package require math
package require math::statistics ; # voor bepalen std dev.

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set log [::ndv::CLogger::new_logger [file tail [info script]] info]

::ndv::source_once ldeep.tcl

proc main {argc argv} {
  global log ar_argv

  $log debug "argv: $argv"
  set options {
      {a "Allow all kinds of games, not just mixing the (two) groups"}
      {c.arg "1" "Number of courts to play on"}
      {p.arg "4 4" "Number of players in each group"}
      {g.arg "D H" "Names of the groups"}
      {r.arg "8" "Number of rounds to play"}
      {u "Round up number of games so everyone plays the same number of games"}
      {fp.arg 1000 "Weighing factor for #different partners"}
      {fo.arg 1 "Weighing factor for #different opponents"}
      {pop.arg 10 "Population (number of solutions to keep"}
      {iter.arg 0 "Number of iterations to run (0 is infinite)"}
      {fitness.arg 100000 "Fitness level to reach before stopping"}
      {loglevel.arg "" "Set global log level"}
      {print.arg "better" "What to print (all, minimum, better)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "playing-scheme.log"

  $log info "Start"
  
  make_schema  
  
  $log info "Finished"
  ::ndv::CLogger::close_logfile  
 
}

proc make_schema {} {
  global ar_argv log nrounds ngamespp ncourts lst_persons lst_solutions iteration max_diff_partners max_diff_opponents
  calc_nrounds
  $log info "#rounds: $nrounds"
  $log info "#games pp: $ngamespp"
  $log info "#courts: $ncourts"
  $log info "#max diff partners: $max_diff_partners"
  $log info "#max diff opponents: $max_diff_opponents"
  
  srandom [clock seconds]
  
  define_strategies 
  
  # @note if groups have different number of players, than -a needs to be given to have each person play the same
  # number of games.
  
  set lst_persons [make_lst_persons]
  # puts_lst_persons $lst_persons
  
  set lst_solutions [::ndv::times $ar_argv(pop) {make_solution [llength $lst_persons] $lst_persons $nrounds $ngamespp $ncourts}]
  puts_solutions $lst_solutions

  set iteration 0
  if {$ar_argv(iter) > 0} {  
    $log info "Calculating for $ar_argv(iter) iterations." 
    ::ndv::times $ar_argv(iter) evol_iteration
  } else {
    # use goal for fitness, also stop when max is reached.
    $log info "Calculating until max reached or fitness >= $ar_argv(fitness)." 
    set best_sol [lindex $lst_solutions 0]
    set fitness [dict get $best_sol fitness]
    if {([dict get $best_sol total_diff_partners] >= $max_diff_partners) && ([dict get $best_sol total_diff_opponents] >= $max_diff_opponents)} {
      set max_reached 1 
    } else {
      set max_reached 0 
    }
    while {$fitness < $ar_argv(fitness) && !$max_reached} {
      evol_iteration 
      set best_sol [lindex $lst_solutions 0]
      set fitness [dict get $best_sol fitness]
      if {([dict get $best_sol total_diff_partners] >= $max_diff_partners) && ([dict get $best_sol total_diff_opponents] >= $max_diff_opponents)} {
        set max_reached 1 
      }      
    }
    $log info "Finished!"
    $log info "Max reached: $max_reached"
    $log info "Fitness: $fitness (goal: $ar_argv(fitness))"
  }
  puts "The final solutions:"
  puts_solutions $lst_solutions
}

proc compare_solution {a b} {
  if {[dict get $a fitness] < [dict get $b fitness]} {
    return -1 
  } elseif {[dict get $a fitness] > [dict get $b fitness]} {
    return 1 
  } else {
    return 0 
  }
}


# list of lists of persons: [[D1 D2 D3 D4] [H1 H2 H3 H4]]
proc make_lst_persons {} {
  global ar_argv log max_group
  set result {}
  set max_group [::math::max {*}$ar_argv(p)]
  set format "%0[string length $max_group]d"  
  foreach countgroup $ar_argv(p) namegroup $ar_argv(g) {
    if {$countgroup == {}} {
      continue 
    }
    $log debug "Making #$countgroup group persons for $namegroup" 
    set sublist {}
    for {set i 1} {$i <= $countgroup} {incr i} {
      lappend sublist "$namegroup[format $format $i]" 
    }
    lappend result $sublist
  }
  return $result
}

proc puts_lst_persons {lst_persons} {
  foreach grp $lst_persons {
    foreach p $grp {
      puts $p 
    }
  }
   
}

# @todo use u argument, now always assume this is set, so each player will play the same number of games.
# @return list: number of rounds, number of games per person, number of courts used.
proc calc_nrounds {} {
  global ar_argv log nrounds ngroups ngamespp ncourts lst_persons lst_solutions \
    iteration max_diff_partners max_diff_opponents fitness_maxpartners

  set ngroups [llength $ar_argv(p)]
  set npersons [::math::sum {*}$ar_argv(p)]
  set ar_argv(c) [::math::min $ar_argv(c) [expr floor(1.0 * $npersons / 4)]]
  set ncourts $ar_argv(c)
  set nperround [expr 4 * $ar_argv(c)]
  set gcd [gcd $nperround $npersons]
  set kgv [expr $nperround * $npersons / $gcd] ; # kleinste gemene veelvoud; smallest common multiple
  set nrounds_min [expr round($kgv / $nperround)]
  set nrounds $ar_argv(r)
  if {$nrounds <= $nrounds_min} {
    set nrounds $nrounds_min
  } else {
    # round up to multiple of nrounds_min
    set nrounds [expr round(ceil(1.0 * $nrounds / $nrounds_min) * $nrounds_min)]
  }
  set ngamespp [expr $nrounds * $nperround / $npersons]
  if {$ngroups == 1} {
    set max_diff_partners1 [expr $npersons * ($npersons - 1)]
    set max_diff_opponents1 $max_diff_partners1
  } else {
    # 2 groepen van personen
    set max_diff_partners1 [expr 2 * [::math::product {*}$ar_argv(p)]]
    set max_diff_opponents1 [expr $npersons * ($npersons - 1)]
  }
  # als aantal wedstrijden niet toereikend is, dan minder
  set max_diff_partners2 [expr $npersons * $ngamespp * 1]
  set max_diff_opponents2 [expr $npersons * $ngamespp * 2]
  set max_diff_partners [::math::min $max_diff_partners1 $max_diff_partners2]
  set max_diff_opponents [::math::min $max_diff_opponents1 $max_diff_opponents2]
  
  # onderstaande voor bepalen strategy, filter hierop.
  set fitness_maxpartners [expr $ar_argv(fp) * $max_diff_partners]
}

# @todo gebruik ::struct::list swap listvar i j 
#
#


proc make_solution {ngroups lst_persons nrounds ngamespp ncourts} {
  # eerste take: elke ronde los bekijken, dus kan zijn dat niet iedereen evenveel speelt.
  # voorlopig even los de 1 en 2 groeps oplossingen
  set lst_rounds [::ndv::times $nrounds {make_round $ngroups $lst_persons $ncourts}]
  return [add_statistics $lst_rounds "Initial solution"]
}

# group van spelers husselen en in wedstrijden/bank zetten.
# @todo maybe also need ngamespp
proc make_round {ngroups lst_persons ncourts} {
  global log
  set shuffled_groups [::struct::list map $lst_persons shuffle_group] 
  # $log debug "shuffled groups: $shuffled_groups"
  set grp [zip_groups $shuffled_groups]
  # lrange: vanaf - tot en met.
  # @todo dit met soort list split te doen?
  for {set c 1} {$c <= $ncourts} {incr c} {
    lappend lst_games [lrange $grp [expr ($c-1) * 4] [expr ($c-1) * 4 + 3]]   
  }
  # overblijvende op de bank
  lappend lst_games [lrange $grp [expr 4 * $ncourts] end]
  return $lst_games
}


# @param lst_groups {{D1 D2 D3 D4} {H1 H2 H3 H4}}
# @param groups don't have to be the same size
# @result {D1 H1 D2 H2 D3 H4 D4 H4}
proc zip_groups {lst_groups} {
  # for now use global max_groups
  global log max_group
  set ngroups [llength $lst_groups]
  set result {}
  for {set i 0} {$i < $max_group} {incr i} {
    for {set i_grp 0} {$i_grp < $ngroups} {incr i_grp} {
      set val [lindex $lst_groups $i_grp $i]
      if {$val != ""} {
        lappend result $val
      }
    }
  }
  return $result
}

proc add_statistics {lst_rounds note} {
  global lst_persons log
  if {$lst_rounds == {}} {
    set fitness -1000 
    set note "Empty solution"
    set sol [dict create lst_rounds $lst_rounds fitness $fitness note $note]
    return $sol
  } else {
    fill_stats_arrays $lst_rounds ar_nplayed ar_partner ar_opponent
    set min_played 1000
    set max_played 0
    set total_diff_partners 0
    set total_diff_opponents 0
    set lst_persons_f [::struct::list flatten $lst_persons]
    set lst_player_stats {}
    set total_diff_partners 0
    set total_diff_opponents 0
    foreach person $lst_persons_f {
      set ngames [incr ar_nplayed($person) 0]
      set max_played [::math::max $max_played $ngames]
      set min_played [::math::min $min_played $ngames]
      # $log debug "Making rec_player_stats: -player $person -ngames $ngames"
      set ndiff_partners [::math::sum {*}[::struct::list mapfor p2 $lst_persons_f {
        incr ar_partner($person,$p2) 0
      }]]
      incr total_diff_partners $ndiff_partners
      set ndiff_opponents [::math::sum {*}[::struct::list mapfor p2 $lst_persons_f {
        incr ar_opponent($person,$p2) 0
      }]]
      incr total_diff_opponents $ndiff_opponents
      lappend lst_player_stats [dict create player $person ngames $ngames \
         ndiff_partners $ndiff_partners ndiff_opponents $ndiff_opponents]
    }
    # set stdev_nplayed [math::sigma {*}[struct::list mapfor el $lst_persons_f {iden $ar_nplayed($el)}]]
    set dict_stdev [dict create]
    foreach stat {ngames ndiff_partners ndiff_opponents} {
      # 17-4-2010 blijkbaar werkt dict append niet goed, of ik doe iets doms, in REPL test doet 'ie het wel.
      # set dict_stdev [dict append $dict_stdev $stat [math::sigma {*}[struct::list mapfor el $lst_player_stats {dict get $el $stat}]]]
      lappend dict_stdev $stat [math::sigma {*}[struct::list mapfor el $lst_player_stats {dict get $el $stat}]]
    }
    #set stdev_nplayed [math::sigma {*}[struct::list mapfor el $lst_player_stats {dict get $el ngames}]]
    #set stdev_npartners [math::sigma {*}[struct::list mapfor el $lst_player_stats {dict get $el ndiff_partners}]]
    #set stdev_nopponents [math::sigma {*}[struct::list mapfor el $lst_player_stats {dict get $el ndiff_opponents}]]
    # puts "stdev: $stdev"
    set fitness [calc_fitness $min_played $max_played $total_diff_partners $total_diff_opponents $dict_stdev]
    set sol [dict create lst_rounds $lst_rounds lst_player_stats $lst_player_stats \
                               min_played $min_played max_played $max_played \
                               total_diff_partners $total_diff_partners \
                               total_diff_opponents $total_diff_opponents \
                               fitness $fitness note $note]
    return $sol
  }
}


proc fill_stats_arrays {lst_rounds ar_nplayed_name ar_partner_name ar_opponent_name} {
  upvar $ar_nplayed_name ar_nplayed
  upvar $ar_partner_name ar_partner
  upvar $ar_opponent_name ar_opponent
  array unset ar_nplayed
  array unset ar_partner
  array unset ar_opponent
  foreach round $lst_rounds {
    # last game in round is the bench, don't check.
    foreach game [lrange $round 0 end-1] {
      foreach player $game {
        incr ar_nplayed($player) 
      }
      lassign $game p1 p2 p3 p4
      set ar_partner($p1,$p2) 1
      set ar_partner($p2,$p1) 1
      set ar_partner($p3,$p4) 1
      set ar_partner($p4,$p3) 1
      set ar_opponent($p1,$p3) 1
      set ar_opponent($p1,$p4) 1
      set ar_opponent($p2,$p3) 1
      set ar_opponent($p2,$p4) 1
      set ar_opponent($p3,$p1) 1
      set ar_opponent($p3,$p2) 1
      set ar_opponent($p4,$p1) 1
      set ar_opponent($p4,$p2) 1
    }
  }
}

# @todo also take into account if we have exactly the same games (regarding mirroring), i.e. with 5 players and 15 games
# 17-4-2010 als min_played != max_played, dan -stdev retourneren. Idee is om fitness functie preciezer te maken, en elke verbetering mee te nemen.
proc calc_fitness {min_played max_played total_diff_partners total_diff_opponents dict_stdev} {
  global ar_argv
  # if min_played is not equal to max_played, then the score stays low, based on the difference
  if {$min_played < $max_played} {
    # return [expr $min_played - $max_played]
    # return -$nplayed_stdev 
    return -[dict get $dict_stdev ngames]
  } else {
    # return [expr ($ar_argv(fp) * $total_diff_partners) + ($ar_argv(fo) * $total_diff_opponents)]
    return [expr ($ar_argv(fp) * $total_diff_partners) + ($ar_argv(fo) * $total_diff_opponents) - \
      [dict get $dict_stdev ndiff_partners] - [dict get $dict_stdev ndiff_opponents]]
  }
}

proc evol_iteration {} {
  global log lst_solutions ar_argv iteration
  incr iteration
  set old_fitness [dict get [lindex $lst_solutions 0] fitness]
  set new_solutions [::struct::list map $lst_solutions mutate_solution]
  # set sorted_solutions [lsort -decreasing -command compare_solution [concat $lst_solutions $new_solutions]]
  # NdV 27-3-2010 put new solutions first, so that with the same fitness the new ones will survice.
  # $log debug "old solutions: $lst_solutions"
  set sorted_solutions [lsort -decreasing -command compare_solution [concat $new_solutions $lst_solutions]]
  if {$ar_argv(print) == "all"} {
    puts "Iteration $iteration"
    puts_solutions $lst_solutions
  } elseif {$ar_argv(print) == "minimum"} {
    # don't print anything 
  } else {
    if {[expr $iteration % 100] == 0} {
      $log debug "Iteration $iteration"
      puts_dot
      #@todo misschien deze logging op nieuwe dict manier.
      #$log info "Old fitnesses: [::struct::list mapfor sol $lst_solutions {$sol cget -fitness}]"
      #$log info "New fitnesses: [::struct::list mapfor sol $new_solutions {$sol cget -fitness}]"
    }
    if {[dict get [lindex $sorted_solutions 0] fitness] > $old_fitness} {
      $log info "Found better solution in iteration $iteration, fitness = [dict get [lindex $sorted_solutions 0] fitness]"
      puts "Iteration $iteration"
      puts_solutions $lst_solutions
    }
  }
  set lst_solutions [lrange $sorted_solutions 0 [expr $ar_argv(pop) - 1]]
}

proc puts_dot {} {
  global stderr
  puts -nonewline stderr "."
  flush stderr
}

proc define_strategies {} {
  global log lst_strategies fitness_maxpartners 
  set lst_strategies {}
  set lst_strategies2 {}
  
  # when min_played < max_played, i.e. fitness < 0
  lappend lst_strategies [list {sol {
    set lst_rounds [dict get $sol lst_rounds]
    set rnd [random_int [llength $lst_rounds]] 
    set lst_rounds [lreplace $lst_rounds $rnd $rnd [mutate_round_bench [lindex $lst_rounds $rnd]]]
    set sol_note "Change in round (bench) [expr $rnd + 1]"
    list $lst_rounds $sol_note
  }} {sol {expr [dict get $sol fitness] < 0}}]
  
  # when teams are not optimal yet (max diff partners), same fitness as previous
  lappend lst_strategies [list {sol {
    set sol_note "mutate_round_bench for two (possibly the same) rounds"
    set lst_rounds [dict get $sol lst_rounds]
    ::ndv::times 2 {
      set rnd [random_int [llength $lst_rounds]] 
      set lst_rounds [lreplace $lst_rounds $rnd $rnd [mutate_round_bench [lindex $lst_rounds $rnd]]]
    }
    list $lst_rounds $sol_note
  }} [replace_vars {sol {expr ([dict get $sol fitness] >= 0) && ([dict get $sol fitness] < $fitness_maxpartners)}} fitness_maxpartners]]
  # gebruik hierboven replace_vars, gebruikelijk is om dit met [list ] te doen.
  # dit lijkt dat wat op de lisp manier met backtick en komma.  
  
  # teams are ok (max_diff_partners), now only switch teams, fitness >= fp * max_diff_partners.
  lappend lst_strategies [list {sol {
    global ncourts
    set sol_note "Keep teams together, change two teams if possible"
    set lst_rounds [dict get $sol lst_rounds]
    # 18-4-2010 regel hieronder stond er nog, volgens mij niet goed!
    # set lst_rounds [::struct::list map $lst_rounds mutate_round_bench]
    lassign [choose_random [llength $lst_rounds] 2] rnd1 rnd2
    set rnd_team1 [random_int [expr 2 * $ncourts]]
    set rnd_team2 [random_int [expr 2 * $ncourts]]
    if {[round_team_switch_ok $sol $rnd1 $rnd2 $rnd_team1 $rnd_team2]} {
      # hier lisp idioom wel handig, pattern matching in method declaratie.
      set team1 [det_team_in_round [lindex $lst_rounds $rnd1] $rnd_team1]
      set team2 [det_team_in_round [lindex $lst_rounds $rnd2] $rnd_team2]
      # voor de replace zou een macro wel handig zijn, of iets anders wat kan vervangen.
      set lst_rounds [lreplace $lst_rounds $rnd1 $rnd1 [replace_round_playing [lindex $lst_rounds $rnd1] $rnd_team1 $team2]]
      set lst_rounds [lreplace $lst_rounds $rnd2 $rnd2 [replace_round_playing [lindex $lst_rounds $rnd2] $rnd_team2 $team1]]
    } else {
      # return empty solution
      set lst_rounds {}
    }
    list $lst_rounds $sol_note
  }} [replace_vars {sol {expr [dict get $sol fitness] >= $fitness_maxpartners}} fitness_maxpartners]] 
}

# 13-4-2010 vervang de varnames in args door actuele waarden (met upvar) in str
# upvar kan klaarblijkelijk meerdere keren met dezelfde doel-var worden uitgevoerd...
# nodig ivm apply, die kent weinig andere vars; met global ook niet netjes.
proc replace_vars {str args} {
  global log
  $log debug "replace_globals: $str"
  foreach varname $args {
    upvar $varname var
    $log debug "$varname = $var"
    set str [regsub -all "\\\$$varname" $str $var]
  }
  $log debug "result: $str"
  return $str
}

# each strategy is a list [lambda expression sol -> [lst_rounds, sol_note], lambda sol -> 0/1]
# the second lambda is a filter: can this strategy be applied with the current solution? (based on e.g. fitness)
proc mutate_solution {sol} {
  # strategies gebruiken wel global vars, hier definieren?!
  global log nrounds ncourts max_diff_partners lst_strategies ar_argv
  
  set lst_strat_f [::struct::list filterfor strat $lst_strategies {
    [apply [lindex $strat 1] $sol] > 0
  }]
  
  #$log debug "#valid strategies for sol: [llength $lst_strat_f]"
  #$log debug "1st valid strategy for sol: [lindex $lst_strat_f 0 1]"
  
  set strategy [random_list $lst_strat_f]
  if {[llength $lst_strat_f] > 1} {
    $log debug "chosen strat: [string range $strategy 100 200]" 
  }
  
  add_statistics {*}[apply [lindex $strategy 0] $sol]
}

# mutate a round by replacing a player with a bench sitter
# @todo? take into account the number of games for each player
# for now, just choose randomly, but only replace player with another from the same group
# @param round a rec_round record.
# @return a new rec_round record.
proc mutate_round_bench {round} {
  global ncourts
  set lst_games $round ; # 11-4-2010 the round is now a list of games.
  set bench [lindex $lst_games end]
  set rnd_game [random_int $ncourts]
  set old_game [lindex $lst_games $rnd_game]
  lassign [mutate_game_bench $old_game $bench] new_game new_bench
  
  set new_lst_games [lreplace [lreplace $lst_games end end $new_bench] $rnd_game $rnd_game $new_game]
  # check_lst_games $new_lst_games
  return $new_lst_games
}

# 11-5-2010 blijkt een fout in algoritme te zitten: teams op bench spelen ook, kan dus niet.
# mutate_round_bench is waarschijnlijke boosdoener, dus testen.
proc check_lst_games {lst_games} {
  global log
  set lst [lsort [::struct::list flatten $lst_games]]
  foreach el $lst {
    set ar($el) 1 
  }
  if {[llength $lst] != [llength [array names ar]]} {
    $log error "Members in list are not unique: $lst_games"
    error "Members in list are not unique: $lst_games"
  }
}

proc mutate_game_bench {game bench} {
  set rnd_bench [random_int [llength $bench]]
  set player_bench [lindex $bench $rnd_bench]
  set rnd_player [random_int 4]
  set player [lindex $game $rnd_player]
  if {![same_group $player_bench $player]} {
    # choose the other player on the same side
    set rnd_player [other_player_index $rnd_player]
    set player [lindex $game $rnd_player]
  }
  # @todo hier lset voor gebruiken, want game en bench zijn toch al (value) kopieen.
  set new_game [lreplace $game $rnd_player $rnd_player $player_bench]
  set new_bench [lreplace $bench $rnd_bench $rnd_bench $player]
  
  return [list $new_game $new_bench]
}

# mutate a round by switching 2 playing players from the same group
# @todo? take into account the partners and opponents of each player
# for now, just choose randomly, but only replace player with another from the same group
# @param round a rec_round record.
# @return a new rec_round record.
proc mutate_round_playing {round} {
  global log ncourts ngroups 
  $log debug "Mutate_round_playing for round: $round, #groups = $ngroups" 
  if {$ngroups == 1} {
    # choose 2 different random value bij limiting and changing the second one.
    lassign [choose_random [expr $ncourts * 4] 2] rnd1 rnd2
  } else {
    set rnd_group [random_int 2]
    lassign [choose_random [expr $ncourts * 2] 2] rnd1 rnd2
    set rnd1 [expr 2 * $rnd1 + $rnd_group]
    set rnd2 [expr 2 * $rnd2 + $rnd_group]
  }
  set lst_games $round
  set ndx_game1 [expr $rnd1 / 4]
  set ndx_game2 [expr $rnd2 / 4]
  if {$ndx_game1 == $ndx_game2} {
    set old_game [lindex $lst_games $ndx_game1] 
    set new_game [lswap $old_game [expr $rnd1 % 4] [expr $rnd2 % 4]]
    set new_lst_games [lreplace $lst_games $ndx_game1 $ndx_game1 $new_game]
  } else {
    set old_game1 [lindex $lst_games $ndx_game1] 
    set old_game2 [lindex $lst_games $ndx_game2] 
    set new_game1 [lreplace $old_game1 \
       [expr $rnd1 % 4] [expr $rnd1 % 4] [lindex $old_game2 [expr $rnd2 % 4]]]
    set new_game2 [lreplace $old_game2 \
       [expr $rnd2 % 4] [expr $rnd2 % 4] [lindex $old_game1 [expr $rnd1 % 4]]]
    set new_lst_games [lreplace [lreplace $lst_games $ndx_game1 $ndx_game1 $new_game1] $ndx_game2 $ndx_game2 $new_game2]   
       
  }
  check_lst_games $new_lst_games
  return $new_lst_games
}

# @param round
# @param ndx_team: 0 to get first team in first game, 1 to get second team in first game, 2 to get first team in second game, etc.
# @return [list player1 player2]
# @note in lisp zou je dit alles waarschijnlijk met lists in lists doen. en dan waarsch ook met setf-able positie
proc det_team_in_round {round ndx_team} {
  return [lrange [lindex $round [expr $ndx_team / 2]] [expr ($ndx_team % 2) * 2] [expr ($ndx_team % 2) * 2 + 1]] 
}

# check if a switch from round1.team1 with round2.team2 is possible, i.e. no duplicate players in each round.
# no real need to check if the teams are the same: with 4+4, this does not happen, with others, the change has no effect.
proc round_team_switch_ok {sol ndx_round1 ndx_round2 ndx_team1 ndx_team2} {
  global log
  set lst_players1 [det_lst_players [lindex [dict get $sol lst_rounds] $ndx_round1]]
  set lst_players2 [det_lst_players [lindex [dict get $sol lst_rounds] $ndx_round2]]
  set new_lst1 [lreplace $lst_players1 [expr $ndx_team1 * 2] [expr $ndx_team1 * 2 + 1] {*}[lrange $lst_players2 [expr $ndx_team2 * 2] [expr $ndx_team2 * 2 + 1]]]  
  set new_lst2 [lreplace $lst_players2 [expr $ndx_team2 * 2] [expr $ndx_team2 * 2 + 1] {*}[lrange $lst_players1 [expr $ndx_team1 * 2] [expr $ndx_team1 * 2 + 1]]]
  if {[lunique $new_lst1] && [lunique $new_lst2]} {
    # $log debug "the switch is ok. lst1=$lst_players1, lst2=$lst_players2, new1=$new_lst1, new2=$new_lst2"
    return 1 
  } else {
    # $log debug "the switch is not ok. lst1=$lst_players1, lst2=$lst_players2, new1=$new_lst1, new2=$new_lst2"
    return 0 
  }
}

# @return a flat list of all players in a round, don't include bench sitters.
proc det_lst_players {round} {
  # return [::struct::list flatten [::struct::list mapfor game [det_real_games $round] {$game cget -lst_players}]]
  return [::struct::list flatten [lrange $round 0 end-1]]
  
}

# @return a list of the real games in the round, i.e. without the bench.
# the bench is always the last element.
proc det_real_games {round} {
  return [lrange $round 0 end-1]
}

# @param round
# @param ndx_team index to replace, see det_team_in_round.
# @param team list of 2 players to put at place index.
# @return new round
# 11-5-2010 bugfix: bench werd niet aangepast, hierdoor op bench spelers die ook spelen in deze ronde.
proc replace_round_playing {round ndx_team team} {
  global log
  set lst_games $round
  set ndx_game [expr $ndx_team / 2]
  # $log info "round: $round; ndx_team: $ndx_team; team: $team; ndx_game: $ndx_game"
  set new_lst_players [lreplace [lindex $lst_games $ndx_game] [expr ($ndx_team % 2) * 2] [expr ($ndx_team % 2) * 2 + 1] {*}$team] 
  # $log info "new_lst_players: $new_lst_players"
  set new_lst_games [fix_bench [lreplace $lst_games $ndx_game $ndx_game $new_lst_players]]  
  # $log info "new_lst_games after fix_bench: $new_lst_games"
  # check_lst_games $new_lst_games
  return $new_lst_games
}

# recalculates the bench based on the games.
proc fix_bench {lst_games} {
  global lst_persons
  set new_bench [::struct::set difference [::struct::list flatten $lst_persons] [::struct::list flatten [lrange $lst_games 0 end-1]]]
  return [lreplace $lst_games end end $new_bench]
}

proc same_group {player1 player2} {
  if {[string range $player1 0 0] == [string range $player2 0 0]} {
    return 1 
  } else {
    return 0
  }
}

# @note also possible with a fixed assoc. array
proc other_player_index {index} {
  if {[expr $index % 2] == 0} {
    return [expr $index + 1] 
  } else {
    return [expr $index - 1] 
  } 
}

# helper functie om in een list 2 elementen te swappen.
proc lswap {lst ndx1 ndx2} {
  set val1 [lindex $lst $ndx1]
  set val2 [lindex $lst $ndx2]
  return [lreplace [lreplace $lst $ndx1 $ndx1 $val2] $ndx2 $ndx2 $val1]
}

proc lswap_new {lst ndx1 ndx2} {
  return [::struct::list swap $lst $ndx1 $ndx2] 
}

######################
# printing functions #
######################
proc puts_solutions {lst_solutions} {
  # @todo sort decreasing on fitness
  global ar_argv
  #      {print.arg "all" "What to print (all, minimum, better)"}
  if {$ar_argv(print) != "all"} {
     puts_solution 1 [lindex $lst_solutions 0]
  } else {
    set sol_nr 0
    foreach sol [lsort -decreasing -command compare_solution $lst_solutions] {
      incr sol_nr 
      puts_solution $sol_nr $sol
    }
  }
}

proc puts_solution {sol_nr sol} {
  global stdout
  puts_solution_file stdout $sol_nr $sol
  set f [open solutions.txt a]
  puts_solution_file $f $sol_nr $sol
  close $f
}  
  
proc puts_solution_file {f sol_nr sol} {
  puts $f "Solution: $sol_nr (id: $sol)\n---------"
  foreach par {fitness min_played max_played total_diff_partners total_diff_opponents note} {
    puts $f "$par: [dict get $sol $par]"
  }
  puts $f "Rounds:"
  set round_nr 0
  foreach round [dict get $sol lst_rounds] {
    incr round_nr
    puts $f "$round_nr: [round_to_string $round]" 
  }
  puts $f "Player statistics:"
  foreach playerstats [dict get $sol lst_player_stats] {
    puts $f [playerstats_to_string $playerstats] 
  }
  puts $f "================================"
}

proc puts_solution_old {sol_nr sol} {
  puts "Solution: $sol_nr (id: $sol)\n---------"
  foreach par {fitness min_played max_played total_diff_partners total_diff_opponents note} {
    puts "$par: [dict get $sol $par]"
  }
  puts "Rounds:"
  set round_nr 0
  foreach round [dict get $sol lst_rounds] {
    incr round_nr
    puts "$round_nr: [round_to_string $round]" 
  }
  puts "Player statistics:"
  foreach playerstats [dict get $sol lst_player_stats] {
    puts [playerstats_to_string $playerstats] 
  }
  puts "================================"
}

proc round_to_string {round} {
   return "[join [::struct::list map [lrange $round 0 end-1] game_to_string] "\t"]\tbench: [join [lsort [lindex $round end]] ", "]"
}

# @todo weet hier niet meer of het een game of een bench is, dus meegeven
# @pre game is een echte game, niet de bench.
proc game_to_string {game} {
  # (M1 F1 v M2 F3)
  lassign $game p1 p2 p3 p4
  return "($p1 $p2 v $p3 $p4)"
}

proc playerstats_to_string {player_stats} {
  return [join [::struct::list mapfor par {player ngames ndiff_partners ndiff_opponents} {
    iden "$par: [dict get $player_stats $par]"
  }] "; "]
}

main $argc $argv

