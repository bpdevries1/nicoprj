#!/usr/bin/env tclsh861

# convert ODBC log file with timestamps to a log with events more suitable to analysis with Splunk
# vanaf 2015-07-31 13:22:21.257 echte tijden, hiervoor dummy.
# nu wel een file met overal timestamps, vanaf het begin dat sessie wordt opgebouwd.
package require ndv
package require tdbc::sqlite3

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  global log db filename
  lassign $argv logfilepath
  set filename [file tail $logfilepath]
  set dbname [file join [file dirname $logfilepath] "odbccalls.db"]
  catch {file delete $dbname} ; # while testing delete the sqlite db first. Not possible if open in SQLiteSpy
  set db [get_db $dbname]
  empty_tables $db
  if {0} {
    test_hex $db
    $db close
    exit
  }
  set f [open $logfilepath r]
  set lst_lines {}
  set linenr 0
  # op verschillende niveau's afhandelen
  $db in_trans {
    while {![eof $f]} {
      gets $f line
      incr linenr
      if {[regexp {^\[([0-9 :.-]+)\] (.*)$} $line z ts_cet rest]} {
        if {$rest == ""} {
          # end of event, handle it.
          handle_event $ts_cet $linenr $lst_lines
          set lst_lines {}
        } else {
          lappend lst_lines $rest
        }
      }
      
    }
  }
  # mogelijk hier nog wat rest dingen om af te handelen
  
  close $f
  $db close
}

proc empty_tables {db} {
  foreach table {event odbccall} {
    $db exec "delete from $table"
  }
}

proc handle_event {ts_cet linenr lst_lines} {
  global log db filename ar_ctx
  set lines [join $lst_lines "\n"]
  # $db insert event [vars_to_dict filename linenr ts_cet enterexit callname HENV HDBC HSTMT query returncode returnstr lines]
  set line1 [:0 $lst_lines]
  set callname ""
  set returncode ""
  set returnstr ""
  set enterexit ""
  if {[regexp {^recwin.*ENTER\s([^\s]+)\s*$} $line1 z callname]} {
    set enterexit "ENTER"
  } elseif {[regexp {^recwin.*EXIT\s+([^\s]+)\s+with return code (\d+)(.*)$} $line1 z callname returncode rest]} {
    set enterexit "EXIT"
    set returnstr ""
    regexp {\(([^ ]+)\)} $rest z returnstr
  } elseif {[regexp {DIAG} $line1]} {
    # nothing, no warnin.  
  } else {
    # something else, warning?
    $log warn "No ENTER/EXIT: $lines\n=========="
    # breakpoint
  }
  if {$enterexit != ""} {
    set d [get_params $lst_lines]
    check_dict $d
    set d2 [set_context_vars $callname $enterexit $d $lst_lines]
    check_dict $d2
    set dfull [append_params_context [dict merge $d $d2]]
  } else {
    set dfull {}
  }
  if {($callname == "SQLAllocConnect") && $enterexit == "EXIT"} {
    #puts "SQLAllocConnect - check!"
    #$db insert event [dict merge [vars_to_dict filename linenr ts_cet enterexit callname returncode returnstr lines] $dfull]
    # breakpoint
  }
  $db insert event [dict merge [vars_to_dict filename linenr ts_cet enterexit callname returncode returnstr lines] $dfull]
  if {$enterexit != ""} {
    reset_context_vars $callname $enterexit $d $lst_lines
  }
}

# met deze toch wel hex waarden in de DB
proc test_hex {db} {
  set HDBC 0x100
  $db insert event [vars_to_dict HDBC]
}

# return dict
proc get_params {lst_lines} {
  set d [dict create]
  foreach line $lst_lines {
    if {[regexp {\s+(\S+)\s+(\S+)\s*$} $line z nm val]} {
      if {[lsearch -exact {HENV HDBC HSTMT} $nm] >= 0} {
        if {$val != "*"} {
          if {$nm == "*"} {
            puts "nm=*"
            breakpoint
          }
          dict set d $nm $val    
        }
      }
    }
  }
  check_dict $d
  return $d  
}


# ar_ctx(HENV,<hdbc>) = <henv>
# ar_ctx(HDBC,<hstmt>) = <hdbc>
# ar_ctx(query,<hstmt>) = <query>
# obv specifieke calls deze vullen of clearen.
# return new params in dict
proc set_context_vars {callname enterexit d lst_lines} {
  global ar_ctx
  set d2 [dict create]
  if {($callname == "SQLAllocConnect") && $enterexit == "EXIT"} {
    #recwin          137c-1774	EXIT  SQLAllocConnect  with return code 0 (SQL_SUCCESS)
		#HENV                0x022D03E8
		#HDBC *              0x022E9E00 ( 0x022EDB00)
    set HDBC [find_value $lst_lines HDBC]
    set ar_ctx(HENV,$HDBC) [:HENV $d]
    dict set d2 HDBC $HDBC
    # breakpoint
    # HENV already set
  }
  if {($callname == "SQLAllocStmt") && $enterexit == "EXIT"} {
    #recwin          137c-1774	EXIT  SQLAllocStmt  with return code 0 (SQL_SUCCESS)
		#HDBC                0x022EDB00
		#HSTMT *             0x00189E64 ( 0x022EE238)
    set HSTMT [find_value $lst_lines HSTMT]
    set ar_ctx(HDBC,$HSTMT) [:HDBC $d]
    dict set d2 HSTMT $HSTMT
    # HDBC already set
  }
  if {($callname == "SQLExecDirect") && $enterexit == "ENTER"} {
    #recwin          137c-1774	ENTER SQLExecDirect 
		#HSTMT               0x022EE238
		#UCHAR *             0x022D66E8 [      -3] "SELECT * FROM approleids WHERE role = 'PrivateMatch'\ 0"
		#SDWORD                    -3
    if {[regexp {UCHAR.*"(.+)"} [lindex $lst_lines 2] z q]} {
      set ar_ctx(query,[:HSTMT $d]) $q
      dict set d2 query $q
    } else {
      breakpoint
      error "SQLExecDirect but no query found in line 3: $lst_lines"
    }
  }
  return $d2
}

# ar_ctx(HENV,<hdbc>) = <henv>
# ar_ctx(HDBC,<hstmt>) = <hdbc>
# ar_ctx(query,<hstmt>) = <query>
# obv specifieke calls deze clearen.
proc reset_context_vars {callname enterexit d lst_lines} {
  global ar_ctx
  if {($callname == "SQLFreeConnect") && $enterexit == "EXIT"} {
    set ar_ctx(HENV,[:HDBC $d]) ""
  }
  if {($callname == "SQLFreeStmt") && $enterexit == "EXIT"} {
    set ar_ctx(HDBC,[:HSTMT $d]) ""
    set ar_ctx(query,[:HSTMT $d]) ""
  }
}

proc find_value {lst_lines name} {
  foreach line $lst_lines {
    if {[regexp "$name \\*\\s+\\S+\\s+\\(\\s*(\\S+)\\s*\\)" $line z val]} {
      return $val
    }
  }
  error "$name value not found in: $lst_lines"
}

# param d: dict
# return dict
proc append_params_context {d} {
  global ar_ctx
  # from HSTMT to HDBC
  check_dict $d
  # breakpoint
  set hstmt [:HSTMT $d]
  if {$hstmt != ""} {
    #dict set d HDBC $ar_ctx(HDBC,$hstmt)
    dict set d HDBC [array_get ar_ctx HDBC,$hstmt]
    #dict set d query $ar_ctx(query,$hstmt)
    dict set d query [array_get ar_ctx query,$hstmt]
  }

  # then from HDBC to HENV
  set hdbc [:HDBC $d]
  if {$hdbc == "*"} {
    breakpoint
  }
  if {$hdbc != ""} {
    # dict set d HENV $ar_ctx(HENV,$hdbc)
    set val [array_get ar_ctx HENV,$hdbc]
    if {$val == ""} {
      #puts "val is empty to set in d: $val, key: HENV,$hdbc"
      #breakpoint
    } else {
      dict set d HENV [array_get ar_ctx HENV,$hdbc]  
    }
  }

  return $d
}

# return value of ndx in array, or empty string if not found
# return second element (:1) of array get result
proc array_get {ar_name ndx} {
  upvar $ar_name ar
  :1 [array get ar $ndx]
}

# some keys should not appear in d, like *
proc check_dict {d} {
  if {[dict exists $d "*"]} {
    error "Found * in dict: $d"
  }
}

proc get_db {db_name} {
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs.
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    # create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  return $db
}

proc define_tables {db} {
  $db add_tabledef event {id} {filename {linenr int} ts_cet enterexit callname HENV HDBC HSTMT query {returncode int} returnstr lines}
  $db add_tabledef odbccall {id} {filename {linenr_enter int} {linenr_exit} ts_cet_enter ts_cet_exit {calltime real} callname HENV HDBC HSTMT query {returncode int}}
  
  # later: ook events op hoger niveau, bv alles van een statement.
  
}


main $argv


