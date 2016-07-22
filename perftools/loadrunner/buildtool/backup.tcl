# procs for making source backups, keeping originals.

# TODO: deze backup functionaliteit overal gebruiken:
# regsub, mogelijk nog anderen, check op orig.

require libdatetime dt

proc tempname {filename} {
  return "$filename.__TEMP__"
}

proc set_origdir {} {
  global _origdir
  set _origdir "_orig.[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]"
}

# to put in backup/orig locations, in order to restore to a non-existing file when
# undo is one.
set EMPTY_CONTENTS "*** EMPTY ***"

# mkdir origdir
# mv $filename => _origdir/$filename, then
# mv $filename.__TEMP__ => $filename
# check if filename is different from temp version:
# different -> do action as described
# same -> remove temp file.
proc commit_file {filename} {
  global _origdir EMPTY_CONTENTS
  
  set backupname [file join $_origdir $filename]
  if {![file exists $filename]} {
    # new file, just rename temp to filename
    file mkdir $_origdir
    set f [open $backupname w]
    puts -nonewline $f $EMPTY_CONTENTS
    close $f
    file rename [tempname $filename] $filename
    return
  }
  # if temp does not exist, this is an error.
  
  if {[read_file $filename] == [read_file [tempname $filename]]} {
    # files are the same, no changes, delete temp file.
    log debug "Unchanged file: $filename"
    file delete [tempname $filename]
  } else {
    log debug "File changed: $filename"
    # Files are different, do update.
    file mkdir $_origdir
    
    if {[file exists $backupname]} {
      # Earlier backup within same main action, keep the earliest one.
      file delete $filename
    } else {
      file rename $filename $backupname
    }
    file rename [tempname $filename] $filename
  }
}

# undo changes, heep original, eg when -do is not given in regsub
proc rollback_file {filename} {
  file delete [tempname $filename]
}

# put a description of the changes in the backup-dir, iff the backup dir has been made.
proc mark_backup {tname trest} {
  global _origdir
  if {[file exists $_origdir]} {
    set f [open [file join $_origdir __BUILDTOOL_CHANGES__] w]
    puts $f "\[[dt/now]] $tname $trest"
    close $f
  }
}

# TODO: should check for dir mtime instead of name, sometimes a functional rename is done,
# and this _will_ mess things up.
task undo {undo last task
  Undo the last task which resulted in a backup directory with files.
} {
  global EMPTY_CONTENTS
  set dir [last_backup_dir]
  if {$dir == ""} {
    puts "No backups found"
    return
  }
  puts "Undoing change backupped in: $dir"
  set changes_file [file join $dir __BUILDTOOL_CHANGES__]
  # breakpoint
  if {[file exists $changes_file]} {
    puts [read_file $changes_file]
    file delete $changes_file
  }
  foreach filename [glob -directory $dir -type f *] {
    if {[read_file $filename]  == $EMPTY_CONTENTS} {
      puts "Deleting new file: [file tail $filename]"
      file delete [file tail $filename]
      file delete $filename
    } else {
      puts "Restoring file: [file tail $filename]"
      file copy -force $filename [file tail $filename]
      file delete $filename
    }
  }
  file delete $dir
}

# find last/newest backup/orig dir.
proc last_backup_dir {} {
  set lst [glob -nocomplain -type d _orig.*]
  if {$lst == {}} {
    return ""
  } else {
    :0 [lsort -decreasing $lst]
  }
}

task test_backup {test a backup with empty file} {
  set filename "test-file-ndv.txt"
  set f [open [tempname $filename] w]
  puts $f "Test creating and undo a new file"
  close $f
  commit_file $filename
}
