# project config versions:
# 1. original, with _orig* and .base directories directly in main directory.
# 2. using .bld subdir, with subdirs .base and _orig*
# 3. using ~/.config/buildtool/env.tcl and prjtype specific settings.

require libdatetime dt

use libmacro

# TODO: add type parameter, and only write stuff to config for certain types, eg lr_include_dir.
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
  # here current >=1 and != latest
  if {![:update $opt]} {
    puts "Already initialised, use init -update to set to latest version"
    return
  }
  init_update [current_version] [latest_version]
  
  # puts "Error: unknown versions: [current_version] <-> [latest_version]"
}

proc latest_version {} {
  return 3
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

proc config_tcl_name {} {
  file join [config_dir] "config.tcl"
}

proc config_env_tcl_name {} {
  global buildtool_env
  file join [config_dir] "config-${buildtool_env}.tcl"
}

proc version_file {} {
  file join [config_dir] .configversion
}

# TODO: also update .gitignore with .base and _orig paths, but should be in hook for git package.
proc init_from_scratch {} {
  set cfgdir [config_dir]
  file mkdir $cfgdir
  make_config_tcl
  set_config_version [latest_version]
}

proc init_update {from to} {
  while {$from < $to} {
    set from [init_update_from_$from]
  }
  set_config_version $to
}

proc init_update_from_1 {} {
  init_from_scratch
  if {[file exists ".base"]} {
    file rename ".base" [file join [config_dir] ".base"]
  }
  foreach orig [glob -nocomplain -type d _orig*] {
    file rename $orig [file join [config_dir] $orig]
  }
  return 2
}

proc init_update_from_2 {} {
  # TODO: read config, add env parts
  set config_name [config_tcl_name]
  set text [read_file $config_name]
  set config_v3 [get_config_v3]
  set text "$text\n$config_v3"
  write_file $config_name $text

  make_config_env_tcl
  return 3
}

# TODO: set to v3, source env things
proc make_config_tcl {} {
  set config_name [config_tcl_name]
  if {[file exists $config_name]} {
    puts "Config file already exists: $config_name"
    return
  }
  # TODO: also with syntax_quote, is cleaner.
  # [2016-08-10 22:55] TODO: global not needed anymore, source is done at global level now.
  set now [dt/now]
  set config_v3 [get_config_v3]
  write_file $config_name [syntax_quote {# config.tcl generated ~@$now
    # set testruns_dir {<FILL IN>}
    set repo_dir [file normalize "../repo"]
    set repo_lib_dir [file join $repo_dir libs]
    # dynamically determine lr_include_dir!? Override if needed
    # set lr_include_dir [det_lr_include_dir]
    ~@$config_v3
  }]
  make_config_env_tcl
}

proc make_config_env_tcl {} {
  set filename [config_env_tcl_name]
  if {[file exists $filename]} {
    puts "File already exists: $filename"
    return
  }
  write_file $filename {set testruns_dir {<FILL IN>}
set lr_include_dir [det_lr_include_dir]
  }
}

# TODO: need code formatting tool.
# simple code format by counting braces per line might work.
proc get_config_v3 {} {
  return {set config_env_tcl_name [config_env_tcl_name]
if {[file exists $config_env_tcl_name]} {
  source $config_env_tcl_name
}
  }
}



proc set_config_version {version} {
  write_file [version_file] $version
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

task2 init_env {initialise environment
  by creating a ~/.config/buildtool/env.tcl file,
  with buildtool_env var default set to hostname
} {
  set filename [buildtool_env_tcl_name]
  if {[file exists $filename]} {
    puts "Already exists: $filename"
    return
  }
  file mkdir [file dirname $filename]
  set hostname [det_hostname]
  write_file $filename [syntax_quote {set buildtool_env ~$hostname}]
}


proc buildtool_env_tcl_name {} {
  file normalize [file join ~ .config buildtool env.tcl]
}
