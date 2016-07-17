# templates - tasks/functions to make script adhere to certain templates and best
# practices: .config files, set of includes/libs, rb_transaction, text checks.

task templates {Make script adhere to templates and best practices
  .config files,
  set of includes/libs,
  rb_transaction,
  text checks.
  add TT var - ThinkTime.
} {
  # TODO: possibly something with options, like selecting files?
  # or keep as standard as possible.
  foreach filename [get_action_files] {
    set_rb_transactions $filename
    set_web_reg_find $filename
    
  }
  
}

proc set_rb_transactions {filename} {
  regsub_file $filename {lr_start_transaction\(([^())]+)\);} \
    {rb_start_transaction(\1);} 1
  regsub_file $filename {lr_end_transaction\(([^()]+), ?LR_AUTO\);} \
    {rb_end_transaction(\1, TT);} 1
  regsub_file $filename {lr_think_time\(([^()]+)\);} {// lr_think_time(\1);} 1
}

# add web_reg_find statements before requests, if they do not already occur.
# cannot simply use regsub to add the web_reg_finds, because it would not be idempotent.
proc set_web_reg_find {filename} {
  set statements [read_source_statements $filename]
  set stmt_groups [group_statements $statements]
  # stmt_groups is sort-of like a parse tree. Work on this one, at the end write
  # back to file.
  set stmt_groups2 [add_web_reg_find $stmt_groups]
  write_source_statements [tempname $filename] $stmt_groups2
  commit_file $filename
}

# web_reg_find("Text=Working at Rabobank", LAST);
proc add_web_reg_find {stmt_groups} {
  #linsert, lreplace : in place of functioneel?
  #lset is inplace: lset lst ndx newvalue
  #linsert is functioneel: $lst ndx element
  map add_web_reg_find_group $stmt_groups
}

# return new statement group based on current one, possibly adding a statement for
# web_reg_find, if it does not exist yet. Add it just before the request
proc add_web_reg_find_group {stmt_grp} {
  if {[stmt_grp_has $stmt_grp main-req]} {
    if {![stmt_grp_has $stmt_grp sub-find]} {
      if {[url_needs_find [:url $stmt_grp]]} {
        dict set stmt_grp statements \
            [linsert [:statements $stmt_grp] end-1 \
                 [stmt_new "\tweb_reg_find(\"Text=<TODO>\", \"Notfound=warning\", LAST);\n" sub-find]]
      }
    }
  }
  return $stmt_grp
}

# sub items like .png and .svg normally don't need web_reg_find
# TODO: more generic, with regexp-list.
proc url_needs_find {url} {
  if {[regexp {\.svg} $url]} {
    return 0
  }
  if {[regexp {\.png} $url]} {
    return 0
  }
  if {[regexp {\.jpg} $url]} {
    return 0
  }
  if {[regexp {\.gif} $url]} {
    return 0
  }
  if {[regexp {dynaTraceMonitor} $url]} {
    return 0
  }
  return 1
}
