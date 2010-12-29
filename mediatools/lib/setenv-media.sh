# setenv-media.sh - set env var's for use within /mp3/new etc. kazaa.
echo shell: $SHELL
echo settings env vars
export MEDIA_DRIVE=/media/nas
export MEDIA_MUSIC=$MEDIA_DRIVE/media/Music
export MEDIA_PLAYLISTS=$MEDIA_MUSIC/playlists
export MEDIA_NEW=$MEDIA_MUSIC/tijdelijk
# export MEDIA_SCRIPTS=~/projecten/mp3-scripts
export MEDIA_SCRIPTS=/home/nico/nicoprj/mediatools/playlist
export MEDIA_COMPLETE=$MEDIA_MUSIC/Albums
export MEDIA_SINGLES=$MEDIA_MUSIC/Singles
# echo media_new1: $MEDIA_NEW

# export lijkt vage dingen te doen.
# komt waarschijnlijk door Ctrl-M in bestanden.

