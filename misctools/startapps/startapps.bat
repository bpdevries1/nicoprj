@echo off
setlocal
rem startapps.bat - start apps like , lync, 
rem start from standard command prompt.
rem source - nicoprj/misctools/startapps
rem target - c:/PCC/nico/util/startapps

rem [2016-05-17 09:59:37] deze zou automatisch moeten kunnen
set workingdir=c:\pcc\nico\util\startapps

rem start /b om geen nieuw window te openen. 
rem /wait wil je juist niet. Toch bij totalcmd wacht 'ie wel.

rem deze doen het:
start /b C:\PCC\Util\TotalCommander\TOTALCMD.EXE
rem start C:\PCC\Util\Console2\Console.exe -t Bash -t 4NT -r c:\PCC\Nico\nicoprj\misctools\startapps\4nt-emacs.bat
rem 4NT moet als eerste config staan, emacs wordt ook hierin geladen dan.
rem start C:\PCC\Util\Console2\Console.exe -t 4NT -t Bash -r c:\PCC\Nico\nicoprj\misctools\startapps\4nt-emacs.bat
start C:\PCC\Util\Console2\Console.exe -t 4NT -t Bash -r %workingdir%\4nt-emacs.bat

rem [2016-12-06 10:22:20] onduidelijk hoe emacs nu wordt gestart, maar wordt wel gedaan bij startapps.bat.
rem kan 4nt-emacs.bat hierboven zijn.
rem C:\PCC\nico\util\startapps>type 4nt-emacs.bat
rem detach C:\PCC\util\emacs24.4\bin\emacs.exe

start C:\PCC\Util\PortableApps\Notepad++Portable\Notepad++Portable.exe
rem start /b C:\PCC\util\emacs24.4\bin\emacs.exe
start /b C:\PCC\Util\PortableApps\FirefoxPortable\FirefoxPortable.exe

rem 31-7-2015 greenshot just added, not tested yet.
start C:\PCC\Util\Greenshot\Greenshot.exe

rem cd "C:\Program Files (x86)\HP\LoadRunner\bin"
rem [2016-06-01 10:05:52] nu versie 12.50.
rem cd "C:\Program Files (x86)\HP\Virtual User Generator\bin"
rem [2016-11-03 14:06:09] LR 12.53 all-inclusive geinstalleerd:
cd "C:\Program Files (x86)\HP\LoadRunner\bin"
start VuGen.exe

cd "C:\Program Files (x86)\Microsoft Office\Office12"
start OUTLOOK.EXE
start WINWORD.EXE

cd "C:\Program Files (x86)\Microsoft Office\Office15"
start lync.exe

rem cd "C:\Program Files (x86)\Microsoft Lync"
rem start communicator.exe

rem typeperf - added 2015-11-03, nog testen.
rem [2016-11-09 13:18:05] nu een jaar later nog niet naar gekeken, en met nieuwe PC met 8GB gaat het beter.
rem cd C:\PCC\nico\typeperf
rem start c:\PCC\util\4nt\4nt.exe /c start-typeperf.bat

rem AHK shortcuts, first only F8 for timestamp insertion.
rem start c:\PCC\Nico\AHK-Demo\demo\send-timestamp.exe
start c:\PCC\Nico\util\ahkmacro\send-timestamp.exe

rem activitylog
c:\PCC\util\4nt\4nt.exe /c C:\pcc\nico\nicoprj\misctools\activitylog\start-activitylog-rabo.bat

rem utils folder met shortcuts
start explorer C:\Users\vreezen\Desktop\utils

rem start tclcron in the background, detach? use 4NT, eg use similar technique to start-activitylog-rabo.bat above.
c:\PCC\util\4nt\4nt.exe /c C:\pcc\nico\nicoprj\systemtools\tclcron\start_tclcron.bat

goto end

:end

rem 31-7-2015 startapps cmd box bleef openstaan, hiermee wellicht gesloten.
rem 31-7-2015 maar na sluiten werd emacs ook mee gesloten...
exit
