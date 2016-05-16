@echo off
setlocal
LOOP: psexec \\HOST -u LOGIN -p PASSWORD -w DRIVE:\DIR typeperf -qx >counters-HOST.txt
