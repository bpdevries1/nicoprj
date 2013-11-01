#!/usr/bin/env tclsh86

# longterm2db.tcl

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

# set script_dir [file dirname [info script]]

proc main {argv} {
  global dargv
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL-longterm" "Directory where downloaded keynote files are (in subdirs) and where DB's (in subdirs) will be created."}
    {moveread "Move read files to subdirectory 'read'"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  set res [longterm2db_main $dargv]
}

proc longterm2db_main {dargv} {
  set root_dir [from_cygwin [:dir $dargv]]  

  set db [open_db $root_dir $dargv]
  # @todo Shop even voor test >1 page.
  foreach subdir [lsort [glob -nocomplain -directory $root_dir -type d *]] {
    set res [longterm2db_subdir $dargv $subdir $db]
    # break ; # for test.
  }
  $db close
  return $res
}

proc open_db {root_dir dargv} {
  set db_name [file join $root_dir db "longterm.db"]
  set existing_db [file exists $db_name]
  file mkdir [file join $root_dir db]
  set db [dbwrapper new $db_name]
  define_tables $db
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    $db create_tables 0 ; # 0: don't drop tables first.
    create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  return $db
}

proc longterm2db_subdir {dargv subdir db} {
  handle_files $subdir $db
  return "ok"
}

proc define_tables {db} {
  $db add_tabledef logfile {id} {path filename filesize}
  # @note geen datatype opgeven, zou automatisch goed moeten gaan, wel testen nog.
  # @note gaat dus niet goed, dus nogmaals met datatype opgeven.
  $db add_tabledef scriptrun {id} {logfile_id slot_id scriptname date {avail real} \
    {total_time_sec real} {npages int} {page_time_sec real} {datacount int}}
  $db add_tabledef page {id} {logfile_id slot_id scriptname {page_seq int} date {avail real} \
    {total_time_sec real}  {datacount int}}
}

proc create_indexes {db} {
  $db exec2 "create unique index if not exists ix_logfile_1 on logfile(filename)"
  $db exec2 "create unique index if not exists ix_scriptrun_1 on scriptrun(scriptname,date)"
  $db exec2 "create unique index if not exists ix_page_1 on page (scriptname, date, page_seq)"
}

# handle each file in a DB trans, not a huge trans for all files.
proc handle_files {subdir db} {
  # log info "Start reading: $subdir"
  # @note don't want recursive, just all directly below subdir
  foreach filename [glob -nocomplain -directory $subdir "*.json"] {
    warn_error read_json_file $db $filename 
  }
  # log info "Finished reading"
}

proc read_json_file {db filename} {
  if {[is_read $db $filename]} {
    # log info "Already read, ignoring: $filename"
    return
  }  
  read_json_file_db $db $filename
  move_read $filename
}

proc move_read {filename} {
  global dargv 
  if {[:moveread $dargv]} {
    set to_file [file join [file dirname $filename] read [file tail $filename]]
    log info "Move $filename => $to_file"
    file mkdir [file dirname $to_file]
    if {[file exists $to_file]} {
      log warn "Target file already exists, should not happen (anymore), deleting duplicate"
      file delete $filename
    } else {
      file rename $filename $to_file
    }
  }
}

proc read_json_file_db {db filename} {
  log info "Reading $filename"
  $db in_trans {    
    set logfile_id [$db insert logfile [dict create path $filename filename [file tail $filename] filesize [file size $filename]] 1]
    set scriptname [det_scriptname $filename]
    set text [read_file $filename]
    if {[regexp {Bad Request} $text]} {
      log warn "Bad Request in result json, continue"
    } elseif {[string length $text] < 500} {
      log warn "Json file too small, continue"
    } else {
      set json [json::json2dict $text]

      # @todo eerst alleen pages inlezen, dan komt scriptrun hierna wel.
      set page_seq 0
      foreach page [:measurement $json] {
        incr page_seq
        set slot_id [:id $page]
        foreach date_data [:bucket_data $page] {
          set str_date [:name $date_data]
          set date [clock format [clock scan $str_date -format "%Y-%b-%d"] -format "%Y-%m-%d"]
          set total_time_sec [:value [:perf_data $date_data]]
          set avail [:value [:avail_data $date_data]]
          set datacount [:value [:data_count $date_data]] 
          set dct [vars_to_dict logfile_id slot_id scriptname page_seq date \
                                avail total_time_sec datacount]
          if {$avail != ""} {                                
            $db insert page $dct
            set ar_dates($date) $date
            set ar_npages($date) $page_seq
            if {$page_seq == 1} {
              set ar_total_time_sec($date) $total_time_sec
              set ar_datacount($date) $datacount ; # deze hoeft bij volgende niet meer te worden.
              set ar_avail($date) $avail ; # kan voor latere pagina's weer 100% worden: dan aantal kleiner, maar wel weer 100%
            } else {
              set ar_total_time_sec($date) [expr $total_time_sec + $ar_total_time_sec($date)]
              if {$avail < $ar_avail($date)} {
                set ar_avail($date) $avail
              }
            }
          }
        }
      }
      # @todo checken dat avail bij latere pagina's altijd lager of gelijk is aan availability van eerdere pagina.
      # @note alle pages gehad, nu op scriptrun niveau inserten
      foreach date [array names ar_dates] {
        set avail $ar_avail($date)
        set total_time_sec [format %.3f $ar_total_time_sec($date)]
        set npages $ar_npages($date)
        set datacount $ar_datacount($date)
        set page_time_sec [format %.3f [expr $total_time_sec / $npages]] 
        set dct [vars_to_dict logfile_id slot_id scriptname date \
                              avail total_time_sec npages page_time_sec datacount]
        $db insert scriptrun $dct
      }
    }
  }
}

proc is_read {db filename} {
  if {[llength [db_query [$db get_conn] "select id from logfile where filename='[file tail $filename]'"]] > 0} {
    return 1 
  } else {
    return 0 
  }
}

# @todo deze waarsch nog aanpassen, of niet gebruiken.
proc is_read_scriptrun {db run_main} {
  if {[llength [db_query [$db get_conn] "select id from scriptrun where slot_id = '[:slot_id $run_main]' and datetime = '[:datetime $run_main]'"]] > 0} {
    return 1 
  } else {
    return 0 
  }
}

proc det_scriptname {filename} {
  file tail [file dirname $filename]  
}

####################################################################################

# library functions
proc warn_error {proc_name args} {
  global dargv
  try_eval {
    $proc_name {*}$args
  } {
    # log warn "$errorResult $errorCode $errorInfo, continuing"
    log_error "continuing..."
    if {[:debug $dargv]} {
      # development mode.
      error $errorResult $errorCode $errorInfo
      breakpoint
      exit
    } else {
      # production, vooral-doorgaan mode 
    }
  }  
}

# return a new dictionary with keys/values as in keys. In dct they may be nested, but not in a list.
# @todo don't use these functions, use the merge solution in 'new/myphilips' way of reading.
proc dict_flat {dct keys} {
  foreach key $keys {
    dict set res $key [dict_find_key $dct $key]
  }
  return $res
}

# find key and return value, key could be nested. If not found, return "<none>"
proc dict_find_key {dct key} {
  if {![is_dict $dct]} {
    return "<none>" 
  }
  set res [dict_get $dct $key "<none>"]
  if {$res != "<none>"} {
    return $res 
  } else {
    dict for {k v} $dct {
      set res [dict_find_key $v $key] 
      if {$res != "<none>"} {
        return $res 
      }
    }
    return "<none>"
  }
}

# return 1 if dct is really a dict(ionary)
proc is_dict {dct} {
  if {[string is list $dct]} {    # Only [string is] where -strict has no effect
    if {[expr [llength $dct]&1] == 0} {
      return 1
    }
  }
  return 0
}

main $argv

