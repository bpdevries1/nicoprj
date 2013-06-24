#!/usr/bin/env tclsh86

proc main {argv} {
  lassign $argv spec_file target_dir
  file mkdir $target_dir
  set fo [open [file join $target_dir copy_files.bat] w]
  puts $fo "REM copy files from network drive to local"
  puts $fo "REM specs in: $spec_file"
  puts $fo "REM target_dir: $target_dir"
  set logfile_native [file nativename [file join $target_dir "copy-files.log"]] 
  set target_dir_native [file nativename $target_dir]
  puts $fo "DEL $logfile_native"
  set redirect ">>$logfile_native 2>&1"
  puts $fo "MKDIR $target_dir $redirect"
  set fi [open $spec_file r]
  while {![eof $fi]} {
    gets $fi line
    if {$line != ""} {
      puts $fo "ECHO COPY \"[file nativename $line]\" $target_dir_native $redirect"
      puts $fo "COPY \"[file nativename $line]\" $target_dir_native $redirect"  
    }    
  }
  close $fi
  close $fo
}

main $argv