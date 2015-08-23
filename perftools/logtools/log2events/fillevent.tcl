proc read_log {logfilepath db} {
  global log filename seqnr_global
  log info "Reading log: $logfilepath"
  set filename [file tail $logfilepath]
  set f [open $logfilepath r]
  set lst_lines {}
  set ts_cet ""
  set linenr ""
  set linenr1 0
  set seqnr_global 0
  # op verschillende niveau's afhandelen
  $db in_trans {
    while {![eof $f]} {
      gets $f line
      incr linenr1
      if {$linenr1 % 10000 == 0} {
        log info "$linenr1 lines read"
      }
#      if {[regexp {^\[([0-9 :.-]+)\] (.*)$} $line z ts_cet rest]} {}
      if {[regexp {^\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}.\d{3})\] (.*)$} $line z ts rest]} {
        # 17-8-2015 NdV neem alleen het tijdstip van de eerste regel, waar recwin op staat. Anders wil het nog wel eens afwijken.
        if {[regexp {^recwin} $rest]} {
          set ts_cet $ts
          set linenr $linenr1
        }
        if {$rest == ""} {
          # end of event, handle it.
          if {$linenr != ""} {
            handle_event $ts_cet $linenr $lst_lines  
          }
          set lst_lines {}
          set ts_cet ""
          set linenr ""
        } else {
          lappend lst_lines $rest
        }
      } elseif {$line == ""} {
        # ok, empty line
      } else {
        log warn "Invalid line: $line"
      }
    }
  }
  # mogelijk hier nog wat rest dingen om af te handelen
  if {$lst_lines != {}} {
    handle_event $ts_cet $linenr $lst_lines
  }
  close $f

}

proc empty_tables {db} {
  foreach table {event odbccall odbcquery userthink} {
    $db exec "delete from $table"
  }
}

proc handle_event {ts_cet linenr lst_lines} {
  global log db filename ar_ctx seqnr_global
  set lines [join $lst_lines "\n"]
  # $db insert event [vars_to_dict filename linenr ts_cet enterexit callname HENV HDBC HSTMT query returncode returnstr lines]
  set line1 [:0 $lst_lines]
  set callname ""
  set returncode ""
  set returnstr ""
  set enterexit ""
  set seqnr ""
  if {[regexp {^recwin.*ENTER\s([^\s]+)\s*$} $line1 z callname]} {
    set enterexit "ENTER"
    incr seqnr_global
    set seqnr $seqnr_global
  } elseif {[regexp {^recwin.*EXIT\s+([^\s]+)\s+with return code (\d+)(.*)$} $line1 z callname returncode rest]} {
    set enterexit "EXIT"
    incr seqnr_global
    set seqnr $seqnr_global
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
  $db insert event [dict merge [vars_to_dict filename seqnr linenr ts_cet enterexit callname returncode returnstr lines] $dfull]
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
# init all params to empty string, so in queries null check is not needed.
proc get_params {lst_lines} {
  set d [dict create HENV "" HDBC "" HSTMT "" query ""]
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
  if {(($callname == "SQLExecDirect") || ($callname == "SQLPrepare")) && $enterexit == "ENTER"} {
    #recwin          137c-1774	ENTER SQLExecDirect 
		#HSTMT               0x022EE238
		#UCHAR *             0x022D66E8 [      -3] "SELECT * FROM approleids WHERE role = 'PrivateMatch'\ 0"
		#SDWORD                    -3
    # [2015-07-31 13:23:49.165] 		UCHAR *             0x022EE7C8 [      -3] "SELECT * FROM "ItemReconHistory" WHERE 0 = 1\ 0"
    if {[regexp {UCHAR.*?"(.+)"$} [lindex $lst_lines 2] z q]} {
      check_sql $q
      set ar_ctx(query,[:HSTMT $d]) $q
      dict set d2 query $q
    } else {
      breakpoint
      error "SQLExecDirect but no query found in line 3: $lst_lines"
    }
  }

  return $d2
}

proc check_sql {q} {
  if {[regexp {^([^ ]+) } [string trim $q] z first]} {
    if {[lsearch -exact {select insert delete update \{call} [string tolower $first]] < 0} {
      log warn "strange query1: $q"
    }
  } else {
    log warn "strange query2: $q"
  }
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
