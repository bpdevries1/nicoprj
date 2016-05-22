setlocal
set DIR=c:\projecten\ericsson\sitehandler-2011-08\tracertgraph
tclsh routes2dot.tcl %DIR%\tracedetail.csv
move paths.dot %DIR%
cd %DIR%
dot -T png -O paths.dot
cd -


