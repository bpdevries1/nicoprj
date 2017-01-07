#!/usr/bin/env tclsh861

package require ndv

# moet hier gewoon set_log kunnen zeggen, maar dan wel met debug/info erachter, optioneel, default = info.
set log [::ndv::CLogger::new_logger [file tail [info script]] info]

proc main {argv} {
  # set logfile "/media/nas5tb_1/home-pi/log/wrapomxplayer-films-move.log"
  # to-dirs hier nog niet nodig, maar wel lokatie voor text file.
  set films_root "/home/media/Films"
  set rpi_films_root "/media/nas5tb_2/media/Films"

  set move_name [file join $films_root _tijdelijk "move-films.txt"]

  do_move $move_name [list $films_root $rpi_films_root]

  # file delete $logfile
}

proc do_move {move_name roots} {
  set action ""
  set logline ""
  set played ""
  set dir_orig ""
  set dir_new ""
  set f [open $move_name r]
  while {![eof $f]} {
    gets $f line
    if {[regexp {^([^:]+):(.*)$} $line z nm val]} {
      set nm [string trim $nm]
      set $nm [string trim $val]
      if {$nm == "action"} {
        handle_action $action $logline $played $dir_orig $dir_new $roots
        set action ""
        set logline ""
        set played ""
        set dir_orig ""
        set dir_new ""
      }
    }
  }
  close $f
}

proc handle_action {action logline played dir_orig dir_new roots} {
  log debug "handle action: $action for $dir_orig => $dir_new"
  foreach root $roots {
    # todo: deze nog anders voor top250
    set dir_path_orig [det_dir_path_orig $root $dir_orig $played]
    # set dir_path_orig [file join $root _tijdelijk $dir_orig]
    
    if {[file exists $dir_path_orig]} {
      set dir_path_new [file join $root $dir_new]
      if {$action == "delete"} {
        log info "Deleting: $dir_path_orig"
        file delete -force $dir_path_orig
      } elseif {$action == "move"} {
        log info "Moving: $dir_path_orig => $dir_path_new"
        file rename $dir_path_orig $dir_path_new
      }
    } else {
      log warn "orig path does not exist: $dir_path_orig"
    }
  }
  
}

proc det_dir_path_orig {root dir_orig played} {
  if {[regexp {(_tijdelijk.*)$} $played z relpath]} {
    return [file join $root [file dirname $relpath]]
  }
  error "Cannot find _tijdelijk in played path: $played"
  #log debug "dir: $dir_orig"
  #log debug "played: $played"
  #breakpoint
}


# return full path of temp movie iff it is really in the temp (tijdelijk) dir.
# otherwise return an empty string
proc det_temp_movie {line} {
  set res ""
  if {[regexp {(Start|Finished): (.+?) \(subs:.*\)} $line z z path]} {
    if {[regexp {/_tijdelijk/} $path]} {
      set res $path
    }
  }
  return $res
}

# TODO kan zijn dat dir wat dieper zit, bv bij de top250 (seven samurai bv)
proc det_dir_orig {temp_movie} {
  # regexp {_tijdelijk/([^/]+)/} $temp_movie z dir_orig
  # return $dir_orig
  file tail [file dirname $temp_movie]
}

main $argv

