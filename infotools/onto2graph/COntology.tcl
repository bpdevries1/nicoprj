package require Itcl
package require Tclx ; #  voor cmdtrace en try_eval
package require ndv

# class maar eenmalig definieren
if {[llength [itcl::find classes COntology]] > 0} {
	return
}

itcl::class COntology {

	private common log
	set log [::ndv::CLogger::new_logger [file tail [info script]] info]
	# set log [::ndv::CLogger::new_logger [file tail [info script]] debug] 
	
	public proc new_instance {} {
		set result [uplevel {namespace which [COntology \#auto]}]
		return $result
	}
	
	private variable db
	private variable lst_obj_types
	
	public method init {} {
		db_connect
		db_make_view_relation
		set lst_obj_types {}
	}
	
	public method cleanup {} {
		db_disconnect
	}

	public method get_db {} {
		return $db
	}
	
	public method get_lst_obj_types {} {
		return $lst_obj_types
	}
	
# @return lowercase name of object_type (object_name)
	public method def_obj_type {object_name lst_attributes} {
		set view_name [string tolower $object_name]
		db_make_view $view_name $object_name $lst_attributes
		lappend lst_obj_types $view_name
		return $view_name
	}

	public method get_objects {obj_type} {
		set query "select object, name from groep order by name"
		set result [::mysql::sel $db $query -list]
		return $result
	}
	
	
	private method db_connect {} {
		set db [::mysql::connect -user itx -password "!Tx00;" -db protege]
	}

	private method db_disconnect {} {
		::mysql::close $db
	}


	# relation is wel zo algemeen dat 'ie hierin kan.
	private method db_make_view_relation {} {
		set query "drop view relation"
		catch {::mysql::exec $db $query}
		set table "newspaper"
		set query "create view relation as
			SELECT frame obj_from, short_value obj_to, slot rel_type FROM $table 
			where not slot like ':%'"
		::mysql::exec $db $query
	}

	private method db_make_view {view_name object_name lst_attributes} {
		set query "drop view $view_name"
		catch {::mysql::exec $db $query}
		
		set table "newspaper"
		
		if {0} {
		set query1 "create view $view_name as 
			select t1.short_value object, [det_db_columns $lst_attributes]
			from $table t1, [det_db_tables $table $lst_attributes]
			where t1.frame = '$object_name'
			and t1.slot = ':DIRECT-INSTANCES'
			[det_db_where_clauses $lst_attributes]"
		}
		set query "create view $view_name as 	
			select t1.short_value as object, [det_db_columns $lst_attributes]
			from $table t1
			[det_db_left_joins $lst_attributes]
			where t1.frame = '$object_name'
			and t1.slot = ':DIRECT-INSTANCES'
			"
			
			
		$log debug "query: $query"
		::mysql::exec $db $query
	}
	
	private method det_db_columns {lst_attributes} {
		set lst {}
		set i 2
		foreach el $lst_attributes {
			lappend lst "t$i.short_value as $el"
			incr i
		}
		return [join $lst ", "]
	}
	
	private method det_db_left_joins {lst_attributes} {
		set lst {}
		set i 2
		foreach el $lst_attributes {
			# lappend lst "and t$i.frame = t1.short_value and t$i.slot = '$el'"
			lappend lst "left join newspaper t${i}
			on (t1.short_value = t${i}.frame and t${i}.slot = '$el')"
			
			
			incr i
		}
		return [join $lst "\n"]
	}	
	
	private method det_db_tables_old {table lst_attributes} {
		set lst {}
		set i 2
		foreach el $lst_attributes {
			lappend lst "$table t$i"
			incr i
		}
		return [join $lst ", "]
	}
	
	private method det_db_where_clauses_old {lst_attributes} {
		set lst {}
		set i 2
		foreach el $lst_attributes {
			lappend lst "and t$i.frame = t1.short_value and t$i.slot = '$el'"
			incr i
		}
		return [join $lst "\n"]
	}
	
	
}
