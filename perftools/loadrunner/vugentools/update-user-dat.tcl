#/usr/bin/env tclsh

package require ndv
package require tdbc::sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "logs/[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

proc main {argv} {
  set options {
    {dir.arg "c:/PCC/Nico/raboprj/VuGen" "Directory with VuGen scripts"}
    {db.arg "" "SQLite DB location with run results (pas_niet_correct)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]

  set dir [:dir $dargv]
  set dbname [:db $dargv]

  set db [get_results_db $dbname]

  set error_users [det_error_users $db]
  puts "Number of users with invalid pass: [:# $error_users]"

  handle_dirs $dir $error_users
  $db close
}

proc det_error_users {db} {
  set res1 [$db query "select distinct user from error_iter where errortype='pas_niet_correct'"]
  set res2 [$db query "select distinct user from trans where transname like '%IncorrectPass%'"]
  lmap el [concat $res1 $res2] {:user $el}
}

proc handle_dirs {dir error_users} {
  # TODO hier evt alle scripts nalopen.
  foreach subdir {RCC_All RCC_CashBalancingWidget RCC_LoansWidget Transact_secure} {
    handle_vugen_dir [file join $dir $subdir] $error_users
  }
}

proc handle_vugen_dir {vugendir error_users} {
  set bakdir [file join $vugendir [clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]]
  file mkdir $bakdir
  foreach ext {.dat .txt .list} {
    foreach filename [glob -nocomplain -directory $vugendir -type f "*$ext"] {
      handle_file $filename $error_users $bakdir
    }
  }
}

proc handle_file {filename error_users bakdir} {
  # alleen file aanpassen als er iets veranderd is. En dan ook alleen backup maken.
  log debug "Handling file: $filename"
  set tmpfile "$filename.__TEMP__"
  set fi [open $filename r]
  set fo [open $tmpfile w]
  set nremoved 0
  while {[gets $fi line] >= 0} {
    set found 0
    foreach us $error_users {
      if {[regexp $us $line]} {
        set found 1
        log warn "User with error found: removing $us from $filename"
      }
    }
    if {$found} {
      incr nremoved
      # log already done
    } else {
      puts $fo $line
    }
  }
  close $fi
  close $fo
  if {$nremoved > 0} {
    log info "File changed, move orig to bak: $filename"
    file rename $filename [file join $bakdir [file tail $filename]]
    file rename $tmpfile $filename
  } else {
    log debug "File not changed: $filename"
    file delete $tmpfile
  }
}

# deze mogelijk in libdb:
proc get_results_db {db_name} {
  #breakpoint
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs. 1: drop tables first.
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    # create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  #breakpoint
  return $db
}

proc define_tables {db} {
  $db add_tabledef logfile {id} {logfile dirname ts_cet {filesize int} {runid int} project script}

  $db add_tabledef retraccts {id} {logfile_id {vuserid int} {linenr int} ts_cet {sec_cet int} user {naccts int} {resptime real}}
  # 17-6-2015 NdV transaction is a reserved word in SQLite, so use trans as table name
  # $db add_tabledef trans {id} {logfile {vuserid int} ts_cet {sec_cet int} transname user {resptime real}}
  $db add_tabledef trans {id} {logfile_id {vuserid int} {linenr int} ts_cet {sec_cet int} transname user {resptime real} {status int}
                   usecase revisit {transid int} transshort searchcrit}
  $db add_tabledef error {id} {logfile_id logfile {vuserid int} {linenr int} {iteration int} srcfile {srcline int} ts_cet user errornr errortype details line}
                   
  # 22-10-2015 NdV ook errors per iteratie, zodat er een hoofd schuldige is aan te wijzen voor het falen.
  $db add_tabledef error_iter {id} {logfile_id logfile {vuserid int} {iteration int} user errortype}
  
}

main $argv
