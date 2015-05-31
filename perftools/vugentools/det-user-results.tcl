package require ndv

proc main {argv} {
  lassign $argv logfilename
  set outfilename "$logfilename.results"
  # out format (tsv): user, result, iteration, notes
  set fi [open $logfilename r]
  set fo [open $outfilename w]
  puts $fo [join [list user status iteration notes] "\t"]
  set iteration "<none>"
  set user "<none>"
  set status "<none>"
  set notes ""
  while {![eof $fi]} {
    gets $fi line
	if {[regexp {Starting iteration (\d+)\.} $line z it]} {
	  set iteration $it
	  set user "<none>"
	  set status "<none>"
	  set notes ""
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
	  set status "fail"
	  # append notes "Notify: Transaction .04_Create_dashboard. ended with .Fail. status"
	  append notes $line
	}
	if {[regexp {05Q_No_Accounts} $line]} {
	  set status "fail"
	  set notes "No accounts;$notes"
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
	
    if {[regexp {Ending iteration \d+\.} $line]} {
	  puts $fo [join [list $user $status $iteration $notes] "\t"]	
	  set iteration "<none>"
	  set user "<none>"
	  set status "<none>"
	  set notes ""
	}
  }
  close $fi
  close $fo
}

main $argv
