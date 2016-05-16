rem set TOOLSET_DIR=C:\vreen00_toolset2\CxR_Toolset\Perf\toolset\cruise\checkout\report

set TOOLSET_DIR=C:\vreen00_toolset2\CxR_Toolset\Perf\toolset\cruise\checkout

set TRACES_DIR=c:\aaa\traces
rem set TRACES_DIR=c:\aaa\traces\klein

rem ***
rem set TOOLSET_DIR=d:\projecten\bd-portals\Perf\toolset\cruise\checkout\report
rem set TOOLSET_DIR=d:\projecten\bd-portals\Perf\toolset\cruise\checkout
rem set TRACES_DIR=d:\projecten\bd-portals\traces

rem tclsh callgraph.tcl %TOOLSET_DIR% <%TRACES_DIR%\filtersuite.tcl.20081114-150933.trace >%TRACES_DIR%\filtersuite1.report
rem tclsh callgraph.tcl %TOOLSET_DIR% <%TRACES_DIR%\filtersuite.tcl.20081114-151514.trace >%TRACES_DIR%\filtersuite2.report

time
rem tclsh callgraph.tcl %TOOLSET_DIR% <%TRACES_DIR%\general.analyse_results.tcl.20081114-151206.trace >%TRACES_DIR%\gen-an-res.report
rem tclsh callgraph.tcl %TOOLSET_DIR% %TRACES_DIR%\filtersuite.tcl.20081114-151514.trace >%TRACES_DIR%\filtersuite2.report
tclsh callgraph.tcl %TOOLSET_DIR% %TRACES_DIR% >%TRACES_DIR%\all.report
time
