@echo off
setlocal

rem eerst shared env, is default:
rem tclsh get-ALM-PC-testruns.tcl -firstrunid 683 -lastrunid 692
rem tclsh get-ALM-PC-testruns.tcl -firstrunid 737 -lastrunid 738
tclsh get-ALM-PC-testruns.tcl -firstrunid 739 -lastrunid 740


rem tclsh get-ALM-PC-testruns.tcl -domain PCC -project WeekvanWaarden

rem volgenden lukken niet met Runs download, waarschijnlijk te oud.
rem calypso vanaf 49 (t/m 111)
rem tclsh get-ALM-PC-testruns.tcl -domain RI -project Calypso_HW -firstrunid 49 -lastrunid 115

rem tclsh get-ALM-PC-testruns.tcl -domain RI -project RI_Combitest -firstrunid 1105 -lastrunid 1650


