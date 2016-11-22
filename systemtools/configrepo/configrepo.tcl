#! /usr/bin/env tclsh

# Create symlinks or replace regular files with symlinks to config repository.
# vraag of je alle packages meteen wilt gebruiken hier, toch een soort bootstrap.
package require ndv

set_log_global debug {filename -}

# default is een dry run, niets doen.
proc main {argv} {
  set options {
    {configroot.arg "~/nicoprjbb/config/linux/homedir" "Repository location"}
    {home.arg "~" "Home directory to sync with repository"}
    {get "Get config files from repository, by creating new symlink"}
    {link "Get config files from repository, by replacing file with symlink"}
    {force "Force writing files, possibly overwriting manual changes"}
    {shell.arg "" "Create shell script for manual actions (diff, rm, cp)"}
    {h "Show extended help"}
  }
  set usage ": [file tail [info script]] \[options]"
  set opt [getoptions argv $options $usage]
  if {[:h $opt]} {
    show_help
    exit 1
  }
  if {[:shell $opt] != ""} {
    set fo [open [:shell $opt] w]
  } else {
    set fo ""
  }
  sync_dirs $opt [file normalize [:configroot $opt]] [file normalize [:home $opt]] $fo
  if {$fo != ""} {
    puts $fo "# Remove file after executing"
    puts $fo "rm [:shell $opt]"
    close $fo
    exec chmod +x [:shell $opt]    
  }
}

proc show_help {} {
  puts "Extended help"
  puts "============="
  puts "If no options are given, just report status, don't perform any action."
}

# Check each file in repo with file in home. Recur subdirs.
# Don't symlink subdirs, so have more control.
proc sync_dirs {opt configdir homedir fo} {
  # log debug "Sync-ing dirs: $configdir <=> $homedir"
  set tail [file tail $configdir]
  if {($tail == ".") || ($tail == "..")} {
    # using .* causes . and .. to be returned by glob as well.
    return
  }
  if {[regexp {./././} $configdir]} {
    breakpoint
  }
  foreach spec {* .*} {
    foreach filename [glob -nocomplain -directory $configdir -type f $spec] {
      sync_file $opt $filename [file join $homedir [file tail $filename]] $fo
    }
    foreach dirname [glob -nocomplain -directory $configdir -type d $spec] {
      sync_dirs $opt $dirname [file join $homedir [file tail $dirname]] $fo
    }
  }
}

proc sync_file {opt config_filename home_filename fo} {
  # log debug "Sync-ing files: $config_filename <=> $home_filename"
  if {[file exists $home_filename]} {
    set link_target [file normalize [file_link $home_filename]]
    if {$link_target == ""} {
      # file in homedir is not a symlink yet, so should change
      if {[read_file $config_filename] == [read_file $home_filename]} {
        log debug "Files are the same, so can create symlink"
        make_link_config $opt $config_filename $home_filename
      } else {
        log warn "Files differ: $config_filename <=> $home_filename"
        if {$fo != ""} {
          puts $fo "# Files differ: $config_filename <=> $home_filename"
          puts $fo "# diff $config_filename $home_filename"
          puts $fo "# rm $config_filename"
          puts $fo "# cp $home_filename $config_filename"
          puts $fo "# => to forget local changes, and get file from repo:"
          puts $fo "# cp $config_filename $home_filename"
          puts $fo "# -------------------"
        }
      }
    } else {
      if {$link_target == $config_filename} {
        # log debug "$home_filename already points to $config_filename"
      } else {
        log debug "$home_filename is a symlink, but does not point to $config_filename"
        set config_link_target [file normalize [file_link $config_filename]]
        if {$link_target == $config_link_target} {
          log debug "$home_filename and $config_filename both point to $link_target, so can change symlink in $home_filename"
          make_link_config $opt $config_filename $home_filename
        } else {
          log debug "$home_filename and $config_filename point to different locations:\n  $home_filename => $link_target\n  $config_filename => $config_link_target"
        }
      }
    }
  } else {
    log debug "File does not exist yet in homedir: $home_filename, so create link"
    make_link_config $opt $config_filename $home_filename
  }
}

# create symlink from home_filename to config_filename
# @pre already checked that files are the same, so this can be done.
# just depends on values of options given.
# get - create symlink in home iff not exist yet. Do for new system.
# link - create symlink in home to replace orig file. Also creates if link does not exist yet in homedir.
# force - not used yet.
proc make_link_config {opt config_filename home_filename} {
  log info "Create symlink from $home_filename => $config_filename"
  set do_create 0
  if {[file exists $home_filename]} {
    # only if link option is given
    if {[:link $opt]} {
      set do_create 1
    }
  } else {
    # new file, ok if either get or link is given.
    if {[:link $opt] || [:get $opt]} {
      set do_create 1
    }
  }
  if {$do_create} {
    log debug "Really create symlink"
    file delete $home_filename
    file mkdir [file dirname $home_filename]
    file link -symbolic $home_filename $config_filename
    if {[regexp {/bin} $home_filename]} {
      # ok, continue
    } else {
      # exit;                       # for test.  
    }
  } else {
    log debug "Don't create, use -link or -get to create."
  }
}

# return file where link points to, or empty string iff linkname is not a link
proc file_link {linkname} {
  set res ""
  catch {
    set res [file link $linkname]
  }
  return $res
}

main $argv
