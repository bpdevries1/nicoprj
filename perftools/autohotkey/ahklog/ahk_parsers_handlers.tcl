# separate function, to be called once, even when handling multiple log files.
proc define_logreader_handlers_ahk {} {
  log info "define_logreader_handlers: start"
  def_parsers_ahk
  def_handlers_ahk
}

proc def_parsers_ahk {} {

  # TODO: timestamp deel in de regexp los definieren? Alternatief is parser voor logline maken en rest met handlers. Voor beide wat te zeggen.
  def_parser_regexp_ts iter_start_finish {\[iter\] ([^ ]+) iteration: (\d+)} \
      start_finish iteration

  # [2016-08-11 11:33:00.126] [trans] Transaction started : FT_Funds_transfer
  def_parser_regexp_ts trans_start \
      {\[trans\] Transaction started ?: ([^,\r\n]+)} transname
  
  def_parser_regexp_ts trans_finish \
      {\[trans\] Transaction finished: ([^,]+), success: (\d), transaction time \(sec\): ([-0-9.]+),} transname success resptime

  def_parser_regexp_ts errorline {\[error\] (.*)$} line

  # [2016-08-13 19:34] need to use \S+, just [^ ]+ fails, adds newline/cr?
  def_parser_regexp_ts user {\[info\] Iteration (\d+), user: (\S+)} \
      iteration user

  def_parser_regexp_ts resource_line \
      {\[info\] capturing screen to: ([^ ]+) in directory:} resource

  # [2016-08-13 19:58] deze niet, want bestaat niet en heb ook capturing screen
  # waar 'ie wel in staat.
  def_parser_regexp_ts resource_linexx \
      {\[info\] Saved desktop to: ([^ ]+)$} resource
}

# [2016-08-13 18:17] for now AHK specific, maybe more generic (also like Splunk with timestamps?).
# add regexp for ts and ts to re and args
proc def_parser_regexp_ts {topic re args} {
  set re_ts {\[([0-9 :.-]+)\]}
  def_parser_regexp $topic "$re_ts $re" ts {*}$args
}

proc def_handlers_ahk {} {

  def_handler {iter_start_finish user trans_start trans_finish eof} trans {
    set transactions [dict create]
    set user "NONE"
  } {
    switch [:topic $item] {
      iter_start_finish {
        if {[:start_finish $item] == "Start"} {
          # TODO: check if all transactions have finished, empty list.
          # assert {[:# $transactions] == 0}
          set iteration [:iteration $item]
          set transactions [dict create]
        } else {
          # TODO: maybe finish transactions
          # assert {[:# $transactions] == 0}
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
        # TODO: activate assert again.
        # assert {[:# $transactions] == 0}
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
        if {$user != [string trim $user]} {
          breakpoint
        }
      }
      errorline {
        res_add res [make_error_ahk [add_sec_ts $item] $iteration $user]
      }
    }
  }

  def_handler {iter_start_finish user trans_start resource_line} resource {
    # [2016-08-13 18:52] start bitmap is saved, before iteration starts.
    set user "NONE"
    set iteration 0
    set transname NONE
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
      trans_start {
        set transname [:transname $item]
      }
      resource_line {
        res_add res [make_resource_ahk [add_sec_ts $item] $iteration $user $transname]
      }
    }
  }
  
  # def_insert_handler trans_line
  def_insert_handler trans
  def_insert_handler error
  def_insert_handler resource

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

proc make_error_ahk_old {item iteration user} {
  dict set item iteration $iteration
  dict set item user $user
  return $item
}

proc make_error_ahk  {item iteration user} {
  dict merge $item [vars_to_dict iteration user]
}

proc make_resource_ahk {item iteration user transname} {
  dict merge $item [vars_to_dict iteration user transname]
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

