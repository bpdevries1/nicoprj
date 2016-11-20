#!/bin/sh

# sync albums and singles
cd /home/nico/nicoprj/mediatools/organise

./sync-music-db.tcl -dir /media/nas/media/Music/Albums >/home/nico/log/sync-music-db-albums.log 2>&1
./sync-music-db.tcl -dir /media/nas/media/Music/Singles >/home/nico/log/sync-music-db-singles.log 2>&1

