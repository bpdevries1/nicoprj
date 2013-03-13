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
  
  det_size_dir_root $conn $cmd_args
  
  $conn close  
}

proc open_db {db_name} {
  file mkdir [file dirname $db_name]
  # for testing
  file delete $db_name
  
  set conn [tdbc::sqlite3::connection create db $db_name]
  if {[$conn tables] == {}} {
    create_db $conn 
  }
  return $conn
}

proc create_db {conn} {
  db_eval $conn "create table size_check (id integer primary key autoincrement, hostname, ts)"
  db_eval $conn "create table size_check_dir (id integer primary key autoincrement, size_check_id, path, size_mb, last_mod)"
  
  # state for long running processes.
  db_eval $conn "create table size_check_todo (size_check_dir_id, path)"
}

proc det_size_dir_root {conn cmd_args} {
  global stmt
  set path_root [file normalize [dict get $cmd_args path]]
  set recur_size [dict get $cmd_args recur_size]
  set hostname [det_hostname]
  set ts [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  set size_check_id [db_eval $conn "insert into size_check (hostname, ts) values ('$hostname', '$ts')" 1]
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

proc db_eval {conn query {return_id 0}} {
  set stmt [$conn prepare $query]
  $stmt execute
  $stmt close
  if {$return_id} {
    return [[$conn getDBhandle] last_insert_rowid]   
  }
}

proc stmt_exec {conn stmt dct {return_id 0}} {
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

main $argv
