# read csv file with data in columns:
package require ndv

proc main {argv} {
  global ar_info
  read_locations
  set filename [lindex $argv 0]
  set f [open $filename r]
  array unset ar_route
  gets $f headerline
  while {![eof $f]} {
    set l [split [gets $f] ","]
    if {[llength $l] < 10} {
      continue
    }
    if {[lindex $l 0] == ""} {
      continue
    }
    set src [lindex $l 2]
    set dest [lindex $l 5]
    if {[regexp "n/a" $dest]} {
      continue 
    }
    set dest_name [lindex $l 6]
    set idx [lindex $l 4]
    set ms [lindex $l 7]
    if {$idx == 1} {
      # incr ar_route($src,$dest)
      set route "$src,$dest"
    } else {
      # incr ar_route($prev,$dest)
      set route "$prev,$dest"
    }
    handle_route $route $ms
    set prev $dest
    set ar_labels([sanitise $dest]) [det_dest_label $dest $dest_name]
      
  }
  close $f
  set f [open "paths.dot" w]
  puts $f "digraph G {"
  foreach el [array names ar_labels] {
    puts $f "$el \[label=\"$ar_labels($el)\"\]"
  } 
  
  foreach el [array names ar_info] {
    lassign [split $el ","] a b
    lassign $ar_info($el) count
    # 20-9-2011 even arbitrair, alleen main paths tonen.
    if {$count > 10} {
      puts $f "  [sanitise $a] -> [sanitise $b] \[label=\"[calc_values $el]\"\];"
    }
  }
  
  puts $f "}"
  close $f
}

proc det_dest_label {dest dest_name} {
  global ar_locations
  if {[array get ar_locations $dest] == {}} {
    set location "<?>" 
  } else {
    set location $ar_locations($dest) 
  }
  
  if {$dest_name == ""} {
    return "$dest ($location)"
  } else {
    return "$dest ($dest_name, $location)"
  }
 
}

proc handle_route {route ms} {
  global ar_info
  if {$ms == ""} {
    breakpoint 
  }
  if {[array get ar_info $route] == {}} {
    set ar_info($route) [list 1 $ms $ms $ms] 
  } else {
    lassign $ar_info($route) count sum min max
    incr count
    if {$ms < $min} {
      set min $ms
    }
    if {$ms > $max} {
      set max $ms 
    }
    set sum [expr $sum + $ms]
    set ar_info($route) [list $count $sum $min $max] 
  }
}

proc calc_values {el} {
  global ar_info
  lassign $ar_info($el) count sum min max
  if {$sum == ""} {
    breakpoint 
  }
  format "#%d (%d/%.1f/%d)" $count $min [expr 1.0 * $sum / $count] $max
}

proc sanitise {str} {
  regsub -all "/" $str "" str
  regsub -all -- "-" $str "_" str
  regsub -all {\.} $str "_" str
  regsub -all { } $str "_" str
  return "_$str"
}

proc read_locations {} {
  global ar_locations
  set locations_filename "locations.txt" 
  if {[file exists $locations_filename]} {
    set f [open $locations_filename r]
    while {![eof $f]} {
      lassign [split [gets $f] ";"] ip location
      set ar_locations($ip) $location
    }
    close $f
  }
}

main $argv