task comment_remove {Remove out commented code
  Remove lines starting with //<tab> and not containing timestamp or initials
} {
  foreach filename [filter_ignore_files [get_source_files]]	{
    comment_remove_file $filename
  }
}

proc comment_remove_file {filename} {
  set fi [open $filename r]
  set fo [open [tempname $filename] w]
  while {[gets $fi line] >= 0} {
    if {[regexp {^//\t} $line]} {
      if {[regexp {\d{4}-\d{2}-\d{2} \d{2}:\d{2}} $line]} {
        # timestamp occurs, probably a comment anyway, so keep
        puts $fo $line
      } else {
        # out commented line, remove.
      }
    } else {
      puts $fo $line
    }
  }
  close $fi
  close $fo
  commit_file $filename
}
