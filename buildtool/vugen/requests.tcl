package require json

require libio io

task show_requests {Create a HTML report of all requests in script
  Check if requests have dynamic items, which should be correlated.
} {
  {clean "Delete DB and generated reports before starting"}
  {all "Show info about all request (default: only requests where action is needed)"}
} {
  #log info "show-requests: TODO"
  file mkdir requests
  set script [file tail [file normalize .]]
  io/with_file f [open requests/requests.html w] {
    set hh [ndv::CHtmlHelper::new]
    $hh set_channel $f
    $hh write_header "All requests in $script" 0
    show_toc $hh
    foreach filename [get_action_files] {
      show_requests_file $opt $hh $filename
    }
  }
}

# TODO: when opt != all, only show relevant items.
proc show_toc {hh} {
  $hh heading 1 "Table of contents"
  foreach filename [get_action_files] {
    $hh href $filename "#$filename"
    $hh br
  }
}

# Add requests in filename to html (hh)
proc show_requests_file {opt hh filename} {
  $hh anchor_name [file tail $filename]
  $hh heading 1 "Requests in [file tail $filename]"
  # $hh write "TODO"
  set stmts [read_source_statements $filename]

  foreach stmt $stmts {
    if {[:type $stmt] == "main-req"} {
      show_request_html $hh $stmt
    }
  }

}

proc show_request_html {hh stmt} {
  set url [stmt_det_url $stmt]
  set stmt_params [stmt_params $stmt]
  set referer [stmt_det_referer $stmt]
  set url_params [url->params $url]; # maybe also set from POST body.
  $hh heading 2 $url
  paragraph $hh [lines_heading $stmt] [lines->html [:lines $stmt]]
  paragraph $hh "Statement Parameters" [stmt_params->html $stmt_params]
  paragraph $hh "URL Parameters" [params->html $url_params]
  paragraph $hh Url $url
  paragraph $hh Referer $referer
}

proc paragraph {hh title content} {
  $hh heading 3 "${title}:"
  $hh text $content
}

proc lines_heading {stmt} {
  return "Lines ([:linenr_start $stmt] to [:linenr_end $stmt])"
}

# return list of url params
# each element is a tuple: type,name,value,valuetype as dict
# package uri can only provide full query string, so not really helpful here.
proc url->params {url} {
  if {[regexp {^[^?]+\?(.*)$} $url z params]} {
    set res [list]
    foreach pair [split $params "&"] {
      # lappend res [split $pair "="]
      lassign [split $pair "="] nm val
      lappend res [dict create type namevalue name $nm value $val \
                      valuetype [det_valuetype $val]]
    }
    return $res
  } else {
    return [list]
  }
}

# TODO: several date/time formats.
proc det_valuetype {val} {
  set base64_min_length 32;     # should test, maybe configurable.
  if {$val == ""} {
    return empty
  }
  if {[regexp {^\d+$} $val]} {
    # integer, check if it could be an epoch time.
    if {($val > "1400000000") && ($val < "3000000000")} {
      return "epochsec: [clock format $val]"
    }
    if {($val > "1400000000000") && ($val < "3000000000000")} {
      return "epochmsec: [clock format [string range $val 0 end-3]]"
    }
    return integer
  }
  foreach stringtype {boolean xdigit double} {
    if {[string is $stringtype $val]} {
      return $stringtype
    }
  }
  # still here, so look deeper.
  # json
  if 0 {
    [2016-11-29 12:36:21] now one body like below, not matched as json, something with backslashes and quotes.
    Body = {\TradingEntities\:null,\RegimeEligibilities\:null,\P }
    and much more.
  }
  if {![catch {json::json2dict $val}]} {
    # also no catch with eg Snapshot = t8.inf [json], so check it is at least surrounded with braces
    if {[regexp {^\{.*\}$} $val]} {
      return json  
    }
  }

  # TODO: should check, not working yet, something with escaping backslashes and quotes.
  if {[regexp TradingEntityReportedRegimes $val]} {
    # log debug "Check jsonexi"
    # breakpoint
  }
  
  # base64 - val should have minimal length
  if {[string length $val] >= $base64_min_length} {
    if {[regexp {^[A-Za-z0-9+/]+$} $val]} {
      return base64
    }
  }


  # url and/or html encoded?

  return string;              # default, if nothing else.
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
      return [wordwrap_html $name]  
    }
    namevalue {
      return [wordwrap_html "$name = $value \[$valuetype\]"]    
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

