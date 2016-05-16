#!/usr/bin/env tclsh

# puts stderr "App started"

package require Itcl

source ../lib/CLogger.tcl
source ../database/CDatabase.tcl
source ../database/CWokoTraceSchemaDef.tcl

proc main {argc argv} {
	set TARGET_DIR "c:/aaa/trace-sourcedep/sourcefiles"
	file mkdir $TARGET_DIR

	set cdb [CDatabase::get_database]
	set csd [CWokoTraceSchemaDef::new_instance]
	$cdb set_schemadef $csd
	set conn [$cdb get_connection]
	
	set lst_sourcefiles [::mysql::sel $conn "select id, path from SourceFile" -list]
	puts "Total sourcefiles: [llength $lst_sourcefiles]"
	foreach sourcefile $lst_sourcefiles {
		puts "Handling $sourcefile..."
		foreach {id path} $sourcefile {
			set pathname [det_name $path]
			set f [open [file join $TARGET_DIR "$pathname"] w]
			set query [det_query $id]
			set lst_targets [::mysql::sel $conn $query -flatlist]
			foreach target $lst_targets {
				puts $f "uses [det_name $target]" 
			}
			close $f
		}		
	}

	::mysql::close $conn
}

proc det_name {path} {
	if {[regexp {cruise/(.*)$} $path z result]} {
		# ok, eerste stuk eraf gefilterd.
	} else {
		set result $path
	}
	regsub -all ":" $result "-" result
	regsub -all "/" $result "-" result
	return "$result.file"	
}

proc det_query {id} {
	return "select distinct s2.path
from sourcefile s2, classdef c1, classdef c2, methoddef m1, methoddef m2, methodcall c
where c1.parent_id = $id
and c1.id = m1.parent_id
and m1.id = c.caller_id
and c.callee_id = m2.id
and m2.parent_id = c2.id
and c2.parent_id = s2.id
and s2.id <> $id"
}

main $argc $argv

