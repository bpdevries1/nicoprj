# test database connection with perftoolset like CDatabase etc.

# source all C*.tcl files in the same dir
foreach filename [glob -directory [file dirname [info script]] C*.tcl] {
  source $filename 
}

proc main {} {
  global db conn
  set db [CDatabase::get_database]
  set conn [$db get_connection]
  
  # remove_doubles_non_existing

  fill_temp_filename
  remove_doubles
}

proc fill_temp_filename {} {
  global db conn

  set query "delete from temp_filename"
  ::mysql::exec $conn $query

  set query "select id, path, play_count, file_exists from musicfile"
  set result [::mysql::sel $conn $query -list]
  foreach record $result {
    foreach {id db_path play_count file_exists} $record break
    set filename [det_filename $db_path]
    puts "inserting: $filename"
    $db insert_object temp_filename -musicfile_id $id -path [str_to_db $db_path] -filename [str_to_db $filename] -play_count $play_count -file_exists $file_exists
  }
}

proc det_filename {path} {
  return [file tail $path]
}

proc str_to_db {str} {
  regsub -all {'} $str "''" str
  return $str 
}

proc remove_doubles {} {
  global db conn

  set query "select t1.musicfile_id id1, t1.path db_path1, t1.play_count pc1, t2.musicfile_id id2, t2.path db_path2, t2.play_count pc2
    from temp_filename t1, temp_filename t2
    where t1.filename = t2.filename
    and t1.path < t2.path"
  set result [::mysql::sel $conn $query -list]
  foreach record $result {
    handle_double $record
  }

}

proc handle_double {record} {
  global db conn
  foreach {id1 db_path1 pc1 id2 db_path2 pc2} $record break
  # puts "handling $id1 <=> $id2"
  set linux_path1 [det_linux_path $db_path1]
  set linux_path2 [det_linux_path $db_path2]
  set size1 [file size $linux_path1]
  set size2 [file size $linux_path2]
  if {$size1 == $size2} {
    puts "Equal files, delete one: $db_path1 <=> $db_path2"
    set keep [det_which_to_keep $db_path1 $db_path2]
    if {$keep == 1} {
      puts "=> Keeping $db_path1"
      combine_musicfiles $id1 $pc1 $id2 $pc2 $linux_path2
    } elseif {$keep == 2} {
      puts "=> Keeping $db_path2" 
      combine_musicfiles $id2 $pc2 $id1 $pc1 $linux_path1
    } else {
      puts "=> Cannot determine which one to keep"  
    }
  } else {
    # puts "Different sizes, choose one: $db_path1 <=> $db_path2"  
  }
}

proc det_which_to_keep {db_path1 db_path2} {
  set score1 [det_score $db_path1]
  set score2 [det_score $db_path2]
  if {$score1 > $score2} {
    return 1 
  } elseif {$score1 < $score2} {
    return 2 
  } else {
    return 0 
  }
}

# higher score equals more chance to keep the file
proc det_score {db_path} {
  if {[regexp "per-jaar" $db_path]} {
    return 10 
  } elseif {[regexp "/Genres/" $db_path]} {
    return 8
  } else {
    return 0 
  }
  
}

proc combine_musicfiles {id_keep pc_keep id_del pc_del linux_path_del} {
  global db conn log
  $db update_object musicfile $id_keep -play_count [expr $pc_keep + $pc_del]
  set query "update played set musicfile = $id_keep where musicfile = $id_del"
  ::mysql::exec $conn $query
  set query "delete from musicfile where id = $id_del"
  ::mysql::exec $conn $query
  puts "deleting $linux_path_del"
  file rename $linux_path_del [file join "/media/nas/_deleted" [file tail $linux_path_del]]
}

proc det_linux_path {db_path} {
  return [file join "/media/nas" $db_path] 
}

proc remove_doubles_non_existing {} {
  global db
  set conn [$db get_connection]

  set query "select t1.musicfile_id id_weg, t1.play_count pc_weg, t2.musicfile_id id_blijf, t2.play_count pc_blijf
    from temp_filename t1, temp_filename t2
    where t1.filename = t2.filename
    and t1.file_exists = 0
    and t2.file_exists = 1"
  set result [::mysql::sel $conn $query -list]
  set i 0
  foreach record $result {
    incr i
    foreach {id_weg pc_weg id_blijf pc_blijf} $record break
    puts "handling $i: $id_weg => $id_blijf"
    $db update_object musicfile $id_blijf -play_count [expr $pc_weg + $pc_blijf]
    set query "update played set musicfile = $id_blijf where musicfile = $id_weg"
    ::mysql::exec $conn $query
    set query "delete from musicfile where id = $id_weg"
    ::mysql::exec $conn $query
  }

}

main
