@echo off
setlocal
rem cd C:\vreen00_view\Webdiensten_performanceVOB\Auto\cruise\checkout

set ROOT_DIR=C:\vreen00_IPB_Plateau_1_test\GPSPRTFund\IPB-Fund-Test\perf\toolset\cruise\checkout
cd %ROOT_DIR%

global /Q /I for %f in (*.tcl) do tclsh \nico\util\tcl\3rdparty\bracecheck\bracecheck.tcl <%f | grep "ERROR:"
cd -

tclsh checktcl.tcl %$ %ROOT_DIR% |& tee %TMP%\checktcl.out

