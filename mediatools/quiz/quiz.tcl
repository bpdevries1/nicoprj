#!/home/nico/bin/tclsh8.6

package require tdbc::sqlite3
package require ndv

source ../lib/libmusic.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

# globals/settings
# toch eerst de nieuwe doen, krijg je een feel van wat er allemaal is.
set algo new_first
# wrong first lijkt wel aardige als er wat tijd tussen je quiz-sessies zit. Dan fouten vorige keer als eerste. Zou na paar fout en 
# een goed mss iets eerder weer terug moeten komen, is wat advanced quizzing...
# set algo wrong_first
# 10 seconden is best kort.
set max_play_time_sec 15

# TODO:
#########
# * @todo hernoemen van alles files obv excel/html: bij huidige niet allemaal goed, en jaartal kan er dan ook bij. Wel ook naam in db aanpassen dan, in beide tabellen. 
# wel jammer dat dit nu eigenlijk de PK is. Kan nog een id kolom toevoegen...
# * sessies noteren in DB, dan ook aan het einde wat stats van de sessie te tonen.
# * groepen definieren die je wilt leren/testen: op jaar, op nummer (bv alleen top 100),
# * maar ook recente singer/songwriters en emo-bands, haal ik altijd door elkaar.
# * laatste mogelijk wel te doen door op jaartal te testen.
# * verschil tussen titel goed omdat je 't weet, of omdat je het hoort en goed raadt/weet.

proc main {argv} {
  global conn stmts
  lassign $argv db_name
  set conn [open_db $db_name]

  set stmts(set_seconds_frames) [$conn prepare "update track set seconds = :seconds, frames = :frames where id = :id"]
  set stmts(update_nright_nwrong) [$conn prepare "update track set nright = :nright, nwrong = :nwrong where id = :id"]
  set stmts(insert_test) [$conn prepare "insert into track_test (track_id, ts, result, start_sec, stop_sec) values (:track_id, :ts, :result, :start_sec, :stop_sec)"]

  quiz $conn
  $conn close
}

proc open_db {db_name} {
  set conn [tdbc::sqlite3::connection create db $db_name]
  return $conn
}

proc quiz {conn} {
  global algo
  # deze while lus simpel houden, later mogelijk toch een GUI.
  while {1} {
    # iets meer dan 10, anders komen de foute erg snel terug, zit nu dus 100 tussen.
    set lst_tracks [get_tracks $conn $algo 100]
    foreach track $lst_tracks {
      quiz_track $track 
    }
  }
}

# @todo randomize possible in SQLite?
proc get_tracks {conn algo ntracks} {
  if {$algo == "new_first"} {
    # quiz tracks that have not been tested before.
    set res [$conn allrows -as dicts "select * from track order by nright, nwrong, random() limit $ntracks"] 
  } elseif {$algo == "wrong_first"} {
    # quiz tracks that have been tested before, and have the most wrongs and least rights.
    set res [$conn allrows -as dicts "select * from track order by nright, nwrong desc, random() limit $ntracks"] 
  } else {
    error "Unknown algorithm: $algo" 
  }
  return $res
}

# @param track: dict (path, nright, nwrong, maybe seconds, frames)
# @todo handle stats: where did the play start, for how many seconds?
proc quiz_track {track} {
  global max_play_time_sec timeout
  # set pid_mpg [start_play $track]
  # in testmode even geen play,
  lassign [start_play $track] pid_mpg start_sec
  set start_time [clock seconds]
  puts "Press enter to stop playing and give answer"
  #puts "after start_play"
  set timeout 0
  set after_id [after [expr $max_play_time_sec * 1000] set_timeout]
  if {0} {
    while {!$timeout && [fblocked stdin]} {
      after 100
      update
    }
  }
  fileevent stdin readable key_pressed
  vwait timeout
  fileevent stdin readable ""
  after cancel $after_id
  
  #puts "before stop_play"
  stop_play $pid_mpg
  set stop_time [clock seconds]
  gets stdin
  set stop_sec [expr $start_sec + ($stop_time - $start_time)]
  puts_track $track
  puts "Right answer? (y(es),n(o),t(itle),a(rtist),q(uit))"
  gets stdin answer
  if {$answer == "q"} {
    exit 
  } else {
    update_track $track $answer $start_sec $stop_sec
  }
  puts "============================================="
}

proc key_pressed {} {
  global timeout
  puts "key pressed"
  set timeout 1
}

proc set_timeout {} {
  puts "timeout"
  global timeout
  set timeout 1
}

# @param track: dict (path, nright, nwrong, maybe seconds, frames)
# @todo handle stats: where did the play start, for how many seconds?
proc quiz_track_old {track} {
  global max_play_time_sec
  # set pid_mpg [start_play $track]
  lassign [start_play $track] pid_mpg start_sec
  set start_time [clock seconds]
  puts "Press enter to stop playing and give answer"
  # after [expr $max_play_time_sec * 1000] stop_play $pid_mpg
  gets stdin
  stop_play $pid_mpg
  set stop_time [clock seconds]
  set stop_sec [expr $start_sec + ($stop_time - $start_time)]
  puts_track $track
  puts "Right answer? (y(es),n(o),t(itle),a(rtist),q(uit))"
  gets stdin answer
  if {$answer == "q"} {
    exit 
  } else {
    update_track $track $answer $start_sec $stop_sec
  }
  puts "============================================="
}

# returns pid of mpg321 process.
proc start_play {track} {
  set track [add_seconds_frames $track]
  # set start_frame [det_start_frame $track]
  lassign [det_start_frame_sec $track] start_frame start_sec
  set pid [exec mpg321 -k $start_frame -q [dict get $track path] &] 
  list $pid $start_sec
}

# if track already has seconds and frames, just return the track.
# else: use mp3info to find these values, update the db and return the updated track.
proc add_seconds_frames {track} {
  global stmts
  if {![dict exists $track seconds]} {
    set res [exec mp3info -p "%u/%S" [dict get $track path]]
    lassign [split $res "/"] frames seconds
    # append and update do not work, maybe have made a dict_set_multi before.
    dict set track seconds $seconds
    dict set track frames $frames
    $stmts(set_seconds_frames) execute $track
  } else {
    # just return original 
  }
  return $track
}

# @todo randomize value, also return seconds, to calculate start/stop seconds to put in DB.
proc det_start_frame_sec {track} {
  set buffer 30
  set sec [dict get $track seconds]
  if {$sec <= $buffer} {
    return [list 0 0] 
  } else {
    set fps [expr 1.0 * [dict get $track frames] / $sec]
    set start_sec [expr round(rand() * ($sec - $buffer))]
    set start_frame [expr $fps * $start_sec]
    return [list $start_frame $start_sec]
  }
}

proc stop_play {pid_mpg} {
  exec kill $pid_mpg
}

proc puts_track {track} {
  puts [file tail [dict get $track path]]
  puts "#right/#wrong: [dict get $track nright]/[dict get $track nwrong]"
}

# beide goed is hier 2 punten, beide fout 2 fouten, alleen titel of artiest is 1 om 1.
proc update_track {track answer start_sec stop_sec} {
  global stmts
  set answer [string tolower [string range $answer 0 0]]
  if {$answer == "y"} {
    dict incr track nright 2
    set result "right"
  } elseif {$answer == "n"} {
    dict incr track nwrong 2
    set result "wrong"
  } elseif {$answer == "t"} {
    dict incr track nright 1
    dict incr track nwrong 1
    set result "title"
  } elseif {$answer == "a"} {
    dict incr track nright 1
    dict incr track nwrong 1
    set result "artist"
  } else {
    puts "Unrecognised answer, continuing..."
    return
  }    
  $stmts(update_nright_nwrong) execute $track
  set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  #$stmts(insert_test) execute [dict create path [dict get $track path] \
  #  result $result ts $ts start_sec $start_sec stop_sec $stop_sec]
  $stmts(insert_test) execute [dict create track_id [dict get $track id] \
    result $result ts $ts start_sec $start_sec stop_sec $stop_sec]
}

proc db_eval {conn query} {
  set stmt [$conn prepare $query]
  $stmt execute
  $stmt close
}

main $argv
