#!/usr/bin/env tclsh86

# xmljtls2db.tcl - convert jtl's (xml) to a sqlite3 db

# @note log debug (and maybe first_line) statements cause memory exhaustion, uncommenting those helps on Windows. (on Linux no problems, but have more memory there).
# @todo ook loopt laptop nu opnieuw uit zijn geheugen, dus verder checken.

# @todo for memory problems:
# delete vars/items explicitly.
# call parser::parse with chunks of main httpSamples.
# info vars ?pattern? to check if there are too many.
# unset om vars te deleten.
# tried all above things, to no avail.

# @todo level does not seem to be a 'real' integer at all places, so explicitly setting the datatype might be needed.
# @todo this shows in handle-myphilips.tcl, determining steps and indices for steps and reqs. Mostly ok, 1 exception.

package require tdbc::sqlite3
package require xml
package require Tclx
package require struct::stack
package require ndv

source lib-akamai-info.tcl
# source watch_globals.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[info script].log"

proc main {argv} {
  global conn dct_insert_stmts
  if {[llength $argv] != 2} {
    log error "syntax: ./xmljtls2db.tcl <dir-with-jtl> <dir-to-put-db>"
    exit 1
  }
  lassign $argv dirname dbdirname
  lassign [create_db $dbdirname] conn table_defs
  foreach td $table_defs {
    dict set dct_insert_stmts [:table $td] [prepare_insert_td_proc $conn $td]
  }
  read_jtls $conn $dirname $dct_insert_stmts
  finish_db $conn
}

proc create_db {dirname} {
  set db_file [file join $dirname "jtldb.db"]
  file mkdir $dirname
  file delete -force $db_file
  set conn [open_db $db_file]
  set td_jtlfile [make_table_def_keys jtlfile {id} {path}]
  set td_httpsample [make_table_def_keys httpsample {id} {level parent_id jtlfile_id t lt ts ts_utc s lb rc rm tn dt \
    de by ng na hn ec it sc responseHeader requestHeader responseFile cookies \
    method queryString redirectLocation java_net_URL cachetype akserver cacheable \
    expires expiry maxage cachekey protocol server path extension domain}]
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
    # exit ; # for testing.
  }
}

proc read_jtl {conn jtlfile dct_insert_stmts} {
  global elt_stack jtlfile_id
  log info "Reading jtl: $jtlfile" 
  db_eval $conn "begin transaction"
  set jtlfile_id [[:jtlfile $dct_insert_stmts] [dict create path $jtlfile] 1]
  log info "jtlfile_id: $jtlfile_id"
  set parser [::xml::parser -parser expat -elementstartcommand [list signal_error elementstart count elt_stack] \
    -elementendcommand [list signal_error elementend elt_stack] \
    -characterdatacommand [list signal_error characterdata elt_stack] \
    -defaultcommand [list signal_error xml_default]]
  set f [open $jtlfile r]
  log info "Reading file: $jtlfile"
  set elt_stack [struct::stack]
  set text [read $f]
  log info "Reading file finished (length:[string length $text]), now parsing text"
  try_eval {
    $parser parse $text
  } {
    log warn "error: $errorResult"
    log warn "Maybe no close tag, because JMeter still running"
  }
  $parser free
  log debug "Parsing text finished"
  log info "reading jtl finished: $jtlfile"
  db_eval $conn "commit"
}

# @note wrapper around xml parser callbacks, to make sure that error are signalled and not silently ignored.
proc signal_error {proc_name args} {
  try_eval {
    $proc_name {*}$args
  } {
    log error "$errorResult $errorCode $errorInfo, exiting"
    error $errorResult $errorCode $errorInfo
    exit
  }  
}

# @note for testing, and memory errors on windows.
proc dummy_cb {args} {
  
}

proc elementstart {count_name elt_stack_name name attlist args} {
  global conn
  upvar #0 $count_name count
  upvar #0 $elt_stack_name elt_stack
  # log debug "elementstart: $name (att: $attlist, args: $args)"
  if {[ignore_elt $name]} {
    # log debug "Ignore element: $name"
    return 
  }
  incr count
  if {[expr $count % 10000] == 0} {
    log info "Handled $count elements, commit and start new transaction."
    db_eval $conn "commit"
    db_eval $conn "begin transaction"
    #log info "call wg_checkpoint"
    #wg_checkpoint
    #log info "called wg_checkpoint"
  }
  
  $elt_stack push [dict create tag $name attrs $attlist]
  # log debug "pushed elt: size now: [$elt_stack size]"
  # log debug "current element after change: [first_line [$elt_stack peek]]"
  # # log debug "current element after change: [$elt_stack peek]"
  # log debug "elementstart: $name finished"
}

proc characterdata {elt_stack_name data} {
  upvar #0 $elt_stack_name elt_stack
  # log debug "1.character data: [first_line $data] ***"
  # breakpoint
  if {[string trim $data] != ""} {
    # log debug "stack size before change: [$elt_stack size]"
    if {[$elt_stack size] > 0} {
      set elt [$elt_stack pop]
      dict set elt text $data
      $elt_stack push $elt
      # log debug "current element after change: [first_line [$elt_stack peek]]"
    } else {
      # log debug "stack is empty, don't change element with character data" 
    }
    # log debug "stack size after change: [$elt_stack size]"
  }
  # # log debug "current element after change: [$elt_stack peek]"
  # log debug "character data end."
}

proc elementend {elt_stack_name name} {
  upvar #0 $elt_stack_name elt_stack
  # log debug "element end: $name"
  if {[ignore_elt $name]} {
    # log debug "Ignore element: $name"
    return 
  }

  # log debug "will pop elt: size now: [$elt_stack size]"
  set child ""
  if {[$elt_stack size] >= 2} {
    set child [$elt_stack pop]
    set parent [$elt_stack pop]
    dict lappend parent subelts $child
    $elt_stack push $parent
  } elseif {[$elt_stack size] == 1} {
    # toplevel finished? callback?
    # log debug "elt_stack size == 1, do callback!"
    handle_main_sample [$elt_stack pop]
  } else {
    log error "Stack size < 1 and found end-tag, should not happen" 
  }
  # log debug "stack size after change: [$elt_stack size]"
  if {[$elt_stack size] > 0} {
    # log debug "current element after change: [first_line [$elt_stack peek]]"
  }
  # log debug "elementend $name: finished"
}

# @note ignore main/root element, so stack will be empty between main httpSample elements.
proc ignore_elt {name} {
  if {$name == "testResults"} {
    return 1 
  }
  return 0
}

proc stack_to_string_old {elt_stack} {
  set res {}
  # stack doesn't correctly handle one stack item which is a list, it doesn't return the single item as a list.
  if {[$elt_stack size] == 1} {
    set l [list [$elt_stack peek [$elt_stack size]]] 
  } else {
    set l [$elt_stack peek [$elt_stack size]]
  }
  foreach el $l {
    lappend res "tag: [:tag $el "<no-tag>"]; lt: [det_latency $el]" 
  }
  join $res ", "
}

proc xml_default {data} {
  # log debug "XML default, data=$data" 
}

proc handle_main_sample {sample} {
  global conn dct_insert_stmts jtlfile_id
  # log debug "handle main sample: [first_line $sample]"
  # log debug "latency of main sample: [dict get $sample attrs lt]"
  # breakpoint
  set main_id [insert_sample $sample "" 0]
  # log debug "inserted main sample"
  insert_assertion_results $main_id $sample
  # log debug "inserted assertion results"
  insert_sub_samples $main_id $sample 1
  # log debug "handle main sample: finished"
}

proc insert_sample {sample parent_id level} {
  global conn dct_insert_stmts jtlfile_id
  # log debug "insert_sample: start"
  set dct [:attrs $sample {}] ; # std attrs like t, ts, ...
  dict set dct jtlfile_id $jtlfile_id
  dict set dct parent_id $parent_id
  dict set dct level $level
  dict set dct ts_utc [clock format [expr round(0.001*[:ts $dct 0])] -format "%Y-%m-%d %H:%M:%S" -gmt 1]
  foreach sub_elt [:subelts $sample {}] {
    set sub_tag [:tag $sub_elt]
    if {$sub_tag == "assertionResult"} {
      # ignore here 
    } elseif {$sub_tag == "httpSample"} {
      # ignore here 
    } else {
      dict set dct $sub_tag [:text $sub_elt ""] 
    }
  }
  add_akamai_fields dct
  dict set dct extension [det_extension [:lb $dct]]
  dict set dct domain [det_domain [:lb $dct]]
  set main_id [[:httpsample $dct_insert_stmts] $dct 1]
  # log debug "insert_sample: finished"
  return $main_id  
}

# @todo maybe should use url lib to handle this
# @note by adding checks for webservice and logout it becomes Philips specific
proc det_extension {lb} {
  if {[regexp {^([^?;]+)} $lb z prefix]} {
    # ext max 10 chars
    if {[regexp {\.([^/.]+)$} [string range $prefix end-10 end] z ext]} {
      return $ext 
    } else {
      if {0} {
        # handle in post processing.
        if {[regexp {service} $lb]} {
          return "webservice" 
        } elseif {[regexp {logout} $lb]} {
          return "logout" 
        }
      }
      return "<none>" 
    }
  } else {
    return "<unknown>" 
  }
}

proc det_domain {url} {
  if {[regexp {https?://([^/]+)} $url z domain]} {
    return $domain 
  } else {
    return "<none>" 
  }
}

# @todo somewhat philips/akamai specific, maybe move to seperate file.
# @note use dct as var to minimise copying, memory is an issue here.
# @note nu eerst minder bestaande checken, zijn er toch niet.
proc add_akamai_fields {dct_name} {
  upvar $dct_name dct
  set resp [:responseHeader $dct]
  foreach fieldname {cachetype cacheable expires expiry maxage cachekey} {
    dict set dct $fieldname [det_$fieldname $resp] 
  }
  dict set dct akserver [det_akamaiserver $resp] 
}

proc insert_assertion_results {sample_id sample} {
  global conn dct_insert_stmts jtlfile_id
  foreach sub_elt [:subelts $sample {}] {
    set sub_tag [:tag $sub_elt]
    if {$sub_tag == "assertionResult"} {
      set dct_assert [dict create parent_id $sample_id]
      foreach sub_sub_elt [:subelts $sub_elt {}] {
         dict set dct_assert [:tag $sub_sub_elt] [:text $sub_sub_elt ""] 
      }
      [:assertionresult $dct_insert_stmts] $dct_assert
    }
  }
}

proc insert_sub_samples {sample_id sample level} {
  # log debug "insert_sub_samples in $sample_id: [first_line $sample]"
  global conn dct_insert_stmts jtlfile_id
  foreach sub_elt [:subelts $sample {}] {
    set sub_tag [:tag $sub_elt]
    if {$sub_tag == "httpSample"} {
      # log debug "inserting sub_sample: [first_line $sub_elt]"
      set sub_id [insert_sample $sub_elt $sample_id $level]
      insert_assertion_results $sub_id $sub_elt
      insert_sub_samples $sub_id $sub_elt [expr $level + 1]
      # log debug "inserted sub_sample"      
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

