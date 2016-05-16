package require ndv

proc main {} {
  set file_lpt_users_pat {C:\PCC\Nico\Projecten\RCC - Cash Balances\LPT users PAT}
  set dir_results {C:\PCC\Nico\Testruns\cashbalance-user-tests}
  set dir_vugen {C:\PCC\Nico\VuGen\RCC_CashBalancingWidget}
  
  set lpt_users_pat [read_lpt_users_pat $file_lpt_users_pat] ; # dict user->#accounts.
  set results [read_results $dir_results] ; # dict user-> list: #accounts result filename
  
  set fi [open [file join $dir_vugen "user-40.dat"] r]
  set fo [open [file join $dir_vugen "check-user-40.tsv"] w]
  gets $fi headerline
  puts $fo [join [list user "#robert" "#mei" result filename] "\t"]
  while {![eof $fi]} {
    gets $fi user
    if {$user != ""} {
	  puts $fo [join [list $user [dict_get $lpt_users_pat $user "-"] {*}[dict_get $results $user {- - -}]] "\t"]
	}	
  }
  close $fi
  close $fo
}

proc read_lpt_users_pat {filename} {
  set res [dict create]
  set f [open $filename r]
  while {![eof $f]} {
    gets $f line
	if {$line != ""} {
	  dict set res {*}[split $line "\t"]
	}
  }
  close $f
  return $res
}

proc read_results {dir} {
  set res [dict create]
  foreach filename [lsort [glob -directory $dir "output-201505*.txt.results"]] {
    set filename_tail [file tail $filename]
	set f [open $filename r]
	# user	status	iteration	nacts	R_getaccts	notes
	# 3002418022	ok	1	14	1.882828	
	while {![eof $f]} {
	  gets $f line
	  if {$line != ""} {
	    lassign [split $line "\t"] user status _ nacts
	    dict set res $user [list $nacts $status $filename_tail]
	  }
	}
	close $f
  }
  return $res
}

proc dict_get {d k def} {
  if {[dict exists $d $k]} {
    dict get $d $k
  } else {
    return $def
  }
}

main
