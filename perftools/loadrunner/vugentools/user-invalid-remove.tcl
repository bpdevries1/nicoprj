package require ndv

# scriptdir is VuGen dir with user*.dat files which will be pruned
# outputfilename is result of det-user-results.tcl - alle users with 'Uw pas is niet correct' will be removed.
#
# result:
# user*.dat files will be renamed to user*.dat.<datetime>
# user*.dat files will be pruned
# user-invalid.txt will be appended with pruned/removed users.
# user-ok.txt will be appended with users that have result 'ok'
#
# invariant:
# * order of users in user*.dat should stay the same.

proc main {argv} {
  global argv0
  if {[llength $argv] != 2} {
    puts "syntax: $argv0 <scriptdir> <outputfilename>"
    exit 1
  }
  lassign $argv scriptdir outputfilename
  lassign [det_invalid_users $outputfilename] inv_users lok

  set fok [open [file join $scriptdir user-ok.txt] a]
  foreach user $lok {
    puts $fok $user
  }
  close $fok

  foreach userfile [glob -directory $scriptdir user*.dat] {
    handle_userfile $scriptdir $userfile $inv_users $outputfilename
  }

}
  
# return: dict of usernames which have 'Uw pas is niet correct' in the result
# dict-key: username
# dict-value: error message, to be put in user-invalid.txt
proc det_invalid_users {filename} {
  set f [open $filename r]
  set d [dict create]
  set lok {}
  while {![eof $f]} {
    gets $f line
	lassign [split $line "\t"] user status iteration notes
	if {$status == "error"} {
	  if {[regexp {Text=Uw pas is niet correct} $notes]} {
		dict append d $user $notes
	  }
	}
	if {$status == "ok"} {
	  lappend lok $user
	}
  }
  close $f
  return [list $d $lok]
}

proc handle_userfile {scriptdir userfile inv_users outputfilename} {
	set backupfile "$userfile.[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]"
	file rename $userfile $backupfile
	set fl [open [file join $scriptdir user-invalid.txt] a]
	set fi [open $backupfile r]
	set fo [open $userfile w]
	while {![eof $fi]} {
	  gets $fi line
	  set user $line
	  if {[dict exists $inv_users $user]} {
	    puts $fl [join [list [file tail $userfile] [file tail $outputfilename] $user [dict get $inv_users $user]] "\t"]
	  } else {
	    puts $fo $user
	  }
	}
	close $fl
	close $fi
	close $fo
}
  
main $argv
