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
  set root_dir "~/media/tijdelijk/music/Top 2000 2012"
  handle_dir_rec $root_dir "*" handle_file
  
}

proc handle_file {filename root_dir} {
  set new_filename [det_new_filename $filename]
  if {$new_filename != ""} {
    log info "Rename $filename => $new_filename"
    file rename $filename $new_filename
  } else {
    log warn "No pos/info found, ignore: $filename" 
  }
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

proc det_new_filename_old {filename} {
  global conn
  set pos_orig [det_positie $filename]
  if {$pos_orig == -1} {
    return "" 
  } else {
    set dct [det_info $pos_orig]
    dict_to_vars $dct
    file join [file dirname $filename] "$artiest - $titel ($jaar)[file extension $filename]"
  }
}

# return position with prefix-zeroes stripped
proc det_positie_old {filename} {
  set name [file tail $filename]
  if {[regexp {^0*([0-9]+)} $name z pos]} {
    if {$pos == ""} {
      breakpoint 
    }
    return $pos
  } else {
    # breakpoint
    return -1
  }
}

# filename: without path.
proc det_info {filename} {
  global conn
  set query "select tx.artiest, tx.titel, tx.jaar
             from top2000text tx, koppeltext k, track tr
             where tx.id = k.text_id
             and tr.id = k.track_id
             and tr.path like '%/[add_quotes $filename]'"
  log debug $query
  set lst [db_query $conn $query]
  if {[llength $lst] == 1} {
    lindex $lst 0 
  } else {
    if {[llength $lst] == 0} {
      return "" 
    } else {
      breakpoint
    }
  }
}

# replace single quotes with double single quotes
proc add_quotes {str} {
  regsub -all "'" $str "''" str
  return $str
}

proc det_info_old {pos_orig} {
  global conn
  set query "select tx.artiest, tx.titel, tx.jaar
             from top2000text tx, koppeltext k, track tr
             where tx.id = k.text_id
             and tr.id = k.track_id
             and 1.0*tr.positie = $pos_orig"
  # log debug $query
  set lst [db_query $conn $query]
  if {[llength $lst] == 1} {
    lindex $lst 0 
  } else {
    breakpoint 
  }
}

proc log_matches {conn status text} {
  log info $text
  foreach el [db_query $conn "select tx.id, tx.positie, tx.artiest, tx.titel,
                              tr.id, tr.path
                              from top2000text tx, track tr, koppeltext k
                              where tr.id = k.track_id
                              and tx.id = k.text_id
                              and k.status='$status'
                              order by 1.0*tx.positie"] {
    log info "Track: [det_track_info $el]"
    log info "Text:  [det_text_info $el]"
    log info "==="
  }
}

proc det_track_info {el} {
  dict_to_vars $el
  return "[file tail $path]"
}

proc det_text_info {el} {
  dict_to_vars $el
  return "$positie. $artiest - $titel"
}

proc insert_manual {conn track_id text_pos} {
  db_eval $conn "insert into koppeltext (track_id, text_id, status)
                 select $track_id, tx.id, 'manual'
                 from top2000text tx
                 where 1.0*tx.positie = $text_pos"  
}

main $argv

