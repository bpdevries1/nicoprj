@echo off
setlocal
LOOP: copy pskill.exe NET:\DIR
LOOP: copy pslist.exe NET:\DIR
LOOP: copy typeperf-HOST.cf NET:\DIR\typeperf.cf
