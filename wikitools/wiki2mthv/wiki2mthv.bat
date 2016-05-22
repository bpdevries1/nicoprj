rem set CRUISE_DIR=D:\Projecten\BD-portals\perf\toolset\cruise

rem goto label1

set SRC_DIR=C:\nico\jspwiki\wiki-portals
set TARGET_DIR=C:\nico\jspwiki\mthv-portals

tclsh wiki2mthv.tcl %SRC_DIR %TARGET_DIR

goto end

pause

:label1
set SRC_DIR=D:\Projecten\BD-portals\wbd-wiki-perf
set TARGET_DIR=D:\Projecten\BD-portals\mthv_test2

tclsh wiki2mthv.tcl %SRC_DIR %TARGET_DIR

:end
