# procs for adding files and actions, and also for splitting an Action.c file according
# to transactions.

# these tasks should be idempotent: if they are called twice, the second time nothing should happen.

# args: 1 or more files to add.

# TODO: task_add maken die ofwel add_file ofwel add_action aanroept.
# dit dan obv name: als deze een extensie heeft (.h of .c) dan is het file, anders action.

# add an empty file if none exist yet
proc task_add_file {args} {
  foreach filename $args {
    add_file $filename
  }  
}

# could be called by bld get, to automatically add files to project.
proc add_file {filename} {
  add_file_usr $filename
  add_file_metadata $filename
}

proc add_file_usr {filename} {
  if {![file exists $filename]} {
    set f [open $filename w]
    close $f
  }
  # maybe use project dir instead of current dir?
  set usr_file "[file tail [file normalize .]].usr"
  set ini [ini_read $usr_file]

  # check if file already occurs, don't add twice
  set header ManuallyExtraFiles
  set lines [ini_lines $ini $header]
  set found 0
  foreach line $lines {
    if {$line == "$filename="} {
      set found 1
    }
  }
  if {!$found} {
    set ini [ini_add $ini $header "$filename="]
    ini_write $usr_file $ini  
  }
}

# add file to ScriptUploadMetadata.xml, also crlf endings
proc add_file_metadata {filename} {
  set meta ScriptUploadMetadata.xml
  set fi [open $meta r]
  set fo [open [tempname $meta] w]
  fconfigure $fo -translation crlf
  set found 0
  while {[gets $fi line] >= 0} {
    if {[regexp {</GeneralFiles>} $line]} {
      if {!$found} {
        puts $fo "    <FileEntry Name=\"$filename\" Filter=\"2\" />"
      }
    } elseif {[regexp {<FileEntry Name=\"(.+)\" Filter} $line z fn]} {
      if {$filename == $fn} {
        set found 1
      }
    } else {
      # nothing
    }
    puts $fo $line
  }
  close $fo
  close $fi
  change_file $meta
}

# add actions. Similar to add_file, but add to action part of hierarchy.
proc task_add_action {args} {

  
}

# split files named in args by transaction names
# default is Action.c
proc task_split_actions {args} {
  
}

