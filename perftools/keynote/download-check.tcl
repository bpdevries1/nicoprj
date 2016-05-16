# download-check.tcl - manage database of downloaded Keynote API data files.

package require TclOO 
package require ndv

oo::class create DownloadCheck {
  
  constructor {a_root_dir} {
    my variable root_dir
    set root_dir $a_root_dir
    my open_db
  }
  
  method open_db {} {
    my variable root_dir db
    set db_name [file join $root_dir "check-dl.db"]
    set existing_db [file exists $db_name]
    set db [dbwrapper new $db_name]
    $db add_tabledef filestatus {id} {path filename status ts_utc ts_cet}
    if {!$existing_db} {
      $db create_tables
      $db exec2 "create index if not exists ix_filestatus on filestatus (filename)" -log
    }
    $db prepare_insert_statements
    $db prepare_stmt sel_status "select status from filestatus where filename = :filename and status = 'ok'"
  }
  
  # trans_start/commit for bulk fill.
  method trans_start {} {
    my variable db
    $db exec "begin transaction"
  }
  
  method trans_commit {} {
    my variable db
    $db exec "commit"
  }
  
  method read? {filename} {
    my variable db
    if {[llength [$db exec_stmt sel_status [dict create filename [file tail $filename]]]] > 0} {
      return 1
    } else {
      return 0 
    }
    # [2013-10-06 13:54:59] for now, also check orig locations.
    set filename_read [file join [file dirname $filename] read [file tail $filename]] 
    if {[file exists $filename]} {
      # log info "Already have $filename, continuing" ; # or stopping?
      return 1
    }
    # 15-9-2013 Filename can also exist in the 'read' subdirectory.
    if {[file exists $filename_read]} {
      return 1
    }
  }
  
  method set_read {filename status} {
    my variable db
    # path filename status ts_utc ts_cet
    set tail [file tail $filename]
    # 7-1-2014 try to delete item with same filename. Could be old.
    # usecase: file is downloaded ok, but when reading it, something wrong is found and file is deleted (or moved to error-dir) so it can be downloaded again.
    $db exec2 "delete from filestatus where filename='$tail'"
    set sec [clock seconds]
    set dct [dict create path $filename filename [file tail $filename] \
      status $status ts_utc [clock format $sec -format "%Y-%m-%d %H:%M:%S" -gmt 1] \
      ts_cet [clock format $sec -format "%Y-%m-%d %H:%M:%S" -gmt 0]]
    $db insert filestatus $dct      
  }
  
  # close db connection
  method close {} {
    my variable db
    $db close
  }
  
}

