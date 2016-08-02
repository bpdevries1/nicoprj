task check {Perform some checks on sources
  location of #includes, todo's, comments.
} {
  set options {
    {includes "Check includes (default)"}
    {todos "Check todo's"}
    {comments "Check comments"}
    {all "Do full check, including todo's and comments"}
  }
  set usage ": regsub \[options] <from> <to>:"
  set opt [getoptions args $options $usage]
  #puts "opt: $opt"
  #breakpoint
  # lassign [det_full $args] args full
  if {$args != {}} {
    foreach filename $args {
      check_file $filename $opt
    }
  } else {
    foreach srcfile [get_source_files]	{
      check_file $srcfile $opt
    }
    check_script
  }
}

proc det_full_old {lst} {
  set full 0
  set res {}
  foreach el $lst {
    if {$el == "-full"} {
      set full 1
    } else {
      lappend res $el
    }
  }
  list $res $full
}

proc check_file {srcfile opt} {
  if {[:all $opt]} {
    set opt [dict merge $opt [dict create includes 1 todos 1 comments 1]]
  }
  if {[count_set_options $opt] == 0} {
    set opt [dict merge $opt [dict create includes 1]]
  }
  if {[:includes $opt]} {
    check_file_includes $srcfile  
  }
  if {[:todos $opt]} {
    check_file_todos $srcfile    
  }
  if {[:comments $opt]} {
    check_file_comments $srcfile
  }
  
  # [2016-02-05 17:29:15] TODO: Wil eigenlijk in globals.h een zeer beperkt aantal globals. Beter om te definieren waar ze gebruikt worden, zoals cachecontrol etc.
  # [2016-07-24 18:46] aan de andere kant nu taken om globals toe te voegen, dus beter te beheren. Maar als global nog steeds maar door 1 lib wordt gebruikt, staat vorige statement nog steeds.
  # [2016-07-29 12:53:39] check_globals does not exist.
  # check_globals
}

# return the number of set binary options in opt
proc count_set_options {opt} {
  set res 0
  dict for {nm val} $opt {
    if {$val == 1} {
      incr res
    }
  }
  return $res
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
  set ini [ini_read default.cfg]
  check_setting $ini WEB FailNonCriticalItem 1
  check_setting $ini WEB ProxyUseProxy 0
  check_setting $ini WEB ProxyUseProxyServer 0
}

proc check_setting {ini header key value} {
  set val [ini_get_param $ini $header $key "<none>"]
  if {$val == $value} {
    # ok, no worries
  } else {
    puts "WARN: unexpected value for $header/$key: $val (expected: $value)"
  }
}
