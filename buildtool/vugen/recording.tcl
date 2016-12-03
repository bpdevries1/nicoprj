# Procedures to search in recordings wrt correlation.

# all tcl files should be automatically sourced by buildtool

# return a list of directories containing recordings for the current script.
# TODO: should be maintained somewhere in the config.tcl file.
# for now hardcoded for RRS.
proc recording_dirs {} {
  filter [fn x {regexp RRS-rec $x}] [glob -directory [file normalize ..] -type d *]
}

proc correlations {stmt} {
  set rec_dirs [stmt_recording_dirs $stmt]

  
  return "Recording dirs where statement is found: $rec_dirs"
    
}

# return all recording dirs where stmt is found.
# found === both snapshot and URL are the same.
proc stmt_recording_dirs {stmt} {
  #breakpoint
  filter [fn dir {stmt_in_recording_dir? $stmt $dir}] [recording_dirs]
}

proc stmt_in_recording_dir? {stmt dir} {
  #some? any?
  #some? [fn file {stmt_in_file? $stmt $file}] [glob -directory $dir -type f "*.c"]
  #breakpoint
  any? [fn inf {stmt_in_inf? $stmt $inf}] [glob -directory "$dir/data" -type f "*.inf"]
}

# check if stmt->url->path occurs in inf file and if snapshot number is the same.
proc stmt_in_inf? {stmt inf} {
  set inf_snapshot [file rootname [file tail $inf]]
  if {$inf_snapshot == [stmt->snapshot $stmt]} {
    set path [-> $stmt stmt->url url->parts :path]
    # for now just check if path occurs in inf file.
    set inf_text [read_file $inf]
    if {[string first $path $inf_text] >= 0} {
      return 1  
    }
  }
  return 0  
}

