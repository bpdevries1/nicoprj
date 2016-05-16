package require tclodbc
package require ndv
package require Tclx

proc get_sla_logs {db dbuser dbpassword andir ts1 ts2 lst_writers} {
  global log ar_argv
  $log info "START get_sla_logs"
  database connect db $db $dbuser $dbpassword
  do_writers $lst_writers open_file "SLARequest"

  set query "select r.id, r.starttijd, r.stoptijd, DATEDIFF(ms, r.starttijd, r.stoptijd) elapsed, r.omschrijving, 0 subentry, sum(datediff(ms, s.starttijd, s.stoptijd)) subtime
              from SLArequest r left join SLASubRequest s on s.SLARequest = r.id
              where r.starttijd >= '$ts1' and r.starttijd <= '$ts2' 
              group by r.id, r.starttijd, r.stoptijd, DATEDIFF(ms, r.starttijd, r.stoptijd), r.omschrijving
              union
              select id, starttijd, stoptijd, DATEDIFF(ms, starttijd, stoptijd) elapsed, class+':'+method omschrijving, 1 subentry, 0 subtime from SLASubRequest
              where starttijd >= '$ts1' and starttijd <= '$ts2'
              order by starttijd"
  foreach el [db $query] {
    lassign $el id starttijd stoptijd elapsed omschrijving subentry subtime
    if {$subtime == ""} {
      set subtime 0.0 ; # if the item has no subitems, the resultset field is null.
    }
    do_writers $lst_writers write_line -dt_start $starttijd -dt_stop $stoptijd \
      -omschrijving [convert_sladb_omschrijving $omschrijving] -ms_elapsed $elapsed -ms_subtime $subtime
  }
  do_writers $lst_writers close_file
  $log info "FINISHED get_sla_logs"
}

proc convert_sladb_omschrijving {omschrijving} {
  regsub -all "," $omschrijving " " omschrijving
  regsub -nocase {^Force\.Service\.Core\.Job\.} $omschrijving "" omschrijving
  regsub -nocase {^/WebForms/Aanvraagadministratie/} $omschrijving "" omschrijving
  regsub -nocase {^Quion.Koppelingen.} $omschrijving "" omschrijving
  # FMS.Koppelingen.Rlb.Relatie.Koppeling.RlbRelatieKoppeling:GetRelatie => RlbRelatieKoppeling:GetRelatie
  if {[regexp {([^.]+:[^.:]+)$} $omschrijving z res]} {
    set omschrijving $res
  }
  return $omschrijving
}
