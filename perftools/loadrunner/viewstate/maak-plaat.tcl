# plaat maken van afhankelijkheden tussen requests en save params.
# @todo start en stop snapshots opgeven.
package require ndv
package require Tclx
package require struct::list
package require math

::ndv::source_once urlencode.tcl
::ndv::source_once lib.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log ar_lst_save_param ar_argv

  $log debug "argv: $argv"
  set options {
    {action-dir.arg "C:\\nico\\test_aanvraag_2_0_55c\\gen-action" "Directory met input files (.c en .aspx)"}
    {firstss.arg "1" "first snapshot number"}
    {lastss.arg "200" "last snapshot number"}
    {loglevel.arg "" "Zet globaal log level"}
    {deletelog "Delete log before running"}
    {dot_dir.arg "c:\\nico\\util\\Graphviz2.26.3\\bin" "Directory waarbinnen graphviz dot.exe staat"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  $log debug "ar_argv: [array get ar_argv]"
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  if {$ar_argv(deletelog)} {
    file delete "[file rootname [file tail [info script]]].log" 
  }
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  $log info START

  handle_action_dir $ar_argv(action-dir)

  $log info FINISHED
  ::ndv::CLogger::close_logfile
}

proc handle_action_dir {dirname} {
  handle_action_file [file join $dirname "Action.c"]
}

proc handle_action_file {filename} {
  global log lst_params
  set text [read_file $filename]
  $log debug "#filename: [string length $text]"
  set fo [open "$filename.dot" w] 
  write_dot_header $fo
  set lst_params {}
  # write_dot_title $fo "Parameter afhankelijkheden voor [file tail $filename]" 
  while {[regexp {(\t[^ \n(]+\(([^\)]*\)[^;])*[^\)]*\);)(.*)} $text z method z rest]} {
    # breakpoint
    handle_method $fo $method 
    $log debug "#rest: [string length $rest]"
    set text $rest
  }
  write_dot_footer $fo
  close $fo
  do_dot "$filename.dot" "$filename.png"
}

proc handle_method {fo method} {
  global lst_params log
  # $log debug "handle_method $method"
  if {[regexp {\t([^ \n(]+)} $method z methodname]} {
    if {[is_request $methodname]} {
      handle_request $fo $method $lst_params
      set lst_params {}
    } elseif {[is_saveparam $methodname]} {
      lappend lst_params [det_paramname $method]
    } else {
      $log debug "Ignore method: $methodname" 
    }
  } else {
    $log warn "geen methodname gevonden in $method" 
  }
}

proc is_request {methodname} {
  if {[lsearch {web_custom_request web_url web_submit_data} $methodname] >= 0} {
    return 1
  } else {
    return 0 
  }
}

proc is_saveparam {methodname} {
  if {$methodname == "web_reg_save_param"} {
    return 1 
  } else {
    return 0 
  }
}

proc handle_request {fo method lst_params} {
  # global ar_argv
  lassign [det_snapshot_action $method] snapshot action
  if {[snapshot_out_of_range $snapshot]} {
    return 
  }
  puts $fo "  $snapshot \[shape=rectangle, label=\"$action\\n$snapshot\"\];"
  foreach param $lst_params {
    puts $fo "$snapshot -> [shorten_param $param];" 
  }
  foreach {z paramname}  [regexp -inline -all {\{([a-zA-Z0-9]+)\}} $method] {
    # lassign $el z paramname
    # breakpoint
    if {[ignore_param $paramname]} {
      # nothing 
    } else {
      puts $fo "[shorten_param $paramname] -> $snapshot;"
    }
  }
  # breakpoint
}

proc ignore_param {param_name} {
  if {[lsearch {pUrl} $param_name] >= 0} {
    return 1 
  } else {
    return 0 
  }
}

proc snapshot_out_of_range {snapshot} {
  global ar_argv log
  if {[regexp {t(.*)} $snapshot z nr]} {
    if {($nr < $ar_argv(firstss)) || ($nr > $ar_argv(lastss))} {
      return 1
    } else {
      return 0 
    }
  } else {
    $log error "Cannot determine number from snapshot: $snapshot, exiting..."
    exit 1
  }
}

proc det_snapshot_action {method} {
  global log
  # 20-3-2011 NdV Changed " to \42, so jedit will format correctly. Not tested!
  if {[regexp {\(\42([^\42]+).*\42Snapshot=(t[0-9]+[^\42\.]*)} $method z action snapshot]} {
    # breakpoint
    list $snapshot $action   
  } else {
    breakpoint
    $log warn "Cannot determine action and snapshot from $method, exiting..."
    exit 1
  }
}

proc shorten_param {param} {
  if {[regexp {cViewState([0-9]+.*)} $param z nr]} {
    return "vs$nr" 
  } elseif {[regexp {cEventValidation([0-9]+.*)} $param z nr]} {
    return "ev$nr"
  } elseif {[regexp {cValueExchange([0-9]+.*)} $param z nr]} {
    return "ve$nr"
  } else {
    return $param 
  }
}

proc det_paramname {method} {
  global log
  if {[regexp {web_reg_save_param\(\"([^"]+)\"} $method z paramname]} {
    return $paramname ; # "  
  } else {
    $log error "paramname not found in $method, exiting"
    exit 1    
  }
}

proc write_dot_header {f} {
		puts $f "digraph G \{
		rankdir = TB
/*
		size=\"40,40\";
		ratio=fill;
		node \[fontname=Arial,fontsize=20\];
		edge \[fontname=Arial,fontsize=16\];
*/
    "
}

proc write_dot_footer {f} {
	puts $f "\}"
}

proc write_dot_title {f title} {
  puts $f "  title \[shape=rectangle, label=\"$title\", fontsize=18\];"
}



proc do_dot {dot_file png_file} {
  global log ar_argv
  $log info "Making png $png_file from dot $dot_file"
  exec [file join $ar_argv(dot_dir) dot.exe] -Tpng $dot_file -o $png_file
}

main $argc $argv

