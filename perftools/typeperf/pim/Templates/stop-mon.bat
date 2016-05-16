@echo off
setlocal
LOOP: psexec \\HOST -u LOGIN -p PASSWORD -w DRIVE:\DIR pskill.exe typeperf
