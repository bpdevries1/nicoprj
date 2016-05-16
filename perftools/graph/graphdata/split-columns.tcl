# @pre: first line contains column headers
proc split_file_columns {infilename outdir} {
  global ar_fd
  set fi [open $infilename r] 
  file mkdir $outdir
  # set fo [open $outfilename w]
  set sepchar [det_sepchar $infilename]
  set lst_headers [add_index [split [gets $fi] $sepchar]]
  open_fds $lst_headers $outdir $sepchar; # including write header
  while {![eof $fi]} {
    set lst_data [split [gets $fi] $sepchar]
    puts_fds $lst_headers $lst_data $sepchar
  }
  close $fi
  close_fds $lst_headers
}

proc open_fds {lst_headers outdir sepchar} {
  global ar_fd
  foreach el [lrange $lst_headers 1 end] {
    set fd [open [file join $outdir [to_filename $el]] w]
    set ar_fd([lindex $el 1]) $fd
    puts $fd "[lindex $lst_headers 0 0]$sepchar[lindex $el 0]"
  }
}

proc to_filename {el} {
  lassign $el name idx
  # regsub -all {[ \\/:\|]} $name "_" name
  # @note use spaces, so the text can be wordwrapped.
  regsub -all {[ \\/:\|]} $name " " name
  return "[format %04d $idx]-$name.tsv"
}

proc close_fds {lst_headers} {
  global ar_fd
  foreach el [lrange $lst_headers 1 end] {
    close $ar_fd([lindex $el 1]) 
  }
}

proc puts_fds {lst_headers lst_data sepchar} {
  global ar_fd
  foreach el [lrange $lst_headers 1 end] {
    # no scaling here, should be in loadrunner specific preprocessing for handling loadrunner analysis export files.
    puts $ar_fd([lindex $el 1]) "[lindex $lst_data 0]$sepchar[lindex $lst_data [lindex $el 1]]"
    # puts $ar_fd([lindex $el 1]) "[lindex $lst_data 0]\t[unscale_number [lindex $lst_data [lindex $el 1]] [lindex $el 0]]"
  }
}

# replace each item in list with a pair: item, index (starting with 0)
proc add_index {lst} {
  set res {}
  set i 0
  foreach el $lst {
    lappend res [list $el $i]
    incr i
  }
  return $res
}

