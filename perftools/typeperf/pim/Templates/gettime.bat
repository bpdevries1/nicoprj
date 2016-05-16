@echo off
setlocal
LOOP: start /b psexec \\HOST -u LOGIN -p PASSWORD -w DRIVE:\DIR cmd /c echo %time% >time-HOST.txt
