# main file for making graphs and reports based on Tools ontology
# @todo deze moet eigenlijk in I:\ staan.

# uitgangspunten
# * eerst baseren op protege-schema voor ITX
# * mogelijk verder te abstraheren, veralgemeniseren.
# * selectie op type object en type relatie.
# * ook selectie op wat onder een algemeen object (groep, straat) valt.
#

package require mysqltcl
package require Itcl

# @todo make a package for protege
# source [file join [file dirname [info script]] protegelib.tcl]
source [file join [file dirname [info script]] COntology.tcl]
source [file join [file dirname [info script]] COntoGraph.tcl]
source [file join [file dirname [info script]] COntoReport.tcl]
source [file join [file dirname [info script]] CObjectStore.tcl]

proc main {argc argv} {
	set do_all [det_do_all $argc $argv]
	
	set contology [COntology::new_instance]
	$contology init
	def_object_types $contology
	
	set contograph [COntoGraph::new_instance]
	$contograph init $contology
	def_graph_types $contograph
	set contoreport [COntoReport::new_instance]
	$contoreport init $contology
	
	if {$do_all} {
		make_all $contograph $contoreport
	} else {
		make_parts $contograph $contoreport
	}
	
	
	$contology cleanup	  
}

proc det_do_all {argc argv} {
	set result 1
	if {$argc == 0} {
		set result 1
	} else {
		if {[lindex $argv 0] == "-p"} {
			set result 0
		} else {
			set result 1
		}
	}
	return $result
}

proc make_all {contograph contoreport} {
	$contograph make_groep_graphs

	make_reports_tools_usage $contoreport
	make_reports_issues $contoreport
	
}

proc make_parts {contograph contoreport} {
	# $contograph make_groep_graphs

	make_reports_tools_usage $contoreport
	# make_reports_issues $contoreport
	# make_xml $contoreport
}


proc def_object_types {contology} {
	$contology def_obj_type Actor [list name description]
	# $contology def_obj_type Artifact [list name artifact_kind description]
	# @todo artifact plaatje dynamischer bepalen, met lambda-proc obv alle attributen 
	$contology def_obj_type Artifact [list name artifact_kind]
	$contology def_obj_type AtomTask [list name description]
	$contology def_obj_type Directory [list name]
	$contology def_obj_type Groep [list name description]
	# @todo: description toegevoegd: mogelijk gaat graph nu fout.
	$contology def_obj_type Issue [list name description]
	# $contology def_obj_type InternalTaskGroup [list name description]
	$contology def_obj_type InternalTaskGroup [list name description]
	$contology def_obj_type Object [list name description]
	$contology def_obj_type BusinessDoel [list name description]
	$contology def_obj_type Activiteit [list name description]
  $contology def_obj_type Stakeholder [list name description]
	$contology def_obj_type Task [list name description]
	# @todo ook usecase en andere subclasses van Task
	$contology def_obj_type Tool [list name description]
	$contology def_obj_type ToolUsage [list name manual description]
	# $contology def_obj_type Usecase [list name]
	#@todo usecase en anderen met description, maar dan wel query-view anders, dat het met left-outer join is, want description is niet verplicht.
	$contology def_obj_type Usecase [list name description]
}

proc def_graph_types {contograph} {
	def_graph_object_types $contograph
	def_graph_relation_types $contograph	
}

proc def_graph_object_types {contograph} {
	$contograph def_object_shape actor [list 1 shape none image "stick.png"]
	# $contograph def_object_shape atomtask [list 1 shape polygon skew 0.10 style filled fillcolor greenyellow]
	# toolusage grotendeels gelijk aan atomtask, dus hetzelfde weergeven
	$contograph def_object_shape atomtask [list 1 shape polygon skew 0.001 style filled fillcolor burlywood1]
	
	$contograph def_object_shape artifact [list 1 shape none image "artifact.png"]
	$contograph def_object_shape "artifact\;database" [list 1 shape none image "database.png"]
	$contograph def_object_shape directory [list 1 shape rectangle style filled fillcolor gold]
	$contograph def_object_shape issue [list 1 shape note style filled fillcolor gold]
	$contograph def_object_shape internaltaskgroup [list 1 shape polygon skew 0.10 style filled fillcolor greenyellow]
	$contograph def_object_shape object [list 1 shape note style filled fillcolor white]
	$contograph def_object_shape activiteit [list 1 shape ellipse style filled fillcolor burlywood1]
	$contograph def_object_shape businessdoel [list 1 shape rectangle style filled fillcolor greenyellow]
  $contograph def_object_shape stakeholder [list 1 shape none image "stick.png"]
	$contograph def_object_shape task [list 1 shape polygon skew 0.10 style filled fillcolor greenyellow]
	$contograph def_object_shape tool [list 1 shape polygon skew 0.001 style filled fillcolor gold]
	
	# @todo nu geen onderscheid meer tussen automatisch en handmatig, heb andere manier nodig om dit aan te geven.
	# @todo dit gaat nu via usecase, met actor. Dit slot dus verwijderen.
	# @todo mogelijk ook toolusage en atomtask samenvoegen.
	$contograph def_object_shape toolusage [list 1 shape polygon skew 0.001 style filled fillcolor burlywood1]
	$contograph def_object_shape "toolusage\;true" [list 1 shape polygon skew 0.10 style filled fillcolor lightpink]
	$contograph def_object_shape "toolusage\;false" [list 1 shape polygon skew 0.001 style filled fillcolor burlywood1]
	# wilde label aan onderkant van stick neerzetten, maar lukt niet, alleen op graph-niveau in te stellen. Misschien nog
	# iets met grouping te doen.
	$contograph def_object_shape usecase [list 1 shape ellipse style filled fillcolor greenyellow]
	
	# @todo misschien moet dit iets worden als:
	# set ar_obj_shapes(artifact) [list 1 [list [list "type=database" shape none image "database.png"] [list 1 erg ingewikkeld.
	# of
	# set ar_obj_shapes(artifact) [list 1 det_special_artifact] waarbij det_special_artifact een method is:
	# proc det_special_artifact {args} {
	#   if {[lindex $args 0] == "database"} {
	#	
	#   } else {
	#
	#   }
	#}
}

proc def_graph_relation_types {contograph} {
	# $contograph def_relation_line  [list 1]

	$contograph def_relation_line actors [list 0] ; # andere kant op, van actor naar usecase.
	$contograph def_relation_line belongs_to [list 0]
	$contograph def_relation_line consumes [list 0]
	$contograph def_relation_line environment_objects [list 0]
	$contograph def_relation_line groeps [list 0]
	$contograph def_relation_line followers [list 1]
	$contograph def_relation_line follows [list 0]
	$contograph def_relation_line has [list 1 label has]
	$contograph def_relation_line input_for [list 1]
	$contograph def_relation_line issues [list 0]
	$contograph def_relation_line issue_objects [list 1]
	$contograph def_relation_line issue_stakeholders [list 0]
	$contograph def_relation_line needs_tools [list 0]	
	$contograph def_relation_line object_issues [list 0]
	$contograph def_relation_line output_from [list 0]
	$contograph def_relation_line produces [list 1]
  $contograph def_relation_line ref_from [list 0]
  $contograph def_relation_line ref_to [list 1]
	$contograph def_relation_line stakeholder_issues [list 1]
	$contograph def_relation_line starts [list 0]
	$contograph def_relation_line start_task [list 1 label "start/sub"]
	$contograph def_relation_line supports [list 1 label supports]
	$contograph def_relation_line task_group [list 0]
	$contograph def_relation_line tasks [list 0] ; # bij sommige graphs misschien wel tonen, niet bij proces-flow.
																								 # of alleen tonen bij reports.
	$contograph def_relation_line usecases [list 1]
	$contograph def_relation_line uses [list 1]
	$contograph def_relation_line uses_tools [list 1]
	$contograph def_relation_line used_by [list 0]
}


proc make_reports_tools_usage {contoreport} {
	$contoreport reset
	$contoreport set_name "Tools and usage"
	$contoreport set_query "select u.name as usage_name, t.name as tool_name 
							 from toolusage u, tool t, relation r
							 where u.object = r.obj_from
							 and t.object = r.obj_to
							 order by u.name, t.name"
	$contoreport add_key_field usage_name
	$contoreport add_value_field tool_name 
	$contoreport make_report

	$contoreport reset
	$contoreport set_name "Tools without usage"
	$contoreport set_query "select t.name, t.description from tool t
							 where not exists (select 1 from toolusage u, relation r 
							 where u.object = r.obj_from
							 and t.object = r.obj_to)"
	$contoreport add_key_field name
	$contoreport add_value_field description 
	$contoreport make_report

	$contoreport reset
	$contoreport set_name "Usage without tools"
	$contoreport set_query "select u.name, u.description from toolusage u
							 where not exists (select 1 from tool t, relation r 
							 where u.object = r.obj_from
							 and t.object = r.obj_to)"
	$contoreport add_key_field name
	$contoreport add_value_field description 
	$contoreport make_report

}

proc make_reports_issues {contoreport} {
	$contoreport reset
	$contoreport set_name "Issues"
	$contoreport set_query "select i.name, i.description, ss.to_name as object
								from issue i
								left join (
									select r.obj_from, r.obj_to, n.short_value to_name
									from relation r, newspaper n
									where n.frame = r.obj_to
									and n.slot = 'name'
								) as ss
								on i.object = ss.obj_from
								order by i.name, ss.to_name"
	$contoreport add_key_field name
	$contoreport add_value_field description
	$contoreport add_value_field object
	$contoreport make_report
	
	$contoreport reset
	$contoreport set_name "Issues per groep"
	$contoreport set_query "select g.name as groep, i.name as issue, i.description
								from groep g, issue i, relation r
								where g.object = r.obj_from
								and r.obj_to = i.object
								order by groep, issue"
	# $contoreport add_key_field groep
	$contoreport add_section_field groep
	$contoreport add_key_field issue
	$contoreport add_value_field description
	$contoreport make_report
	
}

proc make_xml {contoreport} {
	set query "select g.name as groep, i.name as issue, i.description
								from groep g, issue i, relation r
								where g.object = r.obj_from
								and r.obj_to = i.object
								order by groep, issue"
	$contoreport query2xml $query "d:/aaa/issues.xml"
}

main $argc $argv

