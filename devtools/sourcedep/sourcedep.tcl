#!/usr/bin/env tclsh

package require ndv

require libinifile ini

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
  # [2016-09-24 10:34] voorlopig altijd db delete.
  delete_database $dbname
  set db [get_sourcedep_db $dbname $opt]
  read_sources $db $opt
  
  det_include_refs $db
  # TODO: and then make a graphviz/dot
  graph_include_refs $db $opt
  # TODO: 2nd fase here too: after all proc names are known, read files again and check if procs are used.
  
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
  read_vugen_usr $db $rootdir
}

# TODO:
# * buildtool - use ndvlib/libinifile
# * require/namespace - don't use import in current namespace.
proc read_vugen_usr {db rootdir} {
  $db in_trans {
    set usrfile [file join $rootdir "[file tail $rootdir].usr"]
    if {![file exists $usrfile]} {return}
    set usr [ini/read $usrfile]
    set usrfile_id [$db insert sourcefile [dict create path $usrfile name [file tail $usrfile] language vugen]]
    foreach line [ini/lines $usr Actions] {
      if {[regexp {=(.+)$} $line z filename]} {
        $db insert statement [dict create sourcefile_id $usrfile_id stmt_type include callee $filename]
      }
    }
    foreach line [ini/lines $usr ExtraFiles] {
      if {[regexp {^(.+)=$} $line z filename]} {
        $db insert statement [dict create sourcefile_id $usrfile_id stmt_type include callee $filename]
      }
    }
  }
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

# insert ref-records based on include statements, from file to file.
proc det_include_refs {db} {
  set query "insert into ref (from_file_id, to_file_id, reftype)
select st.sourcefile_id, tf.id, 'include' reftype
from statement st 
join sourcefile tf on st.callee = tf.name"
  $db exec $query
}

proc graph_include_refs {db opt} {
  set targetdir [file join [:rootdir $opt] [:targetdir $opt]]
  set dotfile [file join $targetdir "includes.dot"]
  set f [open $dotfile w]
  write_dot_header $f LR
  foreach row [$db query "select * from sourcefile"] {
    dict set nodes [:id $row] [puts_node_stmt $f [:name $row]]
  }
  foreach row [$db query "select * from ref where reftype = 'include'"] {
    puts $f [edge_stmt [dict get $nodes [:from_file_id $row]] \
                [dict get $nodes [:to_file_id $row]]]
  }
  write_dot_footer $f
  close $f
  do_dot $dotfile [file join $targetdir "includes.png"]
}

if {[this_is_main]} {
  main $argv  
}

