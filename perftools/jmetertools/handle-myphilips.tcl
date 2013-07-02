#!/usr/bin/env tclsh86

# handle-myphilips.tcl - add labelmappings to distinguish between janrain, atg, and db requests.

# @note log debug (and maybe first_line) statements cause memory exhaustion, uncommenting those helps on Windows. (on Linux no problems, but have more memory there).

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[info script].log"

# @todo ts_utc als extra veld opnemen in httpsample.
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

main $argv

