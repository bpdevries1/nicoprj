set terminal png
set output 'test-R-verdeling.png'

set format y "%g"
set format y2 "%g"
set grid y2tics
set key below
set pointsize 1.0
set title "CR2-MP9-Z0sec"
set xlabel "N (#threads)"
set ylabel "R (sec)"
set yrange [0:*]
set ytics 

set style fill solid 0.5
plot 'test-R.tsv' using 1:2 axes x1y1 with linespoints title 'R' , \
     'test-R.tsv' using 1:($3+$4+$5) axes x1y1 with filledcurves x1  title 'wait_task' , \
     'test-R.tsv' using 1:($3+$4) axes x1y1 with filledcurves x1 title 'wait_proc' , \
     'test-R.tsv' using 1:($3) axes x1y1 with filledcurves x1 title 'D';

set output
exit
