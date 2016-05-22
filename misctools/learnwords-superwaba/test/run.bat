@echo off

setlocal
set swpath=d:\java\superwaba\
set swpathext=d:\java

set classpath=%classpath%;%swpath%classes;%swpathext%;..\classes
echo %classpath%
rem java ConvertList %1 %2
rem java %swclasspath%;%swpath%org\superwaba\palm\ext\wextras\classes;%swpath%org/superwaba/palm/classes waba.applet.Applet %appName%
rem java waba.applet.Applet ConvertList %1 %2
java waba.applet.Applet LearnWords

