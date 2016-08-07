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

# [2016-08-07 13:29] deze zorgt er nu voor dat global (zoals de naam zegt) overal loglevel
# op debug komt, wil je in het algemeen niet. 2 opties:
# * de set_log_global doet alleen wat als de log nog niet gezet is.
# * iets met namespaces, log object per namespace. De log proc moet dan de goede pakken.

# set_log_global debug {showfilename 0}

proc define_logreader_handlers {} {
  log info "define_logreader_handlers: start"
  # of toch een losse namespace waar deze dingen in hangen?
  def_parsers
  def_handlers
  # breakpoint
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
    if {[regexp {^([^ ]+)\((\d+)\): (Continuing after )?Error ?([0-9-]*): (.*)$} $line z srcfile srclinenr z errornr rest]} {
      # [2016-08-07 13:24] ignore user field returned from det_error_details, too specific and already have in transline.
      lassign [det_error_details $rest] errortype z_user level details
      return [vars_to_dict srcfile srclinenr errornr errortype details line]
    } elseif {[regexp {: Error: } $line]} {
      log error "Error line in log, but could not parse: $line"
      breakpoint
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
  set d [dict create]
  foreach nv [split $line ", "] {
    lassign [split $nv "="] nm val
    dict set d $nm $val
  }
  return $d
}

proc def_handlers {} {

  # TODO: helper or replacement for def_handler so default code will be generated:
  # initialisation
  # set item [yield]
  # while 1 {
  #   set res ""
  #   $body
  #   set item [yield $res]
  # }
  
  def_handler {bof eof transline} trans {
    set user ""; set iteration 0; set split_proc "<none>"
    set item [yield]
    # keep on running, even after eof, could be >1 logfile.
    while 1 {
      set res ""
      switch [:topic $item] {
        bof {
          set started_transactions [dict create]
          dict_to_vars $item ;    # set db, split_proc, ssl
        }
        eof {
          res_add res {*}[make_trans_not_finished $started_transactions]
        }
        transline {
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
              res_add res [make_trans_error $item]
            }
            4 {
              # functional warning, eg. no FT's available to approve.
              res_add res [make_trans_finished $item $started_transactions]
            }
            default {
              error "Unknown transaction status: [:trans_status $item]"
            }
          };                    # end-of-switch-status
        }
      };                        # end-of-switch-topic
      set item [yield $res]
    };                          # end-of-while-1
  };                            # end-of-define-handler

  # make error object from errorline and transline
  def_handler {transline errorline} error {
    set transline_item {}
    set item [yield]
    while 1 {
      set res ""
      switch [:topic $item] {
        transline {
          set transline_item $item
        }
        errorline {
          set res [dict merge $transline_item $item]
        }
      }
      set item [yield $res]
    }
  }
  
  # 'inserter' handler, just for side effects, yields no new results.
  def_handler {bof transline} {} {
    # log debug "puts-handler: started"
    set db "<none>"; set split_proc "<none"; set ssl "<none>"
    set file_item "<none>"
    set item [yield]
    while 1 {
      if {[:topic $item] == "bof"} {
        dict_to_vars $item ;    # set db, split_proc, ssl
        set file_item $item
      } else {
        # log debug "transline handler item: $item, db: $db ***"
        $db insert trans_line [dict merge $file_item $item \
                                   [$split_proc [:transname $item]]]
      }
      set item [yield];         # this one never returns anything.
    }
  }

  # another inserter, for trans records
  def_handler {bof trans} {} {
    # log debug "puts-handler: started"
    set db "<none>"
    set file_item "<none>"
    set item [yield]
    while 1 {
      if {[:topic $item] == "bof"} {
        dict_to_vars $item ;    # set db, split_proc, ssl
        set file_item $item
      } else {
        assert {[:linenr_start $item] > 0}
        # log debug "transline handler item: $item, db: $db ***"
        $db insert trans [dict merge $file_item $item]
      }
      set item [yield];         # this one never returns anything.
    }
  }

  # inserter for error records
  # old one, should not get called.
  def_handler {bofxx errorxx} {} {
    # log debug "puts-handler: started"
    set db "<none>"
    set file_item "<none>"
    set item [yield]
    while 1 {
      if {[:topic $item] == "bof"} {
        dict_to_vars $item ;    # set db, split_proc, ssl
        set file_item $item
      } else {
        $db insert error [dict merge $file_item $item]
      }
      set item [yield];         # this one never returns anything.
    }
  }

  # maybe create def_insert_handler, but is specific to this project, not in liblogreader.
  def_handler2 {bofxx errorxx} {} {
    if {[:topic $item] == "bof"} {
      dict_to_vars $item ;    # set db, split_proc, ssl
      set file_item $item
    } else {
      $db insert error [dict merge $file_item $item]
    }
  }

  def_insert_handler error
  
}

proc def_insert_handler {table} {
  def_handler2 [list bof $table] {} "if {\[:topic \$item\] == \"bof\"} {
      dict_to_vars \$item ;    # set db, split_proc, ssl
      set file_item \$item
    } else {
      \$db insert $table \[dict merge \$file_item \$item\]
    }"
}

# eigenlijk iets als:
# evt de macro` zelfs alleen ` noemen, maar is mss te onduidelijk.
# heeft deze in clojure een naam?
# https://github.com/brandonbloom/backtick
# syntax-quote heet deze, wel ok naam.
# ge-un-quote dingen moeten in uplevel beschikbaar zijn. Zie ook mijn closure dingetje
# in FP.
if 0 {
  proc def_insert_handler {table} {
    def_handler2 [list bof $table] {} [syntax_quote {
      if {[:topic $item] == "bof"} {
        dict_to_vars $item ;    # set db, split_proc, ssl
        set file_item $item
      } else {
        $db insert ~$table [dict merge $file_item $item]
      }
    }]
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

