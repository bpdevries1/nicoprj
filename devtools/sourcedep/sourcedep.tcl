#!/usr/bin/env tclsh

package require ndv

ndv::source_once sourcedepdb.tcl

set_log_global info

set reader_namespaces [list]
set sourcedep_dir [file normalize [file dirname [info script]]]

lappend reader_namespaces [source [file join $sourcedep_dir vugenreader.tcl]]

proc main {argv} {
  set options {
    {rootdir.arg "~/raboprj/VuGen/repo/libs" "Directory that contains db"}
    {dirs.arg "" "Subdirs within root dir to handle, empty for all (: separated)"}
    {targetdir.arg "sourcedep" "Directory where to generate DB, images, html"}
    {db.arg "sourcedep.db" "SQLite DB to create, relative to targetdir"}
    {deletedb "Delete DB first"}
    {loglevel.arg "info" "Set loglevel"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set opt [getoptions argv $options $usage]
  log set_log_level [:loglevel $opt]
  # make_graphs $dargv
  # First only read into DB. Later also graphs and HTML
  sourcedep $opt
}

proc sourcedep {opt} {
  set targetdir [file join [:rootdir $opt] [:targetdir $opt]]
  file mkdir $targetdir
  set dbname [file join $targetdir [:db $opt]]
  if {[:deletedb $opt 0]} {
    delete_database $dbname
  }
  set db [get_sourcedep_db $dbname $opt]
  read_sources $db $opt 
}

proc read_sources {db opt} {
  set rootdir [file normalize [:rootdir $opt]]
  if {[:dirs $opt] != ""} {
    foreach sub [split [:dirs $opt] ":"] {
      read_source_dir $db [file join $rootdir $sub]
    }
  } else {
    read_source_dir $db $rootdir
  }

  # TODO: 2nd fase here too: after all proc names are known, read files again and check if procs are used.
}

proc read_source_dir {db dir} {
  foreach filename [glob -nocomplain -directory $dir -type f *] {
    read_source_file $db $filename
  }
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    read_source_dir $db $subdir
  }
}

proc read_source_file {db filename} {
  log info "Read sourcefile: $filename"

  global reader_namespaces
  set nread 0
  foreach ns $reader_namespaces {
    if {[${ns}::can_read? $filename]} {
      log debug "Reading $filename with ns: $ns"
      ${ns}::read_sourcefile $filename $db
      set nread 1
      break
    }
  }
  if {$nread == 0} {
    log debug "Could not read (no ns): $filename"
  }
  return $nread
}

if {[this_is_main]} {
  main $argv  
}

