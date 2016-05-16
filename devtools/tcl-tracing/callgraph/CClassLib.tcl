package require Itcl

source ../lib/CLogger.tcl

itcl::class CClassLib {

	private common log
	set log [CLogger::new_logger [info script] perf]
	
	public proc new_instance {} {
		return [namespace which [[info class] #auto]]
	}

	private variable ar_classes ; # index: class, value: 1
	private variable ar_methods ; # index: class, value: list of methods
	private variable ar_calls ; # index: class.method, value: 0 of 1 (or number of uses)
	private variable ar_filenames ; # index: class, value: full path
	private variable ar_file_classes ; # index: full path, value: list of classes
	private variable db_outputter
	
	private constructor {} {
		# set ar_classes(ClassA) 1
		# set ar_classes(ClassB) 1
		# set ar_classes(ClassC) 1
	}
	
	public method set_db_outputter {a_db_outputter} {
		set db_outputter $a_db_outputter
	}
	
	public method read_source_tree {source_dir} {
		$log perf "Start reading source tree"
		read_source_tree_rec $source_dir
		$log perf "Finished reading source tree, checking double classes"
		check_double_classes
		$log perf "Finished checking double classes; #files read: [llength [array names ar_file_classes]]"
	}
	
	private method read_source_tree_rec {source_dir} {
		# script/tool dir niet inlezen
		if {[regexp {script/tool$} $source_dir]} {
			return
		}
		# test dirs ook overslaan
		if {[regexp {/test$} $source_dir]} {
			return
		}
		# _archief dirs ook overslaan
		if {[regexp {/_archief$} $source_dir]} {
			return
		}
		
		$db_outputter add_directory $source_dir
		
		set filenames [glob -nocomplain -directory $source_dir *.tcl]
		foreach filename $filenames {
			read_source_file $filename
		}
		foreach subdir [glob -nocomplain -directory $source_dir -type d *] {
			if {![regexp {pfebk} $subdir]} {
				read_source_tree_rec $subdir
			}
		}
	}
	
	private method read_source_file {filename} {
		$db_outputter add_sourcefile $filename
		set lst_classes {}
		set cur_class "NONE"
		set lst_methods {}
		set f [open $filename r]
		while {![eof $f]} {
			gets $f line
			set line_trimmed [string trim $line]
			if {[regexp {^#} $line_trimmed]} {
				continue
			}
			if {[regexp {itcl::class ([^ ]+) } $line z classname]} {
				if {$cur_class != "NONE"} {
					set ar_methods($cur_class) $lst_methods
					$db_outputter add_classdef $filename $cur_class $lst_methods
				}
				set cur_class $classname
				# set ar_classes($classname) 1
				incr ar_classes($classname)
				set ar_filesnames($classname) $filename
				lappend lst_classes $classname
				set lst_methods {}
			} elseif {[regexp {^(.+) method ([^ ]+) } $line z prefix methodname]} {
				#		private method calc_request_times
				set prefix [string trim $prefix]
				if {($prefix == "public") || ($prefix == "private")} { 
					lappend lst_methods $methodname
					set ar_calls($cur_class.$methodname) 0
				}
			} elseif {[regexp {^(.+) proc ([^ ]+) } $line z prefix methodname]} {
				# door 2 puntjes (2 spaties of tabs) alleen de class-procs.
				# puts "Found proc for class $cur_class in file $filename: $methodname"
				set prefix [string trim $prefix]
				if {($prefix == "public") || ($prefix == "private")} { 
					lappend lst_methods $methodname
					set ar_calls($cur_class.$methodname) 0
				}	
			} elseif {[regexp {(constructor)} $line z methodname]} {
				# puts "Found constructor for class $cur_class in file $filename"
				lappend lst_methods $methodname
				set ar_calls($cur_class.$methodname) 0
			}
		} ; # end-while
		if {$cur_class != "NONE"} {
			set ar_methods($cur_class) $lst_methods
			$db_outputter add_classdef $filename $cur_class $lst_methods
		}
		set ar_file_classes($filename) $lst_classes
		close $f
	}
	
	public method is_class {class_name} {
		if {[llength [array get ar_classes $class_name]] > 0} {
			return 1
		} else {
			return 0
		}
	}
	
	public method is_method {class_name method_name} {
		if {[is_class $class_name]} {
			if {[lsearch -exact $ar_methods($class_name) $method_name] > -1} {
				return 1
			} else {
				return 0
			}
		} else {
			return 0
		}
	}
	
	public method output_call {caller_class caller_method callee_class callee_method} {
		# puts "$caller_class.$caller_method => $callee_class.$callee_method"
		if {$callee_method == "#auto"} {
			$log error "Fout: callee_method moet hier al omgezet zijn van #auto naar constructor"
			set callee_method "constructor"
		}
		incr ar_calls($callee_class.$callee_method)
	}
	
	# elke class mag maar een keer voorkomen (niet meerdere namespaces hiervoor)
	# check hiervoor de array ar_classes($classname)
	private method check_double_classes {} {
		foreach clazz [lsort [array names ar_classes]] {
			if {$ar_classes($clazz) > 1} {
				$log warn "Warning: more than 1 definition of class: $clazz ($ar_classes($clazz))"
			}
		}
	}
	
	# report per file, class and method, including number of calls
	public method report {} {
		puts "=============="
		puts "=== Report ==="
		puts "=============="
		foreach filename [lsort [array names ar_file_classes]] {
			puts "File: $filename"
			foreach classname $ar_file_classes($filename) {
				puts "  Class: $classname"
				foreach method $ar_methods($classname) {
					puts "    Method: $method; number of calls: $ar_calls($classname.$method)"
				}
			}
		}
	}
	
}
