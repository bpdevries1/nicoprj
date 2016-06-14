#!/usr/bin/env tclsh861

package require ndv

set MAX_SIMULATIONS 100000
set SIM1 0

if {$SIM1} {
  set_log_global debug
} else {
  set_log_global info  
}

set str_questions {
  1	"smallest time frame"
  2	"stmt appl false"
  3	"stmt baseline true"
  4	"benefit business trans"
  5	"which is calculated"
  6	"which not business trans"
  7	"slowdown online banking"
  8	"how long baseline calc?"
  9	"insight CPU app server"
  10	"which client single server"
  11	"SLA agreements coming year"
  12	"meant by throughput"
  13	"socketwrite0"
  14	"succesful logins 30d"
  15	"what measure aggr vals to repo hourly"
}

proc main {argv} {
  global found_answers n_found_answers
  file delete All-answers-counts.txt 
  set questions [det_questions]
  set poss_answers [read_possible_answers]
  set takes [read_takes]
  check_answers $poss_answers $takes
  simulate $questions $poss_answers $takes
  log info "Found answers: $n_found_answers"
  puts_answers_counts
  # breakpoint
}

proc det_questions {} {
  global str_questions
  set q [dict create]
  foreach {id question} $str_questions {
    dict set q $id $question
  }
  return $q
}

proc read_possible_answers {} {
  set f [open possible-answers.tsv r]
  set d [dict create]
  while {[gets $f line] >= 0} {
    set l [split $line "\t"]
    if {[:# $l] < 4} {
      continue
    }
    set total 0
    set options {}
    foreach {p answer} [lrange $l 2 end] {
      if {$p != ""} {
        lappend options $p $answer
        set total [expr $total + $p]
      }
    }
    if {$total == 100} {
      dict set d [:0 $l] $options
    } else {
      error "Total != 100: $line"
    }
  }
  close $f
  return $d
}

proc read_takes {} {
  set takes [dict create]
  set f [open takes.tsv r]
  set header [split [gets $f] "\t"]
  set i 2
  foreach take [lrange $header 2 end] {
    dict set takes $i [dict create name $take col $i]
    incr i
  }
  while {[gets $f line] >= 0} {
    if {[string trim $line] == ""} {
      continue
    }
    set l [split $line "\t"]
    if {[:0 $l] == "score"} {
      set i 2
      foreach sc [lrange $l 2 end] {
        dict set takes $i score $sc
        incr i
      }
    } else {
      set qid [:0 $l]
      set i 2
      foreach ans [lrange $l 2 end] {
        dict set takes $i $qid $ans
        incr i
      }
    }
  }
  close $f
  return $takes
}

proc check_answers {poss_answers takes} {
  foreach take [dict keys $takes] {
    set name [dict get $takes $take name]
    foreach ansnr [dict keys [dict get $takes $take]] {
      if {[string is integer $ansnr]} {
        set answer [dict get $takes $take $ansnr]
        if {[is_possible_answer $ansnr $answer $poss_answers]} {
          log debug "take $name, ans#: $ansnr, answer: $answer"    
        } else {
          log warn "Impossible answer: take $name, ans#: $ansnr, answer: $answer"
          error "Impossible!"
        }
      }
    }
  }
}

proc is_possible_answer {nr answer poss_answers} {
  set poss [dict get $poss_answers $nr]
  foreach {p ans} $poss {
    if {$ans == $answer} {
      return 1
    }
  }
  return 0
}

proc simulate {questions poss_answers takes} {
  global MAX_SIMULATIONS n_found_answers SIM1
  srandom [clock seconds]
  set sim_it 0
  while 1 {
    incr sim_it
    log debug "Simulation $sim_it"
    if {$sim_it % 1000 == 0} {
      log info "Simulation $sim_it, found: $n_found_answers"
    }
    set sel_ans [select_answer $poss_answers]
    puts_sel_ans $sel_ans
    set all_ok 1
    foreach take [dict keys $takes] {
      set calc [calc_score $sel_ans [dict get $takes $take]]
      set act [dict get $takes $take score]
      if {$calc == $act} {
        # ok, score is ok
        log debug "Take $take: Calculated score ($calc) is the same as actual score ($act)"        
      } else {
        set all_ok 0
        log debug "Take $take: Calculated score ($calc) differs from actual score ($act)"        
      }
    }
    if {$all_ok} {
      append_answers "selected-answers.txt" $sel_ans
    } else {
      log debug "Not all calculated scores are correct"
    }
    if {$sim_it >= $MAX_SIMULATIONS} {
      break
    }
    if {$SIM1} {
      break
    }
  }
}

proc puts_sel_ans {sel_ans} {
  log debug "Selected answers:"
  foreach ansnr [dict keys $sel_ans] {
    log debug "$ansnr: [dict get $sel_ans $ansnr]"
  }
  log debug "---"
}

# select one possible answers based on the possible frequencies
# return dict with key=ansnr, val=answer
proc select_answer {poss_answers} {
  set res [dict create]
  foreach ansnr [dict keys $poss_answers] {
    log debug "*** ansnr: $ansnr *** "
    set poss [dict get $poss_answers $ansnr]
    set rnd [expr { int(100 * rand()) }] ; # between 0-99 inclusive
    log debug "chosen random value: $rnd"
    set sum 0
    foreach {p answer} $poss {
      incr sum $p
      log debug "sum now $sum, rnd=$rnd"
      if {$rnd < $sum} {
        dict set res $ansnr $answer
        log debug "set answer to: $answer"
        break
      }
    }
  }
  # res should have same number of keys as poss_answers
  if {[:# [dict keys $poss_answers]] != [:# [dict keys $res]]} {
    error "res is wrong: $res"
  }
  return $res
}

proc calc_score {sel_ans take} {
  set score 0
  foreach ansnr [dict keys $take] {
    if {[string is integer $ansnr]} {
      set answer [dict get $take $ansnr]
      if {$answer == [dict get $sel_ans $ansnr]} {
        incr score
      }
    }
  }
  return $score
}

set found_answers [dict create]
set n_found_answers 0

# TODO: oplossing in een dict bewaren, kijken welke het meest voorkomt.
proc append_answers {filename sel_ans {with_index 1}} {
  global found_answers n_found_answers
  dict incr found_answers $sel_ans
  incr n_found_answers
  set f [open $filename a]
  puts $f "Found one possible solution:"
  foreach k [dict keys $sel_ans] {
    if {$with_index} {
      puts $f "answer $k: [dict get $sel_ans $k]"  
    } else {
      puts $f [dict get $sel_ans $k]
    }
  }
  puts $f "================"
  close $f
}

proc puts_answers_counts {} {
  global found_answers n_found_answers
  puts "Total #answers found: $n_found_answers"
  set filename "All-answers-counts.txt"
  set curmax 0
  set cursol ""
  foreach sel_ans [dict keys $found_answers] {
    set f [open $filename a]
    set ntimes [dict get $found_answers $sel_ans]
    puts $f "Next answer found $ntimes times:"
    close $f
    if {$ntimes > $curmax} {
      set curmax $ntimes
      set cursol $sel_ans
    }
    append_answers $filename $sel_ans
  }
  set f [open $filename a]
  puts $f "Next answer found the most ($curmax) times:"
  close $f
  append_answers $filename $cursol 0
}

main $argv
