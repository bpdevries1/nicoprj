#/usr/bin/env tclsh

package require ndv
package require tdbc::sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "logs/[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

ndv::source_once libuserinfo.tcl

proc main {argv} {
  set options {
    {dir.arg "c:/PCC/Nico/VuGen" "Directory with VuGen scripts"}
    {db.arg "c:\PCC\Nico\Projecten\RCC\2016-02 (international)\MOED-lijst\MOED-lijst.db" "SQLite DB location with MOED lijst, .dat files and test results."}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]

  set dir [:dir $dargv]
  set dbname [:db $dargv]

  set db [get_info_db $dbname]

  handle_dirs $db $dir
  $db close
}

proc handle_dirs {db dir} {
  foreach subdir [glob -directory $dir -type d *] {
    handle_vugen_dir $db $subdir 
  }
}

proc handle_vugen_dir {db vugendir} {
  puts "Handling dir: $vugendir"
  foreach ext {.dat .txt .list} {
    foreach filepath [glob -nocomplain -directory $vugendir -type f "*$ext"] {
      handle_file $db $vugendir $filepath
    }
  }
}

proc handle_file {db directory filepath} {
  if {[is_file_read $db $filepath]} {
    log info "File already read, continue: $filepath"
	return
  } else {
	log info "Handling file: $filepath"
  }
  set f [open $filepath r]
  gets $f headerline
  set usercol [det_usercol $headerline]
  set project [file tail $directory]
  set filename [file tail $filepath]
  set file_ts [clock format [file mtime $filepath] -format "%Y-%m-%d %H:%M:%S"]
  if {$usercol == -1} {
    # no user column found, ignore file.
  } else {
    $db in_trans {
		while {[gets $f line] >= 0} {
		  set userid [string trim [lindex [split $line ","] $usercol]]
		  if {$userid != ""} {
			$db insert userdat [vars_to_dict directory project filepath filename file_ts userid line]
		  }
		}
	}
  }
  close $f
  set_file_read $db $filepath
}

proc det_usercol {headerline} {
  set i 0
  foreach el [split $headerline ","] {
    if {[regexp {user} $el]} {
	  return $i
	} else {
	  incr i
	}
  }
  return -1
}

main $argv
