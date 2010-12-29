#!/home/nico/bin/tclsh

# note: car-player snapt .m4a niet.

package require ndv
package require Tclx

::ndv::source_once ../db/MusicSchemaDef.tcl

set SINGLES_ON_SD 150

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log db conn stderr argv0 SINGLES_ON_SD
	$log info "Starting"

  set options {
    {drv.arg "f:/" "USB Drive to copy music files to on windows machine"}
    {bat.arg "/media/nas/copy-sd.bat" "Batch file to create"}
    {np "Don't mark selected files as played in database"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

	set to_drive $ar_argv(drv)
	set bat_filename $ar_argv(bat)

  set schemadef [MusicSchemaDef::new]
  set db [::ndv::CDatabase::get_database $schemadef]
  set conn [$db get_connection]

  ::mysql::exec $conn "set names utf8"

  create_random_view
  set lst [::ndv::music_random_select $db $SINGLES_ON_SD "-tablemain generic -viewmain singles -tableplayed played"] 
  make_copy_sd $lst $to_drive $bat_filename
  
  if {!$ar_argv(np)} {
    $log info "Mark files as played in database" 
    ::ndv::music_random_update $db $lst "sd-auto" "-tablemain generic -viewmain singles -tableplayed played"
  } else {
    $log info "Don't mark files as played in database" 
  }
  
  $log info "$bat_filename created"  
	$log info "Finished"
}

proc create_random_view {} {
  global log db conn 
  catch {::mysql::exec $conn "drop view if exists singles"}
  set query "create view singles (id, path, freq, freq_history, play_count) as
             select g.id, m.path, g.freq, g.freq_history, g.play_count
             from generic g, musicfile m, member mem, mgroup mg
             where m.generic = g.id
             and mem.generic = g.id
             and mem.mgroup = mg.id
             and mg.name = 'Singles'"
  ::mysql::exec $conn $query
}

# @param lst: list of tuples/lists: [id path random]
proc make_copy_sd {lst to_drive bat_filename} {
   set f [open $bat_filename w]
   fconfigure $f -translation crlf
   # voor windows encoding op niet-utf-8 zetten, met bjork lijkt het nu goed te gaan.
   fconfigure $f -encoding cp1252
   set lst [lsort -decreasing -real -index 2 $lst] 
   set index 1
   foreach el $lst {
     foreach {id path rnd} $el break
     puts $f [make_copy_line $path $to_drive $index]
     incr index
   }
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
		lappend lst_result "mkdir \"[sub_slash [file join $to_drive $to_dir]]\""
		set prev_dir $to_dir
	}
	lappend lst_result [sub_slash "copy \"[det_windows_path $pathname]\" \"[file join $to_drive $to_dir "[format %03d $index]-$to_file"]\""]
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

proc sub_slash {str} {
	regsub -all "/" $str "\\" str
	return $str
}

proc det_windows_path {db_path} {
  return [file join "w:/" $db_path] 
}

main $argc $argv

