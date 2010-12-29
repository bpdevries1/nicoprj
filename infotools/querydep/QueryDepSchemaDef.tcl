# DB schema definition for the Perfmeetmodel database.
package require Itcl
package require ndv

itcl::class QueryDepSchemaDef {
	inherit ::ndv::AbstractSchemaDef
  
  private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	
  public proc new {} {
 		set instance [uplevel {namespace which [QueryDepSchemaDef #auto]}]
    return $instance  
  }
  
	public constructor {} {
		# set db ""
		set conn ""
		set no_db 0 ; # default is een db beschikbaar.
    set_db_name_user_password  "indquerydep" "itx" "itx42"
	}

	private method define_classes {} {
    define_bestand
    define_query
    define_tabel
    define_query_tabel
	}

	private method define_bestand {} {
		set classdef [::ndv::CClassDef::new_classdef $this bestand id]
		set classdefs(bestand) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def path string
	}

	private method define_query {} {
		set classdef [::ndv::CClassDef::new_classdef $this query id]
		set classdefs(query) $classdef
		if {0} {
      $classdef add_field_def id integer ; # blijkbaar toch nog nodig.
      $classdef add_field_def naam string
      $classdef add_field_def soort string
      $classdef add_field_def sqltekst string
      $classdef add_field_def bestand_id integer
      $classdef add_field_def volgnr integer
      $classdef add_field_def regelnr integer
    }
    $classdef add_field_defs {id integer} {naam string} {soort string} \
      {sqltekst string} {bestand_id integer} {volgnr integer} {regelnr integer}
    
	}

	private method define_tabel {} {
		set classdef [::ndv::CClassDef::new_classdef $this tabel id]
		set classdefs(tabel) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def naam string
    $classdef add_field_def bestand_id integer
	}

	private method define_query_tabel {} {
		set classdef [::ndv::CClassDef::new_classdef $this query_tabel id]
		set classdefs(query_tabel) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def soort string
    $classdef add_field_def query_id integer
    $classdef add_field_def tabel_id integer
	}
  
}

