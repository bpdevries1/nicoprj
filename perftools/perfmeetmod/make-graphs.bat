rem productie - diverse varianten.
rem goto taskonly
goto verwijder
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -min_duration 60 -loglevel info 
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -subdir file -taskregexp file -loglevel info
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -min_duration 60 -subdir fabriek -threadnameregexp "(fabriek)|(scheduler)" -loglevel info
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -min_duration 5 -subdir scheduler -threadnameregexp "scheduler" -loglevel info
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -subdir reslogs -reslogs -loglevel info
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -min_duration 5 -subdir verwijder -threadnameregexp "verwijder" -loglevel info

goto end

:taskonly
tclsh make-graphs.tcl -tasks -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -min_duration 60 -loglevel info 
tclsh make-graphs.tcl -tasks -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -subdir file -taskregexp file -loglevel info
tclsh make-graphs.tcl -tasks -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -min_duration 60 -subdir fabriek -threadnameregexp "(fabriek)|(scheduler)" -loglevel info
tclsh make-graphs.tcl -tasks -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -min_duration 5 -subdir scheduler -threadnameregexp "scheduler" -loglevel info
goto end

:verwijder
tclsh make-graphs.tcl -tr I:/Klanten/IND/Performance/input -o I:/Klanten/IND/Performance/output -min_duration 0 -subdir verwijder -threadnameregexp "verwijder" -loglevel info
goto end

:end
