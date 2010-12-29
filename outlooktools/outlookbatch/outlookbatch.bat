@echo off
setlocal
set OUTLOOK_TOOLS_DIR=d:\nico\nicoprj\outlooktools
set THINKINGROCK_DIR=w:\nico\data\TR

rem 14-11-2009 tooltje om outlook vraag automatisch weg te klikken.
start d:\progs\expressclickyes\ClickYes.exe

d:
cd %OUTLOOK_TOOLS_DIR%\OutlookAutoRuby
call movetodo.bat

d:
cd %OUTLOOK_TOOLS_DIR%\outlookmoveruby
call movemail.bat

echo *** Start nieuwe thoughts ***

type %THINKINGROCK_DIR%\thoughts.txt

echo *** bovenstaande thoughts importeren in TR! ***
echo * staan dus in %THINKINGROCK_DIR% *

rem tooltje weer afsluiten
pskill ClickYes

