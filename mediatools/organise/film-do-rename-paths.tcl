#!/usr/bin/env tclsh861

package require ndv

# moet hier gewoon set_log kunnen zeggen, maar dan wel met debug/info erachter, optioneel, default = info.
set log [::ndv::CLogger::new_logger [file tail [info script]] info]

proc main {argv} {
  # set logfile "/media/nas5tb_1/home-pi/log/wrapomxplayer-films-move.log"
  # to-dirs hier nog niet nodig, maar wel lokatie voor text file.
  set films_root "/home/media/Films/_tijdelijk"

  set move_name [file join $films_root "move-films.txt"]

  do_move $move_name

  # file delete $logfile
}

proc do_move {move_name} {
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
        handle_action $action $path_orig $path_new $path_type
        set action ""
        set path_orig ""
        set path_new ""
        set path_type ""
      }
    }
  }
  close $f
}

proc handle_action {action path_orig path_new path_type} {
  log debug "handle action: $action for $path_orig => $path_new"
  if {$action == "move"} {
    log info "Moving: $path_orig => $path_new"
    if {$path_type == "directory"} {
      file rename $path_orig $path_new
    } elseif {$path_type == "file"} {
      file mkdir $path_new
      file rename $path_orig [file join $path_new [file tail $path_orig]]
    }
    
  }
}

main $argv

