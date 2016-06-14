#!/usr/bin/env tclsh861

package require ndv
set_log_global debug

proc main {argv} {
  set options {
    {dir.arg "." "Directory to handle (default current dir)"}
    {config.arg "~/.config/media/media.tcl" "Config file to load with log and dir settings"}
    {outfile.arg "rm-unseen.sh" "Output shell script file"}
    {minwatch.arg "600" "Minimum time in seconds watched before defined as seen"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  set config [read_config [:config $dargv]] ; # returns dict
  set seen [read_seen $config [:minwatch $dargv]]  ; # also a dict, used as set.
  # breakpoint
  set media_roots [:media_roots $config]
  file delete [:outfile $dargv]
  set seen_unseen [handle_dir [file normalize [:dir $dargv]] $seen $media_roots]
  # breakpoint
  mk_rm_unseen $seen_unseen $media_roots [:outfile $dargv]
}

proc read_config {config_file} {
  source $config_file
  return [get_media_config]
}

# [2016-04-03 19:09:23] Finished: /media/shortcuts-links/Better Call Saul/Season 2b/Better.Call.Saul.S02E01.720p.HDTV.x264-AVS[ettv]/Better.Call.Saul.S02E01.720p.HDTV.x264-AVS[ettv].mkv (subs: )

# [2015-08-30 09:20:15] Finished: /media/shortcuts-links/Coupling/Coupling Season 1/Coupling - [1x04] - Inferno.mkv (subs: /media/shortcuts-links/Coupling/Coupling Season 1/Coupling - [1x04] - Inferno.srt)


# @return dict, used as set. key = absolute path of media item seen.
proc read_seen {config minwatch} {
  set df [dict create];         # finished watching, only if longer than minwatch seconds
  set ds [dict create];         # started watching
  set f [open [:logfile_seen $config] r]
  while {[gets $f line] >= 0} {
    if {[regexp {\[([0-9 :-]+)\] Start: (.+) \(subs: (.*)\)} $line z ts media subs]} {
      dict set ds $media $ts
      if {$subs != ""} {
        dict set ds $subs $ts
      }
    }
    if {[regexp {\[([0-9 :-]+)\] Finished: (.+) \(subs: (.*)\)} $line z ts media subs]} {
      if {[long_enough $ds $media $ts $minwatch]} {
        log debug "Watched long enough: $media"
        dict set df $media 1  
      } else {
        log warn "Watched not long enough: $media"
      }
      if {$subs != ""} {
        if {[long_enough $ds $subs $ts $minwatch]} {
          dict set df $subs 1  
        }
      }
    }
  }
  close $f
  return $df
}

# return 1 if time between start / finish is at least minwatch seconds
proc long_enough {d filename ts_end minwatch} {
  set ts_start [dict_get $d $filename]
  if {$ts_start == ""} {
    return 0
  }
  set sec_start [to_sec $ts_start]
  set sec_end [to_sec $ts_end]
  if {$sec_end - $sec_start >= $minwatch} {
    return 1
  } else {
    return 0
  }
}

proc to_sec {ts} {
  clock scan $ts -format "%Y-%m-%d %H:%M:%S"
}

# return dict: {seen {list of seen files} unseen {list of unseen files}}
# TODO: also handle subdirs.
proc handle_dir {dir seen media_roots} {
  set lfseen {}
  set lfunseen {}
  foreach filename [glob -nocomplain -directory $dir -type f *] {
    if {[ignore_file $filename]} {
      continue
    }
    if {[is_seen $filename $seen $media_roots]} {
      log debug "Adding to lfseen: $filename"
      lappend lfseen $filename
    } else {
      log debug "Adding to lfunseen: $filename"
      lappend lfunseen $filename
    }
  }
  set d [dict create seen $lfseen unseen $lfunseen]

  # [2016-05-30 21:36] first in an imperative way, could be more functional with map or reduce.
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    set d2 [handle_dir $subdir $seen $media_roots]
    set d [dict_merge_append $d $d2]
  }

  return $d
}

proc ignore_file {filename} {
  if {[file extension $filename] == ".log"} {
    return 1
  }
  if {[regexp {DELETE_} [file tail $filename]]} {
    # even deze wel
    return 0
  }
  return 0
}

proc is_seen {filename seen media_roots} {
  set rel_filename [det_rel_filename $filename $media_roots]
  if {$rel_filename == ""} {
    log warn "Could not determine relative filename for: $filename"
    breakpoint
  }
  foreach root $media_roots {
    set abs_filename [file join $root $rel_filename]
    if {[dict exists $seen $abs_filename]} {
      return 1
    }
  }
  return 0
}

proc det_rel_filename {filename media_roots} {
  set root [det_root $filename $media_roots]
  if {$root == ""} {
    return ""
  }
  return [string range $filename [string length $root]+1 end] 
}

proc det_root {filename media_roots} {
  foreach root $media_roots {
    if {[string range $filename 0 [string length $root]-1] == $root} {
      return $root
    }
  }
  return ""
}

proc mk_rm_unseen {seen_unseen media_roots outfile} {
  set f [open $outfile w]
  set rel_seen {}
  puts $f "# Seen files:"
  foreach seenfile [:seen $seen_unseen] {
    lappend rel_seen [det_rel_filename $seenfile $media_roots]
  }
  foreach seenfile [lsort $rel_seen] {
    puts $f "# $seenfile"
  }
  puts $f "# ---------------"
  foreach unseenfile [:unseen $seen_unseen] {
    log info "unseenfile: $unseenfile"
    set rel_name [det_rel_filename $unseenfile $media_roots]
    foreach root $media_roots {
      log info "check root: $root"
      set abs_name [file join $root $rel_name]
      if {[file exists $abs_name]} {
        log info "exists: mk rm: $rel_name"
        # puts $f "rm \"$abs_name\""
        # set abs_deleted [file join [file dirname $abs_name] "DELETE_[file tail $abs_name]"]
        set abs_deleted [file join [det_root $abs_name $media_roots] _DELETED_ [file tail $abs_name]]
        puts $f "mkdir -p \"[file dirname $abs_deleted]\""
        puts $f "mv -f \"$abs_name\" \"$abs_deleted\""
      }
    }
  }
  close $f
  puts "making file executable: $outfile"
  exec /bin/chmod a+x $outfile
}

main $argv

