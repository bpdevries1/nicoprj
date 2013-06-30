#!/usr/bin/env tclsh86

# jtls2db.tcl - convert jtl's (xml) to a sqlite3 db

package require tdbc::sqlite3
package require xml
package require Tclx
package require struct::stack
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[info script].log"

# @todo ts_fmt als extra veld opnemen in httpsample.

proc main {argv} {
  global conn dct_insert_stmts
  if {[llength $argv] != 2} {
    log error "syntax: ./xmljtls2db.tcl <dir-with-jtl> <dir-to-put-db>"
    exit
  }
  lassign $argv dirname dbdirname
  # lassign [create_db $dirname] conn table_defs
  lassign [create_db $dbdirname] conn table_defs
  foreach td $table_defs {
    dict set dct_insert_stmts [dict get $td table] [prepare_insert_td $conn $td]
  }
  read_jtls $conn $dirname $dct_insert_stmts
  finish_db $conn
}

proc create_db {dirname} {
  set db_file [file join $dirname "jtldb.db"]
  file delete -force $db_file
  # sqlite3 db $dbfile
  set conn [open_db $db_file]
  set td_jtlfile [make_table_def_keys jtlfile {id} {path}]
  set td_httpsample [make_table_def_keys httpsample {id} {parent_id jtlfile_id t lt ts s lb rc rm tn dt \
    de by ng na hn ec it sc responseHeader requestHeader responseFile cookies \
    method queryString redirectLocation java_net_URL cachetype akserver protocol server path}]
  set td_assertionresult [make_table_def_keys assertionresult {id} {parent_id name failure error}]
  set table_defs [list $td_jtlfile $td_httpsample $td_assertionresult]
  foreach td $table_defs {
    create_table $conn $td
  }
  return [list $conn $table_defs]
}

proc finish_db {conn} {
  log debug "Create index on ts:"
  db_eval $conn "create index ix_ts on httpsample (ts)"
  log debug "Create index on lb:"
  db_eval $conn "create index ix_lb on httpsample (lb)"
  log debug "Creating indexes finished, closing db"
  $conn close
}

proc read_jtls {conn dirname dct_insert_stmts} {
  foreach jtlfile [glob -directory $dirname "*.jtl"] {
    read_jtl $conn $jtlfile $dct_insert_stmts
    # exit ; # for now.
  }
}

proc read_jtl {conn jtlfile dct_insert_stmts} {
  global elt_stack jtlfile_id
  log info "Reading jtl: $jtlfile" 
  db_eval $conn "begin transaction"
  set jtlfile_id [stmt_exec $conn [dict get $dct_insert_stmts jtlfile] [dict create path $jtlfile] 1]
  log info "jtlfile_id: $jtlfile_id"
  if {0} {
    set parser [::xml::parser -elementstartcommand [list elementstart count elt_stack] \
      -elementendcommand [list elementend elt_stack] \
      -characterdatacommand [list characterdata elt_stack] \
      -defaultcommand xml_default]
  }
  if {1} {  
    set parser [::xml::parser -elementstartcommand [list elementstart count elt_stack] \
      -elementendcommand [list elementend elt_stack] \
      -characterdatacommand [list characterdata elt_stack] \
      -defaultcommand xml_default]
  }
  set f [open $jtlfile r]
  log debug "Reading file: $jtlfile"
  set elt_stack [struct::stack]
  set text [read $f]
  log debug "Reading file finished (length:[string length $text]), now parsing text"
  # $parser parse $text
  try_eval {
    $parser parse $text
  } {
    log debug "error: $errorResult"
    log debug "Maybe no close tag, because JMeter still running"
  }
  log debug "Parsing text finished"
  db_eval $conn "commit"
}

proc elementstart {count_name elt_stack_name name attlist args} {
  global conn
  upvar #0 $count_name count
  upvar #0 $elt_stack_name elt_stack
  incr count
  log debug "Handled $count elements"
  if {[expr $count % 1000] == 0} {
    log debug "Handled $count elements"
    db_eval $conn "commit"
    db_eval $conn "begin transaction"
  }
  log debug "elementstart: $name (att: $attlist, args: $args)"
  $elt_stack push [dict create tag $name attrs $attlist]
  log info "pushed elt: size now: [$elt_stack size]"
  log debug "current element after change: [first_line [$elt_stack peek]]"
  # log debug "current element after change: [$elt_stack peek]"
}

proc characterdata {elt_stack_name data} {
  upvar #0 $elt_stack_name elt_stack
  log debug "character data: [first_line $data] ***"
  if {[string trim $data] != ""} {
    log debug "stack size before change: [$elt_stack size]"
    set elt [$elt_stack pop]
    dict set elt text $data
    $elt_stack push $elt
    log debug "stack size after change: [$elt_stack size]"
  }
  # log debug "current element after change: [$elt_stack peek]"
  log debug "current element after change: [first_line [$elt_stack peek]]"
  log debug "character data end."
}

proc elementend {elt_stack_name name} {
  upvar #0 $elt_stack_name elt_stack
  log debug "element end: $name"
  log info "will pop elt: size now: [$elt_stack size]"
  set child ""
  if {[$elt_stack size] >= 2} {
    set child [$elt_stack pop]
    set parent [$elt_stack pop]
    dict lappend parent subelts $child
    $elt_stack push $parent
  } else {
    # toplevel finished? callback?
    log info "elt_stack size < 2, do callback?"
    log info "stack size: [$elt_stack size]"
    if {[$elt_stack size] == 1} {
      log info "only element: [$elt_stack peek]" 
    }
  }
  if {[$elt_stack size] == 1} {
    # @todo algemene element niet op de stack, want kost veel geheugen, alle sub-tags hier aan toegevoegd.
    # httpSample niet meer current element, niet meer op stack, toegevoegd aan algemene results (hoeft eigenlijk ook niet)
    # handle_main_sample [$elt_stack peek]
    try_eval {
      #log info "calling handle_main_sample, stack: [stack_to_string $elt_stack]"
      #handle_main_sample [$elt_stack peek]
      if {$child == ""} {
        log warn "want to call handle_main_sample, but child is empty" 
      } else {
        log info "calling handle_main_sample, stack: [stack_to_string $elt_stack]"
        handle_main_sample $child
      }
    } {
      log debug "error in handle_main_sample: $errorResult"
      log debug "$errorCode $errorInfo"
      error $errorResult $errorCode $errorInfo
      exit
    }
  }
  
  log info "stack size after change: [$elt_stack size]"
  log debug "current element after change: [first_line [$elt_stack peek]]"
}

proc stack_to_string {elt_stack} {
  set res {}
  # stack doesn't correctly handle one stack item which is a list.
  if {[$elt_stack size] == 1} {
    set l [list [$elt_stack peek [$elt_stack size]]] 
  } else {
    set l [$elt_stack peek [$elt_stack size]]
  }
  foreach el $l {
    lappend res "tag: [dict_get $el tag "<no-tag>"]; lt: [det_latency $el]" 
  }
  join $res ", "
}

proc det_latency {elt} {
  set attrs [dict_get $elt attrs {}]
  if {$attrs != {}} {
    dict_get $attrs lt "<none>"
  } else {
    return "<no-attr>" 
  }
}

proc xml_default {data} {
  log debug "XML default, data=$data" 
}

proc handle_main_sample {sample} {
  global conn dct_insert_stmts jtlfile_id
  log info "handle main sample: [first_line $sample]"
  log info "latency of main sample: [dict get $sample attrs lt]"
  # breakpoint
  set main_id [insert_sample $sample]
  log debug "inserted main sample"
  insert_assertion_results $main_id $sample
  log debug "inserted assertion results"
  insert_sub_samples $main_id $sample
  log info "handled main sample."
}

proc insert_sample {sample {parent_id ""}} {
  global conn dct_insert_stmts jtlfile_id
  log debug "insert_sample: start"
  set dct [dict_get $sample attrs {}] ; # std attrs like t, ts, ...
  dict set dct jtlfile_id $jtlfile_id
  dict set dct parent_id $parent_id
  foreach sub_elt [dict_get $sample subelts {}] {
    set sub_tag [dict get $sub_elt tag]
    if {$sub_tag == "assertionResult"} {
      # ignore here 
    } elseif {$sub_tag == "httpSample"} {
     # ignore here 
    } else {
      dict set dct $sub_tag [dict_get $sub_elt text ""] 
    }
  }
  set main_id [stmt_exec $conn [dict get $dct_insert_stmts httpsample] $dct 1]
  log debug "insert_sample: finished"
  return $main_id  
}

proc insert_assertion_results {sample_id sample} {
  global conn dct_insert_stmts jtlfile_id
  foreach sub_elt [dict_get $sample subelts {}] {
    set sub_tag [dict get $sub_elt tag]
    if {$sub_tag == "assertionResult"} {
      set dct_assert [dict create parent_id $sample_id]
      foreach sub_sub_elt [dict_get $sub_elt subelts {}] {
         dict set dct_assert [dict get $sub_sub_elt tag] [dict_get $sub_sub_elt text ""] 
      }
      stmt_exec $conn [dict get $dct_insert_stmts assertionresult] $dct_assert
    }
  }
}

proc insert_sub_samples {sample_id sample} {
  log debug "insert_sub_samples in $sample_id: [first_line $sample]"
  global conn dct_insert_stmts jtlfile_id
  foreach sub_elt [dict_get $sample subelts {}] {
    set sub_tag [dict get $sub_elt tag]
    if {$sub_tag == "httpSample"} {
      log debug "inserting sub_sample: [first_line $sub_elt]"
      set sub_id [insert_sample $sub_elt $sample_id]
      insert_assertion_results $sub_id $sub_elt
      insert_sub_samples $sub_id $sub_elt
      log debug "inserted sub_sample"      
    }
  }
}

proc first_line {text} {
  if {[regexp {^([^\n]+)} $text z line1]} {
    return "first: $line1" 
  } else {
    return "all: $text"  
  }
}

main $argv

