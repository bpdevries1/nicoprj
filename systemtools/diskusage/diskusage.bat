rem diskusage.bat: filter om du.exe die alleen grote sizes toont van alle drives
rem gebruikt nu du.tcl, omdat du.exe niet goed omgaat met hidden dirs, en deze
rem in Win2000 nogal voorkomen.

setlocal
set month=%_month
set year=%_year
set day=%_day
set hour=%_hour
set minute=%_minute
if %month lt 10 set month=0%month
if %day lt 10 set day=0%day
if %hour lt 10 set hour=0%hour
if %minute lt 10 set minute=0%minute
set date=%year-%month-%day-%hour-%minute

echo Disk usage op %date >dir_%date%.txt
rem for %d in (c d) do (du %d:\ | tclsh filter_du.tcl 10000 >>dir_%_date.txt)
for %r in (c d) do (tclsh du-filter.tcl %r:\ >>dir_%date%.txt)
rem for %r in (c) do (tclsh du-filter.tcl %r:\ >>dir_%date%.txt)

tclsh sort-usage.tcl <dir_%date%.txt >dir_%date%_s.txt

echo TODO: diff with previous: what has been added/grown since last check?
echo use unsorted version, possibly stuff deleted in sorted (-s) version.
