#!/usr/bin/env tclsh861

package require ndv
package require tdbc::sqlite3

ndv::source_once ssl.tcl pubsub.tcl read-vuserlogs-db-coro.tcl

# [2016-07-09 10:09] for parse_ts and now:
use libdatetime

# Note:
# [2016-02-08 11:13:55] Bug - when logfile contains 0-bytes (eg in Vugen output.txt with log webregfind for PDF/XLS), the script sees this as EOF and misses transactions and errors. [2016-07-09 10:12] this should be solved by reading as binary.

set VUSER_END_ITERATION 1000

proc main {argv} {
  set options {
    {dir.arg "" "Directory with vuserlog files"}
    {db.arg "auto" "SQLite DB location (auto=create in dir)"}
    {ssl "Read SSL data provided log is 'always'"}
    {deletedb "Delete DB before reading"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]

  set logdir [:dir $dargv]
  # lassign $argv logdir
  puts "logdir: $logdir"
  set ssl [:ssl $dargv]
  if {[:db $dargv] == "auto"} {
    set dbname [file join $logdir "vuserlog.db"]
  } else {
    set dbname [:db $dargv]
  }
  if {[:deletedb $dargv]} {
    delete_database $dbname
  }

  read_logfile_dir $logdir $dbname $ssl
}

proc read_logfile_dir {logdir dbname ssl {split_proc split_transname}} {
  global pubsub

  # [2016-08-06 12:09] main is not always entry-point, so call define here.
  define_logreader_handlers
  
  # TODO mss pubsub nog eerder zetten als je read-vuserlogs-dir.tcl gebruikt.
  set pubsub [PubSub new]
  set db [get_results_db $dbname $ssl]
  # $db insert read_status [dict create ts [now] status "starting"]
  add_read_status $db "starting"
  set nread 0
  set db [get_results_db $dbname $ssl]
  set logfiles [concat [glob -nocomplain -directory $logdir *.log] \
                    [glob -nocomplain -directory $logdir *.txt]]
  set pg [CProgressCalculator::new_instance]
  $pg set_items_total [:# $logfiles]
  $pg start
  foreach logfile $logfiles {
    # old with all functionality:
    # readlogfile $logfile $db $ssl $split_proc

    # new with coroutines:
    readlogfile_new_coro $logfile $db $ssl $split_proc
    
    # just for testing:
    # readlogfile_trans $logfile $db
    incr nread
    $pg at_item $nread
  }

  if {$ssl} {
    handle_ssl_global_end $db
  }
  log info "handle_ssl_final_end finished, setting read_status"
  # $db insert read_status [dict create ts [now] status "complete"]
  add_read_status $db "complete"
  log info "set read_status, closing DB"
  $db close
  log info "closed DB"
  log info "Read $nread logfile(s) in $logdir"
}

proc add_read_status {db status} {
  $db insert read_status [dict create ts [now] status $status]
}


#  $db add_tabledef trans {id} {logfile {vuserid int} ts {sec_ts int} transname user {resptime real} {status int}
#                   usecase revisit {transid int} transshort searchcrit}
# functions.c(343): [2015-09-02 05:51:41] [1441165901] trans=CR_UC1_revisit_11_Expand_transactions_DEP, user=u_lpt-rtsec_cr_tso_tso1_000005, resptime=0.156, status=0 [09/02/15 05:51:41]	[MsgId: MMSG-17999]
# Transaction "CR_UC1_ -> deze wordt niet geparsed.
# @param split_proc - for splitting a full transaction name into parts (in a dict)
proc readlogfile {logfile db ssl split_proc} {
  log info "Reading: $logfile"
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
    
  # TODO: 22-10-2015 NdV niet tevreden over error bepaling per iteratie. Met prev_iteration is altijd lastig.
  # liever functioneel oplossen, soort merge, en ook prio van errors bepalen, met pas > timeout > rest.
  set fi [open $logfile rb] ; # read binary, so 0 byte will not signal eof
  $db in_trans {
    # insert logfile within trans; if something fails, this will be rolled back.
    set logfile_id [$db insert logfile [vars_to_dict logfile dirname ts \
                                            filesize runid project script]]
    set linenr 0
    set prev_iteration ""  
    set iteration ""
    set error_iter {}
    set user ""
    set ts ""
    if {$ssl} {
      handle_ssl_start $db $logfile_id $vuserid $iteration  
    }
    set bytes_read 0
    while {[gets $fi line] >= 0} {
		  incr linenr
      incr bytes_read [expr [string length $line] + 2] ; # allow for end-of-line characters.
		  set iteration [get_iteration $line $iteration]
      
		  # possibly handle previous error_iteration
      # TODO: dit stukje kan in losse functie, evt met error_iteration en prev_iteration als var params.
		  if {[is_start_iter $line]} {
        # 22-10-2015 bij elk stukje log krijg je een end, dus ook kijken of de iteratie nu anders is dan de vorige.
        if {$iteration != $prev_iteration} {
          if {$prev_iteration != ""} {
            insert_error_iter $db $logfile_id [file tail $logfile] $vuserid $prev_iteration $error_iter
          }
          set error_iter {}
          set prev_iteration $iteration
        }
		  }

      # TODO: [2016-06-17 15:48:17] retraccts not used anymore?
      # [2016-07-31 16:30] removed.
		  # handle_retraccts $line $db $logfile_id $vuserid $linenr $iteration
		  lassign [handle_trans $line $db $logfile_id [file tail $logfile] $vuserid \
                   $linenr $iteration $split_proc] user2 ts2

      # TODO: wat wil ik met user2/ts2, vast goede reden? 
      if {$user2 != ""} {
        log debug "Setting user: $user2"
        set user $user2
      }
      if {$ts2 != ""} {
        log debug "Settings ts: $ts2"
        set ts $ts2
      }
		  set error [handle_error $line $db [file tail $logfile] $logfile_id $vuserid $linenr $iteration $ts $user]
		  set error_iter [update_error_iter $error_iter $error]
      if {$ssl} {
        handle_ssl_line $db $logfile_id $vuserid $iteration $line $linenr  
      }
    } ; # end of while gets
	  log info "Last line number: $linenr"
    if {$bytes_read < [file size $logfile]} {
      log warn "Number of bytes read ($bytes_read) < file size ([file size $logfile])"
      add_read_status $db "$logfile: Number of bytes read ($bytes_read) < file size ([file size $logfile])"
      # breakpoint
    }
    insert_error_iter $db $logfile_id [file tail $logfile] $vuserid $prev_iteration \
        $error_iter
    if {![eof $fi]} {
      log warn "Not EOF yet for $logfile, linenr=$linenr, possibly a 0-byte."
    }
    if {$ssl} {
      handle_ssl_end $db $logfile_id $vuserid $iteration  
    }
    fill_table_trans $db
  };  # end of $db in_trans
  close $fi
}

proc is_logfile_read {db logfile} {
  # if query returns 1 record, return 1=true, otherwise 0=false.
  :# [$db query "select 1 from logfile where logfile='$logfile'"]
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

#Start auto log messages stack - Iteration 1.	[MsgId: MMSG-10545]
#End auto log messages stack.	[MsgId: MMSG-10544]
#functions.c(334): [2016-02-08 10:11:49] [1454922709] trans=CR_UC1_NewVisit_01_Open_Loginpage_FXF, user=u_lpt-rtsec_cr_tso_tso1_000001, resptime=2.434, status=0, iteration=1 [02/08/16 10:11:49]
proc get_iteration {line iteration} {
  global VUSER_END_ITERATION pubsub
  set new_it "unchanged"
  
  if {[regexp {Start auto log messages stack - Iteration (\d+)\.} $line z it]} {
    check_iteration_max $it
    set new_it $it
  }
  if {[regexp {End auto log messages stack.} $line]} {
    set new_it ""
  }
  if {[regexp {, iteration=(\d+)} $line z it]} {
    check_iteration_max $it
    set new_it $it
  }

  if {[regexp {Starting iteration (\d+)} $line z it]} {
    check_iteration_max $it
    set new_it $it
  }

  if {[regexp {Ending iteration (\d+)} $line z it]} {
    check_iteration_max $it
    set new_it $it
  }
  
  if {[regexp {Starting action vuser_end.}	$line]} {
    # return "vuser_end"
    set new_it $VUSER_END_ITERATION
  }

  if {($new_it != "unchanged") && ($iteration != $new_it)} {
    set iteration $new_it
    $pubsub pub iteration $iteration
  }
  return $iteration
}

proc check_iteration_max {it} {
  global VUSER_END_ITERATION
  if {$it >= $VUSER_END_ITERATION} {
    error "Read iteration nr >= $VUSER_END_ITERATION, increase this one!"
  }
}

proc is_end_iter {line} {
  regexp {End auto log messages stack} $line
}

proc is_start_iter {line} {
  regexp {Start auto log messages stack} $line
}

# [2016-07-30 21:18] TODO: clean this one up, based on latest version of rb_end_transaction.
proc handle_trans {line db logfile_id logfile vuserid linenr iteration split_proc} {
  # TODO: parse name/value pairs differently, so more can be added in the future.
  if {[regexp {: \[([0-9 :.-]+)\] trans=([^ ]+), user=([^ ,]+), resptime=([0-9.,-]+), status=([0-9-]+)} \
                 $line z ts transname user resptime trans_status]} {
    # [2016-06-15 10:23:22] timestamp incl milliseconds
    # [2016-07-30 21:18] TODO: possibly this variant is the only one needed now.
    # functions.c(377): [2016-06-09 15:52:22.096] trans=CR_UC3_newuser_01_Login_Cras_QQQ, user=3002568887, resptime=-1.000, status=-1, iteration=1 [06/09/16 15:52:22]
    set sec_ts [parse_ts $ts]
    regsub -all {,} $resptime "." resptime

    $db insert trans_line [dict merge [vars_to_dict logfile_id logfile vuserid \
                                           ts sec_ts transname \
                                       user resptime trans_status linenr iteration] \
                               [$split_proc $transname]]
    
    return [list $user $ts]
  } elseif {[regexp {trans=} $line]} {
    # [2016-07-31 11:54] trans= always signals transaction log line?
    breakpoint
  }
  return [list "" ""]
}

proc handle_trans_old {line db logfile_id vuserid linenr iteration} {
  if {[regexp {: \[([0-9 :-]+)\] \[(\d+)\] trans: ([^ ]+) - user: (\d+), resptime: ([0-9.,]+)} \
           $line z ts sec_ts transname user resptime]} {
    regsub -all {,} $resptime "." resptime
    $db insert trans [vars_to_dict logfile_id vuserid ts sec_ts transname user resptime linenr iteration]
    return [list $user $ts]
  } elseif {[regexp {: \[([0-9 :-]+)\] \[(\d+)\] trans=([^ ]+), user=([^ ,]+), resptime=([0-9.,-]+), status=([0-9-]+)} \
                 $line z ts sec_ts transname user resptime status]} {
    regsub -all {,} $resptime "." resptime
    lassign [split_transname $transname] usecase revisit transid transshort searchcrit
    $db insert trans [vars_to_dict logfile_id vuserid ts sec_ts transname user resptime status usecase \
                          revisit transid transshort searchcrit linenr iteration]
    return [list $user $ts]
  } elseif {[regexp {: \[([0-9 :.-]+)\] trans=([^ ]+), user=([^ ,]+), resptime=([0-9.,-]+), status=([0-9-]+)} \
                 $line z ts transname user resptime status]} {
    # [2016-06-15 10:23:22] timestamp incl milliseconds
    # functions.c(377): [2016-06-09 15:52:22.096] trans=CR_UC3_newuser_01_Login_Cras_QQQ, user=3002568887, resptime=-1.000, status=-1, iteration=1 [06/09/16 15:52:22]
    set sec_ts [parse_cet $ts]
    regsub -all {,} $resptime "." resptime
    lassign [split_transname $transname] usecase revisit transid transshort searchcrit
    $db insert trans [vars_to_dict logfile_id vuserid ts sec_ts transname user resptime status usecase \
                          revisit transid transshort searchcrit linenr iteration]
    return [list $user $ts]
  } elseif {[regexp {trans=CR_UC} $line]} {
    breakpoint
  }
  return [list "" ""]
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

# TODO: this one is not working anymore with all different kinds of transnames, should
# have separate one per project/script.
proc split_transname_old {transname} {
 #regexp {^([^ ]{0,5}_UC\d+)_([^ _]+)_(\d+)_([^ ]+?)_([^_]+)$} $transname z usecase revisit transid transshort searchcrit

  if {[regexp {^([^ ]{0,5}_UC\d+)_([^ _]+)_(\d+)_([^ ]+?)_([^ _]+)$} $transname z usecase revisit transid transshort searchcrit]} {
    list $usecase $revisit $transid $transshort $searchcrit
  } elseif {[regexp {^([^_]+)_(\d+)_(.+)_([^_]+)$} $transname z usecase transid transshort revisit]} {
    # CBW_01_Login_newuser
    list $usecase $revisit $transid $transshort ""
  } elseif {[regexp {^([^_]+)_(.+)_([^_]+)$} $transname z usecase transshort revisit]} {
    # RCC_Login_newuser
    list $usecase $revisit "" $transshort ""
  } elseif {[regexp {^([^0-9]+)_([^_]+)_(\d+)_(.+)$} $transname z usecase revisit transid transshort]} {
    # TrSec_RCM_newuser_01_Login
    list $usecase $revisit $transid $transshort ""
  } elseif {[regexp {^([^_]+)_([0-9.]+)_(.+)_([^_]+)$} $transname z usecase transid transshort revisit]} {
    # DotCom_2.01_Open_the_homepage_NewVisit
    list $usecase $revisit $transid $transshort ""    
  } else {
    puts "Transname niet te splitten: $transname"
	# [2016-05-31 13:07:39] deze komt voor bij Calypso, niet eigen script. Dan alleen transshort=trans
    # breakpoint
    # list "" "" 0 "" ""
	list "" "" 0 $transname ""
  }
}


# Login_cert_main.c(71): Error -26368: "Text=Uw pas is niet correct" found for web_global_verification (count=1)  	[MsgId: MERR-26368]
#Login_cert_main.c(71): Error -26368: "Text=Uw pas is niet correct" found for web_global_verification ("User:3001412900 pas") (count=1)  	[MsgId: MERR-26368]
#Login_cert_main.c(71): Error -35049: No match found for the requested parameter "Marktoverzicht". Check whether the requested regular expression exists in the response data  	[MsgId: MERR-35049]

#PDF_Download_UC3.c(16): Continuing after Error -27789: Server "securepat01.rabobank.com" has shut down the connection prematurely  	[MsgId: MERR-27789]
#PDF_Download_UC3.c(16): Continuing after Error -26366: "Text=%PDF" not found for web_reg_find  	[MsgId: MERR-26366]
#PDF_Download_UC3.c(16): Continuing after Error -26374: The above "not found" error(s) may be explained by header and body byte counts being 0 and 0, respectively.  	[MsgId: MERR-26374]

proc handle_error {line db logfile logfile_id vuserid linenr iteration ts user} {
  # vullen: user errornr errortype
  # ook: functions.c(427): Error: Previous web_reg_find failed while response bytes > 0: Text=PDF-1.4 [01/19/16 03:18:28] [MsgId: MERR-17999]
  if {[regexp {^([^ ]+)\((\d+)\): (Continuing after )?Error ?([0-9-]*): (.*)$} $line z srcfile srclinenr z errornr rest]} {
    # set ts "" ; # mss later nog af te leiden.
    lassign [det_error_details $rest] errortype user2 level details
    if {$user2 != ""} {
      set user $user2
    }
    set sec_ts [parse_ts $ts]
    # log debug "inserting error: [vars_to_dict logfile logfile_id vuserid linenr iteration srcfile srclinenr ts user errornr errortype details line]"
    $db insert error [vars_to_dict logfile logfile_id vuserid linenr iteration srcfile srclinenr ts sec_ts user errornr errortype details line]
    return [list $errortype $user $level]
  } elseif {[regexp {: Error: } $line]} {
    log error "Error line in log, but could not parse: $line"
    breakpoint
  }
  return {}
}

#Login_cert_main.c(71): Error -26368: "Text=Uw pas is niet correct" found for web_global_verification ("User:3001412900 pas") (count=1)  	[MsgId: MERR-26368]
#Homepage.c(20): Error -26366: "Text=Sustainability" not found for web_reg_find  	[MsgId: MERR-26366]
# [2015-12-16 14:19:37] hier level bij te zetten? Als hoger, dan deze bij iteratie noemen.
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

proc update_error_iter {error_iter error} {
  if {$error == {}} {
    return $error_iter
  } else {
    lassign $error_iter etp_iter user_iter level_iter
    lassign $error etp user level
    if {$user_iter == ""} {
      set user_iter $user
    }
    if 0 {
      # 21-10-2015 NdV hier nu specifieke handling van bepaalde fouten, mogelijk prio geven: foute pas, netwerk timeout, de rest.
      if {$etp_iter == "pas_niet_correct"} {
        # niets, al hoogste niveau
      } elseif {[regexp {timeout} $etp_iter]} {
        # alleen foute pas kan nog overrulen.
        if {$etp == "pas_niet_correct"} {
          set etp_iter $etp
        }
      } else {
        # voorlopig zet error_iter op error
        set etp_iter $etp
      }
    }
    if {$level > $level_iter} {
      set level_iter $level
      set etp_iter $etp
    }
    return [list $etp_iter $user_iter $level_iter]
  }
}

# @param error_iter: [list errortype user] or empty
proc insert_error_iter {db logfile_id logfile vuserid iteration error_iter} {
  if {$iteration == ""} {
    # [2016-04-18 15:45:39] deze kan voorkomen als er geen error in de log staat.
    # log warn "Empty iteration: $logfile_id $logfile $vuserid $iteration $error_iter"
    return
  }
  if {$error_iter != {}} {
    lassign $error_iter errortype user level
    # TODO evt level ook in DB.
    set script [det_script $logfile]
    try_eval {
      $db insert error_iter [vars_to_dict logfile_id logfile vuserid iteration user errortype script]
    } {
      breakpoint
    }
  }
}

proc det_script {logfile} {
  if {[regexp {^(.+)_\d+\.log} [file tail $logfile] z sc]} {
    return $sc
  } else {
    return "Unknown"
  }
}

# deze mogelijk in libdb:
proc get_results_db {db_name ssl} {
  global pubsub
  #breakpoint
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db $ssl
  if {$ssl} {
    # TODO: deze eigenlijk op zelfde niveau als waar je handle_ssl_global_end aanroept.
    # maar wat lastig omdat table defs hier moeten.
    handle_ssl_global_start $db $pubsub
  }
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs. 1: drop tables first.
  if {!$existing_db} {
    log info "New db: $db_name, create tables"
    # create_indexes $db
  } else {
    log info "Existing db: $db_name, don't create tables"
  }
  $db prepare_insert_statements
  #breakpoint
  return $db
}

proc define_tables {db ssl} {
  # [2016-07-31 12:01] sec_ts is a representation of a timestamp in seconds since the epoch
  $db def_datatype {sec_ts resptime} real
  $db def_datatype {.*id filesize .*linenr.* trans_status iteration.*} integer
  
  # default is text, no need to define, just check if it's consistent
  # [2016-07-31 12:01] do want to define that everything starting with ts is a time stamp/text:
  $db def_datatype {status ts.*} text

  $db add_tabledef read_status {id} {ts status}
  
  $db add_tabledef logfile {id} {logfile dirname ts filesize \
                                     runid project script}

  set logfile_fields {logfile_id logfile vuserid}
  set line_fields {linenr ts sec_ts iteration}
  set line_start_fields [map [fn x {return "${x}_start"}] $line_fields]
  set line_end_fields [map [fn x {return "${x}_end"}] $line_fields]
  set trans_fields {transname user resptime trans_status usecase
    revisit transid transshort searchcrit}
  
  # 17-6-2015 NdV transaction is a reserved word in SQLite, so use trans as table name
  $db add_tabledef trans_line {id} [concat $logfile_fields $line_fields $trans_fields]
  $db add_tabledef trans {id} [concat $logfile_fields $line_start_fields \
                                   $line_end_fields $trans_fields]
  
  $db add_tabledef error {id} [concat $logfile_fields $line_fields \
                                   srcfile srclinenr user errornr errortype details \
                                   line]
                   
  # 22-10-2015 NdV ook errors per iteratie, zodat er een hoofd schuldige is aan te wijzen voor het falen.
  $db add_tabledef error_iter {id} [concat $logfile_fields script \
                                        iteration user errortype]

  if {$ssl} {
    ssl_define_tables $db  
  }
}

proc delete_database {dbname} {
  log info "delete database: $dbname"
  # error nietgoed
  set ok 0
  catch {
    file delete $dbname
    set ok 1
  }
  if {!$ok} {
    set db [dbwrapper new $dbname]
    foreach table {error trans retraccts logfile} {
      # $db exec "delete from $table"
      $db exec "drop table $table"
    }
    $db close
  }
}

# split transaction name in parts to store in DB. Proc should return a dict with a subset of the following fields:
# usecase, revisit, transid, transshort, searchcrit
# TODO: this one now in two places, also .bld/config.tcl
proc split_transname {transname} {
  regexp {^([^_]+)_(.+)$} $transname z usecase transshort
  dict create usecase $usecase transshort $transshort
}

# mainly used for quicker testing of fill_table_trans
proc readlogfile_trans {logfile db} {
  $db in_trans {
    fill_table_trans $db
  }
}

# this runs within the main db transaction for reading a logfile.
# goal is to full trans table based on trans_line table.
# maybe need to be memory conscious and not return all rows in memory at once.
proc fill_table_trans {db} {
  $db exec "delete from trans"
  set query "select logfile_id, logfile, vuserid, linenr, ts, sec_ts, iteration,
 transname, user, resptime, trans_status, usecase, revisit, transid, transshort,
 searchcrit
from trans_line order by logfile_id, linenr"
  set user ""; set iteration 0
  set started_transactions [dict create]
  # TODO: gaat dit goed met >1 file? Mss niet meer relevant als coroutine versie compleet is.
  foreach row [$db query $query] {
    if {[new_user_iteration? $row $user $iteration]} {
      insert_trans_not_finished $db $started_transactions
      set started_transactions [dict create]
      set user [:user $row]
      set iteration [:iteration $row]
      # dict_assign $row user iteration
    }
    switch [:trans_status $row] {
      -1 {
        # start of a transaction, keep data for now.
        dict set started_transactions [:transname $row] $row
      }
      0 {
        # succesful end of a transaction, find start data and insert row.
        insert_trans_finished $db $row $started_transactions
        dict unset started_transactions [:transname $row]
      }
      1 {
        # synthetic error, just insert.
        insert_trans_error $db $row
      }
      4 {
        # functional warning, eg. no FT's available to approve.
        insert_trans_finished $db $row $started_transactions
      }
      default {
        error "Unknown transaction status: [:trans_status $row]"
      }
    } ; # end-switch
  } ; # end-foreach
  insert_trans_not_finished $db $started_transactions
}

# return 1 iff either old user or old iteration differs from new one in row
proc new_user_iteration? {row user iteration} {
  if {($user != [:user $row]) || ($iteration != [:iteration $row])} {
    return 1
  }
  return 0
}

proc insert_trans_not_finished {db started_transactions} {
  set line_fields {linenr ts sec_ts iteration}
  set line_start_fields [map [fn x {return "${x}_start"}] $line_fields]
  foreach row [dict values $started_transactions] {
    set d [dict_rename $row $line_fields $line_start_fields]
    $db insert trans $d
  }
}

proc make_trans_not_finished {started_transactions} {
  set res [list]
  set line_fields {linenr ts sec_ts iteration}
  set line_start_fields [map [fn x {return "${x}_start"}] $line_fields]
  foreach row [dict values $started_transactions] {
    set d [dict_rename $row $line_fields $line_start_fields]
    # $db insert trans $d
    lappend res $d
  }
  return $res
}

proc insert_trans_finished_old {db row started_transactions} {
  set line_fields {linenr ts sec_ts iteration}
  set line_start_fields [map [fn x {return "${x}_start"}] $line_fields]
  set line_end_fields [map [fn x {return "${x}_end"}] $line_fields]
  #set no_start 0
  set rowstart [dict_get $started_transactions [:transname $row]]
  if {$rowstart == {}} {
    # probably a synthetic transaction. Some minor error.
    set rowstart $row
    #set no_start 1
  }
  set dstart [dict_rename $rowstart $line_fields $line_start_fields]
  set dend [dict_rename $row $line_fields $line_end_fields]
  set d [dict merge $dstart $dend]
  $db insert trans $d
}

proc insert_trans_finished {db row started_transactions} {
  $db insert trans [make_trans_finished $row $started_transactions]
}

proc make_trans_finished {row started_transactions} {
  set line_fields {linenr ts sec_ts iteration}
  set line_start_fields [map [fn x {return "${x}_start"}] $line_fields]
  set line_end_fields [map [fn x {return "${x}_end"}] $line_fields]
  #set no_start 0
  set rowstart [dict_get $started_transactions [:transname $row]]
  if {$rowstart == {}} {
    # probably a synthetic transaction. Some minor error.
    set rowstart $row
    #set no_start 1
  }
  set dstart [dict_rename $rowstart $line_fields $line_start_fields]
  set dend [dict_rename $row $line_fields $line_end_fields]
  set d [dict merge $dstart $dend]
  return $d
}

proc make_trans_error {row} {
  set line_fields {linenr ts sec_ts iteration}
  set line_start_fields [map [fn x {return "${x}_start"}] $line_fields]  
  set line_end_fields [map [fn x {return "${x}_end"}] $line_fields]
  set d [dict_rename $row $line_fields $line_end_fields]
  set d2 [dict merge $d [dict_rename $row $line_fields $line_start_fields]]
  # breakpoint
  return $d2
}


proc insert_trans_error_old {db row} {
  # geen start velden, dus alleen row-waarden naar end velden omzetten.
  set line_fields {linenr ts sec_ts iteration}
  set line_start_fields [map [fn x {return "${x}_start"}] $line_fields]  
  set line_end_fields [map [fn x {return "${x}_end"}] $line_fields]
  set d [dict_rename $row $line_fields $line_end_fields]
  set d2 [dict merge $d [dict_rename $row $line_fields $line_start_fields]]
  $db insert trans $d2
}

proc insert_trans_error {db row} {
  # $db insert trans $d2
  $db insert trans [make_trans_error $row]
}

# TODO: move to libdict:
# rename fields in lfrom to lto and return new dict.
proc dict_rename {d lfrom lto} {
  set res $d
  foreach f $lfrom t $lto {
    # [2016-08-02 13:38:19] could be keys in from are not available.
    dict set res $t [dict_get $d $f]
    dict unset res $f
  }
  return $res
}

if {[this_is_main]} {
  set_log_global perf {showfilename 0}
  log debug "This is main, so call main proc"
  set_log_global debug {showfilename 0}  
  main $argv  
} else {
  log debug "This is not main, don't call main proc"
}

