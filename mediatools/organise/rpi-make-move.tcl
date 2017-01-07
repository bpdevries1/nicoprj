#!/usr/bin/env tclsh861

package require ndv

# moet hier gewoon set_log kunnen zeggen.
set log [::ndv::CLogger::new_logger [file tail [info script]] info]

proc main {argv} {
  set logfile "/media/nas5tb_1/home-pi/log/wrapomxplayer-films-move.log"
  # to-dirs hier nog niet nodig, maar wel lokatie voor text file.
  set films_root "/home/media/Films"

  set move_name [file join $films_root _tijdelijk "move-films.txt"]

  make_move $logfile $move_name

  file delete $logfile

  puts "gedit $move_name"
  exec gedit $move_name &
}

# elke film maar 1x behandelen.
proc make_move {logfile move_name} {
  set fi [open $logfile r]
  set fo [open $move_name w]
  while {![eof $fi]} {
    gets $fi line
    log debug "read line: $line"
    if {[to_handle $line]} {
      handle_line $line $fo
    }
  }
  close $fi
  close $fo
}

# [2015-10-11 19:05:25] Start: /media/shortcuts/Films/_tijdelijk/Napoleon Dynamite (2004) [1080p]/Napoleon.Dynamite.2004.1080p.BrRip.x264.YIFY.mp4 (subs: )

# [2017-01-07 21:06] old: only handle first time a film is mentioned, i.e. the start.
# but also want the finish, to check if I really watched it.
proc to_handle {line} {
  global ar_films
  set res 0  
  set temp_film [det_temp_film $line]
  if {$temp_film != ""} {
    incr ar_films($temp_film)
    if {$ar_films($temp_film) == 1} {
      set res 1
    }
  }
  if {[regexp -nocase napoleon $line]} {
    #breakpoint  
  }
  
  log debug "to_handle $line, res = $res"
  return $res  
}

# [2015-10-11 19:05:25] Start: /media/shortcuts/Films/_tijdelijk/Napoleon Dynamite (2004) 
proc handle_line {line fo} {
  set temp_film [det_temp_film $line]
  puts $fo "logline: $line"
  puts $fo "played: $temp_film"
  # regexp {_tijdelijk/([^/]+)/} $temp_film z dir_orig
  set dir_orig [det_dir_orig $temp_film]
  puts $fo "\n"
  puts $fo "dir_orig: $dir_orig"
  puts $fo "dir_new : [det_dir_new $dir_orig]"
  puts $fo "action  : move"
  puts $fo "------------------------------------------"
}

# return full path of temp film iff it is really in the temp (tijdelijk) dir.
# otherwise return an empty string
proc det_temp_film {line} {
  set res ""
  if {[regexp {(Start|Finished): (.+?) \(subs:.*\)} $line z z path]} {
    if {[regexp {/_tijdelijk/} $path]} {
      set res $path
    }
  }
  if {[regexp -nocase napoleon $line]} {
    #breakpoint
  }
  return $res
}

# TODO kan zijn dat dir wat dieper zit, bv bij de top250 (seven samurai bv)
proc det_dir_orig {temp_film} {
  # regexp {_tijdelijk/([^/]+)/} $temp_film z dir_orig
  # return $dir_orig
  file tail [file dirname $temp_film]
}

proc det_dir_new {dir_orig} {
  # remove numbers from top 250 film
  set dir_new $dir_orig
  if {[regexp {^\d+ - (.+)$} $dir_new z d2]} {
    set dir_new $d2
  }
  regsub -all {\.} $dir_new " " dir_new
  if {[regexp {^(.+) \((\d{4})\)} $dir_new z name year]} {
    return "$name ($year)"
  }
  if {[regexp {^(.+) (\d{4}) } $dir_new z name year]} {
    return "$name ($year)"
  }
  return "$dir_new (__YEAR__)"
}

main $argv

