rem goto log6
rem goto log10k
rem goto log_siebel
goto log_tkcanvas

rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20091221 -o I:/Klanten/IND/Performance/output
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-erik-20091229 -o I:/Klanten/IND/Performance/output

rem alles
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/ -o I:/Klanten/IND/Performance/output

rem testen:
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20091221/20091217 -o I:/Klanten/IND/Performance/output
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-1-20091028 -o I:/Klanten/IND/Performance/output
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-1-20091028 -o I:/Klanten/IND/Performance/output -s 2009-10-22-15-00-00 -e 2009-10-22-18-30-00
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-1-20091028 -o I:/Klanten/IND/Performance/output -s 2009-10-22-15-00-00 -e 2009-10-22-17-00-00

rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20091221/20091219 -o I:/Klanten/IND/Performance/output
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20091221/20091219 -o I:/Klanten/IND/Performance/output -s 2009-12-19-04-00-00 -e 2009-12-19-05-30-00


rem testen naar andere out-dir
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest -o I:/Klanten/IND/Performance/test/output -taskgraphname file -taskregexp ".*-file"
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest -o I:/Klanten/IND/Performance/test/output -tasks -taskgraphname extractie -taskregexp ".*-dg"
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest -o I:/Klanten/IND/Performance/test/output -tasks -taskgraphname extractie -taskregexp ".*-dg" -s 2009-11-23-13-59-45 -e 2009-11-23-13-59-59
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest2 -o I:/Klanten/IND/Performance/test/output -tasks -taskgraphname scheduler -min_duration 10 -taskregexp "scheduler-.*"  
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest2 -o I:/Klanten/IND/Performance/test/output -taskgraphname file -min_duration 10 -taskregexp ".*-file"
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest1 -o I:/Klanten/IND/Performance/test/output -taskgraphname file -min_duration 10 -taskregexp ".*-file"

rem alleen resource logs
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-erik-20091229 -o I:/Klanten/IND/Performance/test/output -reslogs
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest -o I:/Klanten/IND/Performance/test/output -reslogs

rem siebel logs
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-erik-20091229 -o I:/Klanten/IND/Performance/test/output
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-erik-20091229/20091228-1 -o I:/Klanten/IND/Performance/test/output

rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest3 -o I:/Klanten/IND/Performance/test/output -min_duration 0
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest2 -o I:/Klanten/IND/Performance/test/output -min_duration 60
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest2 -o I:/Klanten/IND/Performance/test/output -taskgraphname extractie -s 2009-10-22-16-00-00 -e 2009-10-22-16-10-00 -taskregexp "extractie.*"
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest2 -o I:/Klanten/IND/Performance/test/output -min_duration 60 -taskregexp ".*extr-.*" -taskgraphname extractie
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest4 -o I:/Klanten/IND/Performance/test/output -min_duration 1
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest5 -o I:/Klanten/IND/Performance/test/output -min_duration 20

rem test van lange makegraph op 24000 records
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-1-20091028/20091022 -o I:/Klanten/IND/Performance/output -taskgraphname file -taskregexp ".*-file"
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-1-20091028/20091022 -o I:/Klanten/IND/Performance/output -tasks

tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20100114 -o I:/Klanten/IND/Performance/output -db testmeetmod -taskregexp ".*-file" -taskgraphname file
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20100114 -o I:/Klanten/IND/Performance/output -db testmeetmod -tasks -min_duration 60 -taskgraphname all
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20100114 -o I:/Klanten/IND/Performance/output -db testmeetmod -tasks -min_duration 60 -taskgraphname fabriek -taskregexp "(-full)|(fabriek-)|(scheduler-)"
goto end

:log6
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest6 -o I:/Klanten/IND/Performance/output -db testmeetmod -tasks -min_duration 10 -taskgraphname fabriek -taskregexp "(-file)|(fabriek-)|(scheduler-)"
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest6 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 60 -taskgraphname fabriek -tasks -taskregexp "(-file)|(fabriek-(CO)?[0-9])|(scheduler-)" 
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest6 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 60 -taskgraphname fabriek -taskregexp "(-file)|(fabriek-(CO)?[0-9])|(scheduler-)" -s 2010-01-13-12-00-00 -e 2010-01-13-12-20-00 

rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest6 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 60
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest6 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 60 -subdir fabriek-se -taskregexp "(-file)|(fabriek-(CO)?[0-9])|(scheduler-)" -s 2010-01-13-12-00-00 -e 2010-01-13-12-20-00 
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest6 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 60
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logtest6 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 60 -subdir fabriek -threadnameregexp "(fabriek)|(scheduler)"
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20100119 -o I:/Klanten/IND/Performance/output -db testmeetmod -subdir file -taskregexp file -tasks

tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20100119 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 60 
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20100119 -o I:/Klanten/IND/Performance/output -db testmeetmod -subdir file -taskregexp file
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20100119 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 60 -subdir fabriek -threadnameregexp "(fabriek)|(scheduler)"
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20100119 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 5 -subdir scheduler -threadnameregexp "scheduler"
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/logging-remco-20100119 -o I:/Klanten/IND/Performance/output -db testmeetmod -subdir reslogs -reslogs
goto end

:log10k
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/log-dap-20100122 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 5
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/log-dap-20100122 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 0 -dohtml
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/log-dap-20100129 -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 5 -maxlines 1200
rem tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input/log-dap-20100129 -o I:/Klanten/IND/Performance/output -db testmeetmod -reslogs -subdir reslogs
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -db testmeetmod -min_duration 5 -maxlines 1200
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -db testmeetmod -reslogs -subdir reslogs
goto end

:log_siebel
tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -min_duration 5 -maxlines 1200
tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -min_duration 0 -maxlines 1200 -subdir all
tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -reslogs -subdir reslogs
goto end

:log_tkcanvas
tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input/logging-remco-20100409/20100407 -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -tasks -min_duration 5 -maxlines 1200 
tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input/logging-remco-20100409/20100407 -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -tasks -min_duration 5 -maxlines 1200 -threadnameregexp "(scheduler)|(sturing)" -subdir schedsturing
:end


