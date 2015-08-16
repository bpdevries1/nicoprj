while {![eof stdin]} {
  gets stdin line
  set msec [format %03d [expr [clock milliseconds] % 1000]]
  puts "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"].$msec\] $line"
}

