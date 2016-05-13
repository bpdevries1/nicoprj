@echo off
setlocal
set DIR_ORIG=%_cwd
if "%CRUISE_DIR%"=="" set CRUISE_DIR=D:\perftoolset\toolset\cruise
if "%GNUPLOT_EXE%"=="" set GNUPLOT_EXE=D:\util\gnuplot424\bin\pgnuplot.exe
if "%LQNS_HOME%"=="" set LQNS_HOME=D:\util\perf\lqn\LQN Solvers

set MODEL=%1
subst t: d:\perftoolset

T:
rem cd \model\showcase
cd \model

tclsh CCalcModels.tcl %MODEL%

cd %DIR_ORIG%

