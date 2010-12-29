#!/bin/sh

# sync albums and singles
cd /home/nico/nicoprj/mediatools/organise

./sync-music-db.tcl -dir /media/nas/media/Music/Albums >/tmp/sync-music-db-albums.out 2>&1
./sync-music-db.tcl -dir /media/nas/media/Music/Singles >/tmp/sync-music-db-singles.out 2>&1

