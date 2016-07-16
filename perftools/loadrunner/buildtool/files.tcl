# procs for adding files and actions, and also for splitting an Action.c file according
# to transactions.

# these tasks should be idempotent: if they are called twice, the second time nothing should happen.

# args: 1 or more files to add.

# TODO: task_add maken die ofwel add_file ofwel add_action aanroept.
# dit dan obv name: als deze een extensie heeft (.h of .c) dan is het file, anders action.

# add an empty file if none exist yet
proc task_add_file_old {args} {
  foreach filename $args {
    add_file $filename
  }  
}

task add_file {Add an extra file to prj
  Syntax: add_file <file> [<file> ..]
  Adds files (create if needed) to the extra files part of the project.} {
  foreach filename $args {
    add_file $filename
  }  
}

# could be called by bld get, to automatically add files to project.
proc add_file {filename} {
  add_file_usr $filename
  add_file_metadata $filename
  add_file_include $filename
}

proc add_file_usr {filename} {
  if {![file exists $filename]} {
    set f [open $filename w]
    close $f
  }
  # maybe use project dir instead of current dir?
  set usr_file "[file tail [file normalize .]].usr"
  set ini [ini_read $usr_file]
  set ini [ini_add_no_dups $ini ManuallyExtraFiles "$filename="]
  ini_write $usr_file $ini
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
  commit_file $meta
}

# add file to #include list in globals.h
proc add_file_include {filename} {
  set fn "globals.h"
  set fi [open $fn r]
  set fo [open [tempname $fn] w]
  fconfigure $fo -translation crlf
  set in_includes 0
  set found 0
  while {[gets $fi line] >= 0} {
    if {$in_includes} {
      if {[regexp {\#include \"(.+)\"} $line z include]} {
        if {$include == $filename} {
          set found 1
        }
      } elseif {[string trim $line] == ""} {
        # ok, continue
      } else {
        # not in includes anymore, so add new one if needed
        if {!$found} {
          puts $fo "#include \"$filename\""
        }
        set in_includes 0
      }
    } else {
      if {[regexp {\#include} $line]} {
        # first line should always be lrun.h, so don't check on this one.
        set in_includes 1
      }
    }
    puts $fo $line
  }
  close $fo
  close $fi
  commit_file $fn
}

# add actions. Similar to add_file, but add to action part of hierarchy.
task add_action {Add action to project
  Syntax: add_acion <action> [<action> ..]
  Add actions to project.
} {
  foreach action $args {
    add_action $action
  }  
}

# create $action.c and add to project: default.usp, <prj>.usr, ScriptUploadMetadata.xml
proc add_action {action} {
  create_action_file $action
  update_default_usp $action
  add_action_usr $action
  add_file_metadata ${action}.c
}

proc create_action_file {action} {
  set filename "${action}.c"
  if {![file exists $filename]} {
    set f [open $filename w]
    fconfigure $f -translation crlf
    puts $f "$action\(\) \{

\treturn 0;
\}
"
    close $f
  }
}

proc update_default_usp {args} {
  set new_actions $args ; # could be more than 1
  set fn "default.usp"
  set fi [open $fn r]
  set fo [open [tempname $fn] w]
  fconfigure $fo -translation crlf
  while {[gets $fi line] >= 0} {
    if {[regexp {^Profile Actions name=vuser_init,(.+),vuser_end$} $line z orig_actions]} {
      # breakpoint
      set total_actions [merge_actions [split $orig_actions ","] $new_actions]
      puts $fo "Profile Actions name=vuser_init,[join $total_actions ","],vuser_end"
    } else {
      puts $fo $line
    }
  }
  close $fo
  close $fi
  commit_file $fn
}

# add each action in new list to orig add the end. Return result.
proc merge_actions {orig new} {
  set res $orig
  foreach action $new {
    # breakpoint
    if {[lsearch -exact $orig $action] < 0} {
      lappend res $action
    }
  }
  return $res
}

proc add_action_usr {action} {
  # maybe use project dir instead of current dir?
  set usr_file "[file tail [file normalize .]].usr"
  set ini [ini_read $usr_file]

  set ini [ini_add_no_dups $ini "Actions" "$action=${action}.c"]
  set ini [ini_add_no_dups $ini "Modified Actions" "$action=0"]
  set ini [ini_add_no_dups $ini "Recorded Actions" "$action=0"]
  set ini [ini_add_no_dups $ini "Interpreters" "$action=cci"]

  ini_write $usr_file $ini  
}

# split files named in args by transaction names
# default is Action.c
task split_action {Split file in multiple files per transaction
  syntax: split_action <action> [<action> ..]
  For each start_transaction, create a new file and put statements in here.
} {
  if {$args == {}} {
    set args [list Action]
  }
  foreach action $args {
    split_action $action
  }
}

proc split_action {action} {
  set new_actions {}
  set fn "${action}.c"
  set fi [open $fn r]
  set fo [open [tempname $fn] w]
  fconfigure $fo -translation crlf
  set foc $fo
  while {[gets $fi line] >= 0} {
    if {[regexp {lr_start_transaction\(\"(.+)\"\);} $line z transname]} {
      if {[file exists "${transname}.c"]} {
        log warn "transaction file already exists: ${transname}.c"
        # error "transaction file already exists: ${transname}.c"
      }
      lappend new_actions $transname
      set foa [open "${transname}.c" w]
      fconfigure $foa -translation crlf
      puts $foa "$transname\(\) \{"
      set foc $foa
      puts $fo "\t$transname\(\);"
      puts $foc $line
    } elseif {[regexp {lr_end_transaction} $line]} {
      puts $foa $line
      puts $foa "\treturn 0;\n\}\n"
      close $foa
      set foc $fo
    } else {
      puts $foc $line
    }
  }
  close $fo
  close $fi
  commit_file $fn

  # aan het einde aan project toevoegen
  task_add_action {*}$new_actions
}


