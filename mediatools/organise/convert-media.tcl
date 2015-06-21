#!/usr/bin/env tclsh861

package require ndv
package require Tclx

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

proc main {argc argv} {
  global log


  set options {
    {dir.arg "<NODEFAULT>" "Root dir to start converting in"}
    {fromext.arg "flv,wmv,mpg,ogm" "Source extensions to convert"}
    {toext.arg "mkv" "Extension to convert to"}
    {ignoreext.arg "avi,mp4,mkv,m4v,jpg" "Source extensions to ignore"}
    {minsize.arg "1000000" "Minimum size in bytes of files to convert"}
    {deleteorig "Delete original file"}
  }

  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set d [getoptions argv $options $usage]
  $log info "Starting: [:dir $d] (minsize=[:minsize $d])"
  convert_files [:dir $d] [split  [:fromext $d] ","] [:toext $d] [concat [split  [:ignoreext $d] ","] [:toext $d]] [:minsize $d] [:deleteorig $d]

  $log info "Finished"
}

# @param fromext: list
# @param toext: single element
# @param ignoreext: list
proc convert_files {dir fromext toext ignoreext minsize deleteorig} {
  global log
  foreach fromfile [glob -nocomplain -directory $dir -type f *] {
    if {[file size $fromfile] < $minsize} {
      $log debug "Too small, continue: $fromfile"
      continue
    }
    set ext [string tolower [string range [file extension $fromfile] 1 end]]
    if {[lsearch $fromext $ext] >= 0} {
      convert_file $fromfile [det_tofile $fromfile $toext] $deleteorig
    } elseif {[lsearch $ignoreext $ext] >= 0} {
      # ok, can ignore this one
      $log debug "Ignore: $fromfile"
    } else {
      $log warn "Unknown extension for: $fromfile (ext=$ext, ignores=$ignoreext)"
    }
  }
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    convert_files $subdir $fromext $toext $ignoreext $minsize $deleteorig
  }
}

proc det_tofile {fromfile toext} {
  return "[file rootname $fromfile].$toext"
}

# @pre determined that this file has to be converted
proc convert_file {from to deleteorig} {
  global log
  if {[file exists $to]} {
    $log warn "target already exists, returning: $to"
    return
  }
  set totemp [file join [file dirname $to] "__TEMP__[file tail $to]"]
  file delete $totemp
  set fromsize [file size $from]  
  $log info "Converting from: $from (size=[to_mb $fromsize])"
  set ok 0

  set output "<none>"
  catch {
    set output [exec -ignorestderr avconv -i $from $totemp]
    set ok 1
  } res
  $log info "Converted  from: $from (size=[to_mb $fromsize])"
  $log debug "exec output: $output"
  if {$ok} {
    set tosize [file size $totemp]
    if {[expr $tosize >= 0.25*$fromsize]} {
      # ok, new size is not too small, sizes do vary a lot.
      file rename $totemp $to
      if {$deleteorig} {
        $log debug "Deleting orig: $from"
        file delete $from  
      } else {
        $log warn "Keeping orig: $from"
      }
    } else {
      $log warn "New size seems to small, don't rename and keep orig: $totemp"
    }
  } else {
    $log warn "Error while converting: $from, res: $res"
  }
  $log debug "Finished: $to"
}

proc to_mb {bytes} {
  return "[format %.0f [expr 1.0*$bytes / 1000000]] MBytes"
}

main $argc $argv

