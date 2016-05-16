#!/usr/bin/env tclsh86

# handle-myphilips.tcl - add labelmappings to distinguish between janrain, atg, and db requests.

# @note log debug (and maybe first_line) statements cause memory exhaustion, uncommenting those helps on Windows. (on Linux no problems, but have more memory there).

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[info script].log"

# @todo remove redundant logging.

proc main {argv} {
  global conn dct_insert_stmts argv0
  if {[llength $argv] != 1} {
    log error "syntax: $argv0 <dir-for-db>"
    exit 1
  }
  lassign $argv dbdirname
  set conn [open_db [file join $dbdirname "jtldb.db"]]
  fill_labelmapping $conn
  check_labelmapping $conn
  add_tests_steps $conn
  set_extensions_for_level0 $conn
  finish_db $conn
}

proc finish_db {conn} {
  $conn close
}

proc fill_labelmapping {conn} {
  log info "fill_labelmapping: start"
  db_eval_try $conn "drop table labelmapping"
  db_eval $conn "create table labelmapping (lb, step, lb_short, lb_type)"
  db_eval $conn "insert into labelmapping (lb)
                  select distinct lb
                  from httpsample
                  where level=0"
  db_in_trans $conn {
    # landing page
    update_lm $conn "https://secure.philips.nl/myphilips/landing.jsp" "landing" "landing.jsp" "atg"
    update_lm $conn "https://philips.janrainsso.com/static/server.html" "landing" "jr-buttons" "jr"
    
    # login
    update_lm $conn "https://philips.janraincapture.com/widget/traditional_signin.jsonp" "login" "jr-signin" "jr"
    update_lm $conn "get_result" "login" "jr-get-result" "jr"
    update_lm $conn "set_login" "login" "jr-set-login" "jr"
    update_lm $conn "ATGJanRain" "login" "jr-internal" "jr"
    update_lm $conn "/services/services/JanrainAuthenticationWebService/login" "login" "ws-login" "atg-jr-db"
    update_lm $conn "https://secure.philips.nl/myphilips/home.jsp" "login" "login-home.jsp" "atg-db"

    # logout
    update_lm $conn "https://secure.philips.nl/myphilips/logout" "logout" "logout" "atg-jr-?"
  }  
  log info "fill_labelmapping: finished"
}

proc update_lm {conn lb step lb_short lb_type} {
  db_eval $conn "update labelmapping set step='$step', lb_short='$lb_short', lb_type='$lb_type' where lb='$lb'" 
}

proc check_labelmapping {conn} {
  foreach dct [db_query $conn "select lb from labelmapping where step is null"] {
    log warn "No mapping for [:lb $dct]" 
  }
}

# read all level0 samples, add tests (identified by start-time) and steps in here.
# goal is use these to create waterfalls of an entire step or test.
proc add_tests_steps {conn} {
  # global ar_step
  log info "add_tests_steps: start"
  set sql "select step, lb, lb_short from labelmapping"
  foreach rec [db_query $conn $sql] {
    set ar_step([:lb $rec]) [:step $rec]
    set ar_short([:lb $rec]) [:lb_short $rec]
  }
  #db_eval_try $conn "drop table mainreq"
  #db_eval $conn "create table labelmapping (lb, step, lb_short, lb_type)"
  # set td_mainreq [make_table_def_keys mainreq {id} {utc_run step sample_id lb lb_short utc_req ts_step_start ts_step_end t_step t_req}]
  set td_mainreq [make_table_def_keys mainreq {id} {utc_run step i_step_in_run ts_step_start ts_step_end t_step sample_id i_req_in_run i_req_in_step lb lb_short utc_req ts_req t_req s_req s_step}]
  create_table $conn $td_mainreq 1
  set insert_stmt [prepare_insert_td_proc $conn $td_mainreq]
  
  set td_step [make_table_def_keys step {id} {utc_run step i_step_in_run i_req_in_run i_req_in_step ts_step_start ts_step_end t_step s_step s_req}]
  create_table $conn $td_step 1
  set insert_stmt_step [prepare_insert_td_proc $conn $td_step]
  
  set prev_ts 0
  set utc_curr_run ""
  set curr_step_ts 0
  set prev_step ""
  set i_step_in_run -1
  set i_req_in_run -1
  set i_req_in_step -1
  # @note could dynamically check if request belongs to a new step and then handle previous, but this script is already very specific.
  array set n_req_in_step {landing 2 login 6 logout 1} 
  log info "about to read all httpsamples and add mainreq's"
  set sql "select id, ts, ts_utc, lb, t,s from httpsample where level = 0 order by jtlfile_id, ts"
  db_in_trans $conn {
    set i 0
    foreach rec [db_query $conn $sql] {
      incr i
      if {[expr $i % 1000] == 0} {
        log info "Handled $i records, commit and start new transaction"
        db_eval $conn "commit"
        db_eval $conn "begin transaction"
      }
      dict_to_vars $rec
      set step $ar_step($lb)
      set lb_short $ar_short($lb)
      if {($prev_step == "logout") && ($lb_short == "jr-buttons")} {
        # ignore this one: it's the last of the previous run, but due to timer, it's executed just before the next run.
        continue
      }
      if {[big_diff $prev_ts $ts]} {
        # more than 5 minutes: a new testrun has started
        set utc_curr_run $ts_utc
        set i_step_in_run 0 ; # gets increased below, in a new run, we also start with a new step.
        set i_req_in_run 0
        set i_req_in_step 0
      }
      if {$step != $prev_step} {
        set curr_step_ts $ts
        incr i_step_in_run
        set i_req_in_step 0
        set s_step $s
      } else {
        if {$s == "false"} {
          set s_step $s 
        }
      }
      # ts_utc_end ts_start ts_end t_step
      set ts_end [expr $ts + $t]
      set t_step [expr ($ts - $curr_step_ts) + $t]
      incr i_req_in_run
      incr i_req_in_step
      set dct [dict create utc_run $utc_curr_run \
        step $step i_step_in_run $i_step_in_run ts_step_start $curr_step_ts ts_step_end $ts_end t_step $t_step \
        i_req_in_run $i_req_in_run i_req_in_step $i_req_in_step utc_req $ts_utc sample_id $id lb $lb \
        lb_short $lb_short ts_req $ts t_req $t s_req $s s_step $s_step]
      $insert_stmt $dct 
      if {$i_req_in_step == $n_req_in_step($step)} {
        $insert_stmt_step $dct        
      }
      set prev_ts $ts
      set prev_step $step
    }
  }
  log info "add_tests_steps: finished"
}

# @note timestamps are in milliseconds, so 5 minutes = 5 * 60 * 1000 = 300000
proc big_diff {ts_prev ts_curr} {
  if {$ts_prev == 0} {
    return 1 
  }
  if {[expr $ts_curr - 300000] > $ts_prev} {
    return 1 
  } else {
    return 0 
  }
}

proc set_extensions_for_level0 {conn} {
  # check if level=0 and extension = "<none>". If so, set extension to lb_short
  # db_eval $conn "update httpsample set extension = (select l.lb_short from labelmapping l where l.lb = httpsample.lb) where level = 0 and extension = '<none>'"
  # sowieso extension op lb_short zetten waar level = 0.
  db_eval $conn "update httpsample set extension = (select l.lb_short from labelmapping l where l.lb = httpsample.lb) where level = 0"
}

main $argv

