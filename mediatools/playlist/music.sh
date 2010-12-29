# TODO: meestal aangeroepen met music, een symlink naar deze file, dirname $0 werkt dan niet goed.
# voorlopig even hardcoded dus.
# cd "`dirname $0`"
cd /home/nico/nicoprj/mediatools/playlist
source ../lib/setenv-media.sh

# met $* worden params doorgegeven aan tcl script.
tclsh maak_album_playlist.tcl -pl "$MEDIA_PLAYLISTS/music-r.m3u" $* 
amarok "$MEDIA_PLAYLISTS/music-r.m3u" &
DATETIME=`date +%Y-%m-%d-%H-%M-%S`
# 31-1-2010 voorlopig ook nog even kopietje maken, kan geen kwaad.
cp $MEDIA_PLAYLISTS/music-r.m3u $MEDIA_PLAYLISTS/music-r-$DATETIME.m3u

