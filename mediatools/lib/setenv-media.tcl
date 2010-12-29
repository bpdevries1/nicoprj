# setenv-media.tcl - set env var's for use within media Tcl scripts
# usage: source this file in a Tcl script. Executing directly from the shell (bash) does not work, the environment can not be exported from Tcl.

set env(MEDIA_DRIVE) /media/nas
set env(MEDIA_MUSIC) $env(MEDIA_DRIVE)/media/Music
set env(MEDIA_PLAYLISTS) $env(MEDIA_MUSIC)/playlists
set env(MEDIA_NEW) $env(MEDIA_MUSIC)/tijdelijk
set env(MEDIA_SCRIPTS) /home/nico/nicoprj/mediatools/playlist
set env(MEDIA_COMPLETE) $env(MEDIA_MUSIC)/Albums
set env(MEDIA_SINGLES) $env(MEDIA_MUSIC)/Singles


