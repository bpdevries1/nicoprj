#/usr/bin/env tclsh

package require ndv
package require tdbc::sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "logs/[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

ndv::source_once libuserinfo.tcl

proc main {argv} {
  set options {
    {dir.arg "c:/PCC/Nico/testruns" "Directory with results DB's"}
    {db.arg "c:\PCC\Nico\Projecten\RCC\2016-02 (international)\MOED-lijst\MOED-lijst.db" "SQLite DB location with MOED lijst, .dat files and test results."}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]

  set dir [:dir $dargv]
  set dbname [:db $dargv]

  set db [get_info_db $dbname]

  handle_dir $db $dir
  $db close
}

proc handle_dir {db dir} {
  foreach dbfile [glob -nocomplain -directory $dir -type f *.db] {
    handle_file $db $dir $dbfile
  }
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    handle_dir $db $subdir 
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
  set dbr [get_results_db $filepath]
  set filename [file tail $filepath]
  set file_ts [clock format [file mtime $filepath] -format "%Y-%m-%d %H:%M:%S"]
  set query "select distinct user, errortype from error_iter"
  try_eval {
	set res [$dbr query $query]
  } {
	set res {}
  }
  
  set project [file tail $directory]
  $db in_trans {
    foreach rec $res {
	  set userid [:user $rec]
	  set errortype [:errortype $rec]
      $db insert runresult [vars_to_dict directory project filepath filename file_ts userid errortype]
	}
  }
  
  # [2016-02-03 12:54:33] ook alle transacties opnemen, met errortype=trans
  set query "select distinct user, transname, status from trans order by user, transname"
  try_eval {
	set res [$dbr query $query]
  } {
	set res {}
  }
  $db in_trans {
    set prev_userid ""
	set prev_errortype ""
    set prev_transname ""
	set prev_transstatus ""
    foreach rec $res {
	  set userid [:user $rec]
	  if {$userid == "xx3002672403"} {
		puts "Found user result: $rec"
	  }
	  set transname [:transname $rec]
	  set transstatus [:status $rec]
	  set errortype [det_trans_errortype $transname]
	  if {$errortype != ""} {
		  if {($userid != $prev_userid) || ($errortype != $prev_errortype)} {
			$db insert runresult [vars_to_dict directory project filepath filename file_ts userid errortype]
			if {$userid == "xx3002672403"} {
				puts "-> inserted record, errortype: $errortype/$prev_errortype, $userid/$prev_userid"
			}
		  } else {
			if {$userid == "3002672403"} {
			  puts "-> already have, don't insert again, errortype: $errortype"
			}
		  }
	  } else {
	    # no error, not in runresult table, only runresulttrans
	  }
	  # all unique transnames for user in runresulttrans
	  if {($userid != $prev_userid) || ($transname != $prev_transname) || ($transstatus != $prev_transstatus)} {
	    # $db add_tabledef runresulttrans {id} {directory project filepath filename file_ts userid transname {transstatus int}}
		$db insert runresulttrans [vars_to_dict directory project filepath filename file_ts userid transname transstatus]
		if {$userid == "xx3002672403"} {
			puts "-> inserted record, errortype: $errortype/$prev_errortype, $userid/$prev_userid"
		}
	  } else {
		if {$userid == "xx3002672403"} {
	      puts "-> already have, don't insert again, errortype: $errortype"
		}
	  }
      set prev_userid $userid
	  set prev_transname $transname
	  set prev_transstatus $transstatus
	  set prev_errortype $errortype
	}
  }
  $dbr close
  set_file_read $db $filepath
}

proc det_trans_errortype {transname} {
  if {[regexp -nocase {incorrectpass} $transname]} {
    return "pas_niet_correct"
  } else {
    return ""
  }
}

proc get_results_db {db_name} {
  #breakpoint
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  return $db
}

main $argv
