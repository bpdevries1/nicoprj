package require Itcl
package require Tclx

source ../lib/CLogger.tcl
source ../lib/CProgressCalculator.tcl

itcl::class CLineHandler {

	private common log
	set log [CLogger::new_logger [info script] perf]
	
	private variable lst_coutputters
	private variable ar_obj_calls ; # key: level; elements: [list clazz methodd]
	private variable cclasslib
	private variable cur_class ; # voorlopig, eigenlijk moet het met level en ar_obj_calls ook wel kunnen
	private variable debug_level ; # just for debugging, to print in puts_ar_calls
	private variable nlinesread_total ; # number of lines read.
	private variable nlinesread_file ; # number of lines read.
	private variable filename ; # filename of the currently read file
	private variable cprog_calc ; # progress calculator
	
	public constructor {} {
		set lst_coutputters {}
		set cur_class "NONE"
		set nlinesread_total 0
		set nlinesread_file 0
		set cprog_calc [CProgressCalculator::new_instance]
		# $cprog_calc set_items_total 7244 ; # for one trace file
		# $cprog_calc set_items_total 100000 ; # test met wat meer.
		# $cprog_calc set_items_total 3610000 ; # for all trace files, iets meer dan wordcount opgeeft.
		$cprog_calc set_items_total 5120000 ; # for all trace files, iets meer dan wordcount opgeeft.
		$cprog_calc start
	}
	
	public method add_outputter {an_outputter} {
		# set coutputter $an_outputter
		lappend lst_coutputters $an_outputter
		# puts "class of classB0 = [obj_to_class "classB0"]"
		# puts "class of ::ClassA::classB1 =  [obj_to_class "::ClassA::classB1"]"
	}

	public method set_classlib {a_classlib} {
		set cclasslib $a_classlib
	}
	
	public method new_file {a_filename} {
		set filename $a_filename
		set nlinesread_file 0
		for {set i 0} {$i < 50} {incr i} {
			set ar_obj_calls($i) {}
		}
	}
	
	public method handle_line {line} {
		incr nlinesread_total
		incr nlinesread_file
		if {[expr $nlinesread_file % 1000] == 0} {
			$log perf "Number of lines read in file $filename: $nlinesread_file (total: $nlinesread_total)"
			$cprog_calc at_item $nlinesread_total
		}
		# vreen00, 15-12-2008: gebruik evalLevel ipv procLevel.
		foreach {call proclevel level} [split $line "\t"] {
			set debug_level $level
			# set ar_calls($level) $call
			# set ar_obj_calls($level) {} ; # init to empty list.
			# @invariant: cur_class bevat class van aanroepende methode.
			set el_caller [det_class_method_caller [expr $level - 1]]
			set cur_class [lindex $el_caller 0] ; # class part.
			if {[is_interesting $call $cur_class $level]} {
				# det_class_method $call $cur_class callee_class callee_method
				set el_callee [det_class_method $call $cur_class $level]
				# set ar_obj_calls($level) [list $callee_class $callee_method]
				set prev_stack $ar_obj_calls($level) 
				set ar_obj_calls($level) $el_callee
				if {$level <= 1} {
					puts "Set callstack($level) to $el_callee (prev: $prev_stack)"
				}
				set callee_class [lindex $el_callee 0]
				set callee_method [lindex $el_callee 1]
				# set cur_class $callee_class ; # hoeft hier niet meer, gebeurt hierboven al.
				# puts "set cur_class to: $cur_class"
				if {$level > 0} {
					set el_caller [det_class_method_caller [expr $level - 1]]
					set caller_class [lindex $el_caller 0]
					set caller_method [lindex $el_caller 1]
				} else {
					set caller_class ROOT
					set caller_method MAIN
				}
				foreach coutputter $lst_coutputters {
					$coutputter output_call $caller_class $caller_method $callee_class $callee_method
				}
			} else {
				if {[regexp {servers_analyse_reslogs} $call]} {
					puts "WARN: niet interesting: $call ($level)"
					puts_callstack_levels
				}
			}
		}
	}
	
	# debug methode
	private method puts_callstack_levels {} {
		puts "-- Callstack: --"
		for {set i 0} {$i < 10} {incr i} {
			catch {puts "  Level: $i; value: $ar_obj_calls($i)"}
		}
		puts "-- end of callstack --"
	}
	
	# call is interesting if the class is one of ours.
	private method is_interesting {call cur_class level} {
		$log debug "is_interesting: start"
		set callee_class ""
		set callee_method ""
		set el [det_class_method $call $cur_class $level]
		if {[regexp {^unknown} [lindex $el 0]]} {
			if {[regexp {XXXservers_analyse_reslogs} $call]} {
				puts "Toch interesting: $call"
				return 1
			} else {
				return 0
			}
		} else {
			return 1
		}
	}
	
	# zoek caller class in callstack. Dit kan eerste zijn op hoger level, maar kan ook verder omhoog liggen.
	# @return [list class method]
	# @note hier wordt de eerste in de lijst (vanaf huidige level, omhoog) gegeven die niet leeg is.
	private method det_class_method_caller {level} {
		set el_unknown [list UNKNOWN UNKNOWN]
		set found 0
		set index $level
		while {!$found && ($index >= 0)} {
			set el $ar_obj_calls($index)
			if {[llength $el] == 2} {
				# set clazz [lindex $el 0]
				# set methodd [lindex $el 1]
				set found 1
			} else {
				incr index -1
			}
		}
		if {$found} {
			return $el
		} else {
			return $el_unknown
		}
	}
	
	private method det_class_method {call cur_class level} {
		$log debug "det_class_method: start"
		# call kan 2 vormen hebben:
		# abc: een lindex $call 0 levert dan abc
		# {abc def}: een lindex $call 0 levert dan een lijst met 2 elementen: abc en def.
		# puts "call: $call"
		try_eval {
			set call0 [lindex $call 0]
		}  {
			# catch
			puts "Warning: not a list: $call"
			set call0 "unknown"
		}
		set el [det_class_proc $call0 $cur_class $level]
		if {[llength $el] == 2} {
			# klaar, clazz en methodd zijn gevuld
			set result $el
		} else {
			# set clazz [obj_to_class [lindex [lindex $call 0] 0]]
			# set methodd [lindex [lindex $call 0] 1]
			set clazz [obj_to_class [lindex $call0 0]]
			set methodd [lindex $call0 1]
			# #auto zo vroeg mogelijk omzetten in constructor
			if {$methodd == "#auto"} {
				set methodd "constructor" 
			}
			set result [list $clazz $methodd]
		}
		# ook class methods: ClassB::proc1	3 *** ClassB::new_instance	2
		# {ClassB::proc1 abc}	3
		# naast normale: {::ClassA::classB1 get_value}	3
		return $result
	}
	
	# @return 1 if class and method are found
	# @post if returns 1 then class_varname and method_varname are filled.
	private method det_class_proc {call cur_class level} {
		$log debug "det_class_proc: start"
		# upvar $class_varname clazz
		# upvar $method_varname methodd
		set result 0
		set call_1 [lindex $call 0]
		if {[regexp {([^:]+)::([^:]+)$} $call_1 z clazz methodd]} {
			if {[$cclasslib is_method $clazz $methodd]} {
				set result 1
			}
		} else {
			# kijk of het een lokale call is binnen dezelfde class
			if {[$cclasslib is_method $cur_class $call_1]} {
				set clazz $cur_class
				set methodd $call_1
				set result 1
			} else {
				# het kan ook nog een lokale call zijn, maar dat er iets tussen zitten, bv met callbacks. Kijk vanaf level-1 naar boven.
				set found 0
				set index [expr $level - 1]
				while {!$found && ($index >= 0)} {
					set el $ar_obj_calls($index)
					if {[llength $el] == 2} {
						set clzz [lindex $el 0]
						if {[$cclasslib is_method $clzz $call_1]} {
							set found 1
							set result 1
							set clazz $clzz
							set methodd $call_1
						} else {
							incr index -1
						}
					} else {
						incr index -1
					}
				}
			}
		}
		if {$result} {
			return [list $clazz $methodd]
		} else {
			if {[regexp {servers_analyse_reslogs} $call]} {
				puts "det_class_proc: niets: : $call ($cur_class)"
			}
			return {}
		}
	}
	
	private method obj_to_class {obj} {
		if {[regexp {([^:]+)$} $obj z obj2]} {
			if {[regexp {^(.+?)[0-9]*$} $obj2 z clazz]} {
				set clazz [string toupper $clazz 0 0] ; # eerste karakter wordt hoofdletter.
				if {[$cclasslib is_class $clazz]} {
					return $clazz
				} else {
					return "unknown: $clazz"
				}
			} else {
				puts "warn: failed to determine class from object (2): $obj2"
				return "WARN2"
			}
		} else {
			puts "warn: failed to determine class from object (1): $obj"
			return "WARN1"
		}
	}
	
	private method puts_ar_calls {} { 
		puts "*** DEBUG puts_array_calls ***"
		puts "Level: $debug_level"
		for {set i 0} {$i < $debug_level} {incr i} {
			puts "$i: $ar_obj_calls($i)"
		}
	}
	
}


