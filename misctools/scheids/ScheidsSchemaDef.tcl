package require Itcl
package require ndv

itcl::class ScheidsSchemaDef {
  inherit ::ndv::AbstractSchemaDef
  
  private common log
  set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

  public proc new {} {
 		set instance [uplevel {namespace which [ScheidsSchemaDef #auto]}]
    return $instance  
  }
	
	public constructor {} {
		set db ""
		set no_db 0 ; # default is een db beschikbaar.
    set_db_name_user_password  "scheids" "nico" "pclip01;"
	}

	private method define_classes {} {
    $log debug "Define the classes"
    define_team
    define_persoon
    define_persoon_team
    define_afwezig
    define_zeurfactor
    define_wedstrijd
    define_scheids
    define_kan_team_fluiten
    define_kan_wedstrijd_fluiten
	}

	private method define_team {} {
		set classname "team"
    set classdef [::ndv::CClassDef::new_classdef $this $classname id]
		set classdefs($classname) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def naam string
    $classdef add_field_def scheids_nodig integer
    $classdef add_field_def opmerkingen string
	}

	private method define_persoon {} {
		set classname "persoon"
    set classdef [::ndv::CClassDef::new_classdef $this $classname id]
		set classdefs($classname) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def naam string
		$classdef add_field_def email string
		$classdef add_field_def telnrs string
    $classdef add_field_def speelt_in integer
    $classdef add_field_def opmerkingen string
	}

	private method define_persoon_team {} {
		set classname "persoon_team"
    set classdef [::ndv::CClassDef::new_classdef $this $classname id]
		set classdefs($classname) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def persoon integer
		$classdef add_field_def team integer
		$classdef add_field_def soort string
	}

  	private method define_afwezig {} {
		set classname "afwezig"
    set classdef [::ndv::CClassDef::new_classdef $this $classname id]
		set classdefs($classname) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def persoon integer
		$classdef add_field_def eerstedag date
		$classdef add_field_def laatstedag date
    $classdef add_field_def opmerkingen string
	}

	private method define_zeurfactor {} {
		set classname "zeurfactor"
    set classdef [::ndv::CClassDef::new_classdef $this $classname id]
		set classdefs($classname) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def persoon integer
    $classdef add_field_def speelt_zelfde_dag integer
    $classdef add_field_def factor float
    $classdef add_field_def opmerkingen string
	}
  
	private method define_wedstrijd {} {
		set classname "wedstrijd"
    set classdef [::ndv::CClassDef::new_classdef $this $classname id]
		set classdefs($classname) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
		$classdef add_field_def naam string
    $classdef add_field_def team integer
    $classdef add_field_def lokatie string
    $classdef add_field_def datumtijd datetime
    $classdef add_field_def scheids_nodig integer
    $classdef add_field_def opmerkingen string
    $classdef add_field_def date_inserted datetime CURTIME
    $classdef add_field_def date_checked datetime CURTIME
	}
  
	private method define_scheids {} {
		set classname "scheids"
    set classdef [::ndv::CClassDef::new_classdef $this $classname id]
		set classdefs($classname) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
    $classdef add_field_def scheids integer
    $classdef add_field_def wedstrijd integer
    $classdef add_field_def speelt_zelfde_dag integer
    $classdef add_field_def opmerkingen string
    $classdef add_field_def date_inserted datetime CURTIME
    $classdef add_field_def status string
    $classdef add_field_def waarde float
  }
  
	private method define_kan_team_fluiten {} {
		set classname "kan_team_fluiten"
    set classdef [::ndv::CClassDef::new_classdef $this $classname id]
		set classdefs($classname) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
    $classdef add_field_def scheids integer 
    $classdef add_field_def team integer
    $classdef add_field_def waarde float
    $classdef add_field_def opmerkingen string
  }
  
 	private method define_kan_wedstrijd_fluiten {} {
		set classname "kan_wedstrijd_fluiten"
    set classdef [::ndv::CClassDef::new_classdef $this $classname id]
		set classdefs($classname) $classdef
		$classdef add_field_def id integer ; # blijkbaar toch nog nodig.
    $classdef add_field_def scheids integer 
    $classdef add_field_def wedstrijd integer
    $classdef add_field_def waarde float
    $classdef add_field_def speelt_zelfde_dag integer
    $classdef add_field_def opmerkingen string
    $classdef add_field_def date_inserted datetime CURTIME
  }  
  
}

