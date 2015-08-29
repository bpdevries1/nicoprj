#!/usr/bin/env tclsh

# script to run on shortcut-links, to remove empty dirs where all epi's have been watched.
# also take care of subtitle files.

proc main {argv} {
  lassign $argv root_dir really
  clean_dir $root_dir {} $really
}

# dir: can be a mixed video/subs dir, or a dir with only subs, and need to know parent_episodes.
proc clean_dir {dir parent_episodes really} {
  puts "Check dir: $dir"
  set episodes {}
  # first get all video files, needed for check with subtitles
  # todo: lots of ways to make it more functional (FP)
  foreach filename [glob -nocomplain -directory $dir -type f *] {
    if {[is_video $filename]} {
      # puts "Video file, store episode nr: $filename"
      lappend episodes [det_epi $filename]
    }
  }
  set epis_both [lsort [concat $parent_episodes $episodes]]
  puts "$dir => epi's both to check: $epis_both"
  # then all files again: video, subtitle or other
  foreach filename [glob -nocomplain -directory $dir -type f *] {
    if {[is_video $filename]} {
      # ok, do nothing
    } elseif {[is_subtitles $filename]} {
      # now it gets interesting
      # puts "Subtitles file, determine episode nr: $filename"
      set epi [det_epi $filename]
      if {[lsearch -exact $epis_both $epi] < 0} {
        # puts "Video file for this subtitle file not found, so delete this file: $filename"
        delete_path $filename $really
      }
    } else {
      puts "Other file: delete"
      delete_path $filename $really
    }
  }

  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    clean_dir $subdir $episodes $really
  }

  if {[llength [glob -nocomplain -directory $dir *]] == 0} {
    delete_path $dir $really
    # for now, don't delete dirs.
    # delete_path $dir 0
  }
}

proc is_video_fout {filename} {
  # maybe should check extension, for now just check size, anything bigger than 1MB is a video. Don't use for hulp.
  set size [file size $filename]
  # puts "file size $filename: $size"
  if {$size > 1000000} {
    return 1
  } else {
    return 0
  }
}

proc is_video {filename} {
  set ext [file extension $filename]
  if {[lsearch -exact -nocase {.mkv .mp4 .avi} $ext] >= 0} {
    return 1
  } else {
    return 0
  }
}


proc is_subtitles {filename} {
  set ext [file extension $filename]
  if {[lsearch -exact -nocase {.srt .sub} $ext] >= 0} {
    return 1
  } else {
    return 0
  }
}

# Episode 02
# S01E02
# [2x01]
# (4x03)
proc det_epi {path} {
  set filename [file tail $path]
  if {[regexp -nocase {episode ?0?(\d+)[^0-9]} $filename z epi]} {
    return $epi
  } elseif {[regexp -nocase {s\d+e0?(\d+)[^0-9]} $filename z epi]} {
    return $epi
  } elseif {[regexp -nocase {[\(\[]\d+x0?(\d+)[\]\)]} $filename z epi]} {
    return $epi
  } else {
    # error "Cannot not determine epi from filename: $path"
    # sometimes have extra features, no epi to determine. Return 0 for both video
    # and subtitle, than subtitle won't be deleted.
    return 0
  }
}

proc delete_path {pathname really} {
  if {$really == "-r"} {
    puts "Delete path: $pathname"
    file delete $pathname
  } else {
    puts "Dry run, delete: $pathname"
  }
}

main $argv

