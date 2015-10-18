#!/usr/bin/env tclsh861

# audio-split.tcl - split (long) audio (mp3) files into parts, so in car searching is easier.

package require ndv
package require Tclx

proc main {argv} {
  set src_dir "/home/media/EBooks/_toplace/Donna Tartt - The Goldfinch-m4b"
  set target_prefix "Goldfinch"
  set split_size_sec 300
  set overlap_size_sec 5
  
  set ndx 0
  foreach src_file [glob -directory $src_dir -tails *.mp3] {
    incr ndx
    split_file $src_dir $src_file $target_prefix $ndx $split_size_sec $overlap_size_sec
    if {$ndx >= 1} {
      # break
    }
  }
}

# avconv -i 01\ The\ Goldfinch\ \(Unabridged\)\ Part\ 1.mp3 -t 00:05:05 -ss 00:00:00 -acodec copy gf01b.mp3
# avconv -i 01\ The\ Goldfinch\ \(Unabridged\)\ Part\ 1.mp3 -t 00:05:05 -ss 00:05:00 -acodec copy gf02b.mp3

proc split_file {src_dir src_file target_prefix ndx split_size_sec overlap_size_sec} {
  set size_treshold 10000
  
  set target_dir [file join $src_dir "${target_prefix}_$ndx"]
  file mkdir $target_dir
  # continue until output file's size is below a certain treshold.
  set i 0
  set start_sec 0
  set src_path [file join $src_dir $src_file]
  set t_length [clock format [expr $split_size_sec + $overlap_size_sec] -format "%H:%M:%S" -gmt 1]
  while {1} {
    incr i
    set ts_start [clock format $start_sec -format "%H:%M:%S" -gmt 1]
    set ts_end [clock format [expr $start_sec + $split_size_sec + $overlap_size_sec] -format "%H:%M:%S" -gmt 1]
    puts "$ts_start => $ts_end"
    set exec_ok 0
    set timings "$ts_start--$ts_end"
    regsub -all ":" $timings "_" timings
    set out_path [file join $target_dir "${target_prefix}_${ndx}_[format %03d $i]_$timings.mp3"]
    try_eval {
      if {$i >= 0} {
        exec -ignorestderr avconv -i $src_path -t $t_length -ss $ts_start -acodec copy $out_path
        set exec_ok 1        
      }
    } {
      puts "exec failed somewhat (1), continue for now"
    }
    if {!$exec_ok} {
      puts "exec failed somewhat (2), continue for now"
    } else {
      if {![file exists $out_path]} {
        puts "Output file does not exist, break: $out_path"
        break
      }
      if {[file size $out_path] < $size_treshold} {
        puts "File size < $size_treshold, delete and break: $out_path"
        file delete $out_path
        break
      }
    }
    
    if {$i > 10} {
      # break
    }

    set start_sec [expr $start_sec + $split_size_sec]
  }
  
}

main $argv
