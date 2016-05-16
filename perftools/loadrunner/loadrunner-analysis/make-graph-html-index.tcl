#!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log ar_argv
	$log info "Starting"

  set options {
    {in.arg "split" "Input directory"}
    {out.arg "index.html" "Output filename"}
    {cols.arg "2" "Number of columns"}
    {xsize.arg "640" "x size of a graph"}
    {ysize.arg "480" "y size of a graph"}
    {re.arg ".*" "regular expression for headers"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  handle_dir $ar_argv(in) $ar_argv(out) $ar_argv(re)
	$log info "Finished"

}

# @pre: infile is tab seperated
# @pre: first line contains column headers
proc handle_dir {indirname outfilename re} {
  global ar_argv
  file mkdir [file dirname $outfilename]
  set f [open $outfilename w]
  set hh [::ndv::CHtmlHelper::new]
  $hh set_channel $f
  $hh write_header "Sitescope graphs"
  $hh table_start
  foreach filename [glob -directory $indirname -type f "*.png"] {
    if {[regexp $re $filename]} {
      fill_cell $hh $filename
    }
  }
  close_cell_row $hh
  
  $hh table_end
  
  $hh write_footer
  close $f  
}

set next_col 0
# set ncols $ar_argv(cols)

proc fill_cell {hh filename} {
  global ar_argv next_col 
  if {$next_col == 0} {
    $hh table_row_start 
  }
  
  $hh table_data [$hh get_anchor [$hh get_img $filename " height=$ar_argv(ysize) width=$ar_argv(xsize) "] $filename]
  
  incr next_col
  if {$next_col == $ar_argv(cols)} {
    $hh table_row_end
    set next_col 0
  }
}

proc close_cell_row {hh} {
  global ar_argv next_col  
  if {$next_col != 0} {
    $hh table_row_end 
  }
}

main $argc $argv


