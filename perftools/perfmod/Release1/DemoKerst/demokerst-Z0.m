set terminal png
set output 'generated\demokerst-Z0.png'

#set xdata time
#set timefmt "%d-%m-%Y-%H:%M:%S"
#set format x "%d-%m\n%H:%M"

set key below
set xlabel "N"

set ylabel "X (reqs/sec)"
set yrange [0:*]
set ytics nomirror
set format y "%g"

set y2label "R (sec)"
set y2range [0:*]
set y2tics
set format y2 "%g"

set pointsize 1.0

plot 'Metingen-Z0.tsv' using 1:2 axes x1y1 with linespoints title "X-meet", \
		 'generated\demokerst-calc-Z0.tsv' using 1:2 axes x1y1 with linespoints title "X-calc", \
		 'Metingen-Z0.tsv' using 1:3 axes x1y2 with linespoints title "R-meet", \
		 'generated\demokerst-calc-Z0.tsv' using 1:3 axes x1y2 with linespoints title "R-calc"
		 
set output
exit

