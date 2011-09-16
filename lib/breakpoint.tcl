# van http://www.linuxjournal.com/article/1159
proc breakpoint {} {
  # set max [expr [info level] - 2]
  set max [expr [info level] - 1]
  set current $max
  # NdV 3-11-2010 soms grote waarden in params, tonen duurt erg lang.
  breakpoint_show $current
  while {1} {
    puts -nonewline stderr "#$current: "
    gets stdin line
    while {![info complete $line]} {
      puts -nonewline stderr "? "
      append line \n[gets stdin]
    }
    switch -- $line {
      + {if {$current < $max} {breakpoint_show [incr current]}}
      - {if {$current > 0} {breakpoint_show [incr current -1]}}
      C {puts stderr "Resuming execution";return}
      ? {breakpoint_show $current 1}
      default {
        catch { uplevel #$current $line } result
        puts stderr $result
      }
    }
  }
}

# van http://www.linuxjournal.com/article/1159
# 16-9-2011 NdV info proc failed if withinn namespace. Now exec info proc with uplevel, so it is in correct namespace.
proc breakpoint_show {current {show_params 1}} {
  if {$current > 0} {
    set info [info level $current]
    set proc [lindex $info 0]
    set proc_args [uplevel #$current "info args $proc"]
    puts stderr "$current: Namespace [uplevel #$current {namespace current}] Procedure $proc $proc_args"
    set index 0
    if {$show_params} {
      foreach arg $proc_args {
        puts stderr "\t$arg = [string range [lindex $info [incr index]] 0 50]"
      }
    }
  } else {
    puts stderr "Top level"
  }
}
