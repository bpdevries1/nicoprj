#!/home/nico/bin/tclsh86

# note: car-player snapt .m4a niet.

package require ndv
package require Tclx

::ndv::source_once ../db/MusicSchemaDef.tcl

# set SINGLES_ON_SD 150 ; # 1GB?

# @todo: have option copy-until-full, but then copy directly in this script, don't create batch file
set SINGLES_ON_SD 530 ; # 4GB? Bij 600 te veel, 550 lijkt ongeveer te kunnen. 10-1-2014 toch maar 530 doen.
# set SINGLES_ON_SD 594 ; # test

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argc argv} {
  global log db conn stderr argv0 SINGLES_ON_SD
	$log info "Starting"

  set options {
    {drv.arg "/media/nico/PHILIPS" "USB Drive to copy music files to (on linux machine)"}
    {bat.arg "/media/nas/copy-sd.sh" "Batch/shell file to create"}
    {groupname.arg "Singles-car" "Group name to use"}
    {np "Don't mark selected files as played in database (for testing)"}
  }

  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  array set ar_argv $dargv

	set to_drive $ar_argv(drv)
	set bat_filename $ar_argv(bat)

  set schemadef [MusicSchemaDef::new]
  set db [::ndv::CDatabase::get_database $schemadef]
  set conn [$db get_connection]

  ::mysql::exec $conn "set names utf8"

  # create_random_view Singles
  # create_random_view "Singles-car"
  create_random_view [dict get $dargv groupname] ; # cannot use :groupname here, still Tcl85.
  set lst [::ndv::music_random_select $db $SINGLES_ON_SD "-tablemain generic -viewmain singles -tableplayed played"] 
  make_copy_sd $lst $to_drive $bat_filename
  exec chmod +x $bat_filename
  if {!$ar_argv(np)} {
    $log info "Mark files as played in database"
    # $log warn "NOT: still in testing mode!"
    # 10-01-2014 exec within transaction, otherwise very slow. NOT TESTED YET!
    ::mysql::exec $conn "start transaction"
    ::ndv::music_random_update $db $lst "sd-auto" "-tablemain generic -viewmain singles -tableplayed played"
    ::mysql::exec $conn "commit"
  } else {
    $log info "Don't mark files as played in database" 
  }
  
  $log info "$bat_filename created"  
	$log info "Finished"
}

proc create_random_view {group_name} {
  global log db conn 
  catch {::mysql::exec $conn "drop view if exists singles"}
  set query "create view singles (id, path, freq, freq_history, play_count) as
             select g.id, m.path, g.freq, g.freq_history, g.play_count
             from generic g, musicfile m, member mem, mgroup mg
             where m.generic = g.id
             and mem.generic = g.id
             and mem.mgroup = mg.id
             and mg.name = '$group_name'"
  ::mysql::exec $conn $query
}

# @param lst: list of tuples/lists: [id path random]
proc make_copy_sd {lst to_drive bat_filename} {
   set f [open $bat_filename w]
   if {[file extension $bat_filename] == ".bat"} {
     fconfigure $f -translation crlf
     # voor windows encoding op niet-utf-8 zetten, met bjork lijkt het nu goed te gaan.
     fconfigure $f -encoding cp1252
   } else {
     # leave default: just LF and UTF-8. 
   }
   set lst [lsort -decreasing -real -index 2 $lst] 
   set index 1
   foreach el $lst {
     foreach {id path rnd} $el break
     puts $f [make_copy_line $path $to_drive $index]
     incr index
   }
   puts "rem draai remomedia/maak_m3u_f.tcl"
   close $f
}

proc is_ok {filename} {
	if {$filename == ""} {
		return 0
	}
	set ext [file extension $filename]
	if {$ext == ".m4a"} {
		return 0
	} else {
		return 1
	}
}

set prev_dir ""

proc make_copy_line {pathname to_drive index} {
	global prev_dir log

	set to_dir [det_to_dir $pathname]
	set to_file [file tail $pathname]
	set lst_result {}
	if {$to_dir != $prev_dir} {
		lappend lst_result "mkdir \"[file join $to_drive $to_dir]\""
		set prev_dir $to_dir
	}
	lappend lst_result "cp \"[det_linux_path $pathname]\" \"[file join $to_drive $to_dir "[format %03d $index]-$to_file"]\""
  #$log debug "lst_result: $lst_result"
  #$log debug "join hiervan: [join $lst_result "\n"]"
  return [join $lst_result "\n"]
}

set curr_index 0
proc det_to_dir {pathname} {
	global curr_index
	set to_dir [format "dir%03d" [expr 1 + $curr_index / 10]]
  incr curr_index
	return $to_dir
}

proc det_linux_path {db_path} {
  file join / media nas $db_path 
}

main $argc $argv

