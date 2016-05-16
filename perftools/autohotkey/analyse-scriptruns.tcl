#!/home/nico/bin/tclsh

package require Tclx
# package require csv
package require sqlite3
package require vfs 
package require vfs::zip

# own package
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  lassign $argv dirname
  create_db [file join $dirname "scriptruns.db"]
  db eval "begin transaction"
  read_dir $dirname
  db eval "commit"
  db close
}

proc create_db {db_name} {
  file delete $db_name
  sqlite3 db $db_name
  set scriptrun_pk "machine, script, runtime"
  set trans_pk "$scriptrun_pk, trans"
  
  # kan zijn dat je op andere dingen wilt vergelijken, bv op lijst patterns die gecheckt wordt, checknr kan met loops wel varieren
  set chk_pk "$trans_pk, chkndx"
  
  db eval "create table scriptrun ($scriptrun_pk, filename, script_version, ntrans, trans_sec, sleep_sec, chk_sec, nfiles, nchks, max_area)"
  db eval "create table trans ($trans_pk, success, trans_sec, sleep_sec, chk_sec, nfiles, nchks, max_area)"
  db eval "create table chk ($chk_pk, x1, y1, x2, y2, area, patterns, images, 
                               sec_max, msec_freq, ndx_found, image_found, xfound, yfound, 
                               msec_total, msec_chk, msec_sleep, nfiles, nchks, nsleep,
                               msec_per_chk, chktime_factor)"
  
  # @todo mss later lijst van patterns en/of images in aparte tabel, met id, en per image grootte opnemen, zodat je iets met de check kan.
  
}

proc read_dir {dirname} {
  foreach zipname [glob -directory $dirname "*.zip"] {
    read_zipfile $zipname 
  }
}

proc read_zipfile {zipname} {
  # use zip package
  set mount_point /zip/pproc
  vfs::zip::Mount $zipname $mount_point
  read_dir_rec $mount_point
  # unmount not available, gives error: -mode option not set.
  # vfs::zip unmount $zipname
}

proc read_dir_rec {dirname} {
  foreach subdir [glob -nocomplain -directory $dirname -type d *] {
    read_dir_rec $subdir 
  }
  foreach filename [glob -nocomplain -directory $dirname -type f Result*] {
    read_file $filename
  }
}


proc read_file {filename} {
  global nlogfiles log
  $log debug "read_file: $filename"
  
  init_vars <unknown> machine script runtime trans chk script_version
  init_vars 0 run_ntrans run_trans_sec run_sleep_sec run_chk_sec run_nchks run_nfiles run_max_area
  init_vars 0 trans_nchks trans_trans_sec trans_sleep_sec trans_chk_sec
  init_vars -1 x1 y1 x2 y2 area max_sec freq_msec ndx_found xfound yfound
  init_vars <unknown> patterns images image_found
  init_vars 0 msec_total msec_chk msec_sleep nfiles nchks nsleep msec_per_chk chktime_factor
  init_vars <none> cur_trans cur_chk
  set unexpected_EOF 0
  
  set f [open $filename r]
  while {![eof $f]} {
    gets $f line
    if {[regexp {^\[(.+)\.\d{3}\] \[info\] Script (.+) started$} $line z runtime script2]} {
      if {$script2 == "Thin"} {
        close $f
        $log debug "Thin/download script, not interested, close and return"
        return
      }
    }
    
    # 7-9-2012 NdV script naam anders bepalen, in LotusNotes wordt ook KA gebruikt, dus dirnaam gebruiken.
    if {[regexp {A_ScriptFullPath = (.+)$} $line z path]} {
      set script [det_script $path] 
    }
    
    regexp {Env var COMPUTERNAME = (.+)$} $line z machine
    regexp {\[trans\] Transaction started : (.+)$} $line z cur_trans
    # [2012-08-23 10:36:48.135] [info] Script version: 2012-08-17 13:30:38
    regexp {Script version: (.*)$} $line z script_version  

    set cmd ""
    if {[regexp {\[trans\] Transaction finished: (.+), success: (.), transaction time \(sec\): ([0-9.]+), slept \(sec\): ([0-9.]+)$} $line z trans trans_success trans_trans_sec trans_sleep_sec]} {
      # @calc chk_sec?
      if {$trans != $cur_trans} {
        # error "$trans != $cur_trans ($machine $script $runtime)"
        # kan gebeuren, bij totaal transacties.
      }
      # insert_trans $machine $script $runtime $trans $trans_success $trans_nchks $trans_trans_sec $trans_sleep_sec $trans_chk_sec
      # 24-8-2012 wil alleen inserten als regel hierna niet gelijk is aan 'Transaction finished incl checktime'
      set cmd [list insert_trans $machine $script $runtime $trans $trans_success $trans_trans_sec $trans_sleep_sec $trans_chk_sec -1 -1 -1]
      gets $f line
      #incr run_ntrans
      #set run_trans_sec [expr $run_trans_sec + $trans_trans_sec]
      #set run_sleep_sec [expr $run_sleep_sec + $trans_sleep_sec]
      #set run_chk_sec [expr $run_chk_sec + $trans_chk_sec]
    }
# [2012-08-14 00:07:59.743] [trans] Transaction finished incl checktime: 01_Start_VMWare, success: 1, transaction time (sec): 92.496, slept (sec): 30.000, check (sec): 33.611, nfiles: 35, nchecks: 110, screensize: 1472451

    # wrapper check om moeilijke check heen, duurt anders erg lang.
    if {[regexp {Transaction finished incl checktime} $line]} {
      if {[regexp {\[trans\] Transaction finished incl checktime: (.+), success: (.), transaction time \(sec\): ([0-9.]+), slept \(sec\): ([0-9.]+), check \(sec\): ([0-9.]+), nfiles: (\d+), nchecks: (\d+), screensize: (\d+)$} \
          $line z trans trans_success trans_trans_sec trans_sleep_sec trans_chk_sec trans_nfiles trans_nchks trans_max_area]} {
        if {$trans != $cur_trans} {
          # kan gebeuren, bij totaal transacties.
          # error "$trans != $cur_trans ($machine $script $runtime)"
        }
        insert_trans $machine $script $runtime $trans $trans_success $trans_trans_sec $trans_sleep_sec $trans_chk_sec $trans_nfiles $trans_nchks $trans_max_area
        incr run_ntrans
        set run_trans_sec [expr $run_trans_sec + $trans_trans_sec]
        set run_sleep_sec [expr $run_sleep_sec + $trans_sleep_sec]
        set run_chk_sec [expr $run_chk_sec + $trans_chk_sec]
        set run_nfiles [expr $run_nfiles + $trans_nfiles]
        set run_nchks [expr $run_nchks + $trans_nchks]
        if {$trans_max_area > $run_max_area} {
          set run_max_area $trans_max_area 
        }
      } else {
        breakpoint 
      }
    } else {
      if {$cmd != ""} {
        eval $cmd 
      }
    }
    
    # check details, op meerdere regels.
    if {[regexp {\[check\] index: \d+; region:} $line]} {
      set res [handle_check_details $machine $script $runtime $cur_trans $f $line]
      if {$res == "EOF"} {
        set unexpected_EOF 1  
        break
      }
    }
    
  } ; # end-of-while
  close $f
  
  if {$unexpected_EOF} {
    $log warn "Unexpected EOF: $machine: $filename"  
  } else {
    # @todo handle scriptrun stats
    insert_scriptrun $machine $script $runtime $filename $script_version $run_ntrans $run_trans_sec $run_sleep_sec $run_chk_sec $run_nfiles $run_nchks $run_max_area 
  }
  
  incr nlogfiles
  if {$nlogfiles > 1000000} {
    $log warn "nlogfiles > 10, exit" 
    db close
    exit 
  } else {
    $log debug "nlogfiles = $nlogfiles, continue" 
  }
  if {$nlogfiles % 100 == 0} {
    db eval "commit"
    db eval "begin transaction"
  }
}

# D:\YmorAgent\Script\GMZ_20120628_v09_NdV_VDI_GWS4ALL\GMZ_VDI_GWS4ALL_dowork.exe
proc det_script {path} {
  if {[regexp {GeoPoort_VDI} $path]} {
    return "GeoLight"
  } elseif {[regexp {GeoPoort_VDI} $path]} {
    return "GeoLight"
  } elseif {[regexp {LotusNotes} $path]} {
    return "LotusNotes"
  } elseif {[regexp {GeoPoort_FAT} $path]} {
    return "GeoFat"
  } elseif {[regexp {KA_VDI} $path]} {
    return "KA"
  } elseif {[regexp {GWS} $path]} {
    return "GWS"
  } else {
    return "?s?: [file tail $path]"
  }
}

proc handle_check_details {machine script runtime trans f line1} {
  # totaal 6 regels met info
  init_vars 0 run_ntrans run_trans_sec run_sleep_sec run_chk_sec run_nchks run_nfiles run_max_area
  init_vars 0 trans_nchks trans_trans_sec trans_sleep_sec trans_chk_sec
  init_vars -1 x1 y1 x2 y2 area sec_max msec_freq ndx_found xfound yfound
  init_vars <unknown> patterns images image_found
  init_vars 0 msec_total msec_chk msec_sleep nfiles nchks nsleep msec_per_chk chktime_factor

  gets $f line2
  if {[regexp {index: (\d+); result:} $line2]} {
    # oude versie, geen tussenliggende data
    regexp {index: (\d+); region: \((\d+),(\d+)\)-\((\d+),(\d+)\); files: (.+)$} $line1 z chkndx x1 y1 x2 y2 patterns
    regexp {index: (\d+); result: (\d*); imagefile: (.+); posfound: (\d*),(\d*)$} $line2 z chkndx2 ndx_found image_found xfound yfound
  } else {
    while {1} {
      gets $f line3
      if {[regexp {call image_list_list_search_wait} $line3]} {
        break ; # echte line3 gevonden 
      } elseif {[regexp {^\d+=1:} $line3]} {
        # toevoegen aan line2
        append line2 ";$line3"
      } else {
        # error "Line not expected here (as line2/line3): $line3"
        puts "Line not expected here (as line2/line3): $line3"
        breakpoint
      }
    }
    gets $f line4
    gets $f line5
    if {[regexp {Totaltime_msec: (\d+)} $line5]} {
      # ok, zoals verwacht, dan regel 6 lezen.
      gets $f line6
    } elseif {[regexp {index: (\d+); result: } $line5]} {
      # ok, dit is line6, line5 is er niet.
      set line6 $line5
      set line5 ""
    } elseif {[eof $f]} {
      puts "Unexpected EOF, continue with next file."
      return EOF
    } else {
      # error "Unexpected line5: $line5"
      puts "Unexpected line5: $line5"
      breakpoint
    }
    regexp {index: (\d+); region: \((\d+),(\d+)\)-\((\d+),(\d+)\); files: (.+)$} $line1 z chkndx x1 y1 x2 y2 patterns
    regexp {list of files to check: (.*)$} $line2 z images
    regexp {call image_list_list_search_wait, timeout = (\d+)$} $line3 z sec_max
    # line4 alleen dat 'ie klaar is.
    regexp {Totaltime_msec: (\d+), checktime_msec: (\d+), sleeptime_msec: (\d+), nfiles: (\d+), nchecks: (\d+), screensize: (\d+), check_freq_ms: (\d+), nsleep: (\d+), msecpercheck: ([0-9.]+), checktime_factor: ([0-9.]+)$} \
      $line5 z msec_total msec_chk msec_sleep nfiles nchks area msec_freq nsleep msec_per_chk chktime_factor
    # kan zijn dat niets gevonden is, waarden dan leeg, en dus ook met quotes in db query.
    regexp {index: (\d+); result: (\d*,\-?\d*); imagefile: (.+); posfound: (\d*),(\d*)$} $line6 z chkndx2 ndx_found image_found xfound yfound
  }
  try_eval {
    if {$chkndx != $chkndx2} {
      error "$chkndx != $chkndx2: $line1 *** $line6"    
    }
    insert_chk $machine $script $runtime $trans $chkndx $x1 $y1 $x2 $y2 $area $patterns $images $sec_max $msec_freq $ndx_found $image_found $xfound $yfound $msec_total $msec_chk $msec_sleep $nfiles $nchks $nsleep $msec_per_chk $chktime_factor
  } {
    puts "Error occurred: $errorResult"
    breakpoint
  }    
}

proc insert_scriptrun {machine script runtime filename script_version run_ntrans run_trans_sec run_sleep_sec run_chk_sec run_nfiles run_nchks run_max_area} {
  db eval "insert into scriptrun (machine, script, runtime, filename, script_version, ntrans, trans_sec, sleep_sec, chk_sec, nfiles, nchks, max_area)
           values ('$machine', '$script', '$runtime', '$filename', '$script_version', $run_ntrans, $run_trans_sec, $run_sleep_sec, $run_chk_sec, $run_nfiles, $run_nchks, $run_max_area)"
}

proc insert_trans {machine script runtime trans trans_success trans_trans_sec trans_sleep_sec trans_chk_sec trans_nfiles trans_nchks trans_max_area} {
  db eval "insert into trans (machine, script, runtime, trans, success, trans_sec, sleep_sec, chk_sec, nfiles, nchks, max_area)
           values ('$machine', '$script', '$runtime', '$trans', $trans_success, $trans_trans_sec, $trans_sleep_sec, $trans_chk_sec, $trans_nfiles, $trans_nchks, $trans_max_area)"
}

proc insert_chk {machine script runtime trans chkndx x1 y1 x2 y2 area patterns images sec_max msec_freq ndx_found image_found xfound yfound msec_total msec_chk msec_sleep nfiles nchks nsleep msec_per_chk chktime_factor} {
  # xfound en yfound kunnen leeg zijn, dus als string in db zetten.
  db eval "insert into chk (machine, script, runtime, trans, chkndx, x1, y1, x2, y2, area, patterns, images, 
                               sec_max, msec_freq, ndx_found, image_found, xfound, yfound, 
                               msec_total, msec_chk, msec_sleep, nfiles, nchks, nsleep,
                               msec_per_chk, chktime_factor) 
           values ('$machine', '$script', '$runtime', '$trans', $chkndx, $x1, $y1, $x2, $y2, $area, '$patterns', '$images', $sec_max, $msec_freq, '$ndx_found', '$image_found', '$xfound', '$yfound', $msec_total, $msec_chk, $msec_sleep, $nfiles, $nchks, $nsleep, $msec_per_chk, $chktime_factor)"                               
}

proc init_vars {value args} {
  foreach var_name $args {
    upvar $var_name var
    set var $value
  }  
}

set nlogfiles 0
main $argv
