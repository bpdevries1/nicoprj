package require ndv

proc main {} {
	set_dot_exe {C:\PCC\Util\GraphViz2.38\bin\dot.exe}
	set f [open testdot.dot w]
	write_dot_header $f
	write_dot_title $f "Test GraphViz"
	
	set node1 [puts_node_stmt $f "Node 1" color blue]
	set node2 [puts_node_stmt $f "Node 2" color blue]
	puts $f [edge_stmt $node1 $node2 color red label edgelabel]
	write_dot_footer $f
	
	close $f
	
	do_dot testdot.dot testdot.png
	
}

main
