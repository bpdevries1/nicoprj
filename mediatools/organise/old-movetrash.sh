#!/bin/bash
export TRASHCAN=/media/nas/media/Music/trashcan
mv "`dcop amarok player path`" $TRASHCAN
dcop amarok player next
dcop amarok player seek 90

