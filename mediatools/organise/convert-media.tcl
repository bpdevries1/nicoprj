#!/usr/bin/env tclsh861

package require ndv
package require Tclx

proc main {argc argv} {
  global log warnings

  set log [::ndv::CLogger::new_logger [file tail [info script]] info]
  # $log set_file "[file tail [info script]].log"
  $log set_file [file join ~ log "[file tail [info script]]-[cur_time].log"]

  set options {
    {dir.arg "<NODEFAULT>" "Root dir to start converting in"}
    {fromext.arg "asf,flv,wmv,mpg,mpeg,ogm,vob,divx,mov,qt,ac3,3gp" "Source extensions to convert"}
    {toext.arg "mkv" "Extension to convert to"}
    {ignoreext.arg "avi,mp4,mkv,m4v,jpg,png,rar,sub,mp3,ico,pdf,epub,lrf,azw3,mobi" "Source extensions to ignore"}
    {minsize.arg "1000000" "Minimum size in bytes of files to convert"}
    {deleteorig "Delete original file"}
    {outputoptions.arg "" "Extra output options, like -r 24"}
    {dryrun "Don't actually convert, just count files and MBytes"}
  }

  set usage ": [file tail [info script]] \[options] :"
  # set dargv [::cmdline::getoptions argv $options $usage]
  set d [getoptions argv $options $usage]
  if {[:dir $d] == "<NODEFAULT>"} {
    $log warn "No dir given, exiting..."
    exit 1
  }
  
  $log info "Starting: [:dir $d] (minsize=[:minsize $d])"
  set warnings {}
  set size [convert_files [:dir $d] [split  [:fromext $d] ","] [:toext $d] [concat [split  [:ignoreext $d] ","] [:toext $d]] [:minsize $d] [:deleteorig $d] [:dryrun $d] $d]

  $log warn "All warnings: [join $warnings "\n"]"
  $log info "Total size converted: [format %.1f  $size] MB"
  if {[:dryrun $d]} {
    $log warn "This was a dry run!"
  }
  $log info "Finished"
}

proc warn {msg} {
  global log warnings
  $log warn $msg
  lappend warnings $msg
}

proc cur_time {} {
  clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"
}

# @param fromext: list
# @param toext: single element
# @param ignoreext: list
proc convert_files {dir fromext toext ignoreext minsize deleteorig dryrun d} {
  global log
  set totalsize_MB 0
  foreach fromfile [glob -nocomplain -directory $dir -type f *] {
    set ext [string tolower [string range [file extension $fromfile] 1 end]]
    if {[lsearch $fromext $ext] >= 0} {
      set size [convert_file $fromfile [det_tofile $fromfile $toext] $deleteorig $dryrun $d]
      set totalsize_MB [expr $totalsize_MB + $size]
    } elseif {[lsearch $ignoreext $ext] >= 0} {
      # ok, can ignore this one
      $log debug "Ignore: $fromfile"
    } else {
      if {[file size $fromfile] < $minsize} {
        $log debug "Too small, continue: $fromfile"
        continue
      }
      warn "Unknown extension for: $fromfile (ext=$ext, ignores=$ignoreext)"
    }
  }
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    set size [convert_files $subdir $fromext $toext $ignoreext $minsize $deleteorig $dryrun]
    set totalsize_MB [expr $totalsize_MB + $size]
  }
  return $totalsize_MB
}

proc det_tofile {fromfile toext} {
  return "[file rootname $fromfile].$toext"
}

# @pre determined that this file has to be converted
proc convert_file {from to deleteorig dryrun d} {
  global log warnings
  if {[file exists $to]} {
    warn "target already exists, returning: $to"
    return
  }
  set totemp [file join [file dirname $to] "__TEMP__[file tail $to]"]
  file delete $totemp
  set fromsize [file size $from]  
  $log info "Converting from: $from (size=[to_mb $fromsize]) MB"
  set ok 0

  set output "<none>"
  if {$dryrun} {
    $log debug "Dryrun, don't convert"
    set ok 0
  } else {
    catch {
      set cmd [list avconv {*}[extra_params $from] -i $from -strict experimental -qscale 1 -aq 1 {*}[:outputoptions $d] $totemp]
      log info "Executing cmd: $cmd"
      # set output [exec -ignorestderr avconv -i $from $totemp]
      set output [exec -ignorestderr {*}$cmd]
      set ok 1
    } res
    $log info "Converted  from: $from (size=[to_mb $fromsize] MB)"
    $log debug "exec output: $output"
  }

  if {$ok} {
    set tosize [file size $totemp]
    if {[expr $tosize >= 0.1*$fromsize]} {
      # ok, new size is not too small, sizes do vary a lot.
      file rename $totemp $to
      if {$deleteorig} {
        $log debug "Deleting orig: $from"
        if {$dryrun} {
          $log debug "Dry run, don't delete"
        } else {
          file delete $from    
        }
      } else {
        warn "Keeping orig: $from"
      }
    } else {
      warn "New size seems to small, don't rename and keep orig: $totemp"
    }
  } else {
    if {!$dryrun} {
      warn "Error while converting: $from, res: $res"  
    }
  }

  $log debug "Finished: $to"
  return [to_mb $fromsize]
}

# for some source extension we need extra params, eg -r 22 for VOB files
# not sure yet if 22 is always the correct value.
# found this one at: http://redino.net/blog/category/ffmpeg/
proc extra_params {from} {
  set ext [string range [string tolower [file extension $from]] 1 end]
  if {$ext == "vob"} {
    return [list -r 22]
  }
  return {}
}

proc to_mb {bytes} {
  return "[format %.1f [expr 1.0*$bytes / 1000000]]"
}

main $argc $argv

