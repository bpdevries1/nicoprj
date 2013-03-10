# move files in directory to year-subdirectories if year is in filename
# remove year from filename

package require ndv

proc main {argv} {
  lassign $argv dir
  foreach filename [glob -directory $dir -tails *] {
    handle_file $dir $filename 
  }
}

# @param filename contains just the filename, no path/directory.
proc handle_file {dir filename} {
  if {[regexp {^(.*\W)(\d\d\d\d)(\W.*)$} $filename z pre year post]} {
    set fn2 "$pre$post"
    # check if there's just () left
    # breakpoint
    regsub -all { \(\)} $fn2 "" fn2
    set fn2 [string trim $fn2]
    puts "Rename $filename => $year/$fn2"
    file mkdir [file join $dir $year]
    file rename [file join $dir $filename] [file join $dir $year $fn2]
  }
    
}

main $argv
