@echo off
setlocal
if %1a==a goto error
set outdir=%1
mkdir %outdir%
LOOP: copy NET:\DIR\typeperf.csv %outdir%\typeperf-HOST.csv
goto end
:error
echo Gebruik: get-mon.bat directory-naam, bijv. get-mon.bat Testrun15
pause
:end
