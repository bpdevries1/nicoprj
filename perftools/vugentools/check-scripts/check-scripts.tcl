package require ndv

# check if library files in multiple scripts belonging to the same project are identical.
# due to limitation in VuGen/LR it's not really possible to define a library than can be (automatically) used by multiple scripts.
# possible that a file (ie CRAS_certificate_login.c) is only present in some of the dirs. Only check in those dirs if they are the same.
# first check everything against first dir, but iff files are not present in first dir, should check other dirs as well.
#
# could use Unison instead of this script?
#
# TODO:
# * handle default.cfg and default.usp - F4-settings for script, have some guidelines here.
# * Check if correlated params are not used before they get a value. Possibly requires generic parsing (parsec?) of scripts.

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
set logfilename "logs/[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"
$log set_file $logfilename

set DIFF_BIN {c:\PCC\util\cygwin\bin\diff.exe}

proc main {argv} {
  global root_dir
  lassign $argv configfile
  log info "Checking: $configfile"
  source $configfile
  set root_dir [get_root_dir]
  set dirs [get_dirs_to_check]
  # set filenames [get_filenames_to_check]
  set filenames [get_filenames $root_dir $dirs]
  log trace "filenames to check: $filenames"
  check_scripts $root_dir $dirs $filenames
  log info "Checking end: $configfile\n========================="
}

proc get_filenames {root_dir dirs} {
  set d [dict create]
  set to_check [get_filenames_to_check]
  foreach dir $dirs {
    foreach filename [glob -type f -directory [file join $root_dir $dir] -tails *] {
      if {[lsearch $to_check $filename] >= 0} {
        dict set d $filename 1
      } elseif {[ignore_file $filename]} {
        # ok, ignore
      } else {
        # many files not named, but a pain to do so.
        # log warn "File not named: $filename, so check"
        dict set d $filename 1
      }
    }
  }
  lsort [dict keys $d]
}

# return 1 iff filename should be ignored
# generic ignore and specific ignore for project
proc ignore_file {filename} {
  log trace "ignore_file: $filename"
  if {[ignore_generic $filename]} {
    return 1
  } else {
    return [ignore_specific $filename]
  }
}

# ^globals\.h$ niet algemeen ignoren, tussen CBW en Loans zou het wel hetzelfde moeten zijn.
proc ignore_generic {filename} {
  set res {^vuser_.*\.c \.idx$ ^combined_.*\.c git-add-commit.sh ^mdrv 
           pre_cci.c \.config$ ^output.bak ^output.txt options.txt ^Action\.c 
           ^default\.cfg ^default\.usp TransactionsData.db \.xml$ globals_specific\.h}
  foreach re $res {
    if {[regexp $re $filename]} {
      log trace "regexp $re $filename returns 1"
      return 1
    } else {
      log trace "regexp $re $filename returns 0"
    }
  }
  return 0
}

proc check_scripts {root_dir dirs filenames} {
	check_files_in_sync $root_dir $dirs $filenames
	check_start_end_transactions $root_dir $dirs
}

proc check_files_in_sync {root_dir dirs filenames} {
  foreach filename $filenames {
    log trace "Checking: $filename"
    set dir1 [:0 $dirs]
    set file1 [file join $root_dir $dir1 $filename]
    set basefile ""
    foreach dir $dirs  {
      set file [file join $root_dir $dir $filename]
      if {[file exists $file]} {
        if {$basefile == ""} {
          # first file found, set as base
          set basefile $file
        } else {
          check_files_same $basefile $file
        }
      } else {
        # nothing, filename not in this dir
      }
    }
  }
}

# if both files exists, but are not the same, give a warning
proc check_files_same {file1 file2} {
  if {[file exists $file1] && [file exists $file2]} {
    set text1 [read_file $file1]
    set text2 [read_file $file2]
    if {$text1 != $text2} {
      puts "Warning: files differ: 
  [format_file $file1]
  [format_file $file2]
      ==========="
      set diff [exec_diff $file1 $file2]
      puts $diff
      puts "==================="
    }
  }
}

proc format_file {filename} {
  global root_dir
  return "[string range $filename [string length $root_dir]+1 end] ([file_ts $filename], [file size $filename] bytes)"
}

proc file_ts {filename} {
  clock format [file atime $filename] -format "%Y-%m-%d %H:%M:%S"
}

proc exec_diff {file1 file2} {
  global DIFF_BIN
  set res "<none>"
  # catch {set res [exec -ignorestderr $DIFF_BIN $file1 $file2]}
  # set res [exec -ignorestderr $DIFF_BIN $file1 $file2]
  
  # 26-8-2015 NdV vooralsnog alleen het commando:
  set res "diff $file1 $file2"
  return $res
}

proc check_start_end_transactions {root_dir dirs} {
    foreach dir $dirs {
	  foreach filename [glob -directory [file join $root_dir $dir] *.c] {
      if {![ignore_file_path $filename]} {
        check_file_start_end_transactions $filename
      }
	  }
	}
}

proc ignore_file_path {path} {
  set filename [file tail $path]
  if {$filename == "pre_cci.c"} {
    return 1
  }
  return 0
}

# ignore comments, first only //
# TODO: nested transactions
# TODO: deze functie verdelen in stukken, is nu groter dan een pagina.
# assume a lr_start_transaction(x); needs to occur first, and later a lr_end_transaction(x, LR_AUTO)
proc check_file_start_end_transactions {filename} {
  set in_trans 0
  set trans_current "<none>"
  set linenr_start -1
  set linenr 0
  set f [open $filename r]
  while {![eof $f]} {
    gets $f line
    incr linenr
    set line [string trim $line]
    if {[regexp {^//} $line]} {
      continue
    }
    # ook: 	start_transactie("Client1_ClientSearch");
    if {[regexp {(lr_start_transaction|start_transactie)\((.+)\);} $line z fn_name params]} {
      set tn [string trim $params]
      if {$in_trans} {
        # puts "Warning: 2x lr_start_transaction in a row: $trans_current (#$linenr_start) <==> $tn (#$linenr)"
        warning $filename $linenr "2x lr_start_transaction in a row: $trans_current (#$linenr_start) <==> $tn (#$linenr)"
        # vars niet aanpassen, eerste trans blijft actuele.
      } else {
        # ok, a new transaction
        set in_trans 1
        set linenr_start $linenr
        if {$fn_name == "lr_start_transaction"} {
          set trans_current $tn
        } elseif {$fn_name == "start_transactie"} {
          # gebruikt in Transact_Valuta_UC3_MMLOAN, end_trans moet transactie als naam hebben.
          set trans_current "transactie"
        }
      }
    }
    if {[regexp {lr_end_transaction\((.+)\);} $line z params]} {
  	  lassign [split $params ","] tn lr_auto
      set tn [string trim $tn]
      set lr_auto [string trim $lr_auto]
      if {$in_trans} {
        # ok, end of transaction, check name/params.
        if {$tn != $trans_current} {
          # puts "Warning: transaction names differ: $trans_current (#$linenr_start) <==> $tn (#$linenr)"
          warning $filename $linenr "transaction names differ: $trans_current (#$linenr_start) <==> $tn (#$linenr)"
        }
        if {$lr_auto != "LR_AUTO"} {
          # puts "Warning: second param of lr_end_transaction is not LR_AUTO: $tn (#$linenr)"
          warning $filename $linenr "second param of lr_end_transaction is not LR_AUTO: $tn, $lr_auto <==> $trans_current (#$linenr_start)"
        }
        set in_trans 0
        set trans_current "<none>"
        set linenr_start -1
      } else {
        # nok, no trans started.
        # puts "Warning: no transaction started: $tn (#$linenr)"
        warning $filename $linenr "no transaction started: $tn"
      }
    }
  }
  close $f
}

# change puts to log to put results in file.
proc warning {filepath linenr text} {
  # only print last dir and filename of filename path
  set filename [file join {*}[lrange [file split $filepath] end-1 end]]
  puts "\[$filename#$linenr\] $text"
}

main $argv

file copy -force $logfilename "logs/[file tail [info script]].log"
