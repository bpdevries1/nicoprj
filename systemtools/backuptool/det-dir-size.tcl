#!/home/nico/bin/tclsh8.6

# todo/idee
# op / niveau eerst alleen een ls doen, geen du, want deze duurt heel lang. En mss ook nog wel niveau dieper.
# tijdstip start check is genoteerd, maar wil ook per dir, evt start en stop, om tijd hiervan te bepalen, vooral NAS duurt lang.

# evt check maken: op root-niveau: zijn alle dirs opgenomen. Hieronder: als size > treshold, zijn de subs dan gedaan?
# en checken of er dingen dubbel instaan, of het met root-check goed gaat.

# multi-level van du gebruiken, bv tot level 3 of 5. Dan alleen dieper te gaan als level 5 nog meer dan 1GB is.
# evt de diepere levels niet in db als size < 1GB.
# Dan wel ook goed weten wat diepste level is.

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  set options {
    {path.arg "/" "Path to determine size of"}
    {recur_size.arg "1024" "If size of dir is bigger than recur_size (MB), recur into subdirs to determine sizes"}
    {db.arg "~/.backuptool/backupinfo.db"} 
  }
  set usage ": [file tail [info script]] \[options] :"
  set cmd_args [::cmdline::getoptions argv $options $usage]
  set conn [open_db [dict get $cmd_args db]]
  
  set size_check_id [insert_size_check $conn]
  # 17-3-2013 NdV nu even niet.
  # det_size_dir_root $conn $cmd_args
  det_disk_free $conn $size_check_id
  
  $conn close  
}

proc open_db {db_name} {
  file mkdir [file dirname $db_name]
  # for testing
  # file delete $db_name
  
  set conn [tdbc::sqlite3::connection create db $db_name]
  if {[$conn tables] == {}} {
    log info "Database empty, create tables"
    breakpoint
    create_db $conn 
  }
  return $conn
}

proc create_db {conn} {
  db_eval $conn "create table size_check (id integer primary key autoincrement, hostname, ts)"
  db_eval $conn "create table size_check_dir (id integer primary key autoincrement, size_check_id, path, size_mb, last_mod)"
  
  # state for long running processes.
  db_eval $conn "create table size_check_todo (size_check_dir_id, path)"
  
  # df output
  db_eval $conn "create table diskfree (id integer primary key autoincrement, size_check_id, filesystem, total_mb, used_mb, free_mb, mounted)"
}

proc insert_size_check {conn} {
  set hostname [det_hostname]
  set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  set size_check_id [db_eval $conn "insert into size_check (hostname, ts) values ('$hostname', '$ts')" 1]
  return $size_check_id
}

proc det_size_dir_root {conn cmd_args size_check_id} {
  global stmt
  set path_root [file normalize [dict get $cmd_args path]]
  set recur_size [dict get $cmd_args recur_size]
  #set hostname [det_hostname]
  #set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  # set size_check_id [db_eval $conn "insert into size_check (hostname, ts) values ('$hostname', '$ts')" 1]
  set stmt(size_check_dir) [$conn prepare "insert into size_check_dir (size_check_id, path, size_mb, last_mod) values ($size_check_id, :path, :size_mb, :last_mod)"]
  set stmt(size_check_todo) [$conn prepare "insert into size_check_todo (size_check_dir_id, path) values (:size_check_dir_id, :path)"]
  set stmt(size_check_todo_delete) [$conn prepare "delete from size_check_todo where size_check_dir_id = :size_check_dir_id"]

  # handle_root, als size > treshold, insert record in size_check_todo
  $conn begintransaction
  det_size_dir $conn $path_root $recur_size 1
  $conn commit
  # size_check_todo langslopen totdat 'ie leeg is.
  set lst_todo [$conn allrows -as dicts "select * from size_check_todo order by size_check_dir_id limit 10"]
  # breakpoint
  while {[llength $lst_todo] != 0} {
    $conn begintransaction
    foreach todo $lst_todo {
      det_size_dir $conn [dict get $todo path] $recur_size 0
      $stmt(size_check_todo_delete) execute [dict create size_check_dir_id [dict get $todo size_check_dir_id]]
    }
    set lst_todo [$conn allrows -as dicts "select * from size_check_todo order by size_check_dir_id limit 10"]
    $conn commit
  }
}

proc det_size_dir {conn path recur_size isroot} {
  global stmt log
  $log info "Handle $path"
  set ftmp [file tempfile tempfilename]
  $log debug "Putting output for $path in $tempfilename"  
  # catch {exec -ignorestderr du -m --max-depth=1 --time $path >@$ftmp}
  exec_du $path $ftmp 
  
  close $ftmp
  set res [read_file $tempfilename]
  # $log debug "Do not delete tempfile now"
  # file delete $tempfilename
  # breakpoint
  foreach line [split $res "\n"] {
    # [2013-03-10 10:36:00] NdV jaar soms niet goed, veel te hoog, 5 cijfers, vooral op externe schijven, bug?
    if {[regexp {^(\d+)[ \t]+(\d{4,}-\d{2}-\d{2} \d{2}:\d{2})[ \t]+(.+)$} $line z size_mb last_mod subpath]} {
      if {$path == $subpath} {
        if {$isroot} {
          # dan wel toevoegen.
          set size_check_dir_id [stmt_exec $conn $stmt(size_check_dir) [dict create path $subpath size_mb $size_mb last_mod $last_mod] 1]
        } else {
          # niet toevoegen, bij root al gedaan. 
        }
      } else {
        set size_check_dir_id [stmt_exec $conn $stmt(size_check_dir) [dict create path $subpath size_mb $size_mb last_mod $last_mod] 1]
        if {$size_mb >= $recur_size} {
          $stmt(size_check_todo) execute [dict create size_check_dir_id $size_check_dir_id path $subpath] 
        }
      }
    } elseif {$line == ""} {
      # emtpy, niets
    } else {
      $log warn "Could not parse line: $line"
      breakpoint 
    }
  }
}

proc exec_du {path ftmp} { 
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    catch {exec -ignorestderr c:/util/cygwin/bin/du.exe -m --max-depth=1 --time $path >@$ftmp}
  } elseif {$tcl_platform(platform) == "unix"} {
    catch {exec -ignorestderr du -m --max-depth=1 --time $path >@$ftmp}
  } else {
    error "Unknown platform: $tcl_platform(platform)"  
  }
}

proc exec_df_old {ftmp} { 
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    catch {exec -ignorestderr c:/util/cygwin/bin/df.exe -m >@$ftmp}
  } elseif {$tcl_platform(platform) == "unix"} {
    catch {exec -ignorestderr df -m >@$ftmp}
  } else {
    error "Unknown platform: $tcl_platform(platform)"  
  }
}

proc exec_df {ftmp} {
  exec_system_cmd $ftmp df {-m}
}

# @param cmd_args: list of args.
proc exec_system_cmd {ftmp cmdname {cmd_args {}}} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    set cmdexe [file join "c:/util/cygwin/bin" "$cmdname.exe"]
  } elseif {$tcl_platform(platform) == "unix"} {
    set cmdexe $cmdname
  } else {
    error "Unknown platform: $tcl_platform(platform)"  
  }
  try_eval {
    exec -ignorestderr $cmdexe {*}$cmd_args >@$ftmp
  } {
    log warn "sys cmd gave error/warning: $cmdexe: $errorResult" 
  }
}

proc det_hostname {} {
  global env
  set hostname ""
  catch {set hostname [exec hostname]}
  if {$hostname != ""} {
    return $hostname 
  }
  if {[array get env COMPUTERNAME] != ""} {
    return $env(COMPUTERNAME)
  }
  error "Could not determine hostname, both HOSTNAME and COMPUTERNAME in env are empty" 
}

proc db_eval_old {conn query {return_id 0}} {
  set stmt [$conn prepare $query]
  $stmt execute
  $stmt close
  if {$return_id} {
    return [[$conn getDBhandle] last_insert_rowid]   
  }
}

proc stmt_exec_old {conn stmt dct {return_id 0}} {
  $stmt execute $dct
  if {$return_id} {
    return [[$conn getDBhandle] last_insert_rowid]   
  }
}

proc read_file {filename} {
  set f [open $filename r]
  set res [read $f]
  close $f
  return $res
}

proc det_disk_free {conn size_check_id} {
  set stmt [$conn prepare "insert into diskfree (size_check_id, filesystem, total_mb, used_mb, free_mb, mounted) values ($size_check_id, :filesystem, :total_mb, :used_mb, :free_mb, :mounted)"]
  set res [exec_read_file exec_df]
  foreach line [lrange [split $res "\n"] 1 end] {
    # @pre filesystem has no spaces, mounted-on can (and does) have spaces
    lassign $line filesystem total_mb used_mb free_mb
    set mounted [join [lrange $line 5 end] " "]
    if {$mounted != ""} {
      $stmt execute [vars_to_dict size_check_id filesystem total_mb used_mb free_mb mounted]
    }
  }
}

# @param extra_args: list of args to give procname
proc exec_read_file {procname {extra_args {}}} {
  set ftmp [file tempfile tempfilename]
  log debug "Putting output for $procname in $tempfilename"  
  exec_df {*}$extra_args $ftmp
  close $ftmp
  set res [read_file $tempfilename]
  return $res
}

###########################
# library function
###########################
proc vars_to_dict {args} {
  set res {}
  foreach arg $args {
    upvar $arg val
    # puts "$arg = $val"
    lappend res $arg $val
  }
  return $res
}


main $argv
