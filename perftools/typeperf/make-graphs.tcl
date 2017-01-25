# std packages
package require Tclx
package require csv
package require struct::list
package require struct::matrix
package require math

# eigen package
catch {package require ndv}

# set R_binary "d:/develop/R/R-2.9.0/bin/Rscript.exe"
# set N_POINTS 40

catch {set log [::ndv::CLogger::new_logger [file tail [info script]] debug]} 

proc main {argc argv} {
  global R_binary env ar_argv
  # [2016-10-31 11:29:14] add location to search.
  set R_binary [find_R "c:/develop/R/R-2.13.0/bin/Rscript.exe" "d:/develop/R/R-2.9.0/bin/Rscript.exe" \
    {C:\PCC\Util\R\R-3.1.1\bin\Rscript.exe} \
	"d:/apps/R/R-2.11.1/bin/Rscript.exe" {*}[split $env(PATH) ";"]]

  set options {
    {dir.arg "" "Directory with typeperf files."}  
    {glob.arg "*typeperf*.csv" "glob pattern to use for files."}
    {nopre "Don't preprocess files."}
    {incr "Make graphs incremental, don't create if already exists"}
    {npoints.arg 40 "Number of points to plot."}
    {loglevel.arg "" "Set global log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  # array set ar_argv [::cmdline::getoptions argv $options $usage]
  array set ar_argv [getoptions argv $options $usage]
 
  
  # check_params $argc $argv
  # set root_dir [lindex $argv 0]
  set root_dir $ar_argv(dir)
  # regsub -all {\\} $root_dir "/" root_dir
  set root_dir [file normalize $root_dir]
  # puts "root_dir: $root_dir"
  # for_recursive_glob filename $root_dir "*typeperf*.csv" {}
  for_recursive_glob filename $root_dir $ar_argv(glob) {
    # puts $filename
    if {$ar_argv(incr)} {
      if {![file exists "$filename.png"]} {
        make_graph $filename 
      }
    } else {
      make_graph $filename
    }
  }  
}

proc check_params_old {argc argv} {
  global stderr argv0
  if {$argc != 1} {
    puts stderr "syntax: $argv0 <logs-directory>; got: $argv (#$argc)"
    exit 1
  }
}

proc make_graph {filename} {
  global log R_binary N_POINTS ar_argv
  #$log debug "Make graph for $filename"
  if {!$ar_argv(nopre)} {
    preprocess $filename
  }
  make_legend $filename
  set machine [det_machine $filename]
  set r_script [file join [file dirname [info script]] "graph-typeperf.R"]
  try_eval {
    # exec $r_script_exe $r_script [det_typeperf_output] $npoints $legend_name
    # $log info "calling R: $R_binary $r_script $filename $N_POINTS \"$filename.legend\" $machine"
    puts "npoints: $ar_argv(npoints)"
    # breakpoint
    exec $R_binary $r_script $filename $ar_argv(npoints) "$filename.legend" $machine
  } {
    # $log error "Error during R processing: $errorResult"
    puts "Error during R processing: $errorResult"
  }   
}

proc make_legend {filename} {
  set f [open $filename r]
  gets $f line
  close $f
  set lst [::csv::split $line [det_sepchar $filename]]
  set fo [open "$filename.legend" w]
  puts $fo "legend"
  foreach el $lst {
     puts $fo [det_legend $el]    
  }  
  close $fo
}

proc det_sepchar {filename} {
  if {[file extension $filename] == ".tsv"} {
    return "\t" 
  } elseif {[file extension $filename] == ".tab"} {
    return "\t"
  } elseif {[file extension $filename] == ".csv"} {
    return ","
  } else {
    error "Cannot determine sepchar from filename: $filename" 
  }
}

# 3-11-2010 NdV: naast engels ook nederlands in typeperf.csv
proc det_legend {el} {
  # return $el
  # \\ABAPRD1APP2\Processor(_Total)\% Processor Time
  if {[regexp {Processor\(_Total\)\\(.+)} $el z sub]} {
    if {$sub == "% Processor Time"} {
      return "CPU usage"
    } else {
      return $sub 
    }
  } elseif {[regexp {Available MBytes} $el]} {
    return "Mem MB avail"      
  } elseif {[regexp {Loopback interface} $el]} {
    return "Loopback bytes/sec"
  } elseif {[regexp {Network Interface} $el]} {
    return "Network bytes/sec" 
  # \\ABAPRD1APP2\PhysicalDisk(_Total)\% Disk Time
  } elseif {[regexp {PhysicalDisk.+\\(.*)} $el z sub]} {
    if {$sub == "% Disk Time"} {
      return "Disk usage"
    } else {
      return $sub 
    }
  } elseif {[regexp {Europe Standard Time} $el]} {
    return "timestamp"
  } elseif {[regexp {West-Europa} $el]} {
    return "timestamp"
  } elseif {[regexp {Logische schijf} $el]} {
    return "Logical disk usage"
  } elseif {[regexp {Fysieke schijf} $el]} {
    return "Disk usage"
  } elseif {[regexp {Beschikbare megabytes} $el]} {
    return "Mem MB avail"
  } elseif {[regexp {Netwerk.?interface} $el]} {
    return "Network bytes/sec"
  } else {
    return $el 
  }  
}

# @param filename: .../runXXX/<machine>/typeperf.csv
proc det_machine_ind {filename} {
  set dirname [file dirname $filename]
  set machine [file tail $dirname]
  return $machine  
}

# Deze voor Ordina intranet 2010.
# @param filename: .../testXXX/typeperf-<machine>.csv
proc det_machine {filename} {
  set tail [file tail $filename]
  if {[regexp {typeperf-(.+).csv} $tail z machine]} {
    return $machine
  } elseif {[regexp {(.+).typeperf.csv} $tail z machine]} {
    return $machine
  } else {
    return $tail 
  }
}

# search Rscript in each of the paths given in args.
# @return the path where R is found, or just Rscript, if not found (maybe it's in the PATH)
proc find_R {args} {
  foreach path $args {
    if {[file exists $path]} {
      return $path 
    }
  }
  return "Rscript.exe"
}

# remove the logical disk column, and add all the network columns
# rename the origninal filename to filename.orig

# set filename "c:/aaa/typeperf/ba13-0306-typeperf.csv"
proc preprocess {filename} {
  # 29-11-2010 NdV nu altijd preprocess doen.
  if {0} {
    set f [open $filename r]
    gets $f line
    close $f
    if {![regexp {LogicalDisk} $line]} {
      if {![regexp {Logische schijf} $line]} {
        # preprocess alreay done, return
        return
      }
    }
  }  
  file rename $filename $filename.orig
  set f [open $filename.orig r]
  set m [struct::matrix]
  # csv::read2matrix $f $m , auto
  csv::read2matrix $f $m [det_sepchar $filename] auto
  
  close $f

  delete_columns $m {(LogicalDisk)|(Logische schijf)}
  total_columns $m {(Network Interface)|(Netwerk.?interface)} "Network Interface"

  # breakpoint
  # @todo file extension evt aanpassen als separator char anders wordt.
  set f [open $filename w]
  # @note 3-5-2011 NdV hier altijd een , doen. Dan is R hetzelfde.
  csv::writematrix $m $f , "\""
  close $f
}

# delete columns from matrix m where column name ~ re
proc delete_columns {m re} {
  set lst_columns [matrix_find_columns $m $re]
  foreach col [lreverse $lst_columns] {
    $m delete column $col
  }
}

# add all columns whose name ~ re by row and put the result in a new column with name col_name.
# remove the original columns
proc total_columns {m re col_name} {
  set lst_columns [matrix_find_columns $m $re]
  set lst_lst_values [struct::list mapfor ndx $lst_columns {
    $m get column $ndx
  }]
  set lst_sum [multimap sum $lst_lst_values]
  $m set column [lindex $lst_columns 0] $lst_sum
  $m set cell [lindex $lst_columns 0] 0 $col_name
  foreach col [lreverse [lrange $lst_columns 1 end]] {
    $m delete column $col
  }
}

proc matrix_find_columns {m re} {
  set headers [$m get row 0] 
  lsearch -all -regexp $headers $re
}

# wrapper around math::sum, check if sum can be calculated
# args can contain empty values, so check.
proc sum_old {args} {
  if {[string is double [lindex $args 0]]} {
    math::sum {*}$args 
  } else {
    return 0 
  }
}

proc sum {args} {
  set res 0.0
  foreach el $args {
    if {$el != ""} {
      if {[string is double $el]} {
        set res [expr $res + $el]
      }
    }
  }
  return $res
}

# apply procname to each corresponding member in lst_lsts
# return (single) list with results
# procname should expect the same number of arguments as there are lists in lst_lsts
proc multimap {procname lst_lsts} {
  set res {}
  set n [llength [lindex $lst_lsts 0]]
  for {set i 0} {$i < $n} {incr i} {
    lappend res [$procname {*}[struct::list mapfor lst $lst_lsts {
      lindex $lst $i
    }]]
  }
  return $res
}

# ook transpose, hier niet nodig, verder wel handig, zie ook clojure
proc transpose {lst_lsts} {
  multimap list $lst_lsts 
}

main $argc $argv
