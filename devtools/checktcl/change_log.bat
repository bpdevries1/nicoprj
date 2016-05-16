@echo off
setlocal
set CHANGE_LOG=C:\vreen00_IPB_Plateau_2\CR_Portals\fundament\test\perf\toolset\cruise\checkout\script\tool\checktcl\change_log.tcl
getclip | tclsh %CHANGE_LOG% | putclip

