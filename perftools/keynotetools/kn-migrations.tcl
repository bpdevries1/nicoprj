# kn-migrations.tcl - diff-scripts to put keynote db's in right version

migrate_proc add_fk_indexes "Add foreign key indexes" {
  $db exec2 "create index if not exists ix_page_1 on page (scriptrun_id)"
  $db exec2 "create index if not exists ix_pageitem_1 on pageitem (scriptrun_id)" -try
  $db exec2 "create index if not exists ix_pageitem_2 on pageitem (page_id)" -try
}

migrate_proc add_key_fields "Add key fields: date_cet, ts_cet, scriptname, page_seq" {
  #try should not be necessary, but is here, as fields have already been added in some DB's
  $db exec2 "alter table scriptrun add date_cet" -try
  $db exec2 "alter table page add scriptname" -try
  $db exec2 "alter table page add ts_cet" -try
  $db exec2 "alter table page add date_cet" -try
  $db exec2 "alter table pageitem add scriptname" -try
  $db exec2 "alter table pageitem add ts_cet" -try
  $db exec2 "alter table pageitem add date_cet" -try
  $db exec2 "alter table pageitem add page_seq" -try
}

migrate_proc fill_key_fields "Fill key fields: date_cet, ts_cet, scriptname, page_seq" {
  $db exec2 "update scriptrun set date_cet = strftime('%Y-%m-%d', ts_cet) where date_cet is null" -log
  $db exec2 "update page
              set scriptname = (select r.scriptname from scriptrun r where r.id = page.scriptrun_id),
                  ts_cet = (select r.ts_cet from scriptrun r where r.id = page.scriptrun_id),
                  date_cet = (select r.date_cet from scriptrun r where r.id = page.scriptrun_id)
              where page.scriptname is null" -log
  # pageitem might not exist (maindb)
  $db exec2 "update pageitem
              set scriptname = (select p.scriptname from page p where p.id = pageitem.page_id),
                  ts_cet = (select p.ts_cet from page p where p.id = pageitem.page_id),
                  date_cet = (select p.date_cet from page p where p.id = pageitem.page_id),
                  page_seq = (select p.page_seq from page p where p.id = pageitem.page_id)
              where pageitem.scriptname is null" -try
}

# @note need migrate_kn_create_view_rpi as well as migrate_proc, as first is also called directly for a new DB.
proc migrate_kn_create_view_rpi {db} {
  $db exec2 "create view rpi as
             select r.*, p.*, i.*
             from scriptrun r 
             join page p on p.scriptrun_id = r.id
             join pageitem i on i.page_id = p.id" -try
}

migrate_proc create_view_rpi "Create view rpi" {
  migrate_kn_create_view_rpi $db
}

# copy table script_pages from orig location
# @note maybe only copy rows that are for this script. But would need a way to pass params then.
#       or in this case use $db get_dbname and look at the path.
proc copy_script_pages {db} {
  set src_name "c:/projecten/Philips/script-pages/script-pages.db"
  if {![file exists $src_name]} {
    error "Src db for script_pages does not exist" 
  }
  $db exec "attach database '$src_name' as fromDB"
  set table "script_pages"
  # @note use main.$table, otherwise source might be dropped.
  $db exec "drop table if exists main.$table"
  $db exec_try "create table if not exists $table as select * from fromDB.$table"
  $db exec "detach fromDB"
}

# @note if orig table script_pages changes, just move this def as the latest to do the
# migration again.
migrate_proc copy_script_pages "copy table script_pages" {
  copy_script_pages $db
}

migrate_proc add_fill_page_type "Add and fill page type for page and item" {
  $db exec2 "alter table page add page_type" -try
  $db exec2 "alter table pageitem add page_type" -try
  set res [$db query "select sp.page_type from script_pages sp join page p on p.scriptname = sp.scriptname limit 1"]
  if {[llength $res] > 0} {
    log debug "Found scriptname in script_pages: fill page_type"
    # integer-fields remain difficult, need 1* again here.
    foreach table {page pageitem} {
      $db exec2 "update $table
                set page_type = (
                  select sp.page_type
                  from script_pages sp
                  where sp.scriptname = $table.scriptname
                  and 1*sp.page_seq = 1*$table.page_seq
                )
                where $table.page_type is null" -log
    }
  } else {
    log debug "Did not find scriptname in script_pages: skip filling page_type" 
  }
}

# @note task_succeed is an existing field.
# @todo still big in determining succeed for new items, so not this one for now.
migrate_proc add_fill_task_succeed "Fill task_succeed field" {
  $db exec2 "alter table scriptrun add task_succeed_calc integer" -log -try
  set_task_succeed_calc $db
}

migrate_proc add_fill_topdomain "Add and fill topdomain field" {
  $db exec2 "alter table pageitem add topdomain" -log -try
  add_topdomain $db 0 0 ; # don't clean first, new field. Also don't check first.
}

migrate_proc add_fill_urlnoparams "Add and fill urlnoparams field" {
  $db exec2 "alter table pageitem add urlnoparams" -log -try
  fill_urlnoparams $db
}
