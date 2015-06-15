package require ndv

ndv::source_once lib_userresults.tcl

proc main {argv} {
  lassign $argv logfilepath
  set logfilename [file tail $logfilepath]
  set dbname [file join [file dirname $logfilepath] "userresults.db"]
  set db [get_results_db $dbname]
  set ts_cet [clock format [file mtime $logfilepath] -format "%Y-%m-%d %H:%M:%S"]
  
  set outfilename "$logfilepath.results"
  # out format (tsv): user, result, iteration, notes
  set fi [open $logfilepath r]
  set fo [open $outfilename w]
  puts $fo [join [list user status iteration nacts R_getaccts notes] "\t"]
  set iteration "<none>"
  set user "<none>"
  set status "<none>"
  set notes ""
  set nacts -1
  set R_getaccts -1
  $db in_trans {
	  while {![eof $fi]} {
      gets $fi line
      if {[regexp {Starting iteration (\d+)\.} $line z it]} {
        set iteration $it
        set user ""
        set status ""
        set reason ""
        set notes ""
        set nacts ""
        set R_getaccts ""
      }
      if {[regexp {Parameter Substitution: parameter .user. =  .(\d+)} $line z us]} {
        set user $us
      }
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
      # Create_dashboard.c(254): Error -26374:
      if {[regexp {^[^ ]+.c\(\d+\): Error } $line]} {
        set status "error"
        append notes $line
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
      
      if {[regexp {Ending iteration \d+\.} $line]} {
        puts $fo [join [list $user $status $iteration $nacts $R_getaccts $notes] "\t"]
        $db insert user_result [vars_to_dict user status reason iteration nacts R_getaccts notes logfilename ts_cet]
        set user ""
        set status ""
        set reason ""
        set notes ""
        set nacts ""
        set R_getaccts ""
      }
	  }
  }
  close $fi
  close $fo
}




main $argv
