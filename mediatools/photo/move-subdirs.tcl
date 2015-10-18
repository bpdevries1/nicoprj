#!/usr/bin/env tclsh861

package require ndv

proc main {argv} {
  set dir "/home/media/Foto/Japan-2015/Nico"
  set descr_filename "japan.tsv"
  set dir_specs [read_descr $descr_filename]
  move_files $dir $dir_specs
}

proc read_descr {filename} {
  set f [open $filename r]
  set res {}
  gets $f header
  while {![eof $f]} {
    gets $f line
    set end ""
    lassign $line z z z dirname start end
    if {$end != ""} {
      puts "descr: $dirname: $start -> $end"
      lappend res [list $dirname $start $end]
    }
  }
  close $f
  return $res
}

# eerst alleen noemen, niet echt moven.
proc move_files {dir specs} {
  foreach filename [lsort  [glob -type f -directory $dir *]] {
    set subdir [find_subdir $filename $specs]
    if {$subdir != ""} {
      file mkdir [file join $dir $subdir]
      set tofilename [file join $dir $subdir [file tail $filename]]
      puts "Move $filename => $tofilename"
      file rename $filename $tofilename
    } else {
      puts "WARN: no subdir for: $filename"
    }
  }
}

proc find_subdir {filename specs} {
  foreach spec $specs {
    lassign $spec subdir start end
    set rootname [file rootname [file tail $filename]]
    if {($rootname >= $start) && ($rootname <= $end)} {
      return $subdir
    }
  }
  return ""
}

main $argv

