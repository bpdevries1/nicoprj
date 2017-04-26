# perform some tests. For now only show if libs are up-to-date
task test {Perform tests on script
  Calls following tasks: libs, check, check_configs, check_lr_params.
} {{includes "Check includes (default)"}
  {todos "Check todo's"}
  {comments "Check comments"}
  {misc "Check misc things"}
  {all "Do full check, including todo's and comments"}
} {
  task_libs {*}$args
  # task_check {*}[opt_to_cmdline $opt] {*}$args
  task_check {*}$args
  task_check_configs {*}$args
  task_check_lr_params {*}$args
  # abc;                          # to generate error.
}

# to pass opt from one task to another
# return list to be spliced by caller.
proc opt_to_cmdline {opt} {
  puts "opt: $opt"
  set res [list]
  foreach key [dict keys $opt] {
    lappend res "-$key"
    lappend res [dict get $opt $key]
  }
  return $res
}

task check {Perform some checks on sources
  location of #includes, todo's, comments.
} {{includes "Check includes (default)"}
  {todos "Check todo's"}
  {comments "Check comments"}
  {misc "Check misc things"}
  {all "Do full check, including todo's and comments"}
} {
  #puts "check: opt: $opt; args: $args"
  #breakpoint
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

proc check_file {srcfile opt} {
  #log debug "check_file: $srcfile"
  #puts "check_file: $srcfile"
  if {[:all $opt]} {
    set opt [dict merge $opt [dict create includes 1 todos 1 comments 1]]
  }
  if {[count_set_options $opt] == 0} {
    set opt [dict merge $opt [dict create includes 1 misc 1]]
  }
  if {[:includes $opt]} {
    check_file_includes $srcfile  
  }
  if {[:todos $opt]} {
    check_file_todos $srcfile    
  } else {
    check_file_fixmes $srcfile 
  }
  if {[:comments $opt]} {
    check_file_comments $srcfile
  }
  if {[:misc $opt]} {
    check_file_misc $srcfile
  }
  
  # [2016-02-05 17:29:15] TODO: Wil eigenlijk in globals.h een zeer beperkt aantal globals. Beter om te definieren waar ze gebruikt worden, zoals cachecontrol etc.
  # [2016-07-24 18:46] aan de andere kant nu taken om globals toe te voegen, dus beter te beheren. Maar als global nog steeds maar door 1 lib wordt gebruikt, staat vorige statement nog steeds.
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
    if {[regexp {FIXME} $line]} {
      puts_warn $srcfile $linenr "FIXME found: $line"
    }
    if {[regexp {TODO} $line]} {
      puts_warn $srcfile $linenr "TODO found: $line"
    }

  }
  close $f
}

# [2016-02-05 11:16:37] Deze niet std, levert te veel op, evt wel losse task.
# [2017-04-26 16:48] a hack, should be merged with check_file_todos
proc check_file_fixmes {srcfile} {
  set f [open $srcfile r]
  set linenr 0
  while {[gets $f line] >= 0} {
    incr linenr
    if {[regexp {FIXME} $line]} {
      puts_warn $srcfile $linenr "FIXME found: $line"
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

proc check_file_misc {srcfile} {
  set text [read_file $srcfile]
  if {[regexp {dynaTraceMonitor} $text]} {
    puts_warn $srcfile 0 "Found dynaTraceMonitor"
  }
  # check for deprecated functions, first just one.
  if {[file tail $srcfile] != "functions.c"} {
    if {[regexp {rb_web_reg_find\(} $text]} {
      puts_warn $srcfile 0 "Found deprecated function call: rb_web_reg_find"
      # puts_warn $srcfile 0 ""
      # use:
      # bld regsub -action "rb_web_reg_find\(\"Text=([^\"\"]+)\"\);" "rb_web_reg_findm(\"Text=\1\", \"Fail=NotFound\");"
      # bld regsub -action "rb_check_web_reg_find\(\)" "rb_check_web_reg_findm()"
    }
  }
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
  set ini [ini/read default.cfg]
  set headers [ini/headers $ini]
  if {[lsearch -exact $headers "WEB"] >= 0} {
    # Only check for WEB scripts, so with a [WEB] header
    check_setting $ini WEB FailNonCriticalItem 1
    check_setting $ini WEB ProxyUseProxy 0
    check_setting $ini WEB ProxyUseProxyServer 0
    check_setting $ini General ContinueOnError 0
  }
}

proc check_setting {ini header key value} {
  set val [ini/get_param $ini $header $key "<none>"]
  if {$val == $value} {
    # ok, no worries
  } else {
    puts "WARN: unexpected value for $header/$key: $val (expected: $value)"
  }
}
