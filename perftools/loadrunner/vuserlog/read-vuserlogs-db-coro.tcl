#!/usr/bin/env tclsh

# TODO: [2016-08-18 13:15:36] version for vugen, integrate with version for AHK.

# [2016-08-06 11:31] At first a new file with coroutine implementation for reading logs.
# for now keep side-by-side with orig (working!) version.

# 2 entry points:
# * define_logreader_handlers - define parsers and handlers
# * readlogfile_new_coro $logfile [vars_to_dict db ssl split_proc]
#   - this one calls readlogfile_coro, as defined in liblogreader.tcl, not here.

package require ndv
# ndv::source_once liblogreader.tcl

set perftools_dir [file normalize [file join [file dirname [info script]] .. ..]]

# TODO: use source_once with absolute path?
source [file join $perftools_dir logdb liblogreader.tcl]
source [file join $perftools_dir logdb librunlogreader.tcl]


require libdatetime dt
require libio io
use libmacro;                   # syntax_quote

# [2016-08-07 13:29] deze zorgt er nu voor dat global (zoals de naam zegt) overal loglevel
# op debug komt, wil je in het algemeen niet. 2 opties:
# * de set_log_global doet alleen wat als de log nog niet gezet is.
# * iets met namespaces, log object per namespace. De log proc moet dan de goede pakken.

# set_log_global debug {showfilename 0}

# separate function, to be called once, even when handling multiple log files.
proc define_logreader_handlers {} {
  log info "define_logreader_handlers: start"
  # of toch een losse namespace waar deze dingen in hangen?

  reset_parsers_handlers
  
  def_parsers
  def_handlers
  # breakpoint
}

# main function to be called for each log file.
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
    # call proc in liblogreader.tcl
    readlogfile_coro $logfile [vars_to_dict db ssl split_proc logfile_id vuserid]  
  }
}

proc def_parsers {} {

  def_parser trans_line {
    if {[regexp {: \[([0-9 :.-]+)\] (trans=.+?)( \[[0-9/ :-]+])} $line z ts fields]} {
      set nvpairs [log2nvpairs $fields]; # possibly give whole line to log2nvpairs
      dict set nvpairs ts $ts
      dict set nvpairs sec_ts [parse_ts [:ts $nvpairs]]
      dict set nvpairs resptime [regsub -all {,} [:resptime $nvpairs] "."]
      log debug "assert nvpairs: $nvpairs"
      assert {[lsearch -exact [dict keys $nvpairs] ""] < 0}  
      set res [dict_rename $nvpairs {trans status} {transname trans_status}] 
      return $res
    } else {
      return ""
    }
  }

  def_parser errorline {
    if {[regexp {^([^ ]+)\((\d+)\): (Continuing after )?Error ?([0-9-]*): (.*)$} $line z srcfile srclinenr z errornr rest]} {
      # [2016-08-07 13:24] ignore user field (z_user) returned from det_error_details, too specific and already have in trans_line.
      lassign [det_error_details $rest] errortype z_user level details
      log debug "Parsed errorline, returning: $srcfile/$srclinenr/$linenr: $line"
      return [vars_to_dict srcfile srclinenr errornr errortype details line]
    } elseif {[regexp {: Error: } $line]} {
      log error "Error line in log, but could not parse: $line"
      breakpoint
    } elseif {[regexp {Continuing after Error} $line]} {
      log error "Continuing after Error found, but could not parse: $line"
      breakpoint
    } else {
      return ""      
    }
  }

  def_parser errorline {
    # functions.c(399): [2016-08-18 13:11:19.310] ERROR - Did not find: Text=XXXhas been saved but not released to the bank [08/18/16 13:11:19]
    if {[regexp {^([^ ]+)\((\d+)\): .* ERROR - (.+)$} $line z srcfile srclinenr details]} {
      return [vars_to_dict srcfile srclinenr details line]
    } else {
      return ""
    }
  
  }

}

# functions.c(377): [2016-07-29 16:48:22.368] trans=maker_landing, user=Silver3, resptime=-1.000, status=-1, iteration=1 [07/29/16 16:48:22]
# trans=maker_landing, user=Silver3, resptime=-1.000, status=-1, iteration=1
# @return dict with key=name, val=val.
# [2016-08-07 12:12] for now, line is already the part that needs to be split, not the whole logline.
proc log2nvpairs {line} {
  log debug "log2nvpairs: $line"
  set d [dict create]
  # [2016-08-19 21:00] split works with characters, not string, so only check comma and equals, and use string trim.
  foreach nv [split $line ","] {
    lassign [split [string trim $nv] "="] nm val
    log debug "log2nvpairs: $nm->$val"
    dict set d $nm $val
  }
  return $d
}

proc def_handlers {} {

  # convert trans_line => trans
  def_handler {bof eof trans_line} trans {
    # init
    set user ""; set iteration 0; set split_proc "<none>"
  } {
    # body/loop
    log debug "trans-handler - assert topic [:topic $item], item: $item"
    assert {[lsearch -exact [dict keys $item] ""] < 0}  
    switch [:topic $item] {
      bof {
        set started_transactions [dict create]
        dict_to_vars $item ;    # set db, split_proc, ssl
      }
      eof {
        res_add res {*}[make_trans_not_finished $started_transactions]
      }
      trans_line {
        if {[new_user_iteration? $item $user $iteration]} {
          res_add res {*}[make_trans_not_finished $started_transactions]
          set started_transactions [dict create]
          dict_to_vars $item; # user, iteration
        }
        set item [dict merge $item [$split_proc [:transname $item]]]
        switch [:trans_status $item] {
          -1 {
            # start of a transaction, keep data to combine with end-of-trans.
            dict set started_transactions [:transname $item] $item
          }
          0 {
            # succesful end of a transaction, find start data and insert item.
            res_add res [make_trans_finished $item $started_transactions]
            dict unset started_transactions [:transname $item]
          }
          1 {
            # synthetic error, just insert.
            # [2016-08-17 15:07:08] could also have a start trans (-1) for this, so also dict unset.
            res_add res [make_trans_error $item]
            dict unset started_transactions [:transname $item]
          }
          4 {
            # functional warning, eg. no FT's available to approve.
            # [2016-08-12 20:46] possibly also call make_trans_error here,
            # but no logfile to test with here. Check status (should be 4)
            res_add res [make_trans_finished $item $started_transactions]
            # [2016-08-17 15:07:45] also dict unset just to be sure:
            dict unset started_transactions [:transname $item]
          }
          default {
            error "Unknown transaction status: [:trans_status $item]"
          }
        };                    # end-of-switch-status
      }
    };                        # end-of-switch-topic
  };                          # end-of-define-handler

  # make error object from errorline and trans_line
  def_handler {trans_line errorline} error {set trans_line_item {}} {
    switch [:topic $item] {
      trans_line {
        set trans_line_item $item
      }
      errorline {
        # set res [dict merge $trans_line_item $item]
        log debug "def_handler/errorline found: $item"
        res_add res [dict merge $trans_line_item $item]
      }
    }
    # set item [yield $res]
  }
  
  # [2016-08-09 22:29] introduced a bug here by not calling split_proc in insert-trans_line
  # but in trans split_proc is called, and this is used in report. Could also remove fields
  # in trans_line, also split_proc still is somewhat of a hack now.
  def_insert_handler trans_line
  def_insert_handler trans
  def_insert_handler error
  
}

# Specific to this project, not in liblogreader.
# combination of item and file_item
proc def_insert_handler {table} {
  def_handler [list bof $table] {} [syntax_quote {
    if {[:topic $item] == "bof"} { # 
      # dict_to_vars $item ;    # set db, split_proc, ssl
      # set file_item $item
      set db [:db $item]
      set file_item [dict remove $item db split_proc ssl]
    } else {
      $db insert ~$table [dict remove [dict merge $file_item $item] topic]
    }
  }]
}

proc det_vuserid {logfile} {
  if {[regexp {_(\d+).log} $logfile z vuser]} {
    return $vuser
  } elseif {[file tail $logfile] == "output.txt"} {
    # Vugenlog file, vuser=-1
    return -1
  } else {
    log warn "Could not determine vuser from logfile: $logfile"
    return ""
  }
}

proc det_project_runid_script {logfile} {
  # [-> $logfile {file dirname} {file dirname} {file tail}]
  set project [file tail [file dirname [file dirname $logfile]]]
  if {[regexp {run(\d+)} [file tail [file dirname $logfile]] z id]} {
    set runid $id
  } else {
    set runid ""
  }
  if {[regexp {^(.+)_\d+\.log$} [file tail $logfile] z scr]} {
    set script $scr
  } else {
    set script ""
  }
  
  list $project $runid $script
}

# return 1 iff either old user or old iteration differs from new one in row
proc new_user_iteration? {row user iteration} {
  if {($user != [:user $row]) || ($iteration != [:iteration $row])} {
    return 1
  }
  return 0
}

# TODO: should put this in own namespace.
set error_res {
  {Text=Uw pas is niet correct} pas_niet_correct 10

  {HTTP Status-Code=500} http500 9
  {Er is een technisch probleem opgetreden} tech_problem 9
  {A technical error has occurred at} tech_error 9
  {Gateway Time-out} gateway_timeout 9
  {Connection reset by peer} conn_reset 9
  {has shut down the connection prematurely} conn_shutdown 9
  {SSL protocol error when attempting to connect} ssl_error 9
  
  {Step download timeout} step_timeout 8
  {Connection timed out} connection_timeout 8

  {may be explained by header and body byte counts being} explained_header_body 3
  
  {No match found for the requested parameter} no_match 0
  {not found for web_reg_find} web_reg_find 0
}

proc det_error_details {rest} {
  global error_res
  set user ""
  set errortype ""
  set details ""
  set level -1
  regexp {User:(\d+) pas} $rest z user
  regexp {No match found for the requested parameter \"([^ ]+)\"} $rest z details
  regexp {\"Text=(.+)\" not found for web_reg_find} $rest z details
  foreach {re tp lv} $error_res {
    if {[regexp $re $rest]} {
      set errortype $tp
      set level $lv
      break
    }
  }
  list $errortype $user $level $details
}

