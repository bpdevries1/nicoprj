#!/home/nico/bin/tclsh

package require Tclx
package require csv
package require sqlite3

# own package
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  lassign $argv dirname db_filename
  file delete $db_filename
  create_db $db_filename
  handle_dir $dirname
  db close  
}

proc create_db {filename} {
  sqlite3 db $filename
  # db eval "create table timer (script, vuser, trans_name, timer_name, trans_linenr, trans_it, time, msg, resptime, result)"
  db eval "create table timer (script, vuser, trans_name, timer_name, trans_linenr, trans_it, time float, msg, resptime, result int)"
}

proc handle_dir {dirname} {
  foreach filename [glob -directory $dirname -type f "*.err"] {
    handle_file $filename   
  }
}

proc handle_file {filename} {
  global prev_it result timers timer_name zoektype trans_name trans_linenr tr_it time sev int_error native_error msg
  set fi [open $filename r]
  lassign [det_script_vuser $filename] script vuser
  init_trans
  while {![eof $fi]} {
    gets $fi line
    if {$line == "\}"} {
      # puts [join [list $trans_name $trans_linenr $trans_it $time $sev $int_error $native_error $msg] ";"]
      handle_line $script $vuser $trans_name $trans_linenr $trans_it $time $sev $int_error $native_error $msg
    }
    if {[regexp {^ *([^:]+): (.*)$} $line z nm val]} {
      set nm [string trim $nm]
      set val [string trim $val]
      if {$nm == "Transaction"} {
        # lassign [split $val ","] trans_name trans_linenr trans_it
        lassign [split $val ","] trans_name tr_linenr tr_it
        regexp {line: (\d+)} $tr_linenr z trans_linenr
        regexp {call: (\d+)} $tr_it z trans_it
      }
      if {$nm == "Time"} {
        set time $val
      }
      if {$nm == "Severity"} {
        set sev $val
      }
      if {$nm == "Internal Error"} {
        set int_error $val
      }
      if {$nm == "Native Error"} {
        set native_error $val 
      }
      if {$nm == "Message"} {
        set msg $val
      }
    }
  }
  # afsluitende iteratie
  handle_line $script $vuser $trans_name $trans_linenr <end> $time $sev $int_error $native_error $msg
  
  close $fi
}

proc det_script_vuser {filename} {
  # ontwxd01577@BAM_zoeken_VSearch-FlexAMF3_9.err
  # ontwxd01577@BAM_zoeken_edit_VMutate-FlexAMF3_16.err
  if {[regexp {@(.+)_V.+3_(\d+).err} $filename z script vuser]} {
    list $script $vuser
  } else {
    list "unknown: $filename" "-" 
  }
}

proc init_trans {} {
  global prev_it result timers timer_name zoektype trans_name trans_linenr tr_it time sev int_error native_error msg
  set prev_it "<none>"
  set result 1
  set timers {}
  set timer_name "<none>"
  set zoektype "<none>"
  set trans_name "<none>"
  set trans_linenr "<none>"
  set tr_it "<none>"
  set time "<none>"
  set sev "<none>"
  set int_error "<none>"
  set native_error "<none>"
  set msg "<none>"
}

proc handle_line {script vuser trans_name trans_linenr trans_it time sev int_error native_error msg} {
  global prev_it result timers timer_name zoektype
  if {$prev_it != $trans_it} {
    # handle previous
    if {$prev_it != "<none>"} {
      # db eval "create table timer (script, vuser, trans_name, timer_name, trans_linenr, trans_it, time, msg, result)"
      foreach timer $timers {
        # insert_record $script $vuser $trans_name $timer_name $trans_linenr $trans_it $time $msg $result
        insert_record {*}$timer $result
      }
    } else {
      log debug "prev_it, it: $prev_it, $trans_it, begin transaction at start file"
      db eval "begin transaction"
    }
    if {$trans_it != "<end>"} {
      init_trans
      set prev_it $trans_it
    } else {
      log debug "commit at end file"
      db eval "commit" 
    }
  }
  # handle current line
  if {[regexp {last([^0-9.]+)([0-9.]+)} $msg z srt tm]} {
    set resptime $tm
    set timer_name [det_timer_name $script $trans_linenr $zoektype $srt]
    lappend timers [list $script $vuser $trans_name $timer_name $trans_linenr $trans_it $time $msg $resptime] 
  } elseif {$sev == "error"} {
    set result 0 
  } elseif {[regexp {, s(.+)Check: true} $msg z zt]} {
    set zoektype $zt
    #log debug "zoektype: $zoektype (msg=$msg)"
    #exit
  }
}

proc det_timer_name {script trans_linenr zoektype srt} {
  # return "todo: $srt"
  if {$script == "webservices"} {
    return "maak2contracten_$srt"
  } elseif {$script == "BAM_zoeken_edit"} {
    if {$trans_linenr == 971} {
      return "zoek_${srt}_$zoektype"
    } elseif {$trans_linenr == 1094} {
      return "naarAG_$srt"
    } elseif {$trans_linenr == 1251} {
      return "naarAI_$srt"
    } else {
      error "Unknown linenr in BAM_zoeken_edit: $trans_linenr" 
    }
  } elseif {$script == "BAM_zoeken"} {
    return "zoek_${srt}_$zoektype"
  } elseif {$script == "<history>"} {
    # geen timers in history, anders oplossen? 
  } else {
    error "Unknown script: $script" 
  }
}

proc insert_record {args} {
  set lst2 {}
  foreach el $args {
    lappend lst2 "'$el'" 
  }
  db eval "insert into timer values ([join $lst2 ", "])"
}

proc log {args} {
  global log
  $log {*}$args
}

main $argv

