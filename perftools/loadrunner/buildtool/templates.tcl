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
    # check if backslashes are done correctly when called from Tcl, maybe use braces
    regsub_file $filename {lr_start_transaction\(([^())]+)\);} \
      {rb_start_transaction(\1);} 1
    regsub_file $filename {lr_end_transaction\(([^()]+), ?LR_AUTO\);} \
      {rb_end_transaction(\1, TT);} 1
    regsub_file $filename {lr_think_time\(([^()]+)\);} {// lr_think_time(\1);} 1
  }
  
}
