#!/home/nico/bin/tclsh

set MAX_R_GRAPH 25 ; # see warning msg below:
#Warning messages:
# 1: In plot.xy(xy.coords(x, y), type = type, ...) :
#   unimplemented pch value '26'
# 2: In plot.xy(xy.coords(x, y), type = type, ...) :
#   unimplemented pch value '27'

# SiteScope makes big column names, too big to show in graphs.

set MAX_LEGEND_LENGTH 60

package require Tclx
package require csv
package require struct::list
package require struct::matrix
package require math

# eigen package
catch {package require ndv}

::ndv::source_once "platform-$tcl_platform(platform).tcl" ; # load platform specific functions. 
::ndv::source_once "graphdata-lib.tcl" "find-overlaps.tcl" "split-columns.tcl"

catch {set log [::ndv::CLogger::new_logger [file tail [info script]] debug]} 

proc main {argc argv} {
  global R_binary env ar_argv log
  # set R_binary [find_R "c:/develop/R/R-2.13.0/bin/Rscript.exe" "d:/develop/R/R-2.9.0/bin/Rscript.exe" "d:/apps/R/R-2.11.1/bin/Rscript.exe" {*}[split $env(PATH) ";"]]
  # @todo path-sep characters is ; on windows.
  # @todo is RScript found within directories in PATH? or is just the dir returned?
  set R_binary [find_R "/usr/bin/Rscript" "c:/develop/R/R-2.13.0/bin/Rscript.exe" "d:/develop/R/R-2.9.0/bin/Rscript.exe" "d:/apps/R/R-2.11.1/bin/Rscript.exe" {*}[split $env(PATH) ":"]]

  set options {
    {path.arg "" "Path to graphdata file(s)s: a file, directory or directory/glob pattern"}  
    {npoints.arg 200 "Number of points to plot."}
    {clean "Clean the graph output dir before making graphs."}
    {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] path:"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  # ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  $log debug "remaining argv: $argv"
  if {$ar_argv(path) == ""} {
    lassign $argv path 
  } else {
    set path $ar_argv(path) 
  }
  if {$path == ""} {
    set path "." 
  }
  # handle_path $ar_argv(path)
  if {$ar_argv(clean)} {
    clean_graphdir $path ; # do not clean if the graphdir is the same as the data dir.    
  }
  
  set graph_filename [handle_path $path]
  if {$graph_filename != ""} {
    show_graph_file $graph_filename
  }
  # check_params $argc $argv
  # set root_dir [lindex $argv 0]
}

proc clean_graphdir {path {pattern *}} {
  global log
  set filetype [catch_call error file type $path]
  # $log warn "about to delete $graphdir"
  if {$filetype == "file"} {
    set graphdir "$path-graphs"
    file delete -force $graphdir
  } elseif {$filetype == "directory"} {
    foreach filename [glob -nocomplain -directory $path -type f $pattern] {
      clean_graphdir $filename $pattern 
    }
    foreach dirname [glob -nocomplain -directory $path -type d *] {
      clean_graphdir $dirname $pattern
    }
  } else {
    # split in directory and glob pattern
    set dir [file dirname $path]
    set glob_pattern [file tail $path]
    if {[catch_call error file type $dir] == "directory"} {
      clean_graphdir $dir $glob_pattern  
    } else {
      error "File type of path ([file type $path]) cannot be handled."
    }
  }
}

proc handle_path {path} {
  set filetype [catch_call error file type $path]
  
  if {$filetype == "file"} {
    handle_file $path
  } elseif {$filetype == "directory"} {
    handle_directory $path *
  } else {
    # split in directory and glob pattern
    set dir [file dirname $path]
    set glob_pattern [file tail $path]
    if {[catch_call error file type $dir] == "directory"} {
      handle_directory $dir $glob_pattern  
    } else {
      error "File type of path ([file type $path]) cannot be handled."
    }
  }
}

proc handle_directory {path glob_pattern {graphdir ""} {res ""}} {
  foreach filename [glob -nocomplain -directory $path -type f $glob_pattern] {
    set res2 [handle_file $filename $graphdir]
    if {$res == ""} {
      set res $res2 
    }
  }
  foreach dirname [glob -nocomplain -directory $path -type d *] {
    if {[regexp -- {-graphs$} $dirname]} {
      # nothing, this is the destination graph dir 
    } else {
      set res2 [handle_directory $dirname $glob_pattern $graphdir $res]
      if {$res == ""} {
        set res $res2 
      }
    }
  }
  return $res
}

# first make any graph
# then make it in a subdir
# then return the graph filename, so it can shown with eog/irfanview
proc handle_file {filename {graphdir ""}} {
  global MAX_R_GRAPH log ar_argv
  if {$graphdir == ""} {
    set graphdir "$filename-graphs"
  }
  set result "" ; # should contain the probably most specific graph name.
  file mkdir $graphdir
  # @todo check aantal kolommen, in R geldt een maximum, dan geen pch characters en zo meer te vinden.
  set ncol [det_ncol $filename]
  if {$ncol > 2} {
    set result [split_graph_file $filename $graphdir] ; # split columns, handle flatlines and make graphs. 
  }
  if {$ncol < 2} {
    $log warn "Less than 2 columns in $filename, graph not possible" 
    set result ""
  } elseif {$ncol == 2} {
    set result [make_graph $filename $graphdir noscale]
  } elseif {$ncol < $MAX_R_GRAPH} { 
    $log debug "#columns: $ncol" 
    set result [make_graph $filename $graphdir both]; # make_graph returns graph filename.
  }
  return $result
}

proc split_graph_file {filename graphdir} {
  global log
  set split_dir [file join $graphdir split]
  split_file_columns $filename $split_dir
  # @todo: move flatlines
  # recurse into subdir with split files, but without creating a new subdir, so the graphdir is the current dir
  set res [handle_directory $split_dir "*[file extension $filename]" $split_dir]
  $log debug "result of split: $res"
  return $res
}

# @todo first only the whole datafile, then split into columns (also in datafiles, may be handy)
proc make_graph {filename graphdir {scaletype both}} {
  global log 
  $log debug "Make graphs for $filename"
  set legend_filename [make_legend $filename $graphdir]
  # breakpoint
  # return not strictly needed here, but to clarify that the result is used.
  if {($scaletype == "both") || ($scaletype == "scale")} {
    set result [make_graph_R $filename $graphdir "graph-scale.R" "-scaled" $legend_filename]
  }
  if {($scaletype == "both") || ($scaletype == "noscale")} {
    set result [make_graph_R $filename $graphdir "graph-noscale.R" "" $legend_filename]
  }
  return $result
}

proc make_graph_R {filename graphdir r_script filename_addition legend_filename} {
  global log R_binary N_POINTS ar_argv
  set graph_filename [det_graph_filename $filename $graphdir $filename_addition]
  set r_script_path [file join [file dirname [info script]] $r_script]
  try_eval {
    # $log debug "npoints: $ar_argv(npoints)"
    # @todo determine datetime format
    $log debug "exec: $R_binary $r_script_path $filename $ar_argv(npoints) $legend_filename \"[param_format %H:%M]\" $graph_filename"
    exec $R_binary $r_script_path $filename $ar_argv(npoints) $legend_filename [param_format "%H:%M"] $graph_filename
  } {
    $log error "Error during R processing: $errorResult"
  }   
  return $graph_filename
}

# @param full path to the input file, can be relative to the current directory.
# @param graphdir dir where to put the graphs; they will be put in the root of this dir, not in a subdir of this dir. graphdir is also a full path, and can be relative to the current dir.
proc det_graph_filename {filename graphdir filename_addition} {
  # file join $graphdir "$filename$filename_addition.png"
  file join $graphdir "[file tail $filename]$filename_addition.png"
}

# put original name as second field in legend-file, to correlate where needed.
# @param full path to the input file, can be relative to the current directory.
# @param graphdir dir where to put the graphs; they will be put in the root of this dir, not in a subdir of this dir. graphdir is also a full path, and can be relative to the current dir.
proc make_legend {filename graphdir} {
  global log
  # $log debug "make_legend: $filename *** $graphdir"
  set f [open $filename r]
  gets $f line
  close $f
  set lst [::csv::split $line [det_sepchar $filename]]
  set legend_filename [file join $graphdir "[file tail $filename].legend"]
  # $log debug "legend_filename: $legend_filename"
  set fo [open $legend_filename w]
  puts $fo "legend\toriginal"
  puts $fo "[lindex $lst 0]\t[lindex $lst 0]"
  set lst [lrange $lst 1 end] ; # remove first element "Relative time"
  lassign [remove_overlaps $lst] lst_shortened mapping
  # breakpoint
  foreach {ndx orig} $mapping {
    $log debug "legend mapping: $ndx -> $orig" 
  }
  foreach el $lst el_short $lst_shortened {
     puts $fo "$el_short\t$el"
  }  
  close $fo
  return $legend_filename
}

proc det_ncol {filename} {
  set sepchar [det_sepchar $filename]
  set f [open $filename r]
  set res [llength [split [gets $f] $sepchar]]
  close $f
  return $res
}

# @todo if .ext == .txt, then look into the file.
proc det_sepchar {filename} {
  if {[file extension $filename] == ".tsv"} {
    return "\t" 
  } elseif {[file extension $filename] == ".tab"} {
    return "\t"
  } elseif {[file extension $filename] == ".csv"} {
    return ","
  } else {
    error "Cannot determine sepchar from filename: $filename" 
  }
}

# search Rscript in each of the paths given in args.
# @return the path where R is found, or just Rscript, if not found (maybe it's in the PATH)
# @todo path can be a file or a directory. A file works ok, in a directory search for Rscript(.exe).
proc find_R {args} {
  foreach path $args {
    if {[file exists $path]} {
      return $path 
    }
  }
  # return "Rscript.exe"
  return "Rscript" ; # first make it work on linux, then windows, use os-info, see use of eog/irfanview in a perftoolset script.
}


main $argc $argv

