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
proc change_file {filename} {
  global _origdir
  if {[read_file $filename] == [read_file [tempname $filename]]} {
    file delete [tempname $filename]
  } else {
    file mkdir $_origdir
    file rename $filename [file join $_origdir $filename]
    file rename [tempname $filename] $filename
  }
}

