proc main {argc argv} {
  global env
  set exe_name [lindex $argv 0]
  foreach path [split $env(PATH) ";"] {
    set lst_res [glob -nocomplain -directory $path $exe_name*]
    foreach res $lst_res {
      # puts [file join $path $exe_name]
      puts [file nativename $res]
    }
  }
}

main $argc $argv