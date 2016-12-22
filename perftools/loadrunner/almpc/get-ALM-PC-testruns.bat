@echo off
setlocal

rem eerst shared env, is default:
tclsh get-ALM-PC-testruns.tcl -firstrunid 731 -lastrunid 731
rem tclsh get-ALM-PC-testruns.tcl -domain PCC -project WeekvanWaarden

rem volgenden lukken niet met Runs download, waarschijnlijk te oud.
rem calypso vanaf 49 (t/m 111)
rem tclsh get-ALM-PC-testruns.tcl -domain RI -project Calypso_HW -firstrunid 49 -lastrunid 115

rem tclsh get-ALM-PC-testruns.tcl -domain RI -project RI_Combitest -firstrunid 1105 -lastrunid 1650


