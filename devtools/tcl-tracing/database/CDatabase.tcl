# CDatabase.tcl - main class for database connections to mysql.
package require Itcl
package require mysqltcl

source ../lib/CLogger.tcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CDatabase]] > 0} {
	return
}

# source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
#source [file join $env(CRUISE_DIR) checkout script database NotesSchemaDef.tcl]

#addLogger database
#setLogLevel database info
# setLogLevel database debug

itcl::class CDatabase {

	private common log
	set log [CLogger::new_logger [file tail [info script]] info]
	
  # common, static things for singleton
  private common instance  ""
  # private common DB_NAME "perftest"

  public proc get_database {} {
    if {$instance == ""} {
   		set instance [uplevel {namespace which [CDatabase #auto]}]
    }
    return $instance
  }
  
  # instance stuff
  private variable db
  private variable connected
  private variable schemadef
  # alternative database: use while still working with two databases.
	# too complicated, with 2 PK id's, how to do with f.keys?
  # private variable schemadef_alt
  
  private constructor {} {
    set db ""
    set connected 0
    set schemadef ""
  }

  private destructor {
	  if {$connected} {
      ::mysql::close $db
    }
	  set db "" 
	  set connected 0
    log "Disconnected from database" info database
    set instance ""
  }

	public method set_schemadef {a_csd} {
		set schemadef $a_csd
		set db [::mysql::connect -user perftest -password perftest -db [$schemadef get_db_name]]
		set connected 1
		$log info "Connected to database"
		$schemadef set_db $db
	}
	
	public method get_connection {} {
		if {$connected} {
			return $db
		} else {
			$log warn "Not connected to database" 
			return $db
		}
	}

	public method get_schemadef {} {
		return $schemadef
	}

	# @param class_name: testbuild
	# @param args: -cctimestamp $cctimestamp -label $label -artifacts_dir $artifacts_dir
	public method insert_object {class_name args} {
		$log debug "args: $args \[[llength $args]\]"
		return [$schemadef insert_object $class_name $args]
	}

	# @param class_name: testbuild
	# @param args: -cctimestamp $cctimestamp -label $label -artifacts_dir $artifacts_dir
	public method update_object {class_name id args} {
		$log debug "args: $args \[[llength $args]\]" 
		return [$schemadef update_object $class_name $id $args]
	}

	public method find_objects {class_name args} {
		$log debug "args: $args \[[llength $args]\]"
		return [$schemadef find_objects $class_name $args]
	}

}


