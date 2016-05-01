#!/usr/bin/env tclsh861

package require ndv
package require tdbc::sqlite3

ndv::source_once ssl.tcl
# TODO:
# [2016-02-08 11:13:55] Bug - when logfile contains 0-bytes (eg in Vugen output.txt with log webregfind for PDF/XLS), the script sees this as EOF and misses transactions and errors.

set_log_global debug

proc main {argv} {
  set options {
    {dir.arg "" "Directory with vuserlog files"}
    {db.arg "auto" "SQLite DB location (auto=create in dir)"}
    {deletedb "Delete DB before reading"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]

  set logdir [:dir $dargv]
  # lassign $argv logdir
  puts "logdir: $logdir"
  if {[:db $dargv] == "auto"} {
    set dbname [file join $logdir "vuserlog.db"]
  } else {
    set dbname [:db $dargv]
  }
  if {[:deletedb $dargv]} {
    delete_database $dbname
  }
  set db [get_results_db $dbname]
  set nread 0
  foreach logfile [glob -nocomplain -directory $logdir *.log] {
    readlogfile $logfile $db
    incr nread
  }
  # [2016-02-08 10:55:16] NdV kan ook van Vugen log zijn: output.txt.
  foreach logfile [glob -nocomplain -directory $logdir *.txt] {
    readlogfile $logfile $db
    incr nread
  }
  log info "Read $nread logfile(s)"
}

#  $db add_tabledef trans {id} {logfile {vuserid int} ts_cet {sec_cet int} transname user {resptime real} {status int}
#                   usecase revisit {transid int} transshort searchcrit}
# functions.c(343): [2015-09-02 05:51:41] [1441165901] trans=CR_UC1_revisit_11_Expand_transactions_DEP, user=u_lpt-rtsec_cr_tso_tso1_000005, resptime=0.156, status=0 [09/02/15 05:51:41]	[MsgId: MMSG-17999]
# Transaction "CR_UC1_ -> deze wordt niet geparsed.
proc readlogfile {logfile db} {
  log info "Reading: $logfile"
  set ts_cet [clock format [file mtime $logfile] -format "%Y-%m-%d %H:%M:%S"]
  # set logfile [file tail $logfilepath]
  set vuserid [det_vuserid $logfile]
  
  # $db add_tabledef logfile {id} {logfile dirname ts_cet filesize runid project}
  
  set dirname [file dirname $logfile]
  set filesize [file size $logfile]
  lassign [det_project_runid_script $logfile] project runid script
  
  #log info "Net voor nieuwe insert logfile"
  # breakpoint
  
  set logfile_id [$db insert logfile [vars_to_dict logfile dirname ts_cet filesize runid project script]]
  
  #log info "ending now"
  #exit
  
  # TODO 22-10-2015 NdV niet tevreden over error bepaling per iteratie. Met prev_iteration is altijd lastig.
  # liever functioneel oplossen, soort merge, en ook prio van errors bepalen, met pas > timeout > rest.
  set fi [open $logfile r]
  $db in_trans {
    set linenr 0
    set prev_iteration ""  
    set iteration ""
    set error_iter {}
    set user ""
    set ts_cet ""
    handle_ssl_start $db $logfile_id $vuserid $iteration
	  while {[gets $fi line] >= 0} {
		  incr linenr

		  set iteration [get_iteration $line $iteration]
      if {$iteration == ""} {
        #log debug "iteration is empty, reset user and ts_cet, linenr=$linenr, line=$line"
        #set user ""
        #set ts_cet ""
      }
      
		  # possibly handle previous error_iteration
		  if {[is_start_iter $line]} {
        # 22-10-2015 bij elk stukje log krijg je een end, dus ook kijken of de iteratie nu anders is dan de vorige.
        # #   $db add_tabledef error_iter {id} {logfile_id logfile {vuserid int} {iteration int} user errortype}
        if {$iteration != $prev_iteration} {
          if {$prev_iteration != ""} {
            insert_error_iter $db $logfile_id [file tail $logfile] $vuserid $prev_iteration $error_iter
          }
          set error_iter {}
          set prev_iteration $iteration
        }
		  }
		  
		  handle_retraccts $line $db $logfile_id $vuserid $linenr $iteration
		  lassign [handle_trans $line $db $logfile_id $vuserid $linenr $iteration] user2 ts_cet2
      if {$user2 != ""} {
        log debug "Setting user: $user2"
        set user $user2
      }
      if {$ts_cet2 != ""} {
        log debug "Settings ts_cet: $ts_cet2"
        set ts_cet $ts_cet2
      }
		  set error [handle_error $line $db [file tail $logfile] $logfile_id $vuserid $linenr $iteration $ts_cet $user]
		  set error_iter [update_error_iter $error_iter $error]
      handle_ssl_line $db $logfile_id $vuserid $iteration $line $linenr
    }
	  log info "Last line number: $linenr"
    
    insert_error_iter $db $logfile_id [file tail $logfile] $vuserid $prev_iteration $error_iter
  }
  if {![eof $fi]} {
    log warn "Not EOF yet for $logfile, linenr=$linenr"
  }
  handle_ssl_end $db $logfile_id $vuserid $iteration
  close $fi
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
  if {[regexp {Start auto log messages stack - Iteration (\d+)\.} $line z it]} {
    return $it
  }
  if {[regexp {End auto log messages stack.} $line]} {
    return ""
  }
  if {[regexp {, iteration=(\d+)} $line z it]} {
    return $it
  }

  if {[regexp {Starting iteration (\d+)} $line z it]} {
    return $it
  }

  if {[regexp {Ending iteration (\d+)} $line z it]} {
    return ""
  }
  
  if {[regexp {Starting action vuser_end.}	$line]} {
    return "vuser_end"
  }
  
  return $iteration ; # keep current iteration nr.
}

proc is_end_iter {line} {
  regexp {End auto log messages stack} $line
}

proc is_start_iter {line} {
  regexp {Start auto log messages stack} $line
}

proc handle_retraccts {line db logfile_id vuserid linenr iteration} {
  if {[regexp {: \[([0-9 :-]+)\] \[(\d+)\] RetrieveAccounts - user: (\d+), naccts: (\d+), resptime: ([0-9.,]+)} $line z ts_cet sec_cet user naccts resptime]} {
    regsub -all {,} $resptime "." resptime
    $db insert retraccts [vars_to_dict logfile_id vuserid ts_cet sec_cet user naccts resptime]
  } elseif {[regexp {RetrieveAccounts} $line]} {
    breakpoint
  }
}

proc handle_trans {line db logfile_id vuserid linenr iteration} {
  if {[regexp {: \[([0-9 :-]+)\] \[(\d+)\] trans: ([^ ]+) - user: (\d+), resptime: ([0-9.,]+)} \
           $line z ts_cet sec_cet transname user resptime]} {
    regsub -all {,} $resptime "." resptime
    $db insert trans [vars_to_dict logfile_id vuserid ts_cet sec_cet transname user resptime linenr iteration]
    return [list $user $ts_cet]
  } elseif {[regexp {: \[([0-9 :-]+)\] \[(\d+)\] trans=([^ ]+), user=([^ ,]+), resptime=([0-9.,-]+), status=([0-9-]+)} \
                 $line z ts_cet sec_cet transname user resptime status]} {
    regsub -all {,} $resptime "." resptime
    lassign [split_transname $transname] usecase revisit transid transshort searchcrit
    $db insert trans [vars_to_dict logfile_id vuserid ts_cet sec_cet transname user resptime status usecase \
                          revisit transid transshort searchcrit linenr iteration]
    return [list $user $ts_cet]
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
    error "Could not determine vuser from logfile: $logfile"
  }
}

proc split_transname {transname} {
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
    breakpoint
    list "" "" 0 "" ""
  }
}


# Login_cert_main.c(71): Error -26368: "Text=Uw pas is niet correct" found for web_global_verification (count=1)  	[MsgId: MERR-26368]
#Login_cert_main.c(71): Error -26368: "Text=Uw pas is niet correct" found for web_global_verification ("User:3001412900 pas") (count=1)  	[MsgId: MERR-26368]
#Login_cert_main.c(71): Error -35049: No match found for the requested parameter "Marktoverzicht". Check whether the requested regular expression exists in the response data  	[MsgId: MERR-35049]

#PDF_Download_UC3.c(16): Continuing after Error -27789: Server "securepat01.rabobank.com" has shut down the connection prematurely  	[MsgId: MERR-27789]
#PDF_Download_UC3.c(16): Continuing after Error -26366: "Text=%PDF" not found for web_reg_find  	[MsgId: MERR-26366]
#PDF_Download_UC3.c(16): Continuing after Error -26374: The above "not found" error(s) may be explained by header and body byte counts being 0 and 0, respectively.  	[MsgId: MERR-26374]

proc handle_error {line db logfile logfile_id vuserid linenr iteration ts_cet user} {
  # vullen: user errornr errortype
  # ook: functions.c(427): Error: Previous web_reg_find failed while response bytes > 0: Text=PDF-1.4 [01/19/16 03:18:28] [MsgId: MERR-17999]
  if {[regexp {^([^ ]+)\((\d+)\): (Continuing after )?Error ?([0-9-]*): (.*)$} $line z srcfile srcline z errornr rest]} {
    # set ts_cet "" ; # mss later nog af te leiden.
    lassign [det_error_details $rest] errortype user2 level details
    if {$user2 != ""} {
      set user $user2
    }
    log debug "inserting error: [vars_to_dict logfile logfile_id vuserid linenr iteration srcfile srcline ts_cet user errornr errortype details line]"
    $db insert error [vars_to_dict logfile logfile_id vuserid linenr iteration srcfile srcline ts_cet user errornr errortype details line]
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
proc get_results_db {db_name} {
  #breakpoint
  set existing_db [file exists $db_name]
  set db [dbwrapper new $db_name]
  define_tables $db
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

if 0 {
functions.c(278): [2015-06-15 10:28:06] [1434356886] trans: CBW_01_Log_in_page - user: 3002161992, resptime: 1,055	[MsgId: MMSG-17999]
functions.c(278): [2015-06-15 10:28:14] [1434356894] trans: CBW_02A_CRAS_log_in_OK - user: 3002161992, resptime: 3,183	[MsgId: MMSG-17999]
functions.c(278): [2015-06-15 10:28:22] [1434356902] trans: CBW_03_Sprocket - user: 3002161992, resptime: 1,821	[MsgId: MMSG-17999]

}

proc define_tables {db} {
  $db add_tabledef logfile {id} {logfile dirname ts_cet {filesize int} {runid int} project script}

  $db add_tabledef retraccts {id} {logfile_id {vuserid int} {linenr int} ts_cet {sec_cet int} user {naccts int} {resptime real}}
  # 17-6-2015 NdV transaction is a reserved word in SQLite, so use trans as table name
  # $db add_tabledef trans {id} {logfile {vuserid int} ts_cet {sec_cet int} transname user {resptime real}}
  $db add_tabledef trans {id} {logfile_id {vuserid int} {linenr int} ts_cet {sec_cet int} transname user {resptime real} {status int}
                   {iteration int} usecase revisit {transid int} transshort searchcrit}
  $db add_tabledef error {id} {logfile_id logfile {vuserid int} {linenr int} {iteration int} srcfile {srcline int} ts_cet user errornr errortype details line}
                   
  # 22-10-2015 NdV ook errors per iteratie, zodat er een hoofd schuldige is aan te wijzen voor het falen.
  $db add_tabledef error_iter {id} {logfile_id logfile script {vuserid int} {iteration int} user errortype}
  
  ssl_define_tables $db
  
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

if {[this_is_main]} {
  log info "This is main, so call main proc"
  main $argv  
} else {
  log info "This is not main, don't call main proc"
}

