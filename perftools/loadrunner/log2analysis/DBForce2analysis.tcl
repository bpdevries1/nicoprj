package require tclodbc
package require ndv
package require Tclx

proc get_force_workflow_logs {db dbuser dbpassword andir ts1 ts2 lst_writers} {
  global log ar_argv
  $log info "START get_force_workflow_logs"
  database connect db $db $dbuser $dbpassword

  do_writers $lst_writers open_file "WorkflowStatus"
  
  # NdV 15-9-2010 beide status change dates tussen opgegeven data, anders mogelijk grote outliers.
  # NdV 28-10-2010 op id checken voor volgorde status overgangen. statuschangeddate niet te gebruiken, want op seconde niveau en er kunnen meerdere
  # status overgangen in dezelfde seconde zijn.
  # NdV 28-10-2010 not exists check toegevoegd net zoals bij workflowdef ivm jojo-ende statusovergangen tussen "Wacht op acceptatie klant  (10000055)" en "Offerte termijn bijna verstreken (10000146)"
  set query "select c1.statuschangeddate starttijd, c2.statuschangeddate stoptijd, 
  DATEDIFF(ms, c1.statuschangeddate, c2.statuschangeddate) elapsed, 
  d1.name + ' (' + cast(d1.id as varchar) + ') -> ' + d2.name + ' (' + cast(d2.id as varchar) + ')'
from workflowstatuschange c1, workflowstatuschange c2, workflowstatusdefinition d1, workflowstatusdefinition d2
where c1.streamingobject = c2.streamingobject
and c2.fromstatus = d1.id
and c2.tostatus = d2.id
and c1.tostatus = d1.id
and c1.statuschangeddate between '$ts1' and '$ts2'
and c2.statuschangeddate between '$ts1' and '$ts2'
and c1.id < c2.id
and not exists (
    select 1
    from workflowstatuschange c3
    where c3.streamingobject = c1.streamingobject
    and c3.id > c1.id
    and c3.id < c2.id
)
order by c1.statuschangeddate"

  foreach el [db $query] {
    lassign $el starttijd stoptijd elapsed omschrijving
    do_writers $lst_writers write_line -dt_start $starttijd -dt_stop $stoptijd \
      -omschrijving [convert_workflow_omschrijving $omschrijving] -ms_elapsed $elapsed -ms_subtime 0.0 
  }
  do_writers $lst_writers close_file  
  $log info "FINISHED get_force_workflow_logs"
}

proc convert_workflow_omschrijving {omschrijving} {
  regsub -all "," $omschrijving " " omschrijving
  return $omschrijving
}
