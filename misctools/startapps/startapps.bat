@echo off
setlocal
rem startapps.bat - start apps like , lync, 
rem start from standard command prompt.

rem start /b om geen nieuw window te openen. 
rem /wait wil je juist niet. Toch bij totalcmd wacht 'ie wel.

rem deze doen het:
start /b C:\PCC\Util\TotalCommander\TOTALCMD.EXE
rem start C:\PCC\Util\Console2\Console.exe -t Bash -t 4NT -r c:\PCC\Nico\nicoprj\misctools\startapps\4nt-emacs.bat
rem 4NT moet als eerste config staan, emacs wordt ook hierin geladen dan.
start C:\PCC\Util\Console2\Console.exe -t 4NT -t Bash -r c:\PCC\Nico\nicoprj\misctools\startapps\4nt-emacs.bat
start C:\PCC\Util\PortableApps\Notepad++Portable\Notepad++Portable.exe
rem start /b C:\PCC\util\emacs24.4\bin\emacs.exe
start /b C:\PCC\Util\PortableApps\FirefoxPortable\FirefoxPortable.exe

rem 31-7-2015 greenshot just added, not tested yet.
start C:\PCC\Util\Greenshot\Greenshot.exe

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
cd C:\PCC\nico\typeperf
start c:\PCC\util\4nt\4nt.exe /c start-typeperf.bat

rem AHK shortcuts, first only F8 for timestamp insertion.
start c:\PCC\Nico\AHK-Demo\demo\send-timestamp.exe

rem activitylog
c:\PCC\util\4nt\4nt.exe /c C:\pcc\nico\nicoprj\misctools\activitylog\start-activitylog-rabo.bat

rem utils folder met shortcuts
start explorer C:\Users\vreezen\Desktop\utils


goto end

:end

rem 31-7-2015 startapps cmd box bleef openstaan, hiermee wellicht gesloten.
rem 31-7-2015 maar na sluiten werd emacs ook mee gesloten...
exit
