#!/bin/bash
# cd /home/nico/nicoprj/mediatools/playlist
cd "`dirname $0`"

# call setenv-media.bat
source ../lib/setenv-media.sh

# tclsh ./maakm3u.tcl
/home/nico/bin/tclsh ./maakm3u.tcl 


