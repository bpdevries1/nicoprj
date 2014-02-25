# @todo? [12-11-2013] all_actions and all_combined_actions as global variable.

# 24-1-2014 added param in dargv: Routput R-output-imagelist.txt or default Routput R-output.txt
proc make_graphs {dargv} {
  set rootdir [:rootdir $dargv] 
  set pattern [:pattern $dargv]
  foreach dir [glob -nocomplain -directory $rootdir -type d $pattern] {
    make_graphs_dir $dargv $dir
    # exit ; # for test
  }
  if {[:combinedactions $dargv] == "all"} {
    # set actions [list default ttip topdomain extension slowitem gt3 pagetype]
    set actions [list default ttip aggrsub slowitem gt3 pagetype]
  } else {
    set actions [split [:combinedactions $dargv] ","] 
  }
  if {[:periods $dargv] == "all"} {
    set periods [list "1y" "6w" "2d"]
  } else {
    set periods [split [:periods $dargv] ","]
  }
  set r [Rwrapper new $dargv]
  set combined_db [:combineddb $dargv]
  $r init [file dirname $combined_db] [file tail $combined_db] [:Rfileadd $dargv]
  $r set_outputroot [file normalize [from_cygwin [:outrootdir $dargv]]]
  $r set_outformat [:outformat $dargv]
  foreach action $actions {
    foreach period $periods {
      graph_combined_$action $r $dargv $period
    }
  }
  $r doall
  $r cleanup
  $r destroy
}

proc make_graphs_dir {dargv dir} {
  set r [Rwrapper new $dargv]
  $r init $dir keynotelogs.db [:Rfileadd $dargv]
  # $r set_outputroot [file normalize [from_cygwin [:outrootdir $dargv]]]
  $r set_outputroot [file normalize [file join [from_cygwin [:outrootdir $dargv]] [file tail $dir]]]
  $r set_outformat [:outformat $dargv]
  if {[:actions $dargv] == "all"} {
    # set actions [list kn3 hour ttip]
    # @todo actions weer kn3 laten includen. Doet het [2013-10-31 12:57:46] niet, omdat tabel niet bestaat.
    set actions [list dashboard slowitem topdomain extension ttip]
  } else {
    set actions [split [:actions $dargv] ","] 
  }
  if {[:periods $dargv] == "all"} {
    set periods [list "1y" "6w" "2d"]
  } else {
    set periods [split [:periods $dargv] ","]
  }
  
  foreach action $actions {
    foreach period $periods {
      graph_$action $r $dir $period
    }
  }
  $r doall
  $r cleanup
  $r destroy
}

# @note naast global functions als hierboven (make_graphs_dir etc) ook low level functies zoals hieronder. Mss nog file splitsen.
# @return '2013-11-14 12:00:00' or similar, complete timestamp useable for date comparison as well.
# set time_units [list h hour d day w week m month y year]
proc period2startdate {period} {
  # global time_units
  set time_units [list h hour d day w week m month y year]
  if {[regexp {^(\d+)(.)$} $period z n unit]} {
    clock format [clock add [clock seconds] -$n [dict get $time_units $unit]] -format "%Y-%m-%d %H:%M:%S"
  } else {
    error "Cannot parse period: $period"
  }
}

proc period2days {period} {
  # global time_units
  set time_units [list h hour d day w week m month y year]
  if {[regexp {^(\d+)(.)$} $period z n unit]} {
    set s [clock seconds]
    expr round(($s - [clock add $s -$n [dict get $time_units $unit]]) / (24*60*60))
  } else {
    error "Cannot parse period: $period"
  }
}
