# Procedures to search in recordings wrt correlation.

# all tcl files should be automatically sourced by buildtool

# return a list of directories containing recordings for the current script.
# FIXME: should be maintained somewhere in the config.tcl file.
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

proc stmt_in_inf? {stmt inf} {
  return 1
}
