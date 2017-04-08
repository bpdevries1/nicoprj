#! /usr/bin/env tclsh

# [2017-04-07 19:12] Sync directories, like Unison.
# One dir (via RPi) is slow, so when files are moved in one place, Unison would
# delete and copy again, this is not efficient. Goal here is to find file at old
# location and move to the new location.
# For now one master-dir and one slave, also like the following Unison setting:
# force = <dir name>
#
# Assume if filename and size are the same, the files are the same. No MD5 check for
# now, would take a long time.

package require ndv
package require struct::set

require libio io

use libfp

set_log_global info

# Only show duplicate files if they are bigger than ~1MB.
set SIZE_HANDLE_TRESHOLD 1e6

proc main {argv} {
  set options {
    {unison.arg "" "Read unison profile (just root and force)"}
    {master.arg "" "Master directory"}
    {slave.arg "" "Slave directory"}
    {debug "Set loglevel to debug"}
    {n "Do nothing, just show what would be done"}
  }
  set usage ": [file tail [info script]] \[options]:"
  set opt [getoptions argv $options $usage]
  if {[:debug $opt]} {
    $log set_log_level debug
  }
  if {[:unison $opt] != ""} {
    set opt [read_unison $opt]; # determine master and slave directories from unison
  }
  if {[:master $opt] == "" || [:slave $opt] == ""} {
    puts stderr "Both master and slave should be given, or a Unison project"
    puts stderr "Got: $opt"
    exit 1
  }
  sync_dirs $opt
}

proc sync_dirs {opt} {
  global slave_files master_root slave_root nwarnings; # don't want to pass around as (copied) param each time.
  set nwarnings 0
  
  set master_root [:master $opt]
  set slave_root [:slave $opt]
  assert {$master_root != ""}
  assert {$slave_root != ""}
  assert {$master_root != $slave_root}
  
  puts "master: $master_root"
  puts "slave : $slave_root"

  # Read current file locations in slave, store with filename,size as key, full path as value.
  set slave_files [read_dir $slave_root]
  check_slave_files
  # breakpoint
  
  # Check each file in master:
  # * if it's already in the same place wihtin slave, it's already in sync, do nothing.
  # * if it's in another dir in slave, move from old location to the new, possibly creating dirs.
  # * Otherwise copy from master to slave.
  sync_from_master $master_root $opt
  
  # Then check each file in slave:
  # * If it's in the same place as master, it's in sync, ok.
  # * Otherwise it's an old file, so delete.
  sync_from_slave $slave_root $opt
}

# merge opt with settings read from unison-key in opt
proc read_unison {opt} {
  # set profile_name [file join ~ .unison [:unison $opt].prf]
  # FiXME: prf.ff weer op .prf zetten, tijdens def even handig.
  set profile_name [file join ~ .unison [:unison $opt].prf.ff-niet-ivm-gosleep]
  if {![file exists $profile_name]} {
    puts stderr "Unison profile does not exist: $profile_name"
    exit 2
  }
  # possibly use libinifile, only the unison file does not have [sections].
  set kv_items [read_items $profile_name]
  set roots [list]
  set master ""
  foreach item $kv_items {
    if {[:key $item] == "force"} {
      set master [:value $item]
    }
    if {[:key $item] == "root"} {
      lappend roots [:value $item]
    }
  }
  set slave ""
  foreach root $roots {
    if {$root != $master} {
      set slave $root
    }
  }
  assert {$master != ""}
  assert {$slave != ""}
  assert {$master != $slave}
  dict merge $opt [dict create master $master slave $slave]
}

proc read_items {filename} {
  set items [list]
  io/with_file f [open $filename r] {
    while {[gets $f line] >= 0} {
      set line [string trim $line]
      if {[regexp {^#} $line]} {
        continue;               # comment line
      }
      if {[regexp {^(.+)=(.*)$} $line z k v]} {
        lappend items [dict create key [string trim $k] value [string trim $v]]
      }
    }
  }
  return $items
}

# return dict of all files (or only big files?) in dir;
# key = filename,filesize
# value = full path
# check if key occurs more than once: error or warning
# recurse subdirs
proc read_dir {root} {
  global SIZE_HANDLE_TRESHOLD
  # in one dir, we can't have duplicate names, file system will prevent this.
  set res [dict create]
  foreach filename [glob -nocomplain -directory $root -type f *] {
    # values are lists, so they can be merged/concat-ed.
    if {[file size $filename] >= $SIZE_HANDLE_TRESHOLD} {
      dict set res [filename_key $filename] [list $filename]
    }
  }
  foreach subdir [glob -nocomplain -directory $root -type d *] {
    set subres [read_dir $subdir]
    set res [dict_merge_append $res $subres]
    if 0 {
      if {[dict_has_duplicates $res $subres]} {
        if {[ dict_show_duplicates $res $subres $SIZE_HANDLE_TRESHOLD]} {
          log warn "Found duplicate keys"; # should be more specific.
          exit 2        
        }
      }
      set res [dict merge $res $subres]
    }
  }
  return $res
}

proc check_slave_files {} {
  global slave_files
  foreach key [dict keys $slave_files] {
    set l [dict get $slave_files $key]
    if {[count $l] > [count [struct::set union $l]]} {
      log error "Duplicate values for key: $key"
      foreach el $l {
        log error "  $el"
      }
      exit 3
    }
    foreach filename $l {
      if {![file exists $filename]} {
        log error "Slave file does not exist: $filename"
        exit 3
      }
    }
  }
}

# Check each file in master:
proc sync_from_master {master_dir opt} {
  global slave_files SIZE_HANDLE_TRESHOLD
  foreach filename [glob -nocomplain -directory $master_dir -type f *] {
    if {[file size $filename] >= $SIZE_HANDLE_TRESHOLD} {
      sync_from_master_file $filename $opt
    }
  }
  foreach subdir [glob -nocomplain -directory $master_dir -type d *] {
    sync_from_master $subdir $opt
  }
}

# * if it's already in the same place wihtin slave, it's already in sync, do nothing.
# * if it's in another dir in slave, move from old location to the new, possibly creating dirs.
# * Otherwise copy from master to slave.
proc sync_from_master_file {filename opt} {
  global slave_files master_root slave_root nwarnings
  set slave_name [corresponding_path $master_root $slave_root $filename]
  if {[file exists $slave_name]} {
    # could check size, MD5, whole contents, but not for now.
    log debug "Slave already exists, nothing to do: $slave_name"
    return
  }
  set l [dict_get $slave_files [filename_key $filename]]
  if {[count $l] == 0} {
    log info "Slave does not exist anywhere, so copy: $filename"
    copy_slave_file $filename $opt
  } else {
    # file already exists once or more in slave file system, move the first one to
    # new location, both in file system and in slave_files struct
    move_slave_file $filename $opt
  }


}


# check form current contents of slave_files, should be up-to-date with moving and copying.
proc sync_from_slave {slave_root opt} {
  global slave_files master_root

  foreach key [dict keys $slave_files] {
    set l [dict get $slave_files $key]
    foreach slave_filename $l {
      set master_filename [corresponding_path $slave_root $master_root $slave_filename]
      if {[file exists $master_filename]} {
        log debug "Ok, master exists, do nothing"
      } else {
        log info "Old file in slave-dir, delete: $slave_filename"
        log info "All files in list:"
        foreach filename $l {
          set ex [file exists $filename]
          set exm [file exists [corresponding_path $slave_root $master_root $filename]]
          log info "  ${ex}-${exm}: $filename"
        }
        if {![:n $opt]} {
          log info "Really delete file"
          log warn "TODO!"
        } else {
          log info "-n given, do nothing"
        }
      }
    }
  }
}

proc move_slave_file {filename opt} {
  global slave_files master_root slave_root nwarnings
  set target_slave_name [corresponding_path $master_root $slave_root $filename]
  set l [dict_get $slave_files [filename_key $filename]]
  # set source_slave_name [first $l]
  set source_slave_index [first_non_existing_master $l]
  if {$source_slave_index < 0} {
    log error "No non-existing (in master) slave file found for: $filename, exit"
    exit 3;                     # Should return, and do copy anyway?
    # otoh: this is probably a real duplicatie, so should solve this by deduplication!
  }
  set source_slave_name [lindex $l $source_slave_index]
  log info "Move file: \n  $source_slave_name -> \n  $target_slave_name"
  if {![:n $opt]} {
    log info "Really move file"
    file mkdir [file dirname $target_slave_name]
    file rename $source_slave_name $target_slave_name
    #log warn "Exit after first move"
    #exit 3
  } else {
    log info "-n given, do nothing"
  }

  # set l2 [lreplace $l 0 0 $target_slave_name]
  set l2 [lreplace $l $source_slave_index $source_slave_index $target_slave_name]
  dict set slave_files [filename_key $filename] $l2
}

proc first_non_existing_master {lst} {
  global master_root slave_root
  set index 0
  foreach slave_filename $lst {
    set master_filename [corresponding_path $slave_root $master_root $slave_filename]
    if {![file exists $master_filename]} {
      # ok, can use this one
      return $index
    }
    incr index
  }
  return -1;     # not a suitable source found, so should copy (maybe)
}

proc copy_slave_file {filename opt} {
  global slave_files master_root slave_root nwarnings
  set target_slave_name [corresponding_path $master_root $slave_root $filename]
  log info "Copy file:\n  $filename ->\n  $target_slave_name"
  if {![:n $opt]} {
    log info "Really copy file"
    file mkdir [file dirname $target_slave_name]
    file copy $filename $target_slave_name
    file mtime $target_slave_name [file mtime $filename]
  } else {
    log info "-n given, do nothing"
  }

  dict set slave_files [filename_key $filename] [list $target_slave_name]
}


proc filename_key {filename} {
  return "[file tail $filename]>>[file size $filename]"
}

##############################
# possible library functions, although some not used here anymore.

# proc det_relative_path {sourcefile rootdir}

# determine corresponding path in root2 for path1 within root1
proc corresponding_path {root1 root2 path1} {
  file join $root2 [det_relative_path $path1 $root1]
}

proc dict_has_duplicates {d1 d2} {
  if {[+ [count [dict keys $d1]] [count [dict keys $d2]]] > [count [dict keys [dict merge $d1 $d2]]]} {
    return 1
  } else {
    return 0
  }
}

proc dict_show_duplicates {d1 d2 size_treshold} {
  set shown 0
  dict for {k v} $d2 {
    if {[dict exists $d1 $k]} {
      if {![regexp {>>(.+)$} $k z size]} {
        breakpoint
      }
      if {$size >= $size_treshold} {
        puts stderr "$k -> $v"
        puts stderr "$k -> [dict get $d1 $k]"
        set shown 1
      }
    }
  }
  return $shown
}

main $argv
