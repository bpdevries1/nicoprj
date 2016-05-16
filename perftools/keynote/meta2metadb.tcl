#!/usr/bin/env tclsh86

# meta2metadb.tcl - import Keynote download config.csv into slotmeta-domains.db

package require tdbc::sqlite3
package require Tclx
package require ndv
package require json

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

ndv::source_once libkeynote.tcl libslotmeta.tcl download-metadata.tcl

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL" "Directory to put downloaded keynote files"}
    {db.arg "c:/projecten/Philips/KNDL/slotmeta-domains.db" "DB to use"}
    {filename.arg "" "File with slotmetadata to read (empty if new one must be downloaded)"}
    {apikey.arg "~/.config/keynote/api-key.txt" "Location of file with Keynote API key"}
    {format.arg "json" "Format of downloaden file: json or xml"}
    {test "Test the script, just download a few hours of data"}       
  }
  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set dargv [getoptions argv $options $usage]
  meta2metadb $dargv
}

proc meta2metadb {dargv} {
  if {[:filename $dargv] == ""} {
    set filename [get_meta_data $dargv]
  } else {
    set filename [file join [:dir $dargv] [:filename $dargv]]
  }
  if {$filename == ""} {
    error "filename is empty, download went wrong"
  }
  set db [get_slotmeta_db [:db $dargv]]
  set json [json::json2dict [read_file $filename]]
  $db in_trans {
    foreach prd_el [:product $json] {
      log debug "Handle [:name $prd_el]"
      foreach slot [:slot $prd_el] {
        set npages [llength [split [:pages $slot] ","]]
        if {$npages == 0} {
          set npages 1 ; # sometimes pages field is completely empty, assume 1 page then (is correct for mobile) 
        }
        set dirname [cleanup_alias [:slot_alias $slot]]
        set slot_id [:slot_id $slot]
        set ts_update_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
        set ts_create_cet [det_ts_create_cet $db $slot_id]
        if {$ts_create_cet == ""} {
          # ok, it's a new one.
          set ts_create_cet $ts_update_cet
        } else {
          # delete old entry, and insert new entry with create_cet as before.
          $db exec2 "delete from slot_meta where slot_id = $slot_id"
        }
        set dct [dict merge $slot [vars_to_dict ts_create_cet ts_update_cet npages]]
        
        $db insert slot_meta $dct
      }
    }
  }

  update_slot_download $db
  $db close
}

proc det_ts_create_cet {db slot_id} {
  set res [$db query "select ts_create_cet from slot_meta where slot_id = $slot_id"]
  if {[llength $res] == 1} {
    return [:ts_create_cet [lindex $res 0]]
  } else {
    return ""
  }
}

# goal: all records in slot_meta have a corresponding record in slot_download, so both tables should have the same number of records.
# check this after the update.
proc update_slot_download {db} {
  $db function cleanup_alias
  # first update the existing records, fields: npages, start_date, end_date, ts_update_cet
  set ts_update_cet [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
  $db exec2 "update slot_download 
             set npages = (select m.npages from slot_meta m where m.slot_id = slot_download.slot_id),
                 start_date = (select substr(m.start_date, 1, 10) from slot_meta m where m.slot_id = slot_download.slot_id),
                 end_date = (select substr(m.end_date, 1, 10) from slot_meta m where m.slot_id = slot_download.slot_id),
                 ts_update_cet = '$ts_update_cet'
             where slot_id in (select slot_id from slot_meta)" -log
             
  # then add the new ones.
  $db exec2 "insert into slot_download (slot_id, dirname, npages, start_date, end_date, ts_create_cet, ts_update_cet)
             select m.slot_id, cleanup_alias(m.slot_alias), m.npages, substr(m.start_date, 1, 10), substr(m.end_date, 1, 10),
                    m.ts_update_cet, m.ts_update_cet
             from slot_meta m
             where not m.slot_id in (select slot_id from slot_download)"
             
  # then check the counts
  set count_slot_meta [count_records $db slot_meta]
  set count_slot_download [count_records $db slot_download]
  if {$count_slot_meta == $count_slot_download} {
    log info "Ok, both tables have $count_slot_meta records"
  } else {
    log warn "slot_meta has $count_slot_meta records, slot_download has $count_slot_download records, should be the same number."
  }
  # even if counts are the same, there could still be differences.
  set res [$db query "select * from slot_download where slot_id not in (select slot_id from slot_meta)"]
  if {[llength $res] > 0} {
    log warn "Items in slot_download not in slot_meta:"
    foreach el $res {
      log warn "[:slot_id $el]: [:dirname $el]"
    }
  }
  set res [$db query "select * from slot_meta where slot_id not in (select slot_id from slot_download)"]
  if {[llength $res] > 0} {
    log warn "Items in slot_meta not in slot_download:"
    foreach el $res {
      log warn "[:slot_id $el]: [:slot_alias $el]"
    }
  }
  set res [$db query "select * from slot_download where download_pc is null"]
  if {[llength $res] > 0} {
    log warn "Items in slot_download where download_pc is empty:"
    foreach el $res {
      log warn "[:slot_id $el]: [:dirname $el]"
    }
  }
  
}

proc cleanup_alias {alias} {
  foreach re {{\(TxP\)} {\(MWP\)} {\(ApP\)} {\[IE\]}} {
    regsub $re $alias "" alias 
  }
  regsub {MBF} $alias "Mobile" alias
  regsub {\(([^\(\)]+)\)} $alias {-\1} alias
  regsub -all -- { } $alias "-" alias
  regsub -all -- {_} $alias "-" alias
  while {[regsub -all -- {--} $alias "-" alias]} {}
  regsub -- {-$} $alias "" alias
  regsub -- {^-} $alias "" alias
  return [string trim $alias]
}

proc count_records {db table} {
  set res [$db query "select count(*) number from $table"]
  if {[llength $res] == 1} {
    return [:number [lindex $res 0]]
  } else {
    error "Error while counting number of records in $table"
  }
}

main $argv

