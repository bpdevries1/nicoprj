#!/usr/bin/env tclsh

proc main {} {
  set tempname "/home/pi/log/omxplayer-temp.log"
  set temp2name "/home/pi/log/omxplayer-temp2.log"
  if {[file exists $tempname]} {
    puts "temp exists, rename and read it"
    file rename -force $tempname $temp2name
    set f [open $temp2name r]
    while {![eof $f]} {
      gets $f line
      puts "got line: $line"
      if {[regexp {^[0-9 :-]+: .*/usr/bin/omxplayer.bin --no-osd -r (.+)$} $line z path]} {
        puts "matched regexp: $path"
        if {[is_link $path]} {
          # remove symlink, it has been played
          puts "file is link - delete: $path"
          file delete $path
        } else {
          puts "not a link, leave it: $path
        }
      } else {
        puts "did not match regexp: $line"
      }
    }
    close $f
    file delete $temp2name
  }
}

proc is_link {path} {
  set islink 0
  catch {
    set res [file readlink $path]
    # if path is not a link, the file readlink statement will throw an exception, and the next statement is not reached.
    set islink 1
  }
  return $islink
}

main


