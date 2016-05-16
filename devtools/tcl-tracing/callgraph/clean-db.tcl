#!/usr/bin/env tclsh

# puts stderr "App started"

package require Itcl

source ../lib/CLogger.tcl
source ../database/CDatabase.tcl
source ../database/CWokoTraceSchemaDef.tcl

proc main {argc argv} {
	set cdb [CDatabase::get_database]
	set csd [CWokoTraceSchemaDef::new_instance]
	$cdb set_schemadef $csd
	set conn [$cdb get_connection]
	
	# mogelijk ook index tables legen (van Woko)
	foreach table [list MethodCall MethodDef ClassDef SourceFile] {
		puts "Cleaning table: $table"
		::mysql::exec $conn "delete from $table"
		::mysql::exec $conn "delete from index_[string tolower $table]"
	}
	
	# Directory heeft f.keys naar zichzelf, deleten wat lastiger.
	set continue 1
	set pass 1
	while {$continue} {
		puts "Deleting Directory records, pass $pass"
		set lst_ids [::mysql::sel $conn "select id from Directory" -flatlist]
		if {[llength $lst_ids] == 0} {
			# klaar
			puts "  .. no records left"
			set continue 0
		} else {
			# try to delete each record
			set deleted 0
			foreach id $lst_ids {
				catch {
					::mysql::exec $conn "delete from Directory where id = $id"
					set deleted 1
				}
			}
			if {!$deleted} {
				set continue 0
				puts "Failed to delete all remaining records: ids: $lst_ids"
			} else {
				puts "  .. deleted [llength $lst_ids] records"
			}
		}
		incr pass
	}
	::mysql::exec $conn "delete from index_directory"
	::mysql::close $conn
}


main $argc $argv

