tclsh routes2dot.tcl c:\projecten\rijkswaterstaat\tracertgraph\RWS_Facilitor_1_Trace_detail.csv
move paths.dot c:\projecten\rijkswaterstaat\tracertgraph
cd c:\projecten\rijkswaterstaat\tracertgraph
dot -T png -O paths.dot
cd -


