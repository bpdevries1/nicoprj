#!/home/nico/bin/tclsh

# 17-8-2011 creating graphs is now split into phases:
# * read the data into a (new or existing) sqlite database
# * plot the data (maybe split into define graph en plot graph)

package require Tclx
# package require csv
package require sqlite3

# own package
package require ndv

# @todo 16-9-2011 should source commands be within namespace or not?
::ndv::source_once "platform-$tcl_platform(platform).tcl" ; # load platform specific functions. 
# ::ndv::source_once "graphdata-lib.tcl" "find-overlaps.tcl" "split-columns.tcl"
::ndv::source_once "graphdata-lib.tcl" "find-overlaps.tcl"

namespace eval ::ndv::graphdata::graphsqlite {
  # global env
  
  namespace export main ; # see if this could work
  
  variable log [::ndv::CLogger::new_logger [file tail [info script]] debug] \
           MAX_R_GRAPH 25 \
           set MAX_LEGEND_LENGTH 60 \
           R_binary ""
           
  # array variables separately
  variable ar_argv
  
  # @todo 16-9-2011 should source commands be within namespace or not?
  #::ndv::source_once "platform-$tcl_platform(platform).tcl" ; # load platform specific functions. 
  # ::ndv::source_once "graphdata-lib.tcl" "find-overlaps.tcl" "split-columns.tcl"
  #::ndv::source_once "graphdata-lib.tcl" "find-overlaps.tcl"
  # puts "sourced platform things"
  # breakpoint ; # doesn't work, need to be in proc? NdV 16-9-2011.
  # catch {set log [::ndv::CLogger::new_logger [file tail [info script]] debug]} 
  
  proc main {argv} {
    # global R_binary env ar_argv
    global env
    #variable R_binary
    #variable ar_argv
    variables R_binary ar_argv
    
    # @todo path-sep characters is ; on windows.
    # @todo is RScript found within directories in PATH? or is just the dir returned?
	# @todo on windows path separator is ';' make function in platform-*.
    # set R_binary [find_R "/usr/bin/Rscript" "c:/develop/R/R-2.13.0/bin/Rscript.exe" "d:/develop/R/R-2.9.0/bin/Rscript.exe" "d:/apps/R/R-2.11.1/bin/Rscript.exe" {*}[split $env(PATH) ":"]]
    # set R_binary [find_R "/usr/bin/Rscript" "c:/develop/R/R-2.13.0/bin/Rscript.exe" "d:/develop/R/R-2.9.0/bin/Rscript.exe" "d:/apps/R/R-2.11.1/bin/Rscript.exe" {*}[split $env(PATH) ";"]]
    set R_binary [find_R "/usr/bin/Rscript" "c:/develop/R/R-2.13.0/bin/Rscript.exe" "d:/develop/R/R-2.9.0/bin/Rscript.exe" "d:/apps/R/R-2.11.1/bin/Rscript.exe" {*}[split $env(PATH) [get_path_sep]]]
  
    set options {
      {db.arg "auto" "Read data from a database with this name (auto (=search current dir), default (data.db) or explicit)"}
      {table.arg "auto" "Read data in the named table (auto (=all) or explicit)"}
      {graphdir.arg "auto" "Put graphs in this directory (auto or explicit)"}
      {clean "Clean the graph output dir before making graphs."}
      {npoints.arg 200 "Number of points to plot."}
      {ggplot "Use ggplot for (single line) graphs"}
      {flatlines "Do make graph if it would be a flatline (min=max)"}
      {start.arg "auto" "Start time of graph"}
      {end.arg "auto" "End time of graph"}
      {loglevel.arg "" "Set global log level"}
    }
    set usage ": [file tail [info script]] \[options] sqlite.db"
    array set ar_argv [::cmdline::getoptions argv $options $usage]
    
    if {[llength $argv] > 0} {
      set ar_argv(db) [lindex $argv 0] 
    }
    
    # @todo 2-2-2012 NdV foutmelding op onderstaande, nu even negeren.
    catch {file delete "[file rootname [file tail [info script]]].log"}
    # ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
    log info "graphsqlite: start"
  
    log debug "remaining argv: $argv"
    # no defaults here for unnamed args
    set db_name [det_db_name $ar_argv(db)]
    set graph_dir [det_graph_dir $db_name $ar_argv(graphdir)]
    if {$ar_argv(clean)} {
      clean_graph_dir $graph_dir ; # do not clean if the graph_dir is the same as the data dir.    
    }
    file mkdir $graph_dir
    set graph_filename [make_graphs $db_name $ar_argv(table) $graph_dir]
    
    if {$graph_filename != ""} {
      show_graph_file $graph_filename
    }
    log info "graphsqlite: finished"
  }
  
  proc det_db_name {db} {
    if {$db == "auto"} {
      # search a .db file in the current dir
      set l [glob -nocomplain -type f *.db]
      if {[llength $l] == 0} {
        error "No .db file found in current dir" 
      } elseif {[llength $l] == 1} {
        return [lindex $l 0] 
      } else {
        # @todo alternative is handling all .db files.
        log warn "More than one .db file in current dir, using [lindex $l 0]"
        return [lindex $l 0]
      }
    } elseif {$db == "default"} {
      return data.db
    } else {
      if {[file extension $db] == ".db"} {
        return $db 
      } else {
        return "$db.db"
      }
    }  
  }
  
  proc det_graph_dir {db_name argv_graphdir} {
    if {$argv_graphdir == "auto"} {
      return "[file rootname $db_name]-graphs"
    } else {
      return $argv_graphdir 
    }
  }
  
  proc clean_graph_dir {path} {
    set filetype [catch_call error file type $path]
    foreach filename [glob -nocomplain -directory $path -type f *] {
      file delete $filename 
    }
  }
  
  proc make_graphs {db_name argv_table graph_dir} {
    sqlite3 db $db_name
    if {$argv_table == "auto"} {
      # make default graphs for all tables in the database
      foreach table [db eval "select distinct tabname from columndef"] {
        # set res [make_graphs_table $db_name $table $graph_dir]
        set_if_empty res [make_graphs_table $db_name $table $graph_dir]
      }
    } else {
      set res [make_graphs_table $db_name $argv_table $graph_dir] 
    }
    db close  
    return $res
  }
  
  proc make_graphs_table {db_name table graph_dir} {
    # global MAX_R_GRAPH ar_argv
    variables MAX_R_GRAPH ar_argv
    set result "" ; # should contain the probably most specific graph name.
    # lassign [make_sqlite_db $filename $graph_dir] db_name ncol
    set ncol [det_ncol $table]
    #if {$ncol > 2} {
    #  set result [make_graphs_table_per_col $db_name $table $graph_dir $ncol] ; # split columns, handle flatlines and make graphs. 
    #}
    if {$ncol < 2} {
      log warn "Less than 2 columns in $table, graph not possible" 
      set result ""
    } elseif {$ncol == 2} {
      set result [make_graph $db_name $table $graph_dir noscale]
    } else {
      # ncol > 2
      if {$ncol < $MAX_R_GRAPH} { 
        log debug "#columns: $ncol" 
        set result [make_graph $db_name $table $graph_dir both]; # make_graph returns graph filename.
      }
      set_if_empty result [make_graphs_table_per_col $db_name $table $graph_dir $ncol] ; # split columns, handle flatlines and make graphs.
    }
    return $result
  }
  
  # @result ncol is (still) including the timestamp column
  proc det_ncol {table} {
    db eval "select count(colname) from columndef where tabname = '$table'" 
  }
  
  proc make_graphs_table_per_col {db_name table graph_dir ncol} {
    # set res ""
    # set res [make_graph_R_split $db_name $table $graph_dir 1]
    for {set i 1} {$i < $ncol} {incr i} {
      #set res1 [make_graph_R_split $db_name $table $graph_dir $i]
      #if {$res == ""} {
      #  set res $res1 
      #}
      set_if_empty res [make_graph_R_split $db_name $table $graph_dir $i]
    }
    return $res
  }
  
  proc make_graph {db_name table graph_dir {scaletype both}} {
    log debug "Make graphs for $table"
    set result ""
    # return not strictly needed here, but to clarify that the result is used.
    if {($scaletype == "both") || ($scaletype == "scale")} {
      # set result [make_graph_R $db_name $table $graph_dir "graph-sqlite.R" 1]
      when_set result [make_graph_R $db_name $table $graph_dir "graph-sqlite.R" 1]
    }
    if {($scaletype == "both") || ($scaletype == "noscale")} {
      # set result [make_graph_R $db_name $table $graph_dir "graph-sqlite.R" 0]
      when_set result [make_graph_R $db_name $table $graph_dir "graph-sqlite.R" 0]
    }
    return $result
  }
  
  proc make_graph_R {db_name table graph_dir r_script scale} {
    variables R_binary N_POINTS ar_argv
    set graph_filename [det_graph_filename $table $graph_dir $scale]
    set r_script_path [file join [file dirname [info script]] $r_script]
    try_eval {
      # @todo determine datetime format
      log debug "exec: $R_binary $r_script_path $db_name \"select * from $table\" $ar_argv(npoints) \"select legendname from columndef where tabname = '$table' order by id\" [param_format [det_timestamp_format $table]] $graph_filename $scale [file tail $graph_filename]" 
      # exec $R_binary $r_script_path $db_name "select * from flatdata" $ar_argv(npoints) "select legendname from legend" [param_format "%H:%M"] $graph_filename $scale [file tail $graph_filename]
      
      # %d-%m-%y %H:%M:%S
      # exec $R_binary $r_script_path $db_name "select * from flatdata" $ar_argv(npoints) "select legendname from legend" [param_format "%d-%m-%y %H:%M:%S"] $graph_filename $scale [file tail $graph_filename]
      # exec $R_binary $r_script_path $db_name "select * from $table" $ar_argv(npoints) "select legendname from columndef where tabname = '$table' order by id" [param_format [det_timestamp_format $table]] $graph_filename $scale [file tail $graph_filename]
      set q_data [add_start_end "select * from $table" where]
      exec $R_binary $r_script_path $db_name $q_data $ar_argv(npoints) "select legendname from columndef where tabname = '$table' order by id" $table $graph_filename $scale [file tail $graph_filename]
    } {
      log error "Error during R processing: $errorResult"
    }
    if {[file exists $graph_filename]} { 
      return $graph_filename
    } else {
      return "" 
    }
  }
  
  # make a 'split' graph: only one line, the data of one column, based on the x/time axis.
  proc make_graph_R_split {db_name table graph_dir col_id} {
    variables R_binary N_POINTS ar_argv
    
    if {!$ar_argv(flatlines)} {
      if {[det_flatline $table $col_id]} {
        return "" 
      }
    }  
    set graph_filename [det_graph_filename_col $table $graph_dir $col_id]
    #if {$ar_argv(ggplot)} {
    #  set r_script_path [file join [file dirname [info script]] "graph-sqlite-ggplot-1col.R"]
    #} else {
    #  set r_script_path [file join [file dirname [info script]] "graph-sqlite.R"]
    #}
    set r_script_path [file join [file dirname [info script]] "graph-sqlite[ifelse $ar_argv(ggplot) "-ggplot-1col"].R"]
    
    try_eval {
      set q_legend "select legendname from columndef where tabname = '$table' and colname in ('meas_time', 'val$col_id') order by id"
      # 16-11-11 testje
      set q_data [add_start_end "select meas_time, val$col_id from $table where val$col_id >= 0 and val$col_id <> ' ' " and] ; # 14-9-2011 NdV ignore -1 results from typeperf
      log debug "COL exec: $R_binary $r_script_path $db_name $q_data $ar_argv(npoints) $q_legend [param_format [det_timestamp_format $table]] $graph_filename 0 [file tail $graph_filename]" 
      exec $R_binary $r_script_path $db_name $q_data $ar_argv(npoints) $q_legend $table $graph_filename 0 [file tail $graph_filename]
    } {
      log error "Error during R processing: $errorResult"
    }   
    if {[file exists $graph_filename]} { 
      return $graph_filename
    } else {
      return "" 
    }
  }
  
  proc iff_simple {expr iftrue {iffalse ""}} {
    if $expr {
      return $iftrue 
    } else {
      return $iffalse 
    }
  }

  # functional equivalent of if statement.
  # not sure if uplevel/expr always works as expected.
  proc ifelse {expr iftrue {iffalse ""}} {
    if {[uplevel 1 expr $expr]} {
      return $iftrue 
    } else {
      return $iffalse 
    }
  }
  
  proc add_start_end {query {startwith where}} {
    variables ar_argv
    if {$ar_argv(start) != "auto"} {
      append query " $startwith meas_time >= '$ar_argv(start)'"
      set startwith "and"
    }
    if {$ar_argv(end) != "auto"} {
      append query " $startwith meas_time <= '$ar_argv(end)'" 
    }
    return $query
  }
  
  proc det_flatline {table col_id} {
    # set q_flat "select min(val$col_id) minval, max(val$col_id) maxval from $table where min(val$col_id)=max(val$col_id)"
    # 14-9-2011 NdV ignore -1 results from typeperf
    # 16-11-11 testje
    set q_flat "select min(val$col_id) minval, max(val$col_id) maxval from $table where val$col_id >= 0 and val$col_id <> ' ' "
    set res [db eval $q_flat]
    # blijkbaar in een flatlist.
    if {[lindex $res 0] == [lindex $res 1]} {
      return 1 
    } else {
      return 0 
    }
  }
  
  # @param filename: full path to the input file, can be relative to the current directory.
  # @param graph_dir dir where to put the graphs; they will be put in the root of this dir, not in a subdir of this dir. graph_dir is also a full path, and can be relative to the current dir.
  proc det_graph_filename {table graph_dir scale} {
    file join $graph_dir "$table[expr $scale?"-scaled":""].png"
  }
  
  proc det_graph_filename_col {table graph_dir col_id} {
    set title [lindex [db eval "select fullname from columndef where tabname = '$table' and colname='val$col_id'"] 0]
    log debug "title: $title"
    regsub -all {[\\/:\|\%]} $title " " title
    file join $graph_dir "$table-[format %04d $col_id]-$title.png"
  }
  
  proc det_timestamp_format {table} {
    db eval "select datetimeformat from columndef where tabname = '$table' and isdatetime = 1"
  }
  
  # search Rscript in each of the paths given in args.
  # @return the path where R is found, or just Rscript, if not found (maybe it's in the PATH)
  # @todo path can be a file or a directory. A file works ok, in a directory search for Rscript(.exe).
  proc find_R {args} {
    foreach path $args {
	  # log debug "Checking for R: $path"
      if {[file exists $path]} {
	    if {[file isfile $path]} {
		  log info "Found R: $path"
		  return $path 		
		} elseif {[file isdirectory $path]} {
		  set res [glob -nocomplain -directory $path Rscript*]
		  if {[llength $res] > 0} {
		    set R [lindex $res 0]
			log info "Found R: $R"
			return $R
		  }
		}
      }
    }
    # return "Rscript.exe"
    return "Rscript" ; # first make it work on linux, then windows, use os-info, see use of eog/irfanview in a perftoolset script.
  }
  
  # with this proc no need to 'global log' in every proc, just do 'log XXX' instead of '$log XXX'
  proc log {args} {
    # global log
    variable log
    $log {*}$args
  }
  
  # 28-12-2012 put this proc and the 2 below in fp.tcl in lib.
  # set var_name to value if value is non-empty. Keep unchanged otherwise.
  proc when_set {var_name value} {
    upvar $var_name var
    if {$value != ""} {
      set var $value 
    }
  }
  
  # give a var a value if it does not already have a value (not set, or set to "" or {})
  # compared to the previous proc, this one checks the actual value of var_name, the previous checks value.
  proc set_if_empty {var_name value} {
    upvar $var_name var
    if {[info exists var]} {
      if {($var == "") || ($var == {})} {
        set var $value 
      } else {
        # already set to a value, do nothing. 
      }
    } else {
      set var $value 
    }  
  }

  # wrapper around variable, to define more than 1 variable without settings its value
  proc variables {args} {
    foreach arg $args {
      uplevel variable $arg 
    }
  }
  
} ; # namespace eval, jedit cannot find the matching braces.

if {[file tail $argv0] == [file tail [info script]]} {
  ndv::graphdata::graphsqlite::main $argv
}


