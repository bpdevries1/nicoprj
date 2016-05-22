package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CWikiMigration]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]
source [file join $env(CRUISE_DIR) checkout script tool wiki-migration CJspWikiReader.tcl]
source [file join $env(CRUISE_DIR) checkout script tool wiki-migration CMediaWikiWriter.tcl]

itcl::class CWikiMigration {

	private common log
	set log [CLogger::new_logger wiki_migration debug]

	private variable src_dir
	private variable target_dir
	
	public constructor {a_src_dir a_target_dir} {
		set src_dir $a_src_dir
		set target_dir $a_target_dir
	}

	public method migrate {} {
		$log debug "start"

		set reader [CJspWikiReader #auto]
		set writer [CMediaWikiWriter::new_media_wiki_writer $target_dir]
		$reader set_writer $writer
		$reader migrate_directory $src_dir

		$log debug "finished"
	}

}

proc main {argc argv} {
  check_params $argc $argv
  set src_dir [lindex $argv 0]
  set target_dir [lindex $argv 1]
	# set testrun_id [lindex $argv 2] ; # bv 'testrun001'
  set wiki_migration [CWikiMigration #auto $src_dir $target_dir]
  $wiki_migration migrate
}

proc check_params {argc argv} {
  global env argv0
  if {$argc != 2} {
    fail "syntax: $argv0 <src_dir> <target_dir>; got $argv \[#$argc\]"
  }
}

# aanroepen vanuit Ant, maar ook mogelijk om vanuit Tcl te doen.
if {[file tail $argv0] == [file tail [info script]]} {
  main $argc $argv
}

