require libio io

task show_requests {Create a HTML report of all requests in script
  Check if requests have dynamic items, which should be correlated.
} {
  {clean "Delete DB and generated reports before starting"}
} {
  #log info "show-requests: TODO"
  file mkdir requests
  set script [file tail [file normalize .]]
  io/with_file f [open requests/requests.html w] {
    set hh [ndv::CHtmlHelper::new]
    $hh set_channel $f
    $hh write_header "All requests in $script" 0
    foreach filename [get_action_files] {
      show_requests_file $hh $filename
    }
  }
}

# Add requests in filename to html (hh)
proc show_requests_file {hh filename} {
  $hh heading 1 "Requests in [file tail $filename]"
  # $hh write "TODO"
  set stmts [read_source_statements $filename]
  $hh table {
    $hh table_header Lines Url Referer
    foreach stmt $stmts {
      if {[:type $stmt] == "main-req"} {
        show_request_html $hh $stmt
      }
    }
  }
}

proc show_request_html {hh stmt} {
  set url [stmt_det_url $stmt]
  set referer [stmt_det_referer $stmt]
  $hh table_row [lines->html [:lines $stmt]] \
      [wordwrap_html $url] [wordwrap_html $referer]
  #            "[:linenr_start $stmt]-[:linenr_end $stmt]"
  
}

# lines - list of lines
# result lines, separated by <br/> elements
proc lines->html {lines} {
  set lines2 [map wordwrap_html $lines]
  join $lines2 "<br/>"
}


proc wordwrap_html {str {line_length 60} {splitchars " /&?"}} {
  # set lines [wordwrap_generic $str $wordwrap $splitchars]
  # [2016-11-27 16:38] for now just split text up exactly at line_length sizes
  set lines [list]
  while {$str != ""} {
    lappend lines [string range $str 0 $line_length-1]
    set str [string range $str $line_length end]
  }
  join $lines "<br/>&nbsp;&nbsp;"
}

# algoritme van http://en.wikipedia.org/wiki/Word_wrap
# return list of lines as split up.
# TODO: deze werkt niet, splitchars raken kwijt.
proc wordwrap_generic {str {wordwrap 60} {splitchars " "}} {
  # global wordwrap
  if {$wordwrap == ""} {
    return [list  $str]
  }
  set spaceleft $wordwrap
  set result [list]
  set curr_line ""
  foreach word [split $str $splitchars] {
    if {[string length $word] > $spaceleft} {
      lappend result $curr_line
      set curr_line "$word "
      # lappend result "\\n$word "
      set spaceleft [expr $wordwrap - [string length $word]]
    } else {
      # append result "$word "
      append curr_line "$word "
      set spaceleft [expr $spaceleft - ([string length $word] + 1)]
    }
  }
  lappend result $curr_line
  return $result
}


