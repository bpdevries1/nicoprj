#!/usr/bin/env tclsh86

# Rename selected tracks (normal, not quiz) to new names based on matched text2000 items

package require tdbc::sqlite3
package require ndv

source ../lib/libmusic.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
set logfilename "[file tail [info script]].log" 
file delete $logfilename
$log set_file $logfilename

proc main {argv} {
  global conn
  if {[llength $argv] > 0} {
    lassign $argv db_name
  } else {
    set db_name "/media/Iomega HDD/media/Music/Quiz/Top 2000 2012/top2000-2012.db" 
  }
  set conn [open_db $db_name]
  #set root_dir "~/media/tijdelijk/music/Top 2000 2012"
  #handle_dir_rec $root_dir "*" handle_file
  # fill_path2 $conn
  # do_file_rename $conn
  # do_track_rename $conn
}

proc fill_path2 {conn} {
  set td_track [make_table_def_keys track {id} {path2 positie2 year}]
  set stmt_update [prepare_update $conn $td_track]
  db_in_trans $conn { 
    set query "select tr.id id, tx.artiest, tx.titel, tx.jaar, tx.positie, tr.path
               from top2000text tx, koppeltext k, track tr
               where tx.id = k.text_id
               and tr.id = k.track_id"
    foreach dct [db_query $conn $query] {
      dict_to_vars $dct
      set positie2 $positie
      set path2 [det_path $positie $artiest $titel $jaar $path]
      set year $jaar
      stmt_exec $conn $stmt_update [vars_to_dict id path2 positie2 year] 
    }
  }
}

proc det_path {positie artiest titel jaar path_orig} {
  set ext [file extension $path_orig]
  set root_dir [file dirname [file dirname $path_orig]]
  set sub_dir [det_subdir $positie]
  file join $root_dir $sub_dir [sanitise "[format %04d $positie]. $artiest - $titel ($jaar)$ext"]
}

# 1 => 0001 - 0100
# 100 => 0001 - 0100
# 1995 => 1901 - 2000
proc det_subdir {positie} {
  # met integer deling automatisch een truncate
  set d100 [expr ($positie-1) / 100] ; # 1->0, 1995 -> 19, 200->1
  format "%04d - %04d" [expr $d100 * 100 + 1] [expr $d100 * 100 + 100]
}

proc det_new_filename {filename} {
  set dct [det_info [file tail $filename]]
  if {$dct == ""} {
    return ""
  } else {
    dict_to_vars $dct
    file join [file dirname $filename] [sanitise "$artiest - $titel ($jaar)[file extension $filename]"]
  }
}

# replace illegal characters in pathname with _
proc sanitise {filename} {
  regsub -all {[/\\]} $filename "_" filename
  return $filename  
}

# @todo what if something fails, rollback, exec except/finally clause?
# @todo already in lib now, not yet published.
proc db_in_trans {conn block} {
  db_eval $conn "begin transaction"
  uplevel $block  
  db_eval $conn "commit"
}

proc do_file_rename {conn} {
  set query "select path, path2 from track order by positie2"
  foreach dct [db_query $conn $query] {
    dict_to_vars $dct
    file rename $path $path2
    log info "Rename $path2 -> $path"
  }
}

proc do_file_rename_back {conn} {
  set query "select path, path2 from track order by positie2"
  foreach dct [db_query $conn $query] {
    dict_to_vars $dct
    log info "Rename back $path2 -> $path"
    if {[file exists $path2]} {
      file rename $path2 $path
    } else {
      log warn "not found: $path2" 
    }
  }
}

proc do_track_rename {conn} {
  db_eval $conn "update track set positie=positie2, path=path2" 
}

main $argv

