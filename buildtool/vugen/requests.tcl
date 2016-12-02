package require json

require libio io

use libfp
use liburl

task show_requests {Create a HTML report of all requests in script
  Check if requests have dynamic items, which should be correlated.
} {
  {clean "Delete DB and generated reports before starting"}
  {all "Show info about all request (default: only requests where action is needed)"}
  {treshold.arg "0.5" "Treshold above which requests are marked Red"}
} {
  #log info "show-requests: TODO"
  file mkdir requests
  set script [file tail [file normalize .]]
  io/with_file f [open requests/requests.html w] {
    set hh [ndv::CHtmlHelper::new]
    $hh set_channel $f
    $hh write_header "All requests in $script" 0
    show_toc $opt $hh
    foreach filename [get_action_files] {
      show_requests_file $opt $hh $filename
    }
  }
}

# TODO: when opt != all, only show relevant items.
proc show_toc {opt hh} {
  $hh heading 1 "Table of contents"
  foreach filename [get_action_files] {
    if {[show_requests_file? $opt $filename]} {
      $hh href $filename "#$filename"
      $hh br
    }
  }
}

# Add requests in filename to html (hh)
proc show_requests_file {opt hh filename} {
  if {![show_requests_file? $opt $filename]} {
    return
  }
  $hh anchor_name [file tail $filename]
  $hh heading 1 "Requests in [file tail $filename]"
  # $hh write "TODO"
  set stmts [read_source_statements $filename]

  foreach stmt $stmts {
    if {[:type $stmt] == "main-req"} {
      show_request_html $opt $hh $stmt
    }
  }

}

# return 1 iff requests in file should be shown, based on options and requests in file.
proc show_requests_file? {opt filename} {
  set stmts [read_source_statements $filename]
  # set stmts2 [filter [fn x {[:type $x] == "main-req"}] $stmts]
  set stmts2 [filter [fn x {= [:type $x] "main-req"}] $stmts]
  set stmts3 [filter [fn x {show_request_html? $opt $x}] $stmts2]
  # breakpoint
  if {[count $stmts3] > 0} {
    return 1
  }
  return 0
}

proc show_request_html {opt hh stmt} {
  if {![show_request_html? $opt $stmt]} {
    return
  }
  set url [stmt_det_url $stmt]
  set stmt_params [stmt_params $stmt]
  set referer [stmt_det_referer $stmt]
  set url_params [url->params $url]; # maybe also set from POST body.
  # $hh heading 2 "Request - $url" "class=Failure"
  $hh heading 2 "Request - $url (corr=[det_request_correlation $stmt])" "class=[det_request_class $opt $stmt]"
  paragraph $hh [lines_heading $stmt] [lines->html [:lines $stmt]]
  paragraph $hh "Statement Parameters" [stmt_params->html $stmt_params]
  paragraph $hh "URL Parameters" [params->html $url_params]
  paragraph $hh Url $url
  paragraph $hh Referer $referer
}

# return 1 iff request should be shown with given opt(ions)
proc show_request_html? {opt stmt} {
  if {[:all $opt]} {
    return 1
  }
  if {[det_request_correlation $stmt] >= [:treshold $opt]} {
    return 1
  }
  return 0
}

# return either Failure or an empty string, based on the chance we need to do some
# correlation and the treshold set in opt.
proc det_request_class {opt stmt} {
  if {[det_request_correlation $stmt] >= [:treshold $opt]} {
    return Failure
  } else {
    return ""
  }
}

# return value between 0 and 1 inclusive with chance we need to do some correlation
# on this item
proc det_request_correlation {stmt} {
  # return 0.6
  set url [stmt_det_url $stmt]
  set ext [string tolower [file extension $url]]
  # less chance that images need to be correlated, but this could depend on the script/project.
  if {[lsearch -exact {.gif .jpg .jpeg .png .js .css} $ext] >= 0} {
    return 0.1
  }

  return 0.9
}

proc paragraph {hh title content} {
  $hh heading 3 "${title}:"
  $hh text $content
}

proc lines_heading {stmt} {
  return "Lines ([:linenr_start $stmt] to [:linenr_end $stmt])"
}


proc params->html {params} {
  join [map param->html $params] "<br/>"
}

# param is a tuple: name, value
proc param->html {param} {
  # lassign $param name value
  dict_to_vars $param;          # type, name, value, valuetype
  switch $type {
    name {
      # return [wordwrap_html $name]
      return $name;             # no wordwrap for now
    }
    namevalue {
      # return [wordwrap_html "$name = $value \[$valuetype\]"]
      return "$name = $value \[$valuetype\]"
    }
    else {
      error "Unknown type: $type for: $param"
    }
  }  
}

# return list of tuples: type,name,value,valuetype as dict
# type: namevalue or name
# valuetype: integer, hex, base64, json, ...
# TODO: multi line string parameters, then possibly two quotes straight after each other.
proc stmt_params {stmt} {
  set text ""
  foreach line [:lines $stmt] {
    append text [string trim $line]
  }
  if {[regexp {^.+?\((.*)\);} $text z param_text]} {
    set l [csv::split $param_text]
    set res [list]
    foreach el $l {
      if {[regexp {^(.+?)=(.*)$} $el z nm val]} {
        # lappend res [list $nm $val]
        lappend res [dict create type namevalue name $nm value $val \
                         valuetype [det_valuetype $val]]
      } else {
        # lappend res [list $el "{NO-VALUE}"]
        lappend res [dict create type name name $el]
      }     
    }
    return $res
  } else {
    error "Cannot parse statement text: $text"
  }
}


# parameters: list of name,value pairs
proc stmt_params->html {parameters} {
  params->html $parameters;     # for now, they seem the same.
}




##########################################################
# Library stuff, not specific to statements and URL's    #
##########################################################

# lines - list of lines
# result lines, separated by <br/> elements
proc lines->html {lines} {
  # [2016-12-02 14:32] no word wrap for now.
  # set lines2 [map wordwrap_html $lines]
  join $lines "<br/>"
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

