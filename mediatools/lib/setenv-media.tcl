# setenv-media.tcl - set env var's for use within media Tcl scripts
# usage: source this file in a Tcl script. Executing directly from the shell (bash) does not work, the environment can not be exported from Tcl.

set env(MEDIA_DRIVE) /media/nas
set env(MEDIA_MUSIC) $env(MEDIA_DRIVE)/media/Music
set env(MEDIA_PLAYLISTS) $env(MEDIA_MUSIC)/playlists
# [2016-05-15 15:17] deze dir bestaat niet meer, dus ook def weg:
# set env(MEDIA_NEW) $env(MEDIA_MUSIC)/tijdelijk
set env(MEDIA_SCRIPTS) /home/nico/nicoprj/mediatools/playlist
set env(MEDIA_COMPLETE) $env(MEDIA_MUSIC)/Albums
set env(MEDIA_SINGLES) $env(MEDIA_MUSIC)/Singles

# [2013-01-13 13:57:39] add new temp-dir
# 2015-06-20 aangepast, nu een /home/media. Nog wel tijdelijk-dir waar ook andere dingen dan music in staan.
set env(MEDIA_TEMP) "/home/media/tijdelijk"

# 20-6-2015 check of alle dirs bestaan
foreach k [array names env] {
  if {[regexp {^MEDIA_} $k]} {
    if {[file exists $env($k)]} {
      # ok, path exists
      # puts "Ok, path exists: $env($k)"
    } else {
      puts "ERROR: path does not exist: $env($k)"
    }
  } else {
    # no MEDIA env var, ignore.
  }
}
