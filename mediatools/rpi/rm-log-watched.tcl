#!/usr/bin/env tclsh

# remove shortcut links from R.Pi iff they appear in the watched series.org
# first try for Seinfeld, which has special filenames, like below:
# Seinfeld Season 06 Episode 01 - The Chaperone.mkv

proc main {argv} {
  global stderr argv0
  lassign $argv watched_filename target_dir really
  if {$target_dir == ""} {
    puts stderr "$argv0 <watched_filename> <target_dir> \[-r\]"
    puts stderr "Option -r: really delete links (otherwise dry run)"
    exit 1
  }
  set f [open $watched_filename r]
  while {![eof $f]} {
    gets $f line
    if {[regexp -nocase {s(\d\d?)e(\d\d?) } $line z season episode]} {
      delete_file $target_dir $season $episode $really
    }
  }
  close $f
}

proc delete_file {target_dir season episode really} {
  set season_dir [find_season_dir $target_dir $season]
  if {$season_dir != ""} {
    # could be more than one epi file, eg a subs/srt file.
    set epi_files [find_epi_files $season_dir $season $episode]
    if {$epi_files != {}} {
      foreach epi_file $epi_files {
        if {$really == "-r"} {
          puts "Deleting: $epi_file"
          file delete $epi_file
        } else {
          puts "Dry run, not deleting: $epi_file"
        }
      }
    } else {
      puts "Episode file for $season-$episode not found"
    }
  } else {
    puts "Season dir for $season not found"
  }
}

# paran season: possibly includes 0 at the start, like 06.
proc find_season_dir {target_dir season} {
  set dirs [glob -nocomplain -directory $target_dir -type d "*eason*"]
  set res ""
  regsub {^0} $season "" season
  foreach dir $dirs {
    if {[regexp -nocase "season ?$season\[^0-9\]" "[file tail $dir]ZZZ"]} {
      set res $dir
    }
  }
  return $res 
}

# find one or more episode files. Could be both the video and subs-file.
# param episode should always be 2 digits, so can start with a 0.
# episode file could be without
# param season - just to double check the filename
# filename could be either:
# S01E01
# Seinfeld Season 06 Episode 01 - The Chaperone.mkv
# and maybe others to be added later
proc find_epi_files {season_dir season episode} {
  regsub {^0} $season "" season
  regsub {^0} $episode "" episode
  set res {}
  foreach epi_file [glob -nocomplain -directory $season_dir -type f *] {
    if {[regexp -nocase "season ?0?$season\[^0-9\]episode ?0?$episode\[^0-9\]" "[file tail $epi_file]ZZZ"]} {
      lappend res $epi_file
    }
  }
  return $res
}

main $argv
