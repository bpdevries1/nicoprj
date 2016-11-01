#! /usr/bin/env tclsh

# Run all test scripts in repo (may other repo's too?)

# Renamed to run-all-tests.tcl, so it will not call itself.

# To be sure, also the following:
#@test never

package require ndv

set_log_global info

proc main {argv} {
  set options {
    {root.arg "auto" "Root of files to test"}
    {full "Run full testsuite, including long running tests"}
    {manual "Also run tests defined as manual/interactive"}
    {coe "Continue on error"}
    {nopopup "Don't show Tk popup when a test fails"}
  }
  set usage ": [file tail [info script]] \[options]:"
  set opt [getoptions argv $options $usage]
  test_all $opt 
}

proc test_all {opt} {
  if {[:root $opt] == "auto"} {
    set root [file normalize [file join [info script] .. .. ..]]  
  } else {
    set root [file normalize [:root $opt]]
  }
  log info "Running all tests in: $root"
  set lst [libio::glob_rec $root is_test]
  set nfiles_with_errors 0
  set files_with_errors [list]
  foreach path $lst {
    log debug "Run tests in: $path"
    if {[should_test $path $opt]} {
      log debug "Running tests in: $path"
      set old_pwd [pwd]
      cd [file dirname $path]
      try_eval {
        exec -ignorestderr tclsh $path  
      } {
        log warn "Found error(s) in $path: $errorCode"
        if {[:coe $opt]} {
          # continue-on-error
          incr nfiles_with_errors
          lappend files_with_errors $path
        } else {
          exit
        }
      }
      
      cd $old_pwd
    } else {
      log debug "-> Don't run tests"
    }
    # puts "============================="
  };                            # end-of-foreach file

  # for testing popup:
  #incr nfiles_with_errors
  #lappend files_with_errors a bc.def en nog een paar
  
  if {$nfiles_with_errors > 0} {
    set warn_msg "WARNING: Tcl test suite: $nfiles_with_errors file(s) with errors found!:\n[join $files_with_errors "\n"]"
    log warn $warn_msg
    if {![:nopopup $opt]} {
      popup_warning $warn_msg
    }
  } else {
    log info "Everything ok!"
  }
  exit;                         # to quit from Tk.
}

proc is_test {path} {
  if {[file type $path] == "directory"} {
    return 1;                   # recurse all sub directories
  } else {
    if {[regexp -- {^test-.+\.tcl$} [file tail $path]]} {
      return 1
    } else {
      # possibly other files as well.
      return 0
    }
  }
}

# TODO: if spec in file is set in options, return true.
proc should_test {path opt} {
  set tspec [test_spec $path]
  if {$tspec == "full"} {
    if {![:full $opt]} {
      return 0
    } else {
      return 1
    }
  } elseif {$tspec == "manual"} {
    if {[:manual $opt]} {
      return 1
    } else {
      return 0
    }
  } elseif {$tspec == "never"} {
    return 0
  } else {
    return 1  
  }
}

proc test_spec {path} {
  set text [read_file $path]
  if {[regexp big $path]} {
    # breakpoint
  }
  if {[regexp {\#@test (\S+)} $text z spec]} {
    return $spec
  } else {
    return "always"
  }
}

proc popup_warning {text} {
  package require Tk
  wm withdraw .
  set answer [::tk::MessageBox -message "Warning!" \
                  -icon info -type ok \
                  -detail $text]
}

main $argv
