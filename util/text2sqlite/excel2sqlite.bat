@echo off
setlocal
set EXCEL=%1
tclsh excel2sqlite.tcl %EXCEL%

