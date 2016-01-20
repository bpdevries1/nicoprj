package require ndv

# read vugen output.txt (log) file and put results in sqlite DB.
# tables: user_result

ndv::source_once lib_userresults.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# $log set_file "[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

proc main {argv} {
  global log
  lassign $argv logfilepath
  set logfilename [file tail $logfilepath]
  set dbname [file join [file dirname $logfilepath] "userresults.db"]
  set db [get_results_db $dbname]
  set ts_cet [clock format [file mtime $logfilepath] -format "%Y-%m-%d %H:%M:%S"]
  
  set outfilename "$logfilepath.results"
  # out format (tsv): user, result, iteration, notes
  # set fi [open $logfilepath r]
  set fi [open $logfilepath rb] 
  set fo [open $outfilename w]
  puts $fo [join [list user status iteration nacts R_getaccts notes] "\t"]
  set iteration "<none>"
  set user "<none>"
  set status "<none>"
  set notes ""
  set nacts -1
  set R_getaccts -1
  $log debug "start reading log file: $logfilepath"
  set linenr 0
  $db in_trans {
	  while {![eof $fi]} {
      gets $fi line
      $log trace "read line: $line"
      incr linenr
      if {$linenr < 0} {
        break ; # for testing.
      }
      if {[regexp {Starting iteration (\d+)\.} $line z it]} {
        $log info "read starting iteration: $it"
        set iteration $it
        set user ""
        set status ""
        set reason ""
        set notes ""
        set nacts ""
        set R_getaccts ""
      }

      if {[regexp {Ending iteration \d+\.} $line]} {
        $log info "read ending iteration: $line"
        puts $fo [join [list $user $status $iteration $nacts $R_getaccts $notes] "\t"]
        $db insert user_result [vars_to_dict user status reason iteration nacts R_getaccts notes logfilename ts_cet linenr]
        set user ""
        set status ""
        set reason ""
        set notes ""
        set nacts ""
        set R_getaccts ""
      }
      
      # generic checks
      # 10-8-2015 NdV extra generic:
      if {[regexp {Transaction .([^ ]+). ended with a .([^ ]+). status} $line z transname result]} {
        $log debug "$transname: $result"
        if {$result == "Fail"} {
          set status "error"
          # append notes "Notify:   Transaction .04_Create_dashboard. ended with .Fail. status"
          append notes $line
        }
        # add transaction to db
        # $db add_tabledef trans {id} {user iteration transname result line ts_cet}
        $db insert trans [vars_to_dict user iteration transname result line logfilename ts_cet linenr]
      }

      # Search_Customer.c(62): Notify: Transaction "CR_UC1_revisit_99_Customer_not_found_DEP" set.
      if {[regexp {Transaction "([^ ]+)" set.} $line z transname]} {
        if {[regexp {_99_} $transname]} {
          set result "Warning"
          set status "Warning"
        } else {
          set result "Unknown"
        }
        $db insert trans [vars_to_dict user iteration transname result line ts_cet]
      }
      
      # Create_dashboard.c(254): Error -26374:
      if {[regexp {^[^ ]+.c\(\d+\): Error } $line]} {
        set status "error"
        append notes $line
      }
      
      # get user id
      # Login_cras.c(22): Notify: Parameter Substitution: parameter "Userid" =  "3002547091"
      # Login_userpw.c(85): Notify: Parameter Substitution: parameter "Userid" =  "u_lpt-rtsec_cr_tso_tso1_000001"
      if {[regexp -nocase {Parameter Substitution: parameter .user(id)?. *= *"([^ ]+)"} $line z z us]} {
        set user $us
      }
      
      # CBW specific
      
      # maak_groep.c(128): Notify: Transaction "CBW_06_Maak_groep_opslaan" ended with a "Pass" status (Duration: 1.2452 Wasted Time: 0.0083).
      # Login_and_Logout.c(102): Notify: Transaction "CBW_92_Confirm_log_out" ended with a "Pass" status (Duration: 0.4602 Wasted Time: 0.0029).
      if {[regexp {Confirm_log_out} $line]} {
        # breakpoint
      }
      if {[regexp {Transaction [^ ]+92_Confirm_log_out. ended with a "Pass" status} $line]} {
        set status "ok"
        # breakpoint
        # set notes ""
      }
      if {[regexp {Notify: Transaction [^ ]+04_Create_dashboard. ended with .Fail. status} $line]} {
        set status "error"
        # append notes "Notify: Transaction .04_Create_dashboard. ended with .Fail. status"
        append notes $line
      }
      
      if {[regexp {05Q_No_Accounts} $line]} {
        set status "error"
        # set notes "No accounts;$notes"
        set reason "No_accounts"
      }
      # Create_dashboard.c(208): Error: User - 3002934013 - already had an existing dashboard, the dashboard has been deleted and the user has logged out
      if {[regexp {already had an existing dashboard} $line]} {
        set status "existing"
        append notes $line
      }
      if {[regexp {02Q_No_Dashboard} $line]} {
        append notes "Created new dashboard"
      }
      # maak_groep_naam.c(77): Userid: 3002418022 Accounts: 14 ResponseTime: 1.882828
      if {[regexp {Userid: \d+ Accounts: (\d+) ResponseTime: (\d+\.\d+)} $line z na r]} {
        set nacts $na
        set R_getaccts $r
      }
      
	  }
  }
  $log debug "end reading log file: $logfilepath"
  close $fi
  close $fo
}




main $argv
