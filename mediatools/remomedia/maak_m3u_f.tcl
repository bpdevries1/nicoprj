proc main {} {
  set fa [open "f:/all.m3u" w]
  foreach dirname [glob -directory f:/ -type d *] {
    set f [open [file join f:/ "$dirname.m3u"] w]
    foreach filename [lsort [glob -tails -nocomplain -directory $dirname -type f *]] {
      puts $f "[file tail $dirname]\\$filename" 
      puts $fa "[file tail $dirname]\\$filename" 
    }
    close $f
  }
  close $fa
}

main