package require ndv
package require Tclx

proc main {argv} {
  set options {
    {drv.arg "f:/" "USB Drive to copy music files to on windows machine"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  set fa [open "$ar_argv(drv)all.m3u" w]
  foreach dirname [glob -directory $ar_argv(drv) -type d *] {
    set f [open [file join $ar_argv(drv) "$dirname.m3u"] w]
    foreach filename [lsort [glob -tails -nocomplain -directory $dirname -type f *]] {
      puts $f "[file tail $dirname]\\$filename" 
      puts $fa "[file tail $dirname]\\$filename" 
    }
    close $f
  }
  close $fa
}

main $argv