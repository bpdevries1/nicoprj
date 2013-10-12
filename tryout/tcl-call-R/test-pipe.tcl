puts "print(1:10);"
flush stdout
after 5000
puts "print(11:20);"
flush stdout

# tclsh test-pipe.tcl | R --vanilla
# hiermee start R, print 1:10, wacht even, print 11:20.
# lijkt dus goed te werken!

