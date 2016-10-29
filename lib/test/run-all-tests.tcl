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
  if {$nfiles_with_errors > 0} {
    log warn "WARNING: files with errors found!"
  } else {
    log info "Everything ok!"
  }
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

main $argv
