#!/bin/sh
echo unison-etc started >/home/nico/log/unison-etc.log
/home/nico/bin/unison -auto -batch root-etc >>/home/nico/log/unison-etc.log 2>&1


