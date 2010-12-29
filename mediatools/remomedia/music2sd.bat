rem eerste param is pad naar SD kaart, bv F:\
call ..\lib\setenv-media.bat

SET SD_DRIVE=%1
SET WHAT=%2

rem dir %MEDIA_PLAYLISTS%\music-windows.m3u
call tclsh ..\playlist\shuffleplaylist.tcl %WHAT% <%MEDIA_PLAYLISTS%\music-windows.m3u >music-r.m3u
set DATETIME=%_YEAR-%_MONTH-%_DAY-%_HOUR-%_MINUTE-%_SECOND
cp music-r.m3u d:\nico\projecten\muziek\music-sd-%DATETIME%.m3u

tclsh maak_copy_sd.tcl %SD_DRIVE% %WHAT% <music-r.m3u >_copy2sd.bat


