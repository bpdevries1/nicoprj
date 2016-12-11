#! /home/nico/bin/tclsh

#! /usr/bin/env tclsh

# TODO: check of deze werkt vanaf gosleep

package require ndv

require libdatetime dt
use libfp

set_log_global info {filename ~/log/diskusage.log append 0}
# set_log_global debug

proc main {argv} {
  set options {
    {projectdir.arg "~/projecten/diskusage" "Project directory with SQLite DB"}
    {config.arg "config.tcl" "Config file relative to projectdir"}
  }
  set opt [getoptions argv $options ""]
  log info "Started"
  set db [get_db $opt]
  handle_df $db $opt
  handle_dirs $db $opt
  $db close
  log info "Finished"
}

if 0 {
  $ df -m
  Filesystem         1M-blocks    Used Available Use% Mounted on
  udev                    7979       0      7979   0% /dev
  tmpfs                   1600      50      1550   4% /run
  /dev/sdb1             103977   22451     76222  23% /
  tmpfs                   8000       1      8000   1% /dev/shm
  tmpfs                      5       1         5   1% /run/lock
  tmpfs                   8000       0      8000   0% /sys/fs/cgroup
  /dev/sda1            2816556 2394284    279177  90% /home
}

proc get_db {opt} {
  set prjdir [:projectdir $opt]
  file mkdir $prjdir
  set dbname [file join $prjdir diskusage.db]
  set db [dbwrapper new $dbname]
  $db add_tabledef disk_ts {id} {ts filesystem size_mb used_mb avail_mb \
                                     used_perc mounted_on}
  $db add_tabledef dir_ts {id} {ts dir size_mb nfiles ndirs}
  $db create_tables 0 ; # 0: don't drop tables first. Always do create, eg for new table defs. 1: drop tables first.
  $db prepare_insert_statements
  $db load_percentile
  
  return $db
}

proc handle_df {db opt} {
  set res [exec df -m]
  set ts [dt/now]
  $db in_trans {
    foreach line [lrange [split $res "\n"] 1 end] {
      lassign $line filesystem size_mb used_mb avail_mb used_perc mounted_on
      $db insert disk_ts [vars_to_dict ts filesystem size_mb used_mb avail_mb used_perc mounted_on]
    }
  }
}

proc handle_dirs {db opt} {
  set configfile [file join [:projectdir $opt] [:config $opt]]
  source $configfile
  foreach dir $dirs {
    handle_dir $db $dir
  }
}

proc handle_dir {db dir} {
  set counts [det_dir_counts $dir]; # MB, nfiles, ndirs as a dict
  set ts [dt/now]
  $db insert dir_ts [dict merge [vars_to_dict ts dir] $counts]
}

# recursive determine counts of dir: size_mb, nfiles, ndirs
# return dict: size_mb, nfiles, ndirs. All integers.
# ignore hidden dirs/files for now.
proc det_dir_counts {dir} {
  log debug "Handling dir: $dir"
  set size_mb 0
  set nfiles 0
  set ndirs 1
  foreach file [glob -nocomplain -directory $dir -type f *] {
    incr nfiles
    set size_mb [+ $size_mb [file_size_mb $file]]
  }
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    if {![file_link? $subdir]} {
      set res [det_dir_counts $subdir]
      incr ndirs [:ndirs $res]
      incr nfiles [:nfiles $res]
      set size_mb [+ $size_mb [:size_mb $res]]
    }
  }
  dict create size_mb [expr round($size_mb)] nfiles $nfiles ndirs $ndirs
}

proc file_size_mb {file} {
  expr 1.0 * [file size $file] / (1024*1024)
}

# return 1 iff file is a (symbolic) link
proc file_link? {path} {
  set res 0
  catch {
    file link $path
    set res 1
  }
  return $res
}

main $argv
