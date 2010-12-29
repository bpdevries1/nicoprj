package require ndv

proc main {} {
  global stdin fxls fform fsch ar_namen
  lees_namen
  set fxls [open "schema.xls" w]
  puts $fxls [join [list Groep Ronde Veld Team1a Team1b Team2a Team2b Scheids] "\t"]
  set fform [open "schema-form.txt" w]
  set fsch [open "schema-ovz.txt" w]
  set groep 1
  set prev_round 0
  while {![eof stdin]} {
    gets stdin line
    if {[regexp {^([0-9]+): (.*)$} $line z round games]} {
      puts "line: $line"
      if {$round < $prev_round} {
        incr groep 
      }
      set prev_round $round
      set field 1
      set lst_games {}
      set rest ""
      while {[regexp {^([^\(]*)\(([^)(]+)\)(.*)} $games z pre game rest]} {
        # handle_game $round $game $field
        # puts "found game: $game"
        lappend lst_games $game
        set games $rest
        incr field
      }
      if {[regexp "bench: (.*)" $rest z bench]} {
        regsub -all ", " $bench " " bench
        set field 1
        foreach game $lst_games {
          set bench [handle_game $groep $round $field $game $bench]
          incr field
        }
      }
    }
  }
  close $fxls
  close $fform
  close $fsch
}

proc lees_namen {} {
  global ar_namen
  set f [open namen.txt r]
  set i 0
  while {![eof $f]} {
    gets $f line
    if {$line != ""} {
      incr i
      set ar_namen(T[format %02d $i]) $line
    }
  }
  close $f
}

proc handle_game {groep round field game bench} {
  global fxls fform fsch
  puts "game: $game; bench: $bench"
  set rnd [random_int [llength $bench]]
  set scheids [lindex $bench $rnd]
  # set bench [lreplace $bench $rnd $rnd {}]
  # puts "bench: $bench"
  set bench [concat [lrange $bench 0 $rnd-1] [lrange $bench $rnd+1 end]]
  # puts "game: $game"
  puts_game_xls $fxls $groep $round $field $game $scheids
  return $bench
}

proc puts_game_xls {f groep round field game scheids} {
  global ar_namen
  puts $f [join [list $groep $round $field $ar_namen([lindex $game 0]) $ar_namen([lindex $game 1]) \
      $ar_namen([lindex $game 3]) $ar_namen([lindex $game 4]) $ar_namen($scheids)] "\t"]
}

if {0} {
1: (T05 T11 v T01 T03)	(T15 T06 v T07 T16)	(T10 T08 v T13 T04)	bench: T03, T04, T09, T11
2: (T07 T15 v T02 T13)	(T16 T12 v T08 T01)	(T05 T06 v T09 T03)	bench: T07, T14, T15, T16
3: (T14 T08 v T09 T06)	(T04 T07 v T10 T15)	(T02 T16 v T01 T13)	bench: T03, T05, T10, T14
4: (T03 T05 v T12 T02)	(T13 T14 v T04 T11)	(T09 T10 v T15 T01)	bench: T02, T06, T08, T12
5: (T12 T11 v T08 T15)	(T05 T13 v T06 T14)	(T07 T10 v T03 T16)	bench: T06, T07, T08, T16
6: (T04 T02 v T12 T09)	(T08 T07 v T05 T14)	(T13 T03 v T11 T01)	bench: T01, T05, T11, T13
7: (T05 T12 v T16 T10)	(T02 T01 v T04 T14)	(T06 T07 v T09 T11)	bench: T02, T04, T09, T15
8: (T12 T10 v T14 T09)	(T15 T02 v T06 T08)	(T04 T16 v T03 T11)	bench: T01, T10, T12, T13
}

main
