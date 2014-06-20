@echo off
setlocal

rem c:\util\graphviz\graphviz\bin\dot.exe -Tpng -o general.analyse-part2.bat.png general.analyse-part2.bat.dot

set SRCNAME=build-suite.xml
c:\util\graphviz\graphviz\bin\dot.exe -Tpng -o %SRCNAME%.png %SRCNAME.dot
c:\util\graphviz\graphviz\bin\dot.exe -Tcmap -o %SRCNAME%.map %SRCNAME.dot


