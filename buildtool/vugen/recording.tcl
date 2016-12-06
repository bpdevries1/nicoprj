# Procedures to search in recordings wrt correlation.

# all tcl files should be automatically sourced by buildtool

# return a list of directories containing recordings for the current script.
proc recording_dirs {} {
  global recording_dirs
  # [2016-12-04 11:04] cannot use 'info var', with 'global' is is defined.
  if {[catch {set recording_dirs}]} {
    puts "WARN: set recording_dirs in .bld/config.tcl"
    exit
  }
  return $recording_dirs
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

# return 1 iff? statement can be found in recording directory.
# [2016-12-06 21:20] use -nocomplain, data dir not always available.
proc stmt_in_recording_dir? {stmt dir} {
  any? [fn inf {stmt_in_inf? $stmt $inf}] [glob -nocomplain -directory "$dir/data" -type f "*.inf"]
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

# show all statements/requests in recording dir where stmt.path is found in the response. Or a POST or GET parameter.
# algorithm:
# * start at snapshot of inf file, and move back to 1. Stop when 1 found (maybe more later)
# * Only check a snapshot when the .inf refers to a Filename t<snapshot>.x
#   - because eg t12.inf points to t6.htm, but don't want those, are only PNG's.
# TODO: rename proc, now does more than find path.
# TODO: extract part in foreach loop in new proc.
proc show_path_responses {hh stmt rec_dir inf_file} {
  regexp {t(\d+).inf} [file tail $inf_file] z stmt_snapshot_nr
  set path [-> $stmt stmt->url url->parts :path]
  for {set ss_check [expr $stmt_snapshot_nr -1]} {$ss_check >= 1} {incr ss_check -1} {
    # $hh line "Checking snapshot ${ss_check}..."
    # for now only check if stmt.path occurs in snapshot, don't create regexp's yet.
    if {[snapshot_contains_path? $hh $rec_dir $ss_check $path]} {
      $hh line "Found $path in snapshot $ss_check"
    }

    # [2016-12-06 22:12] even hier POST params erbij, daarna procs hernoemen.
    # postparams eerst alleen op value zoeken, als te veel, dan evt ook paramname erbij.
    foreach postparam [stmt->postparams $stmt] {
      if {[snapshot_contains_path? $hh $rec_dir $ss_check [:value $postparam]]} {
        $hh line "Found POST param [:name $postparam] with value [:value $postparam] in snapshot $ss_check"
      }
    }

    set get_params [-> $stmt stmt->url url->parts :params]
    foreach param $get_params {
      if {[snapshot_contains_path? $hh $rec_dir $ss_check [:value $param]]} {
        $hh line "Found GET param [:name $param] with value [:value $param] in snapshot $ss_check"
      }
    }
  }
}

# also have hh here, so can print some debugging statements.
# [2016-12-06 22:04] proc heeft side effects.
proc snapshot_contains_path? {hh rec_dir ss path} {
  set inf_file [file join $rec_dir data "t${ss}.inf"]
  if {[inf_contains_own_snapshot? $inf_file $ss]} {
    # check all files mentioned in .inf
    set response_files [inf->response_files $inf_file]
    foreach resp_file $response_files {
      if {[resp_file_contains_path? $rec_dir $resp_file $path]} {
        $hh line "Found $path in response file: [$hh get_anchor $resp_file [resp_file_path $rec_dir $resp_file]]: [resp_context $hh $rec_dir $resp_file $path]"
        return 1
      }
    }
    # $hh line "Did not find $path in response files for t${ss}.inf."
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

# maybe combine with resp_file_contains_path?
# return path with surrounding text in resp_file, iff path is found.
# otherwise return empty string.
proc resp_context {hh rec_dir resp_file path} {
  set chars_before 60
  set chars_after 40
  set resp_text [read_file [resp_file_path $rec_dir $resp_file]]
  set pos [string first $path $resp_text]
  if {$pos < 0} {
    return ""
  } else {
    $hh pre [$hh to_html [string range $resp_text $pos-$chars_before [expr $pos+$chars_after+[string length $path]]]]
  }
}

proc resp_file_path {rec_dir resp_file} {
  file normalize [file join $rec_dir data $resp_file]
}
