#!/bin/sh

# sync albums and singles
cd /home/nico/nicoprj/mediatools/organise

./sync-music-db.tcl -dir /media/nas/media/Music/Albums >/home/nico/log/sync-music-db-albums.out 2>&1
./sync-music-db.tcl -dir /media/nas/media/Music/Singles >/home/nico/log/sync-music-db-singles.out 2>&1

