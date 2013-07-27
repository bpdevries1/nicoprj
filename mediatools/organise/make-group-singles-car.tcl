#!/usr/bin/env tclsh86

# cp -r ../../ActiveTcl-8.5/lib/mysqltcl-3.05 . uitgevoerd in ActiveTcl-8.6/lib dir, hierna werkt 
# package require mysqltcl in Tcl 8.6.

# make-group-singles-car: make group/members in MySQL music DB which has members pointing to 
# origins of symlinks in .../Singles-car/*/car/*

package require ndv
package require Tclx
package require json

# source ../db/MusicSchemaDef.tcl
source ../lib/libmusic.tcl
# source libdb.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  if {[llength $argv] == 0} {
    set root_dir "/media/nas/media/Music/singles-auto"
  } else {
    lassign $argv root_dir
  }

  #set schemadef [MusicSchemaDef::new]
  #set db [::ndv::CDatabase::get_database $schemadef]
  
  set db [dbwrapper new {*}[det_music_conn_args]]
  # breakpoint
  define_tables $db
  
  # set db [dbwrapper new "test.db"]
  # set conn [$db get_conn]
  # set conn [$db get_db_handle]
  # ::mysql::exec $conn "set names utf8"
  # @note default in tdbc voor mysql zou al utf-8 zijn, dus statement mogelijk helemaal niet nodig...
  [$db get_conn] evaldirect "set names utf8"
  # log info "done: set names utf8"
  
  remove_group $db "Singles-car"
  #log info "remove group done"
  #breakpoint
  set group_id [make_group $db "Singles-car"]
  log info "Group_id: $group_id"
  if {[string trim $group_id] == ""} {
    error "Empty group_id for just created group: $group_id" 
  }
  # breakpoint
  #::mysql::exec $conn "start transaction"
  # @todo transaction started in MySQL context. Ofwel via een niet-prepared statement, ofwel door DB Handle van MySQL te gebruiken.
  #$db exec "start transaction"
  [$db get_conn] begintransaction
  handle_dir_rec $root_dir "*" [list add_to_group $group_id $db]
  #::mysql::exec $conn "commit"
  [$db get_conn] commit
  #$db exec "commit"
}

# @todo could read existing table defs from db connection meta data. Then only need to define new tables.
proc define_tables {db} {
  $db add_tabledef mgroup {id} {name}
  $db add_tabledef member {id} {mgroup generic}
  $db prepare_insert_statements
  # binary needed below to have case sensitive search.
  $db prepare_stmt sel_generic "select generic from musicfile where binary path = :path"
}

proc remove_group {db group_name} {
  set res [$db query "select id from mgroup where name = '$group_name'"]
  log info "Group ids to delete ($group_name): $res"
  foreach rec $res {
    $db exec "delete from member where mgroup = [:id $rec]"
    $db exec "delete from mgroup where id = [:id $rec]"
  }
}

proc make_group {db group_name} {
  # $db insert_object mgroup -name $group_name
  $db insert mgroup [dict create name $group_name]
}

proc add_to_group {group_id db filename root_dir} {
  # log debug "add_to_group called: $group_id $db $filename $root_dir"
  if {![is_music_file $filename]} {
    return 
  }
  if {![regexp {/car/} $filename]} {
    if {[regexp {/not/} $filename]} {
      # return
    } else {
      # @todo deze weer aanzetten, als ik alles langs heb gelopen.
      #log warn "Forgot to move: $filename"
      #breakpoint
    }
    return
  }
  set generic_id [find_generic $db $filename]
  if {$generic_id > 0} {
    # $db insert_object member -mgroup $group_id -generic $generic_id 
    $db insert member [dict create mgroup $group_id generic $generic_id]
  }
  # breakpoint
}

proc find_generic {db filename} {
  set orig_path [find_origin_path $filename]
  # set query "select generic from musicfile where path='$orig_path'"
  # set res [::mysql::sel [$db get_connection] $query -flatlist]
  # /media/nas prefix is not stored in DB (probably because on Windows it's w:/), so remove this part.
  set db_orig_path [det_path_in_db $orig_path]

  set res [$db exec_stmt sel_generic [dict create path $db_orig_path]]
  if {[llength $res] == 1} {
    # log debug "Found 1 result for $orig_path: $res"
    return [:generic [lindex $res 0]] 
  } else {
    log warn "Found <>1 result for $orig_path: $res"
    breakpoint
  }
}

# walk symlinks until real file is foud, return path of this one.
# @note walk max 10 steps, don't want to end up in a recursive circular search.
proc find_origin_path {filename} {
  set MAX_WALK 10
  set found 0
  set step 0
  set path $filename
  while {!$found} {
    incr step
    if {$step > $MAX_WALK} {
      # return ""
      error "Walked more than $MAX_WALK steps to find origin of: $filename"
    }
    if {[file type $path] == "link"} {
       set path [file link $path] 
    } else {
       return $path
    }
  }
}

# lib functions for new tdbc::mysql connection

proc det_music_conn_args {} {
  set f [open ~/.ndv/music-settings.json r]
  set text [read $f]
  close $f
  set d [json::json2dict $text]
  # set_db_name_user_password [dict get $d database] [dict get $d user] [dict get $d password]
  list -db [:database $d] -user [:user $d] -password [:password $d]
}

main $argv
