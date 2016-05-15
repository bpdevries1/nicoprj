#!/usr/bin/env tclsh861

# #!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

::ndv::source_once ../db/MusicSchemaDef.tcl
::ndv::source_once [file join [file dirname [info script]] .. lib libmusic.tcl]

# set SINGLES_ON_SD 150

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set_log_global info

proc main {argc argv} {
  global log db conn stderr argv0 SINGLES_ON_SD
	log info "Starting"

  set options {
    {n.arg "5" "Number of albums to select"}
    {pl.arg "music-r.m3u" "Filename of playlist"}
    {np "Don't mark selected files as played in database"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [getoptions argv $options $usage]

  set schemadef [MusicSchemaDef::new]

  set f [open ~/.config/music/music-settings.json r]
  set text [read $f]
  close $f
  set d [json::json2dict $text]
  $schemadef set_db_name_user_password [:database $d] [:user $d] [:password $d]
  
  set db [::ndv::CDatabase::get_database $schemadef]
  set conn [$db get_connection]

  # ::mysql::exec $conn "set names utf8"

  create_random_view
  set lst [::ndv::music_random_select $db $ar_argv(n) "-tablemain generic -viewmain albums -tableplayed played"] 
  # make_copy_sd $lst $to_drive $bat_filename
  make_album_playlist $lst $ar_argv(pl)
  
  if {!$ar_argv(np)} {
    log info "Mark files as played in database" 
    ::ndv::music_random_update $db $lst "playlist" "-tablemain generic -viewmain albums -tableplayed played"
  } else {
    log info "Don't mark files as played in database" 
  }
  
  log debug "$ar_argv(pl) created"  
	log info "Finished"
}

proc create_random_view {} {
  global log db conn 
  # catch {::mysql::exec $conn "drop view if exists albums"}
  log debug "Dropping view albums"
  try_eval {
    pg_query $conn "drop view if exists albums"
  } {
    log_error "drop view albums failed" 
  }
  log debug "Dropped view albums"
  # breakpoint
  set query "create view albums (id, path, freq, freq_history, play_count) as
             select g.id, a.path, g.freq, g.freq_history, g.play_count
             from generic g, album a, member mem, mgroup mg
             where a.generic = g.id
             and mem.generic = g.id
             and mem.mgroup = mg.id
             and mg.name = 'Albums'
             and (a.file_exists is null or a.file_exists = 1)"
  try_eval {
    pg_query $conn $query
  } {
    log_error "create view albums failed"
    log warn "Possibly the database cannot be accessed"
    log warn "Restarting the system might help (as it did on 13-9-2013)"
    exit
  }
}

# @param lst: list of tuples/lists: [id path random]
proc make_album_playlist {lst filename} {
   set f [open $filename w]
   # fconfigure $f -translation crlf
   # voor windows encoding op niet-utf-8 zetten, met bjork lijkt het nu goed te gaan.
   # fconfigure $f -encoding cp1252
   set lst [lsort -decreasing -real -index 2 $lst] ; # zet in de random order. (index2 = random waarde) 
   foreach el $lst {
     # foreach {generic_id db_path rnd} $el break
     lassign $el generic_id db_path rnd
     puts_album $f $generic_id $db_path
     # puts $f [make_copy_line $path $to_drive $index]
   }
   close $f
}

proc puts_album {f generic_id db_path} {
  # kijk op filesystem zelf, niet in DB.
  # puts "db_path: $db_path"
  set path [det_linux_path $db_path]
  log debug "path: $path"
  set lst [glob -nocomplain -directory $path -type f *]
  set lst2 [lsort [::struct::list filter $lst is_music_file]]
  foreach el $lst2 {
    puts $f $el 
  }
  if {$lst2 == {}} {
    if {[file exists $path]} {
      log warn "No music files found in dir. Other files:"
      log warn $lst
    } else {
      log warn "Directory $path does not exist in file system. Mark as not existing in DB."
      mark_exists album $generic_id 0
    }
  } else {
    log debug "At least one music file"
    mark_exists album $generic_id 1
  }
}

proc mark_exists {table generic_id exists} {
  global db
  # table is album here.
  set query "update $table set file_exists = $exists where generic = $generic_id"
  $db exec_query $query
}

proc det_linux_path {db_path} {
  return [file join "/media/nas" $db_path] 
}

main $argc $argv

