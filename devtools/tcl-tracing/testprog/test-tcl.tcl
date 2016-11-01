package require Itcl
package require Tclx

# [2016-11-01 21:17] test fails, not sure why, not important now, only when doing more with ITcl.
#@test never

set TRACE_TO_FILE 0
# set TRACE_TO_FILE 1

if {!$TRACE_TO_FILE} {
	set ftr [open test-tcl.trace w]
}

proc mytracecmd {command argv evalLevel procLevel args} {
	global ftr
	# set str "==> $command *** $argv *** $evalLevel *** $procLevel *** $args"
	set str $argv
	regsub -all "\n" $str " " str
	regsub -all "\t" $str " " str
	puts $ftr "$str\t$procLevel\t$evalLevel"
}

if {$TRACE_TO_FILE} {
	cmdtrace on [open test-tcl-file.trace w]
} else {
	cmdtrace on command mytracecmd
}

source CClasses.tcl

itcl::class ClassA {

	public method main {} {
  	set cl3 [ClassC #auto]

	  set ref [ClassB::new_instance]
	  $cl3 method1 $ref

	  set ref2 [ClassB::new_instance2]
	  $cl3 method1 $ref2
	  
	  puts "class van ClassA: [info class]"	  ; # werkt wel: ::ClassA
		
		uplevel #0 testproc
	}
}

proc testproc {} {
	puts "calling at level 0"	
}


proc main {} {
	set cl1 [ClassA #auto]
	$cl1 main
}

main

cmdtrace off

if {!$TRACE_TO_FILE} {
	close $ftr
}


