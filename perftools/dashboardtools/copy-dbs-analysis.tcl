#!/usr/bin/env tclsh86

# copy SQLite db's from download location to analyse location to postprocess and make dashboard info.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require csv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  # lassign $argv dirname
  set options {
    {srcdir.arg "c:/projecten/Philips/KNDL" "Source directory where source DB's are is (keynotelogs.db)"}
    {targetdir.arg "c:/projecten/Philips/KN-analysis" "Target dir to put DB's (keynotelogs.db). Rename old if exists"}
    {srcpattern.arg "" "Glob pattern for subdirs in srcdir to use"}
    {config.arg "" "File with subdir names (in srcdir) to copy (config file in scriptdir)"}
    {dbname.arg "keynotelogs.db" "Database names"}
    {debug "Run in debug mode, stop when an error occurs"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [::cmdline::getoptions argv $options $usage]   
  dict_to_vars $dargv
  if {($config != "") && ($srcpattern != "")} {
    error "Both config and srcpattern are given, can handle only one" 
  }
  if {[file exists $targetdir]} {
    # no creation time, so use modification time (not the accesstime=atime)
    set old_date [clock format [file mtime $targetdir] -format "%Y-%m-%d-%H-%M-%S"]
    file rename $targetdir "$targetdir.$old_date"
  }
  file mkdir $targetdir
  if {$config != ""} {
    copy_with_config $srcdir $targetdir $config $dbname 
  }
  if {$srcpattern != ""} {
    copy_with_pattern $srcdir $targetdir $srcpattern $dbname  
  }
}

proc copy_with_pattern {srcdir targetdir srcpattern dbname} {
  foreach subdir [glob -directory $srcdir -type d $srcpattern] {
    set subtarget [file join $targetdir [file tail $subdir]]
    file mkdir $subtarget
    log info "Copying [file join $subdir $dbname] => $subtarget" 
    file copy [file join $subdir $dbname] $subtarget
  }
}

proc copy_with_config {srcdir targetdir config dbname} {
  set subdirs [split [read_file $config] "\n"]
  # @todo should filter out empty items.
  foreach subdir $subdirs {
    if {[string trim $subdir] == ""} {
      continue 
    }
    set subtarget [file join $targetdir $subdir]
    file mkdir $subtarget
    log info "Copying [file join $srcdir $subdir $dbname] => $subtarget" 
    file copy [file join $srcdir $subdir $dbname] $subtarget
  }
}

main $argv

