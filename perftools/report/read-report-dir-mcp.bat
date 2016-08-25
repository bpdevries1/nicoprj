rem for all subdirs in dir: read logs into sqlite db and create html reports.

rem tclsh read-report-dir.tcl -debug -all -dir c:/PCC/Nico/Testruns/MCPv3/run655

rem TODO remaining time van de hele dir berekenen, nu steeds per subdir opnieuw.

rem tclsh read-report-dir.tcl -all -dir c:/PCC/Nico/Testruns/MCPv3

rem TODO check log (>17:55 23-8) op fouten, zag stacktrace voorbijkomen.

rem even alleen run666
rem tclsh read-report-dir.tcl -all -dir c:/PCC/Nico/Testruns/MCPv3/run667
rem tclsh read-report-dir.tcl -all -dir c:/PCC/Nico/Testruns/MCPv3/ahk-upload-21
rem tclsh read-report-dir.tcl -dir c:/PCC/Nico/Testruns/MCPv3/vugen-2016-08-23--10-36-11

rem del c:\PCC\Nico\Testruns\MCPv3\vugen-2016-08-23--14-26-23\*.db
rem del c:\PCC\Nico\Testruns\MCPv3\vugen-2016-08-23--14-26-23\*.html
rem tclsh read-report-dir.tcl -all -debug -dir c:/PCC/Nico/Testruns/MCPv3/vugen-2016-08-23--14-26-23

rem tclsh read-report-dir.tcl -summary -debug -dir c:/PCC/Nico/Testruns/MCPv3/run670
tclsh read-report-dir.tcl -all -dir c:/PCC/Nico/Testruns/MCPv3/run674-uatv3

