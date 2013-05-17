#!/home/nico/bin/tclsh

# move track to subdirectory of dir it's in and go to next song, skipping 90 seconds/

proc main {argv} {
  global argv0
  if {[llength $argv] != 1} {
    puts stderr "syntax: $argv0 <relative subdir>"
    exit 1
  }
  lassign $argv subdir
  set filename [det_current_filename]
  puts "filename: $filename"
  if {1} {
    set to_dir [file join [file dirname $filename] $subdir]
    file mkdir $to_dir
    move_next
    file rename $filename $to_dir
  }
}

proc det_current_filename {} {
  set res [exec qdbus org.kde.amarok /Player org.freedesktop.MediaPlayer.GetMetadata]
  if {[regexp {location: ([^\n]+)} $res z url]} {
    puts "url: $url" 
  }
  url_to_filename $url
}

proc url_to_filename {url} {
  if {[regexp {^file://(.+)$} $url z filename]} {
    set filename [encoding convertfrom utf-8 [url_decode $filename]]
  } else {
    error "Cannot convert to filename: $url" 
  }
  return $filename
}

# from http://wiki.tcl.tk/14144
proc url_decode str {
    # rewrite "+" back to space
    # protect \ from quoting another '\'
    set str [string map [list + { } "\\" "\\\\"] $str]

    # prepare to process all %-escapes
    regsub -all -- {%([A-Fa-f0-9][A-Fa-f0-9])} $str {\\u00\1} str

    # process \u unicode mapped chars
    return [subst -novar -nocommand $str]
}

proc move_next {} {
  exec qdbus org.kde.amarok /Player org.freedesktop.MediaPlayer.Next
  after 500
  exec qdbus org.kde.amarok /Player org.freedesktop.MediaPlayer.Forward 90000
}

main $argv
