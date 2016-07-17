# procs for making source backups, keeping originals.

# TODO: deze backup functionaliteit overal gebruiken:
# regsub, mogelijk nog anderen, check op orig.

proc tempname {filename} {
  return "$filename.__TEMP__"
}

proc set_origdir {} {
  global _origdir
  set _origdir "_orig.[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]"
}

# mkdir origdir
# mv $filename => _origdir/$filename, then
# mv $filename.__TEMP__ => $filename
# check if filename is different from temp version:
# different -> do action as described
# same -> remove temp file.
proc commit_file {filename} {
  global _origdir
  if {![file exists $filename]} {
    # new file, just rename temp to filename
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
    set backupname [file join $_origdir $filename]
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
