task check_lr_params {Check LR parameter settings
  For each parameter, check:
  * not set to sequential - should only be used for script testing.
  * first row != 1        - should only be used for script testing.
} {
  foreach filename [glob -nocomplain *.prm] {
    check_lr_params_file $filename
  }
}

proc check_lr_params_file {filename} {
  set f [open $filename r]
  set param "<none>"
  while {[gets $f line] >= 0} {
    if {[regexp {^\[parameter:(.+)\]$} $line z pm]} {
      set param $pm
    } elseif {[regexp {SelectNextRow="([^""]+)"} $line z sel]} {
      if {$sel == "Sequential"} {
        puts "WARNING: $param: $line"
      }
    } elseif {[regexp {StartRow="(\d+)"} $line z st]} {
      if {$st != 1} {
        puts "WARNING: $param: $line"
      }
    }
  }
  close $f
}
