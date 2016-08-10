# project config versions:
# 1. original, with _orig* and .base directories directly in main directory.
# 2. using .bld subdir, with subdirs .base and _orig*

require libdatetime dt

task2 init {Initialise project/script
  Also update config to latest version.  
} {{update "Update project/script from old config version to latest"}
  {version "Show config version"} 
} {
  # opt dict now available.
  if {[:version $opt]} {
    puts "Current config version: [current_version]"
    return
  }
  if {[latest_version] == [current_version]} {
    puts "Version already set to latest: [current_version]"
    return
  }
  if {[current_version] == 0} {
    puts "Ok, initialise from scratch"
    init_from_scratch
    return
  }
  if {[current_version] == 1} {
    # dependent on -update param
    if {![:update $opt]} {
      puts "Already initialised, use init -update to set to latest version"
      return
    }
    puts "Ok, update from 1 to 2"
    init_update [current_version] [latest_version]
    return
  }
  puts "Error: unknown versions: [current_version] <-> [latest_version]"
}

proc latest_version {} {
  return 2
}

proc current_version {} {
  # first try to read it from .bld/.configversion
  set version_filename [version_file]
  if {[file exists $version_filename]} {
    set version [string trim [read_file $version_filename]]
  } else {
    # if not found, it's 1 (per definition) or 0, if no .base and _orig dirs found.
    if {[file exists .base] || ([glob -nocomplain _orig*] != {})} {
      set version 1
    } else {
      set version 0
    }
  }
  return $version
}

# [2016-07-30 12:17] maybe change, if tool name changes, so one place to change then.
proc config_dir {} {
  return ".bld"
}

# TODO: also update .gitignore with .base and _orig paths, but should be in hook for git package.
proc init_from_scratch {} {
  set cfgdir [config_dir]
  file mkdir $cfgdir
  make_config_tcl
  set_config_version 2
}

proc init_update {from to} {
  if {($from != 1) || ($to != 2)} {
    puts "Don't know how to upgrade from $from to $to"
    return
  }
  init_from_scratch
  if {[file exists ".base"]} {
    file rename ".base" [file join [config_dir] ".base"]
  }
  foreach orig [glob -nocomplain -type d _orig*] {
    file rename $orig [file join [config_dir] $orig]
  }
  set_config_version 2
}

proc make_config_tcl {} {
  set config_name [config_tcl_name]
  if {[file exists $config_name]} {
    puts "Config file already exists: $config_name"
    return
  }
  # TODO: also with syntax_quote, is cleaner.
  # [2016-08-10 22:55] TODO: global not needed anymore, source is done at global level now.
  write_file $config_name "# config.tcl generated [dt/now]
global testruns_dir repo_dir repo_lib_dir lr_include_dir
set testruns_dir \{<FILL IN>\}
set repo_dir [list [file normalize "../repo"]]
set repo_lib_dir \[file join \$repo_dir libs\]
set lr_include_dir [list [det_lr_include_dir]]
"
  
}

proc config_tcl_name {} {
  return [file join [config_dir] "config.tcl"]
}

proc set_config_version {version} {
  write_file [version_file] $version
}

proc version_file {} {
  file join [config_dir] .configversion
}

# for now here, should be in package vugen or vugen-rabo
# return the first of a list of loadrunner include dirs that exists
# if none exists, return empty string.
# [2016-07-24 18:54] this one should be set in a project/repo config task.
proc det_lr_include_dir {} {
  set dirs {{C:\Program Files (x86)\HP\Virtual User Generator\include}
    /home/ymor/RABO/VuGen/lr_include}
  foreach dir $dirs {
    if {[file exists $dir]} {
      return $dir
    }
  }
  return ""
}
