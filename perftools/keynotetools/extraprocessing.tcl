#!/usr/bin/env tclsh86

# extraprocessing.tcl
# goal: post processing for selected databases.
# for now update_maxitem

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

# libpostproclogs: set_task_succeed (and maybe others)
set script_dir [file dirname [info script]]
#source [file join $script_dir libpostproclogs.tcl]
#source [file join $script_dir libmigrations.tcl]
#source [file join $script_dir kn-migrations.tcl]
#source [file join $script_dir checkrun-handler.tcl]
#source [file join $script_dir dailystats.tcl]
source [file join $script_dir libdaily.tcl]

proc main {argv} {
  global dargv
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL" "Directory where downloaded keynote files are (in subdirs) and where DB's (in subdirs) will be created."}
    {justdir "Just read this directory, not subdirectories. If this is set, dir should not contain subdirs besides 'read'"}
    {updatemaxitem "Update maxitem table (daily)"}
    {actions.arg "all" "List of actions to do (comma separated)"}
    {maxitem.arg "20" "Number of maxitems to determine"}
    {pattern.arg "*" "Just handle subdirs that have pattern"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  set res [extraproc_main $dargv]
  log info "Extraproc main finished with return code: $res"
}

proc extraproc_main {dargv} {
  global cr_handler
  set root_dir [from_cygwin [:dir $dargv]]  
  set res "Ok"
  foreach subdir [lsort [glob -nocomplain -directory $root_dir -type d [:pattern $dargv]]] {
    if {[ignore_subdir $subdir]} {
      log info "Ignore subdir: $subdir (for test!)"
    } else {
      set res [extraproc_subdir $dargv $subdir]
    }
  }
  return $res
}

proc ignore_subdir {subdir} {
  return 0 ; # in production don't ignore anything!
  if {[regexp -nocase {Mobile-landing} $subdir]} {
    return 1 
  }
  if {[regexp -nocase {MyPhilips} $subdir]} {
    return 1 
  }
  return 0
}

proc extraproc_subdir {dargv subdir} {
  global cr_handler min_date
  log info "Handle subdir: $subdir"
  set db_name [file join $subdir "keynotelogs.db"]
  set existing_db [file exists $db_name]
  if {!$existing_db} {
    log warn "No database in $subdir, returning"
    return "nodb"
  }
  
  set db [dbwrapper new $db_name]
  define_tables $db
  $db prepare_insert_statements
  
  if {[:actions $dargv] == "all"} {
    set actions [list maxitem gt3] 
  } else {
    set actions [split [:actions $dargv] ","] 
  }
  foreach action $actions {
    # graph_$action $r $dir
    check_do_daily $db $action {
      # update_maxitem $db [:maxitem $dargv]
      extra_update_$action $db $dargv $subdir
    }
    
  }  
  
  if {0} {
    # update_maxitem $db [:maxitem $dargv]
    if {[:updatemaxitem $dargv]} {
      check_do_daily $db "maxitem" {
        update_maxitem $db [:maxitem $dargv]
      }
    }
  }
  $db close
  log info "Created/updated db $db_name, size is now [file size $db_name]"
  return "ok"
}

# @todo volgens nieuwe spec: daily update, maxitems per dag.
proc extra_update_maxitem {db dargv subdir} {
  log info "Recreate maxitem table"
  set max_urls [:maxitem $dargv]
  $db exec2 "drop table if exists maxitem" -log
  
  $db exec2 "CREATE TABLE maxitem (id integer primary key autoincrement, 
                  url, page_seq int, loadtime real)" -log

  set last_week [det_last_week $db]
  log info "Determined last week as: $last_week (possibly old database)"
  log info "Max_urls to determine: $max_urls"
  $db exec2 "insert into maxitem (url, page_seq, loadtime)
            select i.urlnoparams, i.page_seq, avg(0.001*i.element_delta) loadtime
            from pageitem i
            where i.status_code between '200' and '399'
            and i.ts_cet > '$last_week'
            group by 1,2
            order by 3 desc
            limit $max_urls" -log
  log info "Dropped, created and filled maxitem"        
}

# @todo als base-table (pageitem) verandert, moet deze mee veranderen.
# of moet materialised view worden. => even gekeken, maar is er niet [2013-10-31 17:38:09]
proc extra_update_gt3 {db dargv subdir} {
  # zelfde structuur vullen (daily) als bij daily aggr tabellen.
  
}

# @todo dailystatus table also defined in kn-migrations.tcl
proc define_tables {db} {
  $db add_tabledef dailystatus {} {actiontype dateuntil_cet}
  $db add_tabledef dailystatuslog {} {ts_start_cet ts_end_cet datefrom_cet dateuntil_cet notes}
}

# @pre we have a new day, and added some daily stats.
# @pre updatemaxitem cmdline param is given.
proc update_maxitem_old {db max_urls} {
  log info "Recreate maxitem table"
  $db exec2 "drop table if exists maxitem" -log
  
  $db exec2 "CREATE TABLE maxitem (id integer primary key autoincrement, 
                  url, page_seq int, loadtime real)" -log

  set last_week [det_last_week $db]
  log info "Determined last week as: $last_week (possibly old database)"
  log info "Max_urls to determine: $max_urls"
  if {0} {
    $db exec2 "insert into maxitem (url, page_seq, loadtime)
              select i.urlnoparams, p.page_seq, avg(0.001*i.element_delta) loadtime
              from scriptrun r, page p, pageitem i
              where p.scriptrun_id = r.id
              and i.page_id = p.id
              and 1*r.task_succeed_calc = 1
              and r.ts_cet > '$last_week'
              group by 1,2
              order by 3 desc
              limit $max_urls" -log
  }            
  $db exec2 "insert into maxitem (url, page_seq, loadtime)
            select i.urlnoparams, i.page_seq, avg(0.001*i.element_delta) loadtime
            from pageitem i
            where i.status_code between '200' and '399'
            and i.ts_cet > '$last_week'
            group by 1,2
            order by 3 desc
            limit $max_urls" -log
  log info "Dropped, created and filled maxitem"        
  
}

# want to calc top 20 items from last week data. But use last moment of measurements in the DB, not current time.
proc det_last_week {db} {
  set res [$db query "select date(max(r.ts_cet), '-7 days') lastweek from scriptrun r"]
  :lastweek [lindex $res 0]
}

main $argv

