set terminal png
set output 'T:/model/CR2-MP9/metingen-ESB/XR-Z1.png'

set format y "%g"
set format y2 "%g"
set grid y2tics
set key below
set pointsize 1.0
set title "CR2-MP9-Z1sec-ESB"
set xlabel "N (#threads)"
set y2label "R (sec)"
set y2range [0:*]
set y2tics 
set ylabel "X (#reqs/sec)"
set yrange [0:*]
set ytics nomirror
plot 'T:/model/CR2-MP9/generated-Z1sec-ESB/LQNS.tsv' every 1 using 1:5 axes x1y2 with linespoints title "ESBBericht.R-LQNS", \
'T:/model/CR2-MP9/generated-Z1sec-ESB/LQNS.tsv' every 1 using 1:7 axes x1y2 with linespoints title "ESBRelatie.R-LQNS", \
'T:/model/CR2-MP9/metingen-ESB/ESB-meting-Z1-b1016.tsv' every 1 using 1:2 axes x1y2 with linespoints title "ESBBericht.R-Meting", \
'T:/model/CR2-MP9/metingen-ESB/ESB-meting-Z1-b1016.tsv' every 1 using 1:3 axes x1y2 with linespoints title "ESBRelatie.R-Meting
set output
exit
