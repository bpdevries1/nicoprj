# separate function, to be called once, even when handling multiple log files.
proc define_logreader_handlers {} {
  log info "define_logreader_handlers: start"
  def_parsers
  def_handlers
}

proc def_parsers {} {

  # TODO: def_parser_regexp iter_start_finish $re ts start_finish iteration
  def_parser iter_start_finish {
    # [2016-08-09 16:37:49.630] [iter] Start iteration: 1
    # TODO: timestamp deel in de regexp los definieren?
    # TODO: define simple regexp parser, like Splunk. Just the RE and varnames.
    if {[regexp {\[([0-9 :.-]+)\] \[iter\] ([^ ]+) iteration: (\d+)} $line z ts start_finish iteration]} {
      vars_to_dict ts start_finish iteration
    } else {
      return ""
    }
  }

  def_parser trans_start {
    # [2016-08-09 16:37:49.630] [trans] Transaction started : 01_Start_Internet_Explorer
    if {[regexp {\[([0-9 :.-]+)\] \[trans\] Transaction started: ([^,]+)} $line z ts transname]} {
      vars_to_dict ts transname
    } else {
      return ""
    }
  }

  def_parser trans_finish {
    # [2016-08-09 16:37:51.034] [trans] Transaction finished: 01_Start_Internet_Explorer, success: 1, transaction time (sec): 0.404, slept (sec): 1.000
    if {[regexp {\[([0-9 :.-]+)\] \[trans\] Transaction finished: ([^,]+), success: (\d), transaction time \(sec\): ([-0-9.]+),} $line z ts transname success resptime]} {
      vars_to_dict ts transname success resptime
    } else {
      return ""
    }
  }

  def_parser errorline {
    # [2016-08-09 16:38:22.161] [error] ERROR - image submit-uploaded.png not found
    if {[regexp {\[([0-9 :.-]+)\] \[error\] (.*)$} $line z ts line]} {
      vars_to_dict ts line
    } else {
      return ""
    }
  }

  # [2016-08-11 11:30:52.847] [info] Iteration 1, user: STU1
  def_parser user {
    # [2016-08-09 16:38:22.161] [error] ERROR - image submit-uploaded.png not found
    if {[regexp {\[([0-9 :.-]+)\] \[info\] Iteration (\d+), user: (.+)$} $line z ts iteration user]} {
      vars_to_dict ts iteration user
    } else {
      return ""
    }
  }
  
}

proc def_handlers {} {

  def_handler {iter_start_finish user trans_start trans_finish eof} trans {
    set transactions [dict create]
    set user "NONE"
  } {
    switch [:topic $item] {
      iter_start_finish {
        if {[:start_finish $item] == "Start"} {
          # TODO: check if all transactions have finished, empty list.
          assert {[:# $transactions] == 0}
          set iteration [:iteration $item]
          set transactions [dict create]
        } else {
          # TODO: maybe finish transactions
          assert {[:# $transactions] == 0}
          set user "NONE"
        }
      }
      trans_start {
        dict set transactions [:transname $item] [add_sec_ts $item]
      }
      trans_finish {
        # TODO: remove res name here, is always the same, just res_add is enough
        res_add res [make_trans_finished_ahk [add_sec_ts $item] $transactions \
                         $iteration $user]
        dict unset transactions [:transname $item]
      }
      user {
        set user [:user $item]
      }
      eof {
        assert {[:# $transactions] == 0}
      }
    }
  }

  def_handler {iter_start_finish user errorline} error {
    set user "NONE"
  } {
    switch [:topic $item] {
      iter_start_finish {
        if {[:start_finish $item] == "Start"} {
          set iteration [:iteration $item]
        }
      }
      user {
        set user [:user $item]
      }
      errorline {
        res_add res [make_error_ahk [add_sec_ts $item] $iteration $user]
      }
    }
  }
  
  # def_insert_handler trans_line
  def_insert_handler trans
  def_insert_handler error

}

proc add_sec_ts {item} {
  dict merge $item [dict create sec_ts [parse_ts [:ts $item]]]
}

# TODO: [2016-08-13 11:24] name clash with vugen version, so renamed for now.
proc make_trans_finished_ahk {item transactions iteration user} {
  assert {$iteration > 0}
  log debug "iteration: $iteration"
  set line_fields {linenr ts sec_ts}
  set line_start_fields [map [fn x {return "${x}_start"}] $line_fields]
  set line_end_fields [map [fn x {return "${x}_end"}] $line_fields]
  #set no_start 0

  dict set item trans_status [success_to_trans_status [:success $item]]
  set item [dict merge $item [split_transname [:transname $item]]]
  set itemstart [dict_get $transactions [:transname $item]]
  if {$itemstart == {}} {
    # probably a synthetic transaction. Some minor error.
    set itemstart $item
    #set no_start 1
  }
  set dstart [dict_rename $itemstart $line_fields $line_start_fields]
  set dend [dict_rename $item $line_fields $line_end_fields]
  set diteration [dict create iteration_start $iteration iteration_end $iteration]
  set duser [dict create user $user]
  set d [dict merge $diteration $duser $dstart $dend]
  log debug "d: $d"
  log debug "dtart: $dstart"
  log debug "dend: $dend"
  assert {[:iteration_start $d] > 0}
  return $d
}

proc split_transname {transname} {
  # TODO: straks andere transnames incl usecase, zonder nummers.
  if {[regexp {^([^_]+)_(.+)$} $transname z usecase transshort]} {
    vars_to_dict usecase transshort
  } else {
    dict create usecase NONE transshort $transname  
  }
}

proc success_to_trans_status {success} {
  switch $success {
    0 {return 1}
    1 {return 0}
  }
}

proc make_error_ahk {item iteration user} {
  dict set item iteration $iteration
  dict set item user $user
  return $item
}

# Specific to this project, not in liblogreader.
# combination of item and file_item
# TODO: maybe generic after all, directly usable for AHK log?
proc def_insert_handler {table} {
  def_handler [list bof $table] {} [syntax_quote {
    if {[:topic $item] == "bof"} { # 
      dict_to_vars $item ;    # set db, split_proc, ssl
      set file_item $item
    } else {
      log debug "Insert record in ~$table: $item"
      $db insert ~$table [dict merge $file_item $item]
    }
  }]
}

