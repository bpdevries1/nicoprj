# NotesSchemaDef.tcl - DB schema definition for Notes, with more than 3 tables.

package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CWokoTraceSchemaDef]] > 0} {
	return
}

# source [file join $env(CRUISE_DIR) checkout script database CClassDef.tcl]

source [file join [file dirname [info script]] CClassDef.tcl]
source [file join [file dirname [info script]] .. lib CLogger.tcl]

# setLogLevel NotesSchemaDef debug

# @todo (?) ook nog steeds pk en fk defs, voor queries?
itcl::class CWokoTraceSchemaDef {

	private common log
	set log [CLogger::new_logger [file tail [info script]] info]
	
	private variable db
	private variable classdefs

	# todo pk- en fk-defs afleiden uit classdefs, later misschien helemaal weg.
	private variable pk_field
	private variable fk_field

	public proc new_instance {} {
		return [namespace which [[info class] #auto]]
		# return [CTextOutputter #auto] ; # gaat fout, wegens namespace.
	}
	
	private constructor {} {
		if {0} {
			set pk_field(testbuild) notesobject_id
			set pk_field(testrun) notesobject_id
			set pk_field(testproperty) id
			
			set fk_field(testrun,testbuild) testBuild_id
			set fk_field(testproperty,testrun) testRun_id
		}
		
		set db ""
	}

	public method get_db_name {} {
		return "perftoolset_test"
	}

	public method set_db {a_db} {
		set db $a_db
		define_classes
	}

	public method get_db {} {
		return $db
	}

	public method get_pk_field {table_name} {
		return $pk_field($table_name)
	}
	
	public method get_fk_field {fromtable totable} {
		return $fk_field($fromtable,$totable)
	}
		
	private method define_classes {} {
		define_directory
		define_sourcefile
		define_wokoclassdef
		define_methoddef
		define_methodcall
	}

	private method define_directory {} {
		# Directory: name of table
		# directory: internal tcl name
		set classdef [::CClassDef::new_classdef $this Directory id]
		set classdefs(directory) $classdef
		$classdef add_field_def description string "<Invullen>"
		$classdef add_field_def path string
		$classdef add_field_def parent_id integer NULL
	}
	
	private method define_sourcefile {} {
		set classdef [::CClassDef::new_classdef $this SourceFile id]
		set classdefs(sourcefile) $classdef
		$classdef add_field_def description string "<Invullen>"
		$classdef add_field_def path string
		$classdef add_field_def parent_id integer
	}
	
	private method define_wokoclassdef {} {
		set classdef [::CClassDef::new_classdef $this ClassDef id]
		set classdefs(classdef) $classdef
		$classdef add_field_def description string "<Invullen>"
		$classdef add_field_def name string
		$classdef add_field_def parent_id integer
	}
	
	private method define_methoddef {} {
		set classdef [::CClassDef::new_classdef $this MethodDef id]
		set classdefs(methoddef) $classdef
		$classdef add_field_def description string "<Invullen>"
		$classdef add_field_def methodType integer
		$classdef add_field_def name string
		$classdef add_field_def parent_id integer
	}
	
	private method define_methodcall {} {
		set classdef [::CClassDef::new_classdef $this MethodCall id]
		set classdefs(methodcall) $classdef
		$classdef add_field_def nCalls integer
		$classdef add_field_def caller_id integer
		$classdef add_field_def callee_id integer
	}
	
	public method get_classdef {class_name} {
		return $classdefs($class_name)
	}
	
	# @param class_name: testbuild
	# @param args: -cctimestamp $cctimestamp -label $label -artifacts_dir $artifacts_dir
	public method insert_object {class_name args} {
		$log debug "args: $args \[[llength $args]\]" 
		set classdef $classdefs($class_name)
		return [$classdef insert_object $args]
	}

	# @param class_name: testbuild
	# @param args: -cctimestamp $cctimestamp -label $label -artifacts_dir $artifacts_dir
	public method update_object {class_name id args} {
		$log debug "args: $args \[[llength $args]\]" 
		set classdef $classdefs($class_name)
		return [$classdef update_object $id $args]
	}

	public method find_objects {class_name args} {
		$log debug "args: $args \[[llength $args]\]" 
		set classdef $classdefs($class_name)
		return [$classdef find_objects $args]
	
	}

}
