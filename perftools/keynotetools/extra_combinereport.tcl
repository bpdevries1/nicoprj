# extra-combinereport.tcl - called by libextraprocessing.tcl (remove pageitem records older than 6 weeks)

ndv::source_once ../dailyscripts/libcombinereport.tcl 

# @todo make working on Linux
# @todo find out bash location dynamically.

proc extra_update_combinereport {db dargv subdir} {
  set scriptname [file tail $subdir]
  check_do_daily_allinone $db "combinereport" {} {
    # datefrom_cet and dateuntil_cet are available.
    # only need dateuntil_cet here, to make/check combined reports.
    set dbcr [get_combine_report_db [dict create srcdir [file dirname $subdir] db "combinereport.db"]]
    set def_list [det_def_list $dbcr $subdir]
    foreach cdef_row $def_list {
      copy_to_target_db $db $scriptname [:targetdir $cdef_row] $datefrom_cet $dateuntil_cet
      set cdef_id [:combinedef_id $cdef_row]
      set cdate_id [det_combinedate_id $dbcr $cdef_id $dateuntil_cet]
      $dbcr insert combinedatedir [dict create combinedefdir_id [det_combinedefdir_id $dbcr $cdef_id $subdir] \
        combinedate_id $cdate_id date_cet $dateuntil_cet dir $subdir status "dir-pre-combine" ts_ready_cet [det_now]]
      set ncurrent [det_ncurrent $dbcr $cdate_id]
      if {$ncurrent >= [:ndirs $cdef_row]} {
        do_combined_report $dbcr $cdef_row $dateuntil_cet $cdate_id
      } else {
        log info "Not complete yet ($ncurrent < [:ndirs $cdef_row]), so wait until next one."
      }
    }
    $dbcr close
    identity "combinereport - $dateuntil_cet"
  }
}

proc det_def_list {db subdir} {
  $db query "select cdd.combinedef_id combinedef_id, cd.ndirs ndirs, cd.cmds cmds, cd.targetdir targetdir
             from combinedefdir cdd
             join combinedef cd on cd.id = cdd.combinedef_id
             where cdd.dir = '$subdir' and cd.active=1"
}

proc det_combinedate_id {db cdef_id date_cet} {
  set res [$db query "select id from combinedate where combinedef_id = $cdef_id and date_cet = '$date_cet'"]
  if {[llength $res] >= 1} {
    return [:id [lindex $res 0]]
  } else {
    set id [$db insert combinedate [dict create combinedef_id $cdef_id date_cet $date_cet status "pre-combine"] 1]
    return $id
  }
}

proc det_combinedefdir_id {db cdef_id subdir} {
  :id [lindex [$db query "select id from combinedefdir where combinedef_id = $cdef_id and dir='$subdir'"] 0]
}

proc det_now {} {
  clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"
}

proc det_ncurrent {db cdate_id} {
  :ncurrent [lindex [$db query "select count(*) ncurrent from combinedatedir where combinedate_id = $cdate_id"] 0]
}

proc do_combined_report {db cdef_row dateuntil_cet cdate_id} {
  set ts_start_cet [det_now]
  set cmds [:cmds $cdef_row]
  #foreach cmd [split $cmds "\n"] {
  #  exec_cmd $cmd
  #}
  exec_cmd $cmds
  set ts_end_cet [det_now]
  $db exec2 "update combinedate set status = 'done', ts_start_cet = '$ts_start_cet', ts_end_cet = '$ts_end_cet'
             where id = $cdate_id"
  $db exec2 "update combinedatedir set status = 'done'
             where combinedate_id = $cdate_id"
}

# @param cmd possibly multiline command, assume Tcl for now, or single line bash script call.
proc exec_cmd {cmd} {
  log info "Executing cmd: $cmd"
  if {[bash? $cmd]} {
    log info "Executing: c:/util/cygwin/bin/bash.exe {*}$cmd"
    try_eval {
      exec -ignorestderr c:/util/cygwin/bin/bash.exe {*}$cmd
    } {
      log_error "Something failed during exec"
    }
    log info "Exec finished"
  } else {
    # log warn "Don't know how to exec: $cmd"
    log info "No bash, assume Tcl commands"
    try_eval {
      # breakpoint
      uplevel $cmd
    } {
      log_error "Something failed during Tcl eval"
    }
    # breakpoint
    log info "Tcl eval finished"
  }
  log info "Executed cmd."
}

proc bash? {cmd} {
  set f [lindex [split $cmd " "] 0]
  if {[regexp {\.sh$} $f]} {
    return 1
  } else {
    return 0
  }
}

# @todo create target tables if not exists.
proc copy_to_target_db {db scriptname targetdir datefrom_cet dateuntil_cet} {
  file mkdir [file join $targetdir daily]
  set targetdbname [file join $targetdir daily daily.db]
  log info "Copying aggregate data to targetDB: $targetdbname"
  $db exec2 "attach database '$targetdbname' as toDB"
  foreach table {aggr_run aggr_page aggr_slowitem aggr_sub pageitem_gt3 pageitem_topic domain_ip_time aggr_specific} {
    set new_table 0
    try_eval {
      # @note hier geen -try bijzetten, want wil exceptie als het fout gaat.
      $db exec2 "delete from toDB.$table where date_cet between '$datefrom_cet' and '$dateuntil_cet' and _scriptname = '$scriptname'" -log
    } {
      # if this one fails, this could mean that the target table does not exist yet, so create it.
      set new_table 1
    }
    if {$new_table} {
      $db exec2 "create table toDB.$table as 
                 select '$scriptname' _scriptname, * from main.$table
                 where date_cet between '$datefrom_cet' and '$dateuntil_cet'" -log -try
    } else {
      $db exec2 "insert into toDB.$table 
                 select '$scriptname' _scriptname, * from main.$table
                 where date_cet between '$datefrom_cet' and '$dateuntil_cet'" -log -try
    }
  }
  $db exec2 "detach toDB"
}

