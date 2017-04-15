@echo off
setlocal
rem [2016-05-17 09:59:37] deze zou automatisch moeten kunnen
set workingdir=c:\pcc\nico\util\startapps

rem start tclcron in the background, detach? use 4NT, eg use similar technique to start-activitylog-rabo.bat above.
c:\PCC\util\4nt\4nt.exe /c C:\pcc\nico\nicoprj\systemtools\tclcron\start_tclcron.bat

goto end

:end

rem 31-7-2015 startapps cmd box bleef openstaan, hiermee wellicht gesloten.
rem 31-7-2015 maar na sluiten werd emacs ook mee gesloten...
exit
