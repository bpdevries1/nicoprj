task check {Perform some checks on sources
  (eg location of #includes)} {
  lassign [det_full $args] args full
  if {$args != {}} {
    foreach libfile $args {
      check_file $libfile $full
    }
  } else {
    foreach srcfile [get_source_files]	{
      check_file $srcfile $full
    }
    check_script
  }
}

proc check_file {srcfile full} {
  check_file_includes $srcfile
  if {$full} {
    check_file_todos $srcfile
    check_file_comments $srcfile
  }
  # [2016-02-05 17:29:15] TODO: Wil eigenlijk in globals.h een zeer beperkt aantal globals. Beter om te definieren waar ze gebruikt worden, zoals cachecontrol etc.
  # [2016-07-24 18:46] aan de andere kant nu taken om globals toe te voegen, dus beter te beheren. Maar als global nog steeds maar door 1 lib wordt gebruikt, staat vorige statement nog steeds.
  # check_globals
}

# check if include statement occurs after other statements. Includes should all be at the top.
proc check_file_includes {srcfile} {
  set other_found 0
  set in_comment 0
  set f [open $srcfile r]
  set linenr 0
  while {[gets $f line] >= 0} {
    incr linenr
    set lt [line_type $line]
    if {$lt == "comment_start"} {
      set in_comment 1
    }
    if {$lt == "comment_end"} {
      set in_comment 0
    }
    if {!$in_comment} {
      if {$lt == "include"} {
        if {$other_found} {
          # puts "$srcfile \($linenr\) WARN: #include found after other statements: $line"
          puts_warn $srcfile $linenr "#include found after other statements: $line"
        }
      }
      if {$lt == "other"} {
        set other_found 1
      }
    }
  }
  close $f
}

# [2016-02-05 11:16:37] Deze niet std, levert te veel op, evt wel losse task.
proc check_file_todos {srcfile} {
  set f [open $srcfile r]
  set linenr 0
  while {[gets $f line] >= 0} {
    incr linenr
    if {[regexp {TODO} $line]} {
      puts_warn $srcfile $linenr "TODO found: $line"
    }
  }
  close $f
}

# [2016-02-05 11:14:23] deze niet std uitvoeren, levert te veel op. Mogelijk wel los, maar dan een task van maken.
proc check_file_comments {srcfile} {
  set f [open $srcfile r]
  set linenr 0
  while {[gets $f line] >= 0} {
    incr linenr
    set lt [line_type $line]
    if {$lt == "comment"} {
      # [2016-02-05 11:10:41] als er een haakje inzit, is het waarschijnlijk uitgecommente code.
      if {[regexp {[\(\)]} $line]} {
        puts_warn $srcfile $linenr "Possible out-commented code found: $line"
      }
    }
  }
  close $f
}

# check script scope things, eg all .c/.h files in dir are included in the script. Also for .config files.
proc check_script {} {
  # puts "check_script called"
  set src_files [filter_ignore_files \
                     [concat [glob -nocomplain -tails -directory . -type f "*.c"] \
                          [glob -nocomplain -tails -directory . -type f "*.h"] \
                          [glob -nocomplain -tails -directory . -type f "*.config"]]]
  set prj_text [read_file [lindex [glob *.usr] 0]]
  foreach src_file $src_files {
    if {[string first $src_file $prj_text] == -1} {
      puts "Sourcefile not in script.usr file: $src_file"
    } else {
      # puts "Ok: $src_file found in script.usr"
    }
  }
  #check_setting default.cfg <header> FailNonCriticalItem 1
  #check_setting default.cfg <header> ProxyUseProxy 0
}

