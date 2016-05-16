package require Itcl

source ../lib/CLogger.tcl
source ../database/CDatabase.tcl
source ../database/CWokoTraceSchemaDef.tcl

itcl::class CDatabaseOutputter {

	private common TO_DATABASE 1 ; # tijdelijk/test, om wel of niet iets in database te schrijven.

	private common log
	set log [CLogger::new_logger [info script] info]
	
	private variable cdb

	private variable ar_bieb_methods ; # key: class.method; value: id in database
	private variable ar_bieb_calls ;   # key: method1_id=>method2_id; value: id in database
	
	public proc new_instance {} {
		return [namespace which [[info class] #auto]]
		# return [CTextOutputter #auto] ; # gaat fout, wegens namespace.
	}
	
	private constructor {} {
		$log debug "CDatabaseOutputter constructor"
		if {$TO_DATABASE} {
			set cdb [CDatabase::get_database]
			set csd [CWokoTraceSchemaDef::new_instance]
			$cdb set_schemadef $csd
		} else {
			set cdb ""
			set csd ""
		}
	}
	
	public method output_line {line} {
		puts $line
	}
	
	public method output_call {caller_class caller_method callee_class callee_method} {
		puts "$caller_class.$caller_method => $callee_class.$callee_method"
		set caller_method_id [select_method $caller_class $caller_method]
		if {$caller_method_id == -1} {
			if {$caller_class != "UNKNOWN"} {
				$log warn "$caller_class.$caller_method not found in database, ignoring..."
			}
			return
		}
		set callee_method_id [select_method $callee_class $callee_method]
		if {$callee_method_id == -1} {
			if {$callee_class != "UNKNOWN"} {
				$log warn "$callee_class.$callee_method not found in database, ignoring..."
			}
			return
		}

		set call_id [select_call $caller_method_id $callee_method_id]
		if {$call_id >= 0} {
			incr_methodcall $call_id
		} else {
			if {$TO_DATABASE} {
				set call_id [$cdb insert_object methodcall -nCalls 1 -caller_id $caller_method_id -callee_id $callee_method_id]
			} else {
				set call_id 1
			}
			set ar_bieb_calls("${caller_method_id}=>${callee_method_id}") $call_id
		}
	}

	# @pre staat mogelijk in bieb, of niet.
	# @post als in db, dan ook in bieb.
	# @post als niet in db, dan ook niet in bieb.
	# @return id van de call, als gevonden, anders -1
	private method select_call {caller_method_id callee_method_id} {
		set lst [array get ar_bieb_calls "${caller_method_id}=>${callee_method_id}"]
		if {[llength $lst] == 2} {
			return [lindex $lst 1]
		}
		
		if {$TO_DATABASE} {		
			set lst_ids [$cdb find_objects methodcall -caller_id $caller_method_id -callee_id $callee_method_id]
			if {[llength $lst_ids] == 1} {
				set call_id [lindex $lst_ids 0]
				set ar_bieb_calls("${caller_method_id}=>${callee_method_id}") $call_id
				return $call_id
			} elseif {[llength $lst_ids] == 0} {
				# a new call
				return -1
			} else {
				$log error "More than one methodcall found for: $caller_class.$caller_method => $callee_class.$callee_method: $lst_ids"
				return -1
			}
		} else {
			return 1 ; # doe net alsof alles gevonden is, dan geen warning.
		}
	}
	
	# private variable ar_bieb_methods ; # key: class.method; value: id in database
	private method select_method {class_name method_name} {
		# first check the cache
		set lst [array get ar_bieb_methods "$class_name.$method_name"]
		if {[llength $lst] == 2} {
			return [lindex $lst 1]
		}
		
		set result -1
		if {$TO_DATABASE} {
			# gebruik even beschikbare functies, niet meest efficient, want 2 queries nodig...
			set lst_ids [$cdb find_objects classdef -name $class_name]
			if {[llength $lst_ids] == 1} {
				set classdef_id [lindex $lst_ids 0]
				set lst_ids [$cdb find_objects methoddef -parent_id $classdef_id -name $method_name]
				if {[llength $lst_ids] == 1} {
					set result [lindex $lst_ids 0]
				} else {
					if {$class_name != "UNKNOWN"} {
						$log warn "Method: $class_name.$method_name not found exactly 1 time: $lst_ids"
					}
				}
			} else {
				if {$class_name != "UNKNOWN"} {
					$log warn "Class: $class_name not found exactly 1 time: $lst_ids"
				}
			}
		} else {
			set result 1 ; # doe net alsof alles gevonden is, dan geen warning.
		}
		set ar_bieb_methods("$class_name.$method_name") $result
		return $result
	}
	
	private method incr_methodcall {methodcall_id} {
		if {$TO_DATABASE} {
			set conn [$cdb get_connection]
			::mysql::exec $conn "update MethodCall set nCalls = nCalls + 1 where id = $methodcall_id"
		}
	}
	
	# @pre directory zit nog niet in database. Nog niet checken, maar als checken, dan hier
	public method add_directory {a_directory} {
		$log debug "Adding $a_directory to database"
		if {$TO_DATABASE} {
			set lst_parent_ids [$cdb find_objects directory -path [file dirname $a_directory]]
			if {[llength $lst_parent_ids] == 1} {
				set parent_id [lindex $lst_parent_ids 0]
			} else {
				set parent_id NULL
				# zou alleen bij root mogen voorkomen
				$log warn "No parent_dir found for: $a_directory, is this the root?"
			}
			set id [$cdb insert_object directory -path $a_directory -parent_id $parent_id]
		} else {
			# nothing
		}
	}

	# @pre sourcefile nog niet in db, z'n parent-dir wel.
	public method add_sourcefile {a_sourcefile} {
		# return ; # nu even niet.
		if {$TO_DATABASE} {
			set str_parent [file dirname $a_sourcefile]
			set lst_ids [$cdb find_objects directory -path $str_parent]
			if {[llength $lst_ids] == 1} {
				set parent_id [lindex $lst_ids 0]
				set id [$cdb insert_object sourcefile -path $a_sourcefile -parent_id $parent_id]	
			} else {
				$log error "Found 0 or more than 1 parent for: $a_sourcefile: $lst_ids"
			}
		} else {
			# nothing
		}
	}
	
	public method add_classdef {a_sourcefile a_classdef lst_methods} {
		# return ; # nu even niet.
		if {$TO_DATABASE} {
			set lst_ids [$cdb find_objects sourcefile -path $a_sourcefile]
			if {[llength $lst_ids] == 1} {
				set parent_id [lindex $lst_ids 0]
				set id [$cdb insert_object classdef -name $a_classdef -parent_id $parent_id]
				foreach method $lst_methods {
					set method_id [$cdb insert_object methoddef -name $method -parent_id $id]
				}
			} else {
				$log error "Found 0 or more than 1 parent for: $a_classdef: $lst_ids"
			}
		}
	}
	
	
}

