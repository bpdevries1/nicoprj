# args are ignored, but needed for task_check.
task libs {Overview of lib files, including status
  Show status of all library files, with respect to repository.
} {
  global as_project
  file mkdir ".base"
  set repo_libs [get_repo_libs]
  # puts "repo_libs: $repo_libs"
  set source_files [lsort [get_source_files]]
  log debug "source_files: $source_files"
  set included_files [det_includes_files [filter_ignore_files $source_files]]
  log debug "included_files: $included_files"
  set all_files [lsort -unique [concat $source_files $included_files]]
  set diff_found 0
  # also check if all included files exist.
  log debug "all_files; $all_files"
  foreach srcfile $all_files {
    set st "ok"
    if {$srcfile == "globals.h"} {
      # ignore
    } elseif {[in_lr_include $srcfile]} {
      # default loadrunner include file, ignore.
    } elseif {[file extension $srcfile] == ".h"} {
      set st [show_status $srcfile]
    } elseif {[lsearch -exact $included_files $srcfile] >= 0} {
      # puts "in included: $srcfile"
      set st [show_status $srcfile]
    } elseif {[lsearch -exact $repo_libs $srcfile] >= 0} {
      # puts "in repo: $srcfile"
      set st [show_status $srcfile]
    } else {
      # puts "ignore: $srcfile"
    }
    if {$st != "ok"} {
      set diff_found 1
    }
  }
  if {$diff_found} {
    puts "\n*** FOUND DIFFERENCES ***"
  } else {
    if {!$as_project} {
      puts "\nEverything up to date"  
    }
  }
}

# @param libfile: relative, just file name.
proc show_status {libfile} {
  global repolibdir as_project
  #set repofile [file join $repolibdir $libfile]
  set repofile [repofile $libfile]
  set basefile [basefile $libfile]

  set lib_ex [file exists $libfile]
  set repo_ex [file exists $repofile]
  set base_ex [file exists $basefile]

  set status_ex "$lib_ex-$repo_ex-$base_ex"
  switch  $status_ex {
    1-1-1 {
      # all exist, check mtimes
      set status [mtime_status $libfile]
    }
    1-1-0 {
      # no base, check mtimes as before
      if {[file mtime $libfile] < [file mtime $repofile]} {
        set status "repo-new - NO BASE!"
      } elseif {[file mtime $libfile] > [file mtime $repofile]} {
        set status "local-new - NO BASE!"
      } else {
        set status "ok"
        log info "$libfile: lib == repo, copy to base"
        file copy $libfile $basefile
      }
    }
    1-0-0 {
      # just local
      set status "only local"
    }

    default {
      log warn "$libfile - Unexpected situation: status_ex"
      set status "Unexpected: $status_ex (lib-repo-base)"
    }
  }
  # in project scope zo weinig mogelijk uitvoer naar stdout.
  if {$status != "ok" || !$as_project} {
    puts "\[$status\] $libfile"  
  }

  return $status
}

# @pre all 3 versions of libfile exists: local, repo and base
# TODO: maybe allow for tiny difference between mtimes? Could be that a file system is
# less detailed?
proc mtime_status {libfile} {
  global repolibdir
  set repofile [file join $repolibdir $libfile]
  set basefile [file join .base $libfile]

  set lib_mtime [file mtime $libfile]
  set repo_mtime [file mtime $repofile]
  set base_mtime [file mtime $basefile]

  if {$lib_mtime == $repo_mtime} {
    set status "ok"
    if {$lib_mtime != $base_mtime} {
      log warn "base mtime != lib time, copy lib->base"
      file copy -force $libfile $basefile
    }
  } elseif {$lib_mtime < $repo_mtime} {
    # repo is newer
    if {$lib_mtime == $base_mtime} {
      set status "repo-new"
    } else {
      set status "both-new"
    }
  } else {
    # local is newer
    if {$repo_mtime == $base_mtime} {
      set status "local-new"
    } else {
      set status "both-new"
    }
  }
  return $status
}

task diff {Show differences between local version and repo version
  Show date/time, size, and differences between local and repo version.
} {
  set st [show_status $libfile]
  puts "1:local: [file_info $libfile]"
  puts "2:base : [file_info [basefile $libfile]]"
  puts "3:repo : [file_info [repofile $libfile]]"
  if {[regexp {new} $st]} {
    diff_files $libfile [repofile $libfile] [basefile $libfile]
  } else {
    # no use to do diff
  }
}

# diff_files also called from regsub_file, with no base file.
proc diff_files {libfile repofile {basefile ""}} {
  set res "<none>"
  try_eval {
    set temp_out "__TEMP__OUT__"
    if {[file exists $basefile]} {
      # 3 way diff
      log debug "Exec diff3:"
      set res [exec -ignorestderr diff3 $libfile $basefile $repofile >$temp_out]
    } else {
      # just two way diff
      set res [exec -ignorestderr diff $libfile $repofile >$temp_out]  
    }
  } {
    # diff always seems to fail, possibly exit-code.
    log debug "diff(3) failed: $errorResult"
  }
  if {($res == "<none>") || ($res == "")} {
    set res [read_file $temp_out]
  } else {
    log info "Res != none: $res"
  }
  file delete $temp_out
  puts $res
}

proc file_info {libfile} {
  if {[file exists $libfile]} {
    return "[clock format [file mtime $libfile] -format "%Y-%m-%d %H:%M:%S"], [file size $libfile] bytes"
  } else {
    return "-"
  }
}

proc repofile {libfile} {
  global repolibdir
  file join $repolibdir $libfile
}

proc basefile {libfile} {
  file join .base $libfile
}

# put lib file from working/script directory into repository
task put {Put a local lib file in the repo
  Syntax: put [-force] <lib>
  Only put file in repo if it is newer than repo version, unless -force is used.
} {
  global repolibdir
  file mkdir ".base"
  # puts "args: $args"
  file mkdir $repolibdir
  lassign [det_force $args] args force
  foreach libfile $args {
    if {[file exists $libfile]} {
      set repofile [file join $repolibdir $libfile]
      if {[file exists $repofile]} {
        if {[file mtime $libfile] > [file mtime $repofile]} {
          # ok, newer file
          puts "Putting newer lib file to repo: $libfile"
          #file copy -force $libfile $repofile
          file_copy_base $libfile $repofile [basefile $libfile]
        } else {
          if {$force} {
            puts "\[FORCE\] Putting older lib file to repo: $libfile"
            # file copy -force $libfile $repofile
            file_copy_base $libfile $repofile [basefile $libfile]            
          } else {
            puts "Local file $libfile is not newer than repo file: do nothing"  
          }
        }
      } else {
        # ok, new lib file
        puts "Putting new lib file to repo: $libfile"
        file_copy_base $libfile $repofile [basefile $libfile]
        # file copy $libfile $repofile
      }
    } else {
      puts "Local lib file not found: $libfile"
    }
  }
}

# get lib file from repository into working/script directory
task get {Get a repo lib file to local dir
  Syntax: get [-force] <lib>
  Only get repo version if it is newer than the local version, unless -force is used.
} {
  global repolibdir
  file mkdir ".base"
  # puts "args: $args"
  file mkdir $repolibdir
  lassign [det_force $args] args force
  foreach libfile $args {
    set repofile [file join $repolibdir $libfile]
    if {[file exists $repofile]} {
      if {[file exists $libfile]} {
        if {[file mtime $libfile] < [file mtime $repofile]} {
          # ok, newer file in repo
          puts "Getting newer repo file: $repofile"
          # file copy -force $repofile $libfile
          file_copy_base $repofile $libfile [basefile $libfile]
        } else {
          if {$force} {
            puts "\[FORCE\] Getting older repo file: $repofile"
            # file copy -force $repofile $libfile
            file_copy_base $repofile $libfile [basefile $libfile]
          } else {
            puts "Repo file $libfile is not newer than local file: do nothing"  
          }
        }
      } else {
        # ok, new repo file, not yet in local prj dir.
        puts "Getting new repo file: $repofile"
        # file copy $repofile $libfile
        file_copy_base $repofile $libfile [basefile $libfile]
        # also add to project
        add_file $libfile
      }
    } else {
      puts "Repo lib file not found: $repofile"
    } ; # if file exists repofile
  } ; # foreach libfile
}

proc file_copy_base {src target base} {
  file copy -force $src $target
  file copy -force $src $base
}

proc det_force {lst} {
  set force 0
  set res {}
  foreach el $lst {
    if {$el == "-force"} {
      set force 1
    } else {
      lappend res $el
    }
  }
  list $res $force
}
