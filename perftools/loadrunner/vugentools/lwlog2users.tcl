proc main {argv} {
  lassign $argv dir
  set logfile [file join $dir output.txt]
  set f [open $logfile r]
  set user ""
  set show_ok 0
  set linenr 0
  while {![eof $f]} {
    gets $f line
    incr linenr
    # functions.c(345): [2015-09-01 14:41:06] [1441111266] trans=LW_02_Login, user=3002334866, resptime=6.042, status=0 [1-9-2015 14:41:06]
    # functions.c(345): [2015-09-01 14:41:24] [1441111284] trans=LW_05_LoanWidget_Show, user=3003299558, resptime=0.987, status=0 [1-9-2015 14:41:24]
    # functions.c(345): [2015-09-01 14:42:16] [1441111336] trans=LW_05_LoanWidget_Add, user=3001656379, resptime=1.071, status=0 [1-9-2015 14:42:16]

    if {[regexp {Login, user=(\d+),} $line z us]} {
      # puts "#$linenr: new user found: $us"
      if {$user != ""} {
        puts $show_ok,$user
      }
      set user $us
      set show_ok 0
    } elseif {[regexp {LoanWidget_Show, user=(\d+), resptime=[0-9.]+, status=(\d+)} $line z us st]} {
      if {$user == $us} {
        if {$st == "0"} {
          set show_ok 1
        } else {
          set show_ok 0
        }
      } else {
        error "#$linenr: users are different: $user <=> $us"
      }
    } elseif {[regexp {LoanWidget_Add, user=(\d+), resptime=[0-9.]+, status=(\d+)} $line z us st]} {
      if {$user == $us} {
        if {$st == "0"} {
          set show_ok 1
        } else {
          set show_ok 0
        }
      } else {
        error "#$linenr: users are different: $user <=> $us"
      }
    }
  }
  # handle last
  if {$user != ""} {
    puts $show_ok,$user
  }
  
  close $f
  
}

main $argv