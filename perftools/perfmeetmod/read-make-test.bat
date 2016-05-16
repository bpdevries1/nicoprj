rem call read-directories-test.bat
rem set DIRNAME=D:/ITX/Klanten/IND/Performance/input/logging-minh-20100326
rem set DIRNAME=D:/ITX/Klanten/IND/Performance/input/logging-remco-20100409
rem set DIRNAME=D:/ITX/Klanten/IND/Performance/input/logging-minh-20100512
rem set DIRNAME=D:/ITX/Klanten/IND/Performance/input/logging-remco-20100409/20100326
rem set DIRNAME=D:/ITX/Klanten/IND/Performance/input
set DIRNAME=D:/projecten/FrieslandBank2010/fb-logs/2010-09-04
set DIROUTPUT=D:/projecten/FrieslandBank2010/fb-logs/output

del read-directories.log
tclsh read-directories.tcl -dd %DIRNAME% -db testmeetmod -loglevel debug
rem tclsh read-directories.tcl -dd %DIRNAME% -db testmeetmod

rem goto end

tclsh set-machines-tasks.tcl -db testmeetmod

rem call make-graphs-test.bat
del make-graphs.log

goto fb

tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -min_duration 0 -maxlines 2000 -threadnameregexp "sturing" -subdir sturing

rem alles behalve check: in de andere tasknames zit geen 'c'.
rem 13-4-2010 NdV overal -tasks bijgezet, nu nog 1 met -reslogs. Reslogs maken met R is vrij traag.
tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -reslogs -subdir reslogs

:graph

:rest
tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -tasks -min_duration 5 -maxlines 1200 -taskregexp "file" -subdir file
tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -tasks -min_duration 0 -maxlines 2000 -threadnameregexp "sturing" -taskregexp "^[^c]+$" -subdir sturingnocheck
tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -tasks -min_duration 0 -maxlines 2000 -taskregexp "^([^cl])|(laden)" -subdir nocheck
tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -tasks -min_duration 5 -maxlines 1200 -threadnameregexp "(scheduler)|(sturing)" -subdir schedsturing
tclsh make-graphs.tcl -tr D:/ITX/Klanten/IND/Performance/input -o D:/ITX/Klanten/IND/Performance/output -db testmeetmod -tasks -dohtml -min_duration 0 -maxlines 1200 -subdir all

:fb
(Aanmaken overeenkomsten)|(Wachten op BPM)
tclsh make-graphs.tcl -tr %DIRNAME% -o %DIROUTPUT% -db testmeetmod -tasks -dohtml -min_duration 0 -maxlines 1200 -subdir wfstatus -threadnameregexp "wfstatus"
tclsh make-graphs.tcl -tr %DIRNAME% -o %DIROUTPUT% -db testmeetmod -tasks -dohtml -min_duration 1 -subdir wfstatus1 -threadnameregexp "wfstatus"
tclsh make-graphs.tcl -tr %DIRNAME% -o %DIROUTPUT% -db testmeetmod -tasks -dohtml -min_duration 1 -subdir wfstatuspart1 -threadnameregexp "wfstatus" -taskregexp "(Aanmaken overeenkomsten)|(Wachten op BPM)" 
tclsh make-graphs.tcl -tr %DIRNAME% -o %DIROUTPUT% -db testmeetmod -tasks -dohtml -min_duration 0 -maxlines 1200 -subdir all
tclsh make-graphs.tcl -tr %DIRNAME% -o %DIROUTPUT% -db testmeetmod -tasks -dohtml -min_duration 0 -maxlines 1200 -subdir jobs -taskregexp "Job"
rem tclsh make-graphs.tcl -tr %DIRNAME% -o %DIROUTPUT% -db testmeetmod -tasks -dohtml -min_duration 0 -maxlines 1200 -subdir 5min -s 2010-09-02-12-35-00 -e 2010-09-02-12-40-00
rem tclsh make-graphs.tcl -tr %DIRNAME% -o %DIROUTPUT% -db testmeetmod -tasks -dohtml -min_duration 0 -maxlines 1200 -subdir halfmin -s 2010-09-02-12-36-00 -e 2010-09-02-12-36-30 -threadnameregexp "request"

rem @TODO in grafiek ook msec bij start- en eindtijd tonen! (staat wel in DB).

:end
