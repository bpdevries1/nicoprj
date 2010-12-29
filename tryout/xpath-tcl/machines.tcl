#!/home/nico/bin/tclsh

# NdV 21-9-2010 deze versie nog in d:\aaa gevonden, leek nieuwer dan de versie in deze dir, door is_interesting functie.

package require tdom
package require ndv
package require Tclx
package require struct::list

proc main {} {
  set xml [read_file data.xml]
  set doc [dom parse $xml]
  set root [$doc documentElement]

  set lst_pages [$root selectNodes {/VisioDocument/Pages/Page}]
  foreach page $lst_pages {
    set page_name [$page @Name] 
    puts "================\npage: $page_name\n-------------------"
    set lst_shapes [$page selectNodes {Shapes/Shape}] 
    set lst_shape_info_all [struct::list map $lst_shapes det_shape_info]
    # set lst_shape_info [struct::list filterfor el $lst_shape_info_all {[dict get $el name] != ""}]
    set lst_shape_info [struct::list filter $lst_shape_info_all is_interesting]
    struct::list split $lst_shape_info is_computer lst_computers lst_others
    foreach computer $lst_computers {
      set nearest [det_nearest $computer $lst_others]
      if {$nearest != ""} {
        puts "[dict get $computer name] => [dict get $nearest name] ([dict get $computer point] => [dict get $nearest point])"
      } else {
        puts "[dict get $computer name]  => <NOTHING FOUND> ([dict get $computer point])"
      }
    }
    
    if {0} {
      puts "shape infos:"
      foreach el $lst_shape_info {
        set name [dict get $el name]
        if {$name != ""} {
          if {[regexp {^[A-Z]{3} rc} $name]} {
            puts "computer: [dict get $el name]: [dict get $el point]"
          } else {
            puts "logical: [dict get $el name]: [dict get $el point]"
          }
        }
      }
    }
    # $page text
  }

  $doc delete  
}

proc is_computer {shape_info} {
  regexp {^[A-Z]{3} rc} [dict get $shape_info name]
}
proc is_interesting {shape_info} {
  set name [dict get $shape_info name]
  if {$name == ""} {
	return 0
  } elseif {$name == "X"} {
	return 0
  }
  return 1
}

proc det_shape_info {shape} {
  set shape_name [det_shape_name $shape]
  set point [det_point $shape]
  return [dict create name $shape_name point $point]
  # puts [join [list $page_name $shape_name {*}$point] "\t"]
  
}

proc det_shape_name {shape} {
  set text_node [$shape selectNodes {Text}]
  if {$text_node != ""} {
    set text [$text_node text] 
    regsub -all "\n" $text " " text
    return  $text
    # return [$shape selectNodes {Text/.}]
  } else {
    # puts "shape with no text: [$shape text] [$shape attributes]"
    return ""
  }
}

proc det_point {shape} {
  # return "<point>" 
  set elem_x [$shape selectNodes {XForm/PinX}]
  if {$elem_x != ""} {
    return [list [$elem_x text] [[$shape selectNodes {XForm/PinY}] text]]
  } else {
    return {} 
  }
}

proc det_nearest {computer lst_others} {
  if {$lst_others == {}} {
    return "" 
  }
  set min_dist [det_dist $computer [lindex $lst_others 0]]
  set min_other [lindex $lst_others 0]
  foreach other [lrange $lst_others 1 end] {
    set dist [det_dist $computer $other]
    if {$dist < $min_dist} {
      set min_dist $dist
      set min_other $other
    }
  }
  return $min_other
}

proc det_dist {computer other} {
  lassign [dict get $computer point] x1 y1
  lassign [dict get $other point] x2 y2
  expr sqrt(($x1 - $x2)**2 + ($y1 - $y2)**2)
}

main
