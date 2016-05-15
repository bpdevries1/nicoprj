# DB schema definition for the Music test database, just 2 tables
# 24-10-2009 this one is for ndv::database package
# @todo separate general functionality with specific music functionality
package require Itcl
package require ndv
package require json

# class maar eenmalig definieren
if {[llength [itcl::find classes MusicSchemaDef]] > 0} {
	return
}

# source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
# source [file join [file dirname [info script]] CClassDef.tcl]


# @todo (?) ook nog steeds pk en fk defs, voor queries?
# source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class MusicSchemaDef {
	inherit ::ndv::AbstractSchemaDef
  
  private common log
	set log [::ndv::CLogger::new_logger [file tail [info script]] info]
	# set log [CLogger::new_logger [file tail [info script]] debug]

  public proc new {} {
    set instance [uplevel {namespace which [MusicSchemaDef #auto]}]
    return $instance
  }
  
	public constructor {} {
		set conn ""
    set db ""
    set dbtype "postgres"
		set no_db 0 ; # default is een db beschikbaar.
    if 0 {
      set f [open ~/.ndv/music-settings.json r]
      set text [read $f]
      close $f
      set d [json::json2dict $text]
      set_db_name_user_password [dict get $d database] [dict get $d user] [dict get $d password]
    }
	}

	private method define_classes {} {
		define_generic
    define_artist
    define_album
    define_musicfile
    define_played
    define_property
    define_mgroup
    define_member
    define_temp_filename
	}

	private method define_generic {} {
		set classdef [::ndv::CClassDef::new_classdef $this generic id]
		set classdefs(generic) $classdef
		$classdef add_field_def id integer
		$classdef add_field_def gentype string
    $classdef add_field_def freq float 1.0
		$classdef add_field_def freq_history float
		$classdef add_field_def play_count integer 0
  }
 
	private method define_artist {} {
		set classdef [::ndv::CClassDef::new_classdef $this artist id]
		set classdefs(artist) $classdef
		$classdef add_field_def id integer
    $classdef add_field_def generic integer
		$classdef add_field_def path string
    $classdef add_field_def name string
    $classdef add_field_def notes string
  }
  
	private method define_album {} {
		set classdef [::ndv::CClassDef::new_classdef $this album id]
		set classdefs(album) $classdef
		$classdef add_field_def id integer
		$classdef add_field_def generic integer
    $classdef add_field_def path string
    $classdef add_field_def artist integer
    $classdef add_field_def name string
    $classdef add_field_def notes string
    $classdef add_field_def file_exists integer 1
    $classdef add_field_def is_symlink integer
    $classdef add_field_def realpath string
  }
  
	private method define_musicfile {} {
		set classdef [::ndv::CClassDef::new_classdef $this musicfile id]
		set classdefs(musicfile) $classdef
		$classdef add_field_def id integer
		$classdef add_field_def path string
		$classdef add_field_def file_exists integer 1
    $classdef add_field_def artistname string
    $classdef add_field_def trackname string
    $classdef add_field_def filesize integer
    $classdef add_field_def seconds integer
    $classdef add_field_def bitrate integer
    $classdef add_field_def vbr integer
    $classdef add_field_def generic integer
    $classdef add_field_def album integer
    $classdef add_field_def artist integer
    $classdef add_field_def is_symlink integer
    $classdef add_field_def realpath string
	}

	private method define_played {} {
		set classdef [::ndv::CClassDef::new_classdef $this played id]
		set classdefs(played) $classdef
		$classdef add_field_def id integer
    $classdef add_field_def generic integer
		$classdef add_field_def kind string
		$classdef add_field_def datetime datetime CURTIME
	}

	private method define_property {} {
		set classdef [::ndv::CClassDef::new_classdef $this property id]
		set classdefs(property) $classdef
		$classdef add_field_def id integer
    $classdef add_field_def generic integer
		$classdef add_field_def name string
		$classdef add_field_def value string
	}

	private method define_mgroup {} {
		set classdef [::ndv::CClassDef::new_classdef $this mgroup id]
		set classdefs(mgroup) $classdef
		$classdef add_field_def id integer
    $classdef add_field_def name string
  }

	private method define_member {} {
		set classdef [::ndv::CClassDef::new_classdef $this member id]
		set classdefs(member) $classdef
		$classdef add_field_def id integer
    $classdef add_field_def mgroup integer
    $classdef add_field_def generic integer
  }
  
	private method define_temp_filename {} {
		set classdef [::ndv::CClassDef::new_classdef $this temp_filename musicfile_id]
		set classdefs(temp_filename) $classdef
		$classdef add_field_def musicfile_id integer
		$classdef add_field_def path string
		$classdef add_field_def filename string
		$classdef add_field_def play_count integer 0
		$classdef add_field_def file_exists integer 1
	}

}

