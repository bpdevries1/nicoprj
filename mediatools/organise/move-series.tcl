#!/usr/bin/env tclsh86

package require ndv

proc main {argv} {
  global target_root
  set target_root "/media/nico/Iomega HDD/media/Series"
  set src_root "/home/nico/media/tijdelijk"
  set series [det_series $target_root]
  handle_dir_root $src_root $target_root $series
  handle_dir_root [file join $src_root Series] $target_root $series
}

proc handle_dir_root {src_root target_root series} {
  foreach filename [glob -nocomplain -directory $src_root -type f *] {
    handle_file $filename $target_root $series
  }
  foreach filename [glob -nocomplain -directory $src_root -type d *] {
    handle_dir $filename $target_root $series
  }
}

proc handle_file {filename target_root series} {
  lassign [det_serie_season $filename $series] serie season
  if {$serie != "<none>"} {
    set target_filename [file join $target_root $serie "Season $season" [file tail $filename]]
    log info "Move $filename => $target_filename"
    file mkdir [file dirname $target_filename]
    file rename $filename $target_filename
  }
}

proc handle_dir {dirname target_root series} {
  lassign [det_serie_season $dirname $series] serie season
  if {$serie != "<none>"} {
    set nmoved 0
    foreach filename [glob -directory $dirname -type f "*"] {
      if {[lsearch {.avi .mp4 .mkv} [string tolower [file extension $filename]]] >= 0} {
        set target_filename [file join $target_root $serie "Season $season" [file tail $filename]]
        log info "Move $filename => $target_filename"
        file mkdir [file dirname $target_filename]
        file rename $filename $target_filename
        incr nmoved 
      }
    }
    if {$nmoved == 1} {
      log info "Files moved from $dirname, remove the dir"
      # file delete -force $dirname
      file rename $dirname "$dirname.TODELETE"
    } else {
      log warn "Could not find movie files to move in $dirname, other extension?" 
    }
  }
}

# @return list of series in target_root, just the name of the dir, tail part
proc det_series {target_root} {
  glob -tails -directory $target_root -type d *
}

proc det_serie_season {filename series} {
  foreach serie $series {
    if {[file_is_serie? $filename $serie]} {
      if {[regexp -nocase {S(\d\d)E\d\d} [file tail $filename] z season]} {
        return [list $serie [scan $season %d]] 
      } else {
        log warn "$filename belongs to $serie, but cannot determine season"
        return [list "<none>" 0]
      }
    } else {
      # nothing 
    }
  }
  return [list "<none>" 0]
}

# @return 1 if all words in serie occur in tail part of filename
proc file_is_serie? {filename serie} {
  set filetail [string tolower [file tail $filename]]
  set found 1
  foreach word [split $serie " '()"] {
    if {[string first [string tolower $word] $filetail] == -1} {
      set found 0 
    }
  }
  return $found
}

main $argv
