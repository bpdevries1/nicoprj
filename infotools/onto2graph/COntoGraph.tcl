package require Itcl
package require Tclx ; #  voor cmdtrace en try_eval
package require ndv

# class maar eenmalig definieren
if {[llength [itcl::find classes COntoGraph]] > 0} {
	return
}

itcl::class COntoGraph {

	private common log
	set log [::ndv::CLogger::new_logger [file tail [info script]] info]
	# set log [::ndv::CLogger::new_logger [file tail [info script]] debug] 
	
	public proc new_instance {} {
		set result [uplevel {namespace which [COntoGraph \#auto]}]
		return $result
	}

	private variable contology
	private variable ar_obj_shapes
	private variable cobj_store
	private variable db
	
	# elementen var array: el 0: wel (1) of niet (0) opnemen.
	#                      el n en (n+1) (n is oneven): name, value paren van extra op te nemen bij arrow.
	private variable ar_rel_types
	private variable def_rel_type_info	
	
	public method init {an_ontology} {
		set contology $an_ontology
		array unset ar_obj_shapes
		array unset ar_rel_types
		set cobj_store [CObjectStore::new_instance]
		#def_graph_object_types
		#def_graph_relation_types
		set db [$contology get_db]
		set def_rel_type_info [list 1]
	}
	
	public method def_object_shape {object_name lst_shape} {
		set ar_obj_shapes($object_name) $lst_shape		
	}

	public method def_relation_line {relation_type lst_line} {
		set ar_rel_types($relation_type) $lst_line		
	}
	
	# @todo: deze methode naar 'buiten' en hierbij checken op 'plaat' attribuut.
	public method make_groep_graphs {} {
		set lst_groepen [$contology get_objects Groep]
		# elementen zijn lijst: object-id, name.
		foreach el $lst_groepen {
			$log info "make graph for [lindex $el 1]"
			make_groep_graph $el
		}
		
	}
	
	# elementen zijn lijst: object-id, name.
	private method make_groep_graph {el_graph} {
		global env
		# global env db ar_rel_types lst_obj_types log
		set graph_name [lindex $el_graph 1]
		$cobj_store	reset_objects
		
		# create_filter_$graph_name
		create_groep_filter $el_graph
	
		set target_dir [file normalize "generated"]
		set old_dir [pwd]
		cd $target_dir
		
		set f [open [det_dot_name $graph_name] w]
		write_dot_header $f
		
		# set lst_obj_types [list toolusage artifact activity]
		set n_objects 0
		# foreach obj_type $lst_obj_types {}
		foreach obj_type [$contology get_lst_obj_types] {
			set n [puts_objects $f $obj_type]
			incr n_objects $n
		}
		if {$n_objects == 0} {
			$log warn "Graph $graph_name has no objects"
		} else {
			$log debug "Graph $graph_name has $n_objects objects"
		}
		# relaties: van een bepaald type en alleen als beide objecten voorkomen.
		set query "select * from relation"
		set result [::mysql::sel $db $query -list]
		foreach el $result {
			foreach {obj_from obj_to rel_type} $el {
				if {[$cobj_store has_object $obj_from] && [$cobj_store has_object $obj_to]} {
					# puts_dot_relation $f $obj_from $obj_to [list label "\"$rel_type\""]
					# set rel_type_info $ar_rel_types($rel_type)
					set rel_type_info [det_rel_type_info $rel_type]

					if {[lindex $rel_type_info 0] == 1} {
						# puts_dot_relation $f $obj_from $obj_to [list label $rel_type]
						puts_dot_relation $f $obj_from $obj_to [lrange $rel_type_info 1 end]
					}
				}
			}
		}
		
		write_dot_footer $f
		close $f
		
		foreach png_file [glob -nocomplain -directory $env(ONTO2GRAPH_DIR) *.png] {
			# wel multi-copy per graph-file, dus eigenlijk elders neerzetten...
			file copy -force $png_file $target_dir
		}
		exec [file join $env(DOT_DIR) dot.exe] -Tpng [det_dot_name $graph_name] -o [det_png_name $graph_name]
		cd $old_dir
			
	}
	
	# deze is ontologie afhankelijk, beter ergens anders?
	private method create_groep_filter {el_groep} {
		set query "drop view filter"
		catch {::mysql::exec $db $query} 
		set groep_object [lindex $el_groep 0]
		set query "create view filter as
			select o.short_value object
			from newspaper o
			where o.frame = '$groep_object'
			and o.slot = 'elements'"
		::mysql::exec $db $query
	}

	private method puts_objects {f obj_type} {
		#global db
		# alle artifacts met relevante attributen
		# set attr_names $ar_attr_names($objtype)
		set n 0
		set query "select o.* from $obj_type o, filter f where o.object = f.object order by name"
		set result [::mysql::sel $db $query -list]
		foreach el $result {
			set object [lindex $el 0]
			set name [lindex $el 1]
			set lst_attributes [lrange $el 2 end] ; # end-1: laatste veld (van filter-view) niet meegeven.
			if {[puts_dot_object $f $obj_type $object $name $lst_attributes]} {
				$cobj_store add_object $object
				incr n
			}
		}	
		return $n
	}
	
	private method det_rel_type_info {rel_type} {
		set kv_result [array get ar_rel_types $rel_type]
		if {[llength $kv_result] == 2} {
			return [lindex $kv_result 1]
		} else {
			$log warn "No relation type info defined for: $rel_type"
			return $def_rel_type_info
		}
	}

	
	private method det_dot_name {graph_name} {
		return "${graph_name}.dot"
	}
	
	private method det_png_name {graph_name} {
		return "${graph_name}.png"
	}
	
	private method write_dot_header {f} {
		puts $f "digraph G \{
		rankdir = TB
		/*
		size=\"8,11\";
		ratio=fill;
	*/
		node \[fontname=Arial,fontsize=20\];
		edge \[fontname=Arial,fontsize=16\];
	"
	}
	
	
	private method puts_dot_object {f obj_type obj name {lst_obj_attributes {}}} {
		#global ar_obj_shapes
		if {$lst_obj_attributes == {}} {
			set ndx $obj_type
		} else {
			set ndx "$obj_type;[join $lst_obj_attributes ";"]"
		}
		set val [list 0]
		catch {set val $ar_obj_shapes($obj_type)}
		catch {set val $ar_obj_shapes($ndx)}
		set result [lindex $val 0]
		if {$result} {
			set lst_attr [list "label=\"$name\""]
			foreach {nm val} [lrange $val 1 end] {
				lappend lst_attr "$nm=\"$val\""
			}
			puts $f "  $obj \[[join $lst_attr ","]\];"
			#puts "  $obj \[[join $lst_attr ","]\];"
			#exit 1
		} else {
			# don't print this object
			$log warn "Don't graph object: $name ($obj_type)"
		}
		return $result
	}
	
	private method puts_dot_relation {f obj_from obj_to {lst_attributes {}}} {
		set lst_attr {}
		foreach {nm val} $lst_attributes {
			lappend lst_attr "$nm=\"$val\""
		}
		if {$lst_attributes == {}} {
			puts $f "  $obj_from -> $obj_to;"
		} else {
			puts $f "  $obj_from -> $obj_to \[[join $lst_attr ","]\];"
		}
	}
	
	private method write_dot_footer {f} {
		puts $f "\}"
	}	
}
