# puts "before proc do_checks"

proc do_checks {db} {
  log info "DB/Log technical consistency check:"

  do_checks_event $db
  do_checks_odbccall $db
  do_checks_odbcquery $db
  
  do_checks_functional $db
}

proc do_checks_event {db} {
  
  # check if EXIT always follows ENTER  
  check_query $db "select count(*)
from event e1 join event e2 on e1.seqnr + 1 = e2.seqnr
where e1.enterexit = 'ENTER'
and e2.enterexit <> 'EXIT'"

  # ENTER/EXIT belong to same HDBC
  # bij SQLAllocConnect is HDBC pas bij EXIT gevuld.
  check_query $db "select count(*)
from event e1 join event e2 on e1.seqnr + 1 = e2.seqnr
where e1.enterexit = 'ENTER'
and e2.enterexit = 'EXIT'
and e1.callname != 'SQLAllocConnect'
and e1.HDBC <> e2.HDBC"

  # ENTER/EXIT belong to same call, have same callname
  check_query $db "select count(*)
from event e1 join event e2 on e1.seqnr + 1 = e2.seqnr
where e1.enterexit = 'ENTER'
and e2.enterexit = 'EXIT'
and e1.HDBC = e2.HDBC
and e1.callname != e2.callname"

  # if HDBC is filled, HENV should be filled as well
  check_query $db "select count(*) from event where HDBC <> '' and HENV = ''" "HENV should be filled if HDBC is filled"
}

proc do_checks_odbccall {db} {
  
  # check that all events belong to a odbccall
  check_query $db "select count(*) from event where enterexit = 'ENTER'
                   and not seqnr in (select seqnr_enter from odbccall)" "ENTER event should belong to odbccall"
  check_query $db "select count(*) from event where enterexit = 'EXIT'
                   and not seqnr in (select seqnr_exit from odbccall)" "EXIT event should belong to odbccall"

  # check that all alloc/free statements belong to an odbcquery
  # but only 'correct' alloc/free statements, which are (still) coupled to a HENV/HDBC
  check_query $db "select count(*) from odbccall where callname = 'SQLAllocStmt'
                   and HSTMT != '' and HDBC != '' and HENV != ''
                   and not seqnr_enter in (select seqnr_start from odbcquery)" "Alloc should belong to odbcquery"
  check_query $db "select count(*) from odbccall where callname = 'SQLFreeStmt'
                   and HSTMT != '' and HDBC != '' and HENV != ''
                   and not seqnr_exit in (select seqnr_end from odbcquery)" "Free should belong to odbcquery"

  check_query $db "select count(*) from odbccall where HSTMT != '' and HDBC != ''
                   and odbcquery_id is null" "call with HSTMT not belonging to query"
}

# puts "before proc do_checks_odbcquery"

proc do_checks_odbcquery {db} {

  check_query $db "select count(*) from odbcquery where query is null or query=''" "ODBC query without SQL-query-field"

  # check if queries overlap in time/seqnr
  if {0} {
    check_query $db "select count(*) from odbcquery q1, odbcquery q2
                   where q2.seqnr_start between q1.seqnr_start and q1.seqnr_end" "Overlap in queries (start)"
    check_query $db "select count(*) from odbcquery q1, odbcquery q2
                   where q2.seqnr_end between q1.seqnr_start and q1.seqnr_end" "Overlap in queries (end)"
    
  }

  # 19-8-2015 NdV now only check odbcquery_do
  check_query $db "select count(*) from odbcquery_do q1, odbcquery_do q2
                   where q2.seqnr_start between q1.seqnr_start + 1 and q1.seqnr_end - 1" "Overlap in queries_do (start)"
  check_query $db "select count(*) from odbcquery_do q1, odbcquery_do q2
                   where q2.seqnr_end between q1.seqnr_start + 1 and q1.seqnr_end - 1" "Overlap in queries_do (end)"

  # queries belonging to more than 1 user action?
  check_query $db "select count(*) from odbcquery_do where start_useraction_id != end_useraction_id" "queries_do belonging to >1 useraction"
  check_query $db "select count(*) from odbcquery_do where start_useraction_id is null or end_useraction_id is null" "queries_do with null useraction field(s)"
  
  # query which does not look like valid SQL, eg just 'WHERE 0 = 1\ 0'
  
  # servertime bigger than elapsed time?
  check_query $db "select count(*) from odbcquery where query_servertime > query_elapsed" "Servertime > Elapsed"
}

proc do_checks_functional {db} {

  log info "===================="
  log info "DB/Log functional consistency check:"
  # if HSTMT is filled, HDBC should be filled as well
  # 18-8-2015 NdV this is not always the case, but is not an error in this script, but could/should report on this.
  check_query $db "select count(*) from event where HSTMT <> '' and HDBC = ''" "HSTMT without HDBC"
  
}

proc check_query {db query {msg ""}} {
  # log debug "check_query: $query"
  set res [$db query $query]
  if {[llength $res] == 0} {
    log info "check_query: ok"
  } else {
    if {[llength $res] == 1} {
      if {[dict get [:0 $res] "count(*)"] == 0} {
        log debug "check_query: ok, count==0"
      } else {
        if {$msg != ""} {
          log warn $msg
        } else {
          log warn $query  
        }
        log warn $res
      }
    } else {
      log warn $query
      log warn $res
    }
  }
}
