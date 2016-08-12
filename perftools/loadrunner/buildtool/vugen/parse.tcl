# TODO: (ooit) use a real parser.
# comment and empty lines should just be added to the current statement, so no special handling.
proc read_source_statements {filename} {
  set f [open $filename r]
  set linenr 0
  set lines {}
  set linenr_start -1
  while {[gets $f line] >= 0} {
    incr linenr
    if {($linenr > 76) && [regexp authorise_ft $filename]} {
      # breakpoint
    }
    if {$lines == {}} {
      set linenr_start $linenr
    }
    lappend lines $line
    if {[is_statement_end $line]} {
      #puts "before add 1"
      lappend stmts [dict create lines $lines type [stmt_type $lines] \
                         linenr_start $linenr_start linenr_end $linenr]
      set lines {}
    } else {
      # nothing.
    }
  } ; # end-of-while gets
  if {$lines != {}} {
    #puts "before add 2"
    # [2016-07-31 14:44] could be lines only has 1 empty line, so then list is not empty. This should be ok, could be more empty/comment lines at the end, want to keep those.
    lappend stmts [dict create lines $lines type [stmt_type $lines] \
                       linenr_start $linenr_start linenr_end $linenr]
  }
  close $f
  return $stmts
}

proc read_source_statements_old {filename} {
  set f [open $filename r]
  set linenr 0
  set lines {}
  set linenr_start -1
  while {[gets $f line] >= 0} {
    incr linenr
    if {([string trim $line] == "") || [regexp {^\s*//} $line]} {
      # do want those lines in output again
      lappend stmts [dict create lines [list $line] type comment \
                         linenr_start $linenr linenr_end $linenr]
      continue
    }
    if {$lines == {}} {
      set linenr_start $linenr
    }
    lappend lines $line
    if {[is_statement_end $line]} {
      lappend stmts [dict create lines $lines type [stmt_type $lines] \
                         linenr_start $linenr_start linenr_end $linenr]
      set lines {}
    } else {
      # nothing.
    }
  } ; # end-of-while gets
  if {$lines != {}} {
    lappend stmts [dict create lines $lines type [stmt_type $lines] \
                       linenr_start $linenr_start linenr_end $linenr]
  }
  close $f
  return $stmts
}

# new statement for single line
proc stmt_new {line {type ""} {linenr_start 0} {linenr_end 0}} {
  dict create lines [list $line] type $type linenr_start $linenr_start \
      linenr_end $linenr_end
}

proc is_statement_end {line} {
  # [2016-07-31 15:13] comment lines are never statement end!
  if {[regexp {^\s*//} $line]} {
    return 0
  }
  if {[regexp {;$} [string trim $line]]} {
    return 1
  }
  # begin en einde file ook als statements zien.
  if {[regexp {[\{\}]$} [string trim $line]]} {
    return 1
  }
  return 0
}

# just check first lines, so Action()\n<brace> will not be recognised.
# by checking on ending on just a paren, it should work too.
# TODO: text checks (also added with build script) and web_reg_save_param => subs!
# web_reg_find
set stmt_types_regexps {
  {[\{\}]$} main
  {\)$} main
  {\sreturn\s} main
  
  {\sweb_url} main-req
  {\sweb_custom_request} main-req
  {\sweb_submit_data} main-req
  {auto_header}  main
  {transaction\(} main
  {\sweb_concurrent} main
  {web_global_verification} main

  {web_reg_find} sub-find
  {web_add_header} sub
  {web_reg_save_param} sub-save
}

# determine type of statement based on first line.
proc stmt_type {lines} {
  global stmt_types_regexps
  # set firstline [:0 $lines]
  set firstline [first_statement_line $lines]
  foreach {re tp} $stmt_types_regexps {
    if {[regexp $re $firstline]} {
      return $tp
    }
  }
  # maybe check full text if just first line does not find anything.
  # error "Cannot determine type of $firstline (lines=$lines)"
  # [2016-07-18 11:22:50] main-other as default?
  return "main-other"
}

# return the first line in lines that is not empty or a comment
proc first_statement_line {lines} {
  foreach line $lines {
    if {([string trim $line] != "") && ![regexp {^\s*//} $line]} {
      return $line
    }
  }
  # [2016-07-31 14:45] could be (at the eof) that only empty/comment lines exist.
  return ""
  #breakpoint
  #error "No non-empty/comment lines found in: $lines"
}

# return list of statement-groups: each group is a dict with a list of statements and
# a domain.
# for now, assume that sub-types only occur before a main type, not after.
proc group_statements {statements} {
  set res {}
  set stmts {}
  set i 0
  foreach stmt $statements {
    incr i
    if {$i > 10} {
      # breakpoint
    }
    lappend stmts $stmt
    # breakpoint
    #log debug "stmt: $stmt"
    #log debug "keys: [dict keys $stmt]"
    # TODO: [2016-07-17 10:56] now need to set tp in a separate statement, if put directly within if, it will fail. [2016-07-27 22:03] non-reproduceable now.
    #if {[regexp {^main} [:type $stmt]]} {set stmt}
    #set tp [:type $stmt]
    if {[regexp {web_add_header} $stmt]} {
      # log debug "web add header found"
      # breakpoint
    }
    # [2016-07-27 22:02] This line below supposedly gave error before:
    if {[regexp {^main} [:type $stmt]]} {
      # log debug "tp=main, create new group and put in res"
      # TODO: maybe determining domain should be a separate step.
      set url [stmt_det_url $stmt]
      lappend res [dict create statements $stmts domain [det_domain $url]\
                       url $url]
      set stmts {}
    } else {
      # nothing
      # log debug "tp=sub, keep and add to next main"
    }
  }
  if {$stmts != {}} {
    set url [stmt_det_url $stmt]
    lappend res [dict create statements $stmts domain [det_domain $url]\
                     url $url]
  }
  return $res
}

proc write_source_statements {filename stmt_groups {opt {debug 0}}} {
  #set f [open $temp_filename w]
  #fconfigure $f -translation crlf
  set f [open_temp_w $filename]
  foreach grp $stmt_groups {
    if {[:debug $opt]} {
      puts $f "// <NEW STATEMENT GROUP domain=[:domain $grp]>"  
    }    
    foreach stmt [:statements $grp] {
      if {[:debug $opt]} {
        puts $f "// <NEW STATEMENT type=[:type $stmt]>"  
      }
      puts $f [join [:lines $stmt] "\n"]    
    }
  }
  close $f
}

# return 1 iff there is at least one statement in group with the given type
# TODO: could use FP or list comprehension.
proc stmt_grp_has {stmt_grp type} {
  set found 0
  foreach stmt [:statements $stmt_grp] {
    if {[:type $stmt] == $type} {
      set found 1
    }
  }
  return $found
}

# TODO: multiline comment blocks
proc line_type {line} {
  set line [string trim $line]
  if {$line == ""} {
    return empty
  }
  if {[regexp {^//} $line]} {
    return comment
  }
  if {[regexp {^/\*} $line]} {
    return comment_start
  }
  if {[regexp {\*/$} $line]} {
    return comment_end
  }
  if {[regexp {^\#} $line]} {
    if {[regexp {^\#include} $line]} {
      return include
    } else {
      return directive
    }
  }
  return other
}
