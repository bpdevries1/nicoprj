# Procedures to search in recordings wrt correlation.

# all tcl files should be automatically sourced by buildtool

# return a list of directories containing recordings for the current script.
# TODO: should be maintained somewhere in the config.tcl file.
# for now hardcoded for RRS.
proc recording_dirs {} {
  filter [fn x {regexp RRS-rec $x}] [glob -directory [file normalize ..] -type d *]
}

# Write html (with hh) with correlation info
proc correlations {hh stmt} {
  set rec_dirs [stmt_recording_dirs $stmt]
  foreach rec_dir $rec_dirs {
    correlations_rec_dir $hh $stmt $rec_dir
  }
  

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

# TODO: also look for other things besides paths, like GET/POST parameters.
proc correlations_rec_dir {hh stmt rec_dir} {
  $hh line "Recording dir where statement is found: $rec_dir"
  set inf_files [filter [fn inf {stmt_in_inf? $stmt $inf}] \
                     [glob -directory "$rec_dir/data" -type f "*.inf"]]
  foreach inf_file $inf_files {
    $hh line "Statement found in inf_file: $inf_file"
    show_path_responses $hh $stmt $rec_dir $inf_file
  }
}

# show all statements/requests in recording dir where stmt.path is found in the response.
# algorithm:
# * start at snapshot of inf file, and move back to 1. Stop when 1 found (maybe more later)
# * Only check a snapshot when the .inf refers to a Filename t<snapshot>.x
#   - because eg t12.inf points to t6.htm, but don't want those, are only PNG's.
proc show_path_responses {hh stmt rec_dir inf_file} {
  regexp {t(\d+).inf} [file tail $inf_file] z stmt_snapshot_nr
  set path [-> $stmt stmt->url url->parts :path]
  for {set ss_check [expr $stmt_snapshot_nr -1]} {$ss_check >= 1} {incr ss_check -1} {
    # $hh line "Checking snapshot ${ss_check}..."
    # for now only check if stmt.path occurs in snapshot, don't create regexp's yet.
    if {[snapshot_contains_path? $hh $rec_dir $ss_check $path]} {
      $hh line "Found $path in snapshot $ss_check"
    }
  }
}

# also have hh here, so can print some debugging statements.
proc snapshot_contains_path? {hh rec_dir ss path} {
  set inf_file [file join $rec_dir data "t${ss}.inf"]
  if {[inf_contains_own_snapshot? $inf_file $ss]} {
    # TODO: continue looking, check actual response file!
    # check all files mentioned in .inf
    set response_files [inf->response_files $inf_file]
    foreach resp_file $response_files {
      # $hh line "Found response file in inf: $resp_file"
      if {[resp_file_contains_path? $rec_dir $resp_file $path]} {
        # $hh line "Found $path in response file: $resp_file"
        $hh line "Found $path in response file: [$hh get_anchor $resp_file [resp_file_path $rec_dir $resp_file]]"
        return 1
      }
    }
    $hh line "Did not find $path in response files for t${ss}.inf."
    return 0
  } else {
    # don't look here for now, probably only images
    return 0
  }
}

proc inf_contains_own_snapshot? {inf_file ss} {
  set inf_text [read_file $inf_file]
  # FileName1=t6.htm
  set re "FileName\\d+=t$ss\\."
  regexp $re $inf_text
}

proc inf->response_files {inf_file} {
  set res [list]
  foreach line [split [read_file $inf_file] "\n"] {
    if {[regexp {^FileName\d+=(.+)$} $line z filename]} {
      lappend res $filename
    }
  }
  return $res
}

proc resp_file_contains_path? {rec_dir resp_file path} {
  # set resp_file_path [file join $rec_dir data $resp_file]
  set resp_text [read_file [resp_file_path $rec_dir $resp_file]]
  if {[string first $path $resp_text] >= 0} {
    return 1
  } else {
    return 0
  }
}

proc resp_file_path {rec_dir resp_file} {
  file normalize [file join $rec_dir data $resp_file]
}
