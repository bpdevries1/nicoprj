package require struct::list
package require fileutil
package require Tclx
package require ndv
package require math

# ::ndv::source_once check-files-lib.tcl
::ndv::source_once [file join [file dirname [info script]] check-files-lib.tcl]
set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global stderr argv0 log
  if {$argc != 4} {
    puts stderr "syntax: $argv0 <dirname> <start> <step> <prefix>; got: $argv" 
    exit 1
  }
  $log set_file "make-svn-renumber.log"  
  $log debug "argv: $argv"
  lassign $argv dirname str_start step prefix
  set fr [open "renumber.bat" w]

  foreach subdir [lsort [glob -directory $dirname -type d *]] { 
    renumber_dir $fr $subdir $str_start $step $prefix 
  }

  close $fr
  $log close_file
}

proc renumber_dir {fr subdir str_start step prefix} {
  set number_size [string length $str_start]
  scan $str_start "%0d" start
  set current $start
  foreach filename [lsort -command comp_files [struct::list filterfor el [glob -directory $subdir *] {[lsearch -exact [list .doc .xls .ppt] [file extension $el]] >= 0}]] {
    set new_name [det_new_filename $filename $current $number_size $prefix]
    # puts $fr "svn rename \"[file nativename [file normalize $filename]]\" \"[file nativename [file normalize $new_name]]\""
    puts $fr "svn rename \"[file nativename $filename]\" \"[file nativename $new_name]\""
    incr current $step
  }
}

proc det_new_filename {filepath number number_size prefix} {
  set dirname [file dirname $filepath]
  set last_dir [file tail $dirname]
  puts "last_dir $last_dir"
  regexp {^([0-9.]+)} $last_dir z prefix2
  set filename [file tail $filepath]
  regexp {^[0-9]*(.*)$} $filename z target_name
  regsub -nocase {gmp [0-9]+ } $target_name "" target_name
  regsub -nocase {[0-9]+ } $target_name "" target_name
  return [file join $dirname "$prefix$prefix2.[format "%0${number_size}d" $number] [string trim $target_name]"]
}

proc comp_files {file1 file2} {
  if {[regexp -nocase {gmp ([0-9]+)} $file1 z nr1]} {
    if {[regexp -nocase {gmp ([0-9]+)} $file2 z nr2]} {
      if {$nr1 < $nr2} {
        return -1 
      } elseif {$nr1 > $nr2} {
        return 1
      } else {
        return [string compare $file1 $file2] 
      }
    } else {
      return -1 
    }
  } else {
    if {[regexp -nocase {gmp ([0-9]+)} $file2 z nr2]} {
      return 1 
    } else {
      return [string compare $file1 $file2]
    }
  }
}

main $argc $argv
