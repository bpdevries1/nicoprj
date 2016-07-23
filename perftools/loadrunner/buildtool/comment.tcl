task comment_remove {Remove out commented code
  Remove lines starting with //<tab> and not containing timestamp or initials.
  Only do this with action files, not library files etc.
} {
  foreach filename [get_action_files]	{
    comment_remove_file $filename
  }
}

proc comment_remove_file {filename} {
  set fi [open $filename r]
  #set fo [open [tempname $filename] w]
  #fconfigure $fo -translation crlf
  set fo [open_temp_w $filename]
  while {[gets $fi line] >= 0} {
    if {[is_commented_line $line]} {
      # out commented line, remove.
    } else {
      puts $fo $line
    }
  }
  close $fi
  close $fo
  commit_file $filename
}

proc is_commented_line {line} {
  if {[regexp {^//\t} $line]} {
    if {[regexp {\d{4}-\d{2}-\d{2} \d{2}:\d{2}} $line]} {
      # timestamp occurs, probably a comment anyway, so keep
      return 0
    } elseif {[regexp -nocase {todo} $line]} {
      return 0
    } elseif {[regexp -nocase {ndv} $line]} {
      return 0
    } else {
      return 1
    }
  } elseif {$line == "//"} {
    # just 2 slashes
    return 1
  } else {
    return 0
  }
}

task uncomment {Uncomment commented lines in source
  Syntax: uncomment [<file> ..]
  If no files given, do nothing.
  Uncomment the same lines that would be removed by task comment_remove
} {
  foreach filename $args {
    uncomment_file $filename
  }
}

proc uncomment_file {filename} {
  set fi [open $filename r]
  #set fo [open [tempname $filename] w]
  #fconfigure $fo -translation crlf
  set fo [open_temp_w $filename]
  while {[gets $fi line] >= 0} {
    if {[is_commented_line $line]} {
      regexp {^//(.*)$} $line z line2
      puts $fo $line2
    } else {
      puts $fo $line
    }
  }
  close $fi
  close $fo
  commit_file $filename
}

