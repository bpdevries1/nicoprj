#!/usr/bin/env tclsh

# [2016-08-06 11:31] At first a new file with coroutine implementation for reading logs.
# for now keep side-by-side with orig (working!) version.

# 2 entry points:
# * define_logreader_handlers - define parsers and handlers
# * readlogfile_new_coro $logfile [vars_to_dict db ssl split_proc]
#   - this one calls readlogfile_coro, as defined in liblogreader.tcl, not here.

package require ndv
ndv::source_once liblogreader.tcl

require libdatetime dt
require libio io

set_log_global debug {showfilename 0}

proc define_logreader_handlers {} {
  log info "define_logreader_handlers: start"
  # of toch een losse namespace waar deze dingen in hangen?
  def_parsers
  def_handlers
}

proc def_parsers {} {

  def_parser transline {
    if {[regexp {: \[([0-9 :.-]+)\] (trans=.+?)( \[[0-9/ :-]+])} $line z ts fields]} {
      set nvpairs [log2nvpairs $fields]; # possiply give whole line to log2nvpairs
      dict set nvpairs ts $ts
      dict set nvpairs sec_ts [parse_ts [:ts $nvpairs]]
      dict set nvpairs resptime [regsub -all {,} [:resptime $nvpairs] "."]
      return [dict_rename $nvpairs {trans status} {transname trans_status}]
    } else {
      return ""
    }
  }

  def_parser errorline {
    # TODO: define
    return ""
  }

  
}

# functions.c(377): [2016-07-29 16:48:22.368] trans=maker_landing, user=Silver3, resptime=-1.000, status=-1, iteration=1 [07/29/16 16:48:22]
# trans=maker_landing, user=Silver3, resptime=-1.000, status=-1, iteration=1
# return dict with key=name, val=val.
proc log2nvpairs {line} {
  set d [dict create]
  foreach nv [split $line ", "] {
    lassign [split $nv "="] nm val
    dict set d $nm $val
  }
  return $d
}

proc def_handlers {} {
  # 'inserter' handler, just for side effects, yields no new results.
  def_handler {bof transline} {} {
    # log debug "puts-handler: started"
    set db "<none>"; set split_proc "<none"; set ssl "<none>"
    set file_item "<none>"
    set item [yield]
    while 1 {
      if {[:topic $item] == "bof"} {
        dict_to_vars $item ;    # set db, split_proc, ssl
        #set db [:db $item]
        #set split_proc [:split_proc $item]
        set file_item $item
      } else {
        # log debug "transline handler item: $item, db: $db ***"
        $db insert trans_line [dict merge $file_item $item \
                                   [$split_proc [:transname $item]]]

        #bof: logfile
        #item: ts sec_ts transname user resptime trans_status
        #todo: logfile_id vuserid iteration
      }
      set item [yield];         # this one never returns anything.
    }
  }

}

proc readlogfile_new_coro {logfile db ssl split_proc} {
  # some prep with inserting record in db for logfile, also do with handler?
  if {[is_logfile_read $db $logfile]} {
    return
  }
  set vuserid [det_vuserid $logfile]
  if {$vuserid == ""} {
    log warn "Could not determine vuserid from $logfile: continue with next."
    return
  }
  set ts [clock format [file mtime $logfile] -format "%Y-%m-%d %H:%M:%S"]
  
  set dirname [file dirname $logfile]
  set filesize [file size $logfile]
  lassign [det_project_runid_script $logfile] project runid script

  $db in_trans {
    set logfile_id [$db insert logfile [vars_to_dict logfile dirname ts \
                                            filesize runid project script]]
    readlogfile_coro $logfile [vars_to_dict db ssl split_proc logfile_id vuserid]  
  }
  

  
}

