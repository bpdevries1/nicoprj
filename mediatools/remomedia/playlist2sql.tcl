# input: playlist, output: sql to import singles in music db
proc main {} {
  global env
  set fn_in "/media/nas/media/Music/playlists/singles.m3u"
  set fn_out "/media/nas/media/Music/playlists/singles.sql"
  set fi [open $fn_in r]
  set fo [open $fn_out w]
  while {![eof $fi]} {
    gets $fi line
    if {[regexp {^/media/nas/(.*)$} $line z path]} {
      regsub -all {'} $path "''" path
      puts $fo "insert into musicfile (path, freq, play_count) values ('$path', 1.0, 0);"
    }
  }
  close $fi
  close $fo
}

main
