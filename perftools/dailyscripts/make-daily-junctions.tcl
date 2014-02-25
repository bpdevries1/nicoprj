# junction CQ5-CN-test c:\projecten\Philips\CQ5-CN-test\daily

proc main {} {
  set fo [open "c:/projecten/Philips/DailyReports/make-link.bat" w]
  foreach dir [glob -directory "c:/projecten/Philips" -type d *] {
    if {[file exists [file join $dir daily]]} {
      make_link $fo $dir
    }
  }
  close $fo
}

proc make_link {fo dir} {
  puts $fo "junction [file tail $dir] c:\\projecten\\Philips\\[file tail $dir]\\daily"
}

main