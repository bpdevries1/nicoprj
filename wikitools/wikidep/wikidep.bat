set DIR_NAME=c:\temp\wiki
set EXPORT_NAME=wiki-export.xml
echo y | del /sx %DIR_NAME%\pages\*
echo y | del /sx %DIR_NAME%\sourcedep\*
md /s %DIR_NAME%\pages
md /s %DIR_NAME%\sourcedep
tclsh splitxml2files.tcl %DIR_NAME% %EXPORT_NAME%
ruby ..\sourcedep\sourcedep.rb sourcedep-wiki.xml

