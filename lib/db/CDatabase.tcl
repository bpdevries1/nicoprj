# Main class for database connections to mysql.
# @todo separate general with music specific functionality
package require Itcl
# package require ndv
package require Tclx

package provide ndv 0.1.1

namespace eval ::ndv {

  # class maar eenmalig definieren
  if {[llength [itcl::find classes CDatabase]] > 0} {
    return
  }

	namespace export CDatabase
	#variable MYSQLTCL_LIB  
  # source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
  # source [file join $env(CRUISE_DIR) checkout script database JMSchemaDef.tcl]
  # source [file join $env(CRUISE_DIR) checkout script database NOSchemaDef.tcl]
  # source [file join $env(CRUISE_DIR) checkout script database NotesSchemaDef.tcl]
  # source [file join [file dirname [info script]] ModelSchemaDef.tcl]
  
  # controlled loading of package.
  if {[catch {package require mysqltcl} msg]} {
    #set MYSQLTCL_LIB 0
    # 18-6-2013 NdV don't put error message anymore, is irritating and mysql not used so much anymore.
    # puts stderr "Failed to load mysqltcl library. Msg = $msg"
  } else {
    #set MYSQLTCL_LIB 1
  }
  
  # source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]
  
  itcl::class CDatabase {
    private common log
    set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  
    # common, static things for singleton
    private common instance  ""
    private common DB_NAME "indmeetmod"
  
    # if param new != 0, return a new instance.
    public proc get_database {a_schemadef {new 0}} {
      if {($instance == "") || $new} {
        set instance [uplevel {namespace which [::ndv::CDatabase #auto]}]
        $instance set_schemadef $a_schemadef
        $log debug "Returning new database instance"
      } else {
        $log debug "Returning existing database instance"
      }
      $log debug "Returning database instance with schemadef: [$instance get_schemadef]"
      return $instance
    }
  
    # instance stuff
    private variable conn
    private variable connected
    private variable schemadef
    
    private constructor {} {
      set conn ""
      set connected 0
    }
  
    public method set_modelclass_old {modelclass} {
      # global MYSQLTCL_LIB
      #variable MYSQLTCL_LIB
      set schemadef [uplevel {namespace which [$modelclass #auto]}]
      set_schemadef $schemadef
    }
  
    public method set_schemadef {a_schemadef} {
      # global MYSQLTCL_LIB
      # variable MYSQLTCL_LIB
      $log debug "a_schemadef: $a_schemadef"
      # set schemadef [uplevel {namespace which [ModelSchemaDef #auto]}]
      # set schemadef [uplevel {namespace which [$modelclass #auto]}]
      set schemadef $a_schemadef
      if {[lsearch [package names] mysqltcl] >= 0} {        
        connect
      } else {
        $schemadef set_no_db 1
      }
      $schemadef set_conn $conn
    }
    
    private method connect {} {
      $log debug "new connect method, for reconnecting also"
      try_eval {
        set conn [::mysql::connect -host localhost -user [$schemadef get_username] \
          -password [$schemadef get_password] -db [$schemadef get_db_name]]
        set connected 1
        $log info "Connected to database"
      } {
        $log warn "Failed to connect to database: $errorResult"
        $log warn "schemadef: $schemadef"
        $schemadef set_no_db 1
      }
    }
    
    # check DB connection and reconnect if needed
    public method reconnect {} {
      $log debug "reconnect"
      set still_connected 0
      try_eval {
        ::mysql::sel $conn "select 1" -flatlist
        set still_connected 1
      } {
        $log debug "Failed to query: $errorResult"
        set still_connected 0
      }
      if {!$still_connected} {
        $log debug "Connection gone, reconnect..."
        catch {::mysql::close $conn}
        connect
      }
    }
    
    private destructor {
      if {$connected} {
        ::mysql::close $conn
      }
      set conn "" 
      set connected 0
      $log info "Disconnected from database"
      set instance ""
    }
  
    public method get_connection {} {
      if {$connected} {
        return $conn
      } else {
        $log warn "Not connected to database"
        return $conn
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
  
    # @todo add select_objects, which selects objects based on id, name the fields to select.
    # possibly combine with find_objects.
    
    public method delete_object {class_name id} {
      # $log debug "args: $args \[[llength $args]\]"
      return [$schemadef delete_object $class_name $id]
    }
  
    # @result: gelijk aan input, met /-: en spatie verwijderd
    public method dt_to_decimal {dt} {
      # 27-12-2009 NdV moet -- gebruiken, anders wordt "-" als optie gezien.   
      regsub -all -- {[-/: ]} $dt "" dt
      return $dt
    }
    
    # replace ' and \ with doubled characters
    # 17-1-2010 NdV only call this method from the framework, not externally.
    # 2-2-2010 NdV still sometimes needed, for music-monitor for instance.
    public method str_to_db {str} {
      regsub -all {'} $str "''" str
      regsub -all {\\} $str {\\\\} str
      return $str
      
    }
    
  }
  
}  

