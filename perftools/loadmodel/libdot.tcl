# functions for creating dot files (and calling dot)
# 26-12-2011 copied file to ~/nicoprj/lib directory.

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

# @todo work for linux
proc do_dot {dot_file png_file} {
  global tcl_platform
  #global log ar_argv
  #$log info "Making png $png_file from dot $dot_file"
  #exec [file join $ar_argv(dot_dir) dot.exe] -Tpng $dot_file -o $png_file
  if {$tcl_platform(platform) == "unix"} {
    exec dot -Tpng $dot_file -o $png_file
  } else {
    puts "tbd" 
  }
}

# algoritme van http://en.wikipedia.org/wiki/Word_wrap 
proc wordwrap {str {wordwrap 60}} {
  # global wordwrap
  if {$wordwrap == ""} {
    return $str
  }
  set spaceleft $wordwrap
  set result ""
  foreach word [split $str " "] {
    if {[string length $word] > $spaceleft} {
      append result "\\n$word "
      set spaceleft [expr $wordwrap - [string length $word]]
    } else {
      append result "$word "
      set spaceleft [expr $spaceleft - ([string length $word] + 1)]
    }
  }
  return $result
}

proc puts_node_stmt {f label args} {
  lassign [node_stmt $label {*}$args] name statement
  puts $f $statement
  return $name  
}

# return list: node name, node statement
# example: node_stmt mynode shape ellipse color black
# @doc pure function
proc node_stmt {label args} {
  set name [sanitise $label]
  list $name "  $name [det_dot_args [concat [list label $label] $args]];"
}

# @example: edge_stmt from to color red label abc
proc edge_stmt {from to args} {
  # possible args: label, color, fontcolor
  # return "  $from -> $to \[[join $lst_edge_args ","]\];"
  return "  $from -> $to [det_dot_args $args];"
}

proc det_dot_args {lst_args} {
  set lst_dot_args {}
  foreach {nm val} $lst_args {
    lappend lst_dot_args "$nm=\"$val\"" 
  }
  return "\[[join $lst_dot_args ","]\]"
}

proc sanitise_old {str} {
  regsub -all "/" $str "" str
  regsub -all -- "-" $str "_" str
  regsub -all {\.} $str "_" str
  regsub -all { } $str "_" str
  return "_$str"
}

proc sanitise {str} {
  regsub -all {[^A-Za-z0-9_]} $str "_" str
  return "_$str"
}

# @example: do_list {123 456} {"puts stdout" "set b"}
proc do_list {lst_items lst_procs} {
  #ar_name
  #upvar $ar_name ar
  #set ar(1) 2
  
  upvar up_item item
  foreach item $lst_items procname $lst_procs {
    # need upvar with up_item and braces, otherwise to much eval is done (quoting hell?)
    uplevel 1 {*}$procname {$up_item} 
  }
}

# functional equivalent of if statement.
# not sure if uplevel/expr always works as expected.
proc ifelse {expr iftrue {iffalse ""}} {
  if {[uplevel 1 expr $expr]} {
    return $iftrue 
  } else {
    return $iffalse 
  }
}

