task domains {get/update domains
  Create or update domains.ini file with headers for [keep] and [delete], which
  may next be edited manually. In the next execution of this task, the script will be updated by the settings: domains which should be deleted will be commented out.
  Use comment_remove to really delete those statements.
} {
  if {[file exists domains.ini]} {
    set domains_ini [ini_read domains.ini]
  } else {
    set domains_ini [ini_add_no_dups {} keep ""]
    set domains_ini [ini_add_no_dups $domains_ini ignore ""]
  }

  foreach filename [get_action_files] {
    if {$filename == "vuser_init.c"} {
      log info "Ignore $filename, could be template, more difficult"
      continue
    }
    log info "Handling file: $filename"
    set statements [read_source_statements $filename]
    # breakpoint
    set stmt_groups [group_statements $statements]
    set domains_ini [update_domains_ini $domains_ini $stmt_groups]; # any new ones?
    write_source_statements [tempname $filename] $stmt_groups $domains_ini
    commit_file $filename
  }
  ini_write domains.ini $domains_ini
  update_vuser_init $domains_ini
}

# TODO: (ooit) use a real parser.
proc read_source_statements {filename} {
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
  }
  if {$lines != {}} {
    lappend stmts [dict create lines $lines type [stmt_type $lines] \
                       linenr_start $linenr_start linenr_end $linenr]
  }
  close $f
  return $stmts
}

proc is_statement_end {line} {
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
  
  {\sweb_url} main
  {\sweb_custom_request} main
  {\sweb_submit_data} main
  {auto_header}  main
  {transaction\(} main
  {\sweb_concurrent} main
  {web_global_verification} main

  {web_reg_find} sub
  {web_add_header} sub
  {web_reg_save_param} sub
}

# determine type of statement based on first line.
proc stmt_type {lines} {
  global stmt_types_regexps
  set firstline [:0 $lines]
  foreach {re tp} $stmt_types_regexps {
    if {[regexp $re $firstline]} {
      return $tp
    }
  }
  # maybe check full text if just first line does not find anything.
  error "Cannot determine type of $firstline (lines=$lines)"
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
    # TODO: [2016-07-17 10:56] now need to set tp in a separate statement, if put directly within if, it will fail.
    set tp [:type $stmt]
    if {[regexp {web_add_header} $stmt]} {
      log debug "web add header found"
      # breakpoint
    }
    if {$tp == "main"} {
      log debug "tp=main, create new group and put in res"
      lappend res [dict create statements $stmts domain [det_domain $stmt]]
      set stmts {}
    } else {
      # nothing
      log debug "tp=sub, keep and add to next main"
    }
  }
  if {$stmts != {}} {
    lappend res [dict create statements $stmts domain [det_domain $stmt]]
  }
  return $res
}

proc det_domain {stmt} {
  foreach line [:lines $stmt] {
    if {[regexp {\"(URL|Action)=https?://([^/]+)/} $line z z domain]} {
      return $domain
    }
  }
  return ""
}

# first test if file written stays the same, idempotency
proc write_source_statements {filename stmt_groups domains_ini} {
  set f [open $filename w]
  fconfigure $f -translation crlf
  foreach grp $stmt_groups {
    set ignore [is_ignore_domain $domains_ini [:domain $grp]]
    # puts $f "// domain: [:domain $grp]"
    foreach stmt [:statements $grp] {
      if {$ignore} {
        foreach line [:lines $stmt] {
          puts $f "//$line"
        }
      } else {
        puts $f [join [:lines $stmt] "\n"]    
      }
    }
  }
  close $f
}

proc is_ignore_domain {ini domain} {
  if {$domain == ""} {
    return 0
  } else {
    ini_exists $ini ignore [domain_suffix $domain]  
  }
}

# return new domains_ini.
# foreach set domain in stmt_grp: check if suffix already exists in ini.
# if not, add it to the [keep] header.
proc update_domains_ini {ini stmt_groups} {
  foreach grp $stmt_groups {
    set domain [:domain $grp]
    if {$domain == ""} {
      # nothing
    } else {
      set suffix [domain_suffix $domain]
      if {[ini_exists $ini keep $suffix] ||
          [ini_exists $ini ignore $suffix]} {
        # nothing
      } else {
        log debug "Adding suffix to ini/keep: $suffix (domain=$domain)"
        set ini [ini_add $ini keep $suffix]
      }
    }
  }

  # sort lines under headers.
  set ini [ini_set_lines $ini keep [lsort [ini_lines $ini keep]]]
  set ini [ini_set_lines $ini ignore [lsort [ini_lines $ini ignore]]]
  
  return $ini
}

proc domain_suffix {domain} {
  log debug "determine suffix for domain: $domain"
  # only find rabo in last 3 parts of domain.
  set domain3 [join [lrange [split $domain "."] end-2 end] "."]
  if {[regexp {rabo} $domain3]} {
    # take last 3 items of domain when rabo is included
    join [lrange [split $domain "."] end-2 end] "."
  } else {
    # take last 2 items of domain
    join [lrange [split $domain "."] end-1 end] "."
  }
}

# //Filter out some production URLs
# add filter lines just after the comment (// Filter out), or just before return 0;
# replace all settings with info in domains.ini
proc update_vuser_init {domains_ini} {
  # alle huidige ignore lines helemaal weg en vervangen door domains_ini, op alfabet.
  set replaced 0
  set fi [open vuser_init.c r]
  set fo [open [tempname vuser_init.c] w]
  fconfigure $fo -translation crlf
  while {[gets $fi line] >= 0} {
    if {[regexp {Filter out some production URLs} $line]} {
      puts $fo $line
      puts_ignore_lines $fo $domains_ini
      set replaced 1
    } elseif {[regexp {return 0;} $line]} {
      if {!$replaced} {
        puts_ignore_lines $fo $domains_ini
        set replaced 1
      }
      puts $fo $line
    } elseif {[regexp {web_add_auto_filter} $line]} {
      # ignore line
    } else {
      puts $fo $line
    }
  }
  close $fi
  close $fo
  commit_file vuser_init.c
}

proc puts_ignore_lines {fo ini} {
  foreach line [lsort [ini_lines $ini ignore]] {
    if {$line != ""} {
      puts $fo "\tweb_add_auto_filter\(\"Action=Exclude\", \"HOSTSUFFIX=${line}\", LAST);"      
    }
  }
}

