#!/bin/bash
export SINGLES_OK=/media/nas/media/Music/Singles/Ok
mv "`dcop amarok player path`" $SINGLES_OK
dcop amarok player next
dcop amarok player seek 90

