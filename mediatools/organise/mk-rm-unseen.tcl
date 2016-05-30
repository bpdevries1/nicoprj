#!/usr/bin/env tclsh861

package require ndv
set_log_global debug

proc main {argv} {
  set options {
    {dir.arg "." "Directory to handle (default current dir)"}
    {config.arg "~/.config/media/media.tcl" "Config file to load with log and dir settings"}
    {outfile.arg "rm-unseen.sh" "Output shell script file"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  set config [read_config [:config $dargv]] ; # returns dict
  set seen [read_seen $config];               # also a dict, used as set.
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
proc read_seen {config} {
  set d [dict create]
  set f [open [:logfile_seen $config] r]
  while {[gets $f line] >= 0} {
    if {[regexp {Finished: (.+) \(subs: (.*)\)} $line z media subs]} {
      dict set d $media 1
      if {$subs != ""} {
        dict set d $subs 1
      }
    }
  }
  close $f
  return $d
}

# return dict: {seen {list of seen files} unseen {list of unseen files}}
# TODO: also handle subdirs.
proc handle_dir {dir seen media_roots} {
  set lfseen {}
  set lfunseen {}
  foreach filename [glob -nocomplain -directory $dir -type f *] {
    if {[is_seen $filename $seen $media_roots]} {
      lappend lfseen $filename
    } else {
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
  foreach root $media_roots {
    if {[string range $filename 0 [string length $root]-1] == $root} {
      return [string range $filename [string length $root]+1 end]
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
    # TODO: put remove for all media_roots iff file exists!
    # TODO: ? rename file to DELETE-origname instead of deleting it? (for now)
    puts $f "rm \"$unseenfile\""
  }
  close $f
}

main $argv

