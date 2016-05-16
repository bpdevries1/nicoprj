package require ndv

proc main {argv} {
  lassign $argv dir
  file mkdir [file join $dir gen]
  # tails werkt nu niet goed, begint met /
  foreach cfile [glob -directory $dir *.c] {
    handle_cfile $dir $cfile
  }
}

proc handle_cfile {dir cfile} {
  # breakpoint
  set fi [open $cfile r]
  set fo [open [file join $dir gen [file tail $cfile]] w]
  while {![eof $fi]} {
    gets $fi line
    if {[regexp {^(.*)lr_end_transaction\(([^,]+), ?LR_AUTO\);} $line z prefix trans]} {
      puts $fo "${prefix}log_always_trans($trans, lr_eval_string(\"{Userid}\"));"
      puts $fo $line
    } else {
      puts $fo $line
    }
  }
  close $fi
  close $fo
}

main $argv
