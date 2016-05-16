# CClassDef.tcl - class definition for persisting objects of a given class.

package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CClassDef]] > 0} {
	return
}

source [file join [file dirname [info script]] .. lib CLogger.tcl]

# source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]

# set logger_name [file rootname [file tail [info script]]]

#addLogger $logger_name
#setLogLevel $logger_name info
# setLogLevel $logger_name debug

# @todo (?) ook nog steeds pk en fk defs, voor queries?
itcl::class CClassDef {

	private common log
	set log [CLogger::new_logger [file tail [info script]] info]

	public proc new_classdef {schemadef class_name id_field} {
    set classdef [uplevel {namespace which [CClassDef #auto]}]
    $classdef init $schemadef $class_name $id_field
    return $classdef
	}

	private variable schemadef
	private variable db
	
	private variable class_name
	private variable table_name
	private variable id_field
	private variable superclass_def ""
	private variable superclass_field_name ""
	private variable field_defs ; # assoc. array of CFieldDef

	public method init {a_schemadef a_class_name an_id_field} {
		set schemadef $a_schemadef
		set db [$schemadef get_db]
		set class_name $a_class_name
		set table_name $class_name
		set id_field $an_id_field
	}

	# @param a_superclass_name: notesobject
	# @param a_field_name: notesobject_id ; # fieldname in subclass table
	# @todo superclass_field_name niet nodig, want is gelijk aan id_field
	public method set_superclass {a_superclass_name a_superclass_field_name} {
		# set superclass_name $a_superclass_name
		set superclass_def [$schemadef get_classdef $a_superclass_name]
		set superclass_field_name $a_superclass_field_name
		add_field_def $superclass_field_name integer null
	}

	public method add_field_def {a_field_name {a_datatype string} {a_default ""}} {
		# even spod, voor nieuwe jmatter, zonder deleted velden.
		if {$a_field_name != "deletedOn"} {
			set field_defs($a_field_name) [CFieldDef #auto $a_field_name $a_datatype $a_default]
		}
	}

	public method get_table_name {} {
		return $table_name
	}

	public method get_field_def {field_name} {
		return $field_defs($field_name)
	}

	public method get_id_field {} {
		return $id_field
	}

	# @param args: -cctimestamp $cctimestamp -label $label -artifacts_dir $artifacts_dir
	public method insert_object {args} {
		# @note: possible that all args are now in the list, but llength == 1
		if {[llength $args] == 1} {
			set args [lindex $args 0]
		}

		set args_prev {}
		while {([llength $args] == 1) && ($args != $args_prev)} {
			set args_prev $args
			set args [lindex $args 0]
		}

		$log debug "args: $args \[[llength $args]\]"
	
		init_values values
		if {$superclass_def != ""} {
			set id [$superclass_def insert_object $args]
			set values($superclass_field_name) $id
		} else {
			set id ""
		}
		# array set fields $args
		set_values_from_args values $args

		set query "insert into $table_name ([det_field_names]) values ([det_values values])"
		$log debug "inserting record into $table_name: $query" 
    set res [::mysql::exec $db $query]
    if {$res != 1} {
      $log error "insert of $class_name did not return 1" 
    }
		
		if {$id == ""} {
      set id [::mysql::insertid $db] 
		} else {
			# id al bij superclass gezet.
		}
		
    $log debug "Inserted $class_name with id: $id"
		
		return $id
	}

	# @param args: -cctimestamp $cctimestamp -label $label -artifacts_dir $artifacts_dir
	public method update_object {id args} {
		# @note: possible that all args are now in the list, but llength == 1
		if {[llength $args] == 1} {
			set args [lindex $args 0]
		}
		
		set args_prev {}
		while {([llength $args] == 1) && ($args != $args_prev)} {
			set args_prev $args
			set args [lindex $args 0]
		}
		
		$log debug "args: $args \[[llength $args]\]" 
	
		# init_values values ; # not here, don't want the defaults to overwrite the previously set values.
		if {$superclass_def != ""} {
			$superclass_def update_object $id $args
		} else {
			# nothing
		}
		# array set fields $args
		set_values_from_args values $args

		set set_clause [det_set_clause values]
		if {$set_clause == ""} {
			# nothing, no fields to be updated in this (super)class
			$log debug "set clause empty, no need to update $class_name" 
		} else {
			set query "update $table_name $set_clause where $id_field = $id"
			$log debug "updating record in $table_name with id $id: $query" 
	    set res [::mysql::exec $db $query]
	    if {$res == 1} {
				# ok
			} elseif {$res == 0} {
				# also ok, it's possible that no field is updated, so 0 is returned.
			} else {
	      $log error "update of $class_name $id did not return 0 or 1, but $res; query: $query" 
	    }
	    $log debug "Updated $class_name with id: $id" 
		}		
	}

	private method det_set_clause {values_name} {
		upvar $values_name values
		set result {}
		foreach field_name [array names values] {
			if {[array names field_defs -exact $field_name] != ""} {
				lappend result "$field_name = [$field_defs($field_name) det_value $values($field_name)]"
			} else {
				$log warn "$field_name not found in $class_name" 
			}
		}
		if {[llength $result] == 0} {
			return ""
		} else {
			return "set [join $result ", "] "
		}
	}

	# @return: list of object ids: 0, 1 or more.
	public method find_objects {args} {
		# @note: possible that all args are now in the list, but llength == 1
		set args_prev {}
		while {([llength $args] == 1) && ($args != $args_prev)} {
			set args_prev $args
			set args [lindex $args 0]
		}
		$log debug "args: $args \[[llength $args]\]" 
		# set query "select t.$id_field from $table_name t where [det_where_clause $args]"
		set query "select t.$id_field from [det_table_refs] where [det_where_clause $args]"
		$log debug "query: $query" 
		# @todo query uitvoeren
		# set result {}
		
   	set result [::mysql::sel $db $query -flatlist]
		# lappend result 23
		# lappend result 24
		return $result
	}

	# @return <tablename> t if no superclass and '<tablename> t, <super-tablename> s' if the class has a superclass.
	private method det_table_refs {} {
		if {$superclass_def == ""} {
			return "$table_name t"
		} else {
			return "$table_name t, [$superclass_def get_table_name] s"
		}
	}

	private method init_values {values_name} {
		upvar $values_name values
		foreach field_name [array names field_defs] {
			set values($field_name) [$field_defs($field_name) get_default]
		}
	}

	private method set_values_from_args {values_name lparams} {
		upvar $values_name values
		$log debug "lparams: $lparams \[[llength $lparams]\]" 

		array set params $lparams
		foreach param_name [array names params] {
			if {[regexp {^-(.+)$} $param_name z par_name]} {
				set values($par_name) $params($param_name)
			} else {
				$log error "syntax error in param_name (should start with -): $param_name"
			}
		}		
	}

	private method det_field_names {} {
		set result [lsort [array names field_defs]]
		return [join $result ", "]
	}

	private method det_values {values_name} {
		upvar $values_name values
		set result {}
		foreach field_name [lsort [array names field_defs]] {
			lappend result [$field_defs($field_name) det_value $values($field_name)]
		}
		return [join $result ", "]
	}

	private method det_where_clause {lparams} {
		array set params $lparams
		set result {}
		foreach param_name [array names params] {
			if {[regexp {^-(.+)$} $param_name z par_name]} {
				# set values($par_name) $params($param_name)
				# lappend result "t.$par_name = [$field_defs($par_name) det_value $params($param_name)]"
				if {[array names field_defs -exact $par_name] != ""} {
					lappend result "t.$par_name = [$field_defs($par_name) det_value $params($param_name)]"
				} else {
					$log warn "$par_name not found in $table_name, asking superclass" 
					lappend result "s.$par_name = [[$superclass_def get_field_def $par_name] det_value $params($param_name)]"
				}
			} else {
				$log error "syntax error in param_name (should start with -): $param_name"
			}
		}
		if {$superclass_def != ""} {
			lappend result "t.$id_field = s.[$superclass_def get_id_field]"
		}
		return [join $result " and "]
	}

}

itcl::class CFieldDef {

	private variable field_name
	private variable data_type
	private variable default	

	public constructor {a_field_name a_data_type a_default} {
		set field_name $a_field_name
		set data_type $a_data_type
		set default $a_default
	}

	public method get_default {} {
		if {$default == "CURTIME"} {
			return [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
		} else {
			return $default
		}
	}
	
	# quote the value if necessary
	public method det_value {value} {
		if {($data_type == "integer") || ($data_type == "float")} {
			if {$value == "null"} {
				return $value
			} elseif {$value == ""} {
				return "null"
			} else {
				return $value
			}
		} else {
			if {$value == "null"} {
				return $value
			} else {
				return "'$value'"
			}
		}
	}
	
}

