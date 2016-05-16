@echo off
setlocal
set interval=15
if not %1a==a set interval=%1
LOOP: del NET:\DIR\typeperf.csv
LOOP: psexec \\HOST -u LOGIN -p PASSWORD -w DRIVE:\DIR cmd /c start /b typeperf -si %interval% -cf typeperf.cf -o typeperf.csv
