# kn-migrations.tcl - diff-scripts to put keynote db's in right version

# @note just migrate from 1 version to the next; will be called repeatedly when necessary.
# @note see how this works when a new version is added; lots of double work?
proc migrate_keynotelogs {db version} {
  switch $version {
    "<none>" {
      # Correct Comment Placement
      return [migrate_kn_add_fk_indexes $db]
    }
    "add_fk_indexes" {
      return [migrate_kn_add_key_fields $db]
    }
    "add_key_fields" {
      # return [list "add_key_fields" "No change"]
      return [migrate_kn_fill_key_fields $db]
    }
    "fill_key_fields" {
      # switch option -matchvar cannot be used, works only with an RE.
      # return [list "fill_key_fields" "No change"]
      return [migrate_kn_create_view_rpi $db]
    }
    "create_view_rpi" {
      return [list "create_view_rpi" "No change"]
    }
    "new" {
      # @todo maybe slightly different, now 3 times the same: create_view_rpi
      # @todo maybe something with register_migrate_proc, which handles this, and 
      #       doesn't cause this proc to be changed 'all the time'
      #       Goal would be to just do: migrate_proc add_fk_indexes descr {body}
      #       The order of the procs would then determine the migration order.
      #       Also the final return [list .. ..] could be generated.
      return [list "create_view_rpi" "New database"]
    }
    default {
      error "Unknown db_version found: $version"
    }
  }
}

proc migrate_kn_add_fk_indexes {db} {
  log debug "Creating indexes for: [$db get_dbname]"
  $db exec2 "create index if not exists ix_page_1 on page (scriptrun_id)"
  $db exec2 "create index if not exists ix_pageitem_1 on pageitem (scriptrun_id)" -try
  $db exec2 "create index if not exists ix_pageitem_2 on pageitem (page_id)" -try
  list add_fk_indexes "Add foreign key indexes"  
}

migrate_proc add_fk_indexes "Add foreign key indexes" {
  $db exec2 "create index if not exists ix_page_1 on page (scriptrun_id)"
  $db exec2 "create index if not exists ix_pageitem_1 on pageitem (scriptrun_id)" -try
  $db exec2 "create index if not exists ix_pageitem_2 on pageitem (page_id)" -try
}


proc migrate_kn_add_key_fields {db} {
  #try should not be necessary, but is here, as fields have already been added in some DB's
  $db exec2 "alter table scriptrun add date_cet" -try
  $db exec2 "alter table page add scriptname" -try
  $db exec2 "alter table page add ts_cet" -try
  $db exec2 "alter table page add date_cet" -try
  $db exec2 "alter table pageitem add scriptname" -try
  $db exec2 "alter table pageitem add ts_cet" -try
  $db exec2 "alter table pageitem add date_cet" -try
  $db exec2 "alter table pageitem add page_seq" -try
  list add_key_fields "Add key fields: date_cet, ts_cet, scriptname, page_seq" 
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

proc migrate_kn_fill_key_fields {db} {
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
  list fill_key_fields "Fill key fields: date_cet, ts_cet, scriptname, page_seq"
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

proc migrate_kn_create_view_rpi_old {db} {
  $db exec2 "create view rpi as
              select r.*, p.*, i.*
              from scriptrun r 
                join page p on p.scriptrun_id = r.id
                join pageitem i on i.page_id = p.id" -try
  list create_view_rpi "Create view rpi"                
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

