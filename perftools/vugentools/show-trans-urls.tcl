#!/usr/bin/env tclsh86

# TODO
# protocol/host vervangen door {host} of evt hostx als er meerdere zijn. Hosts ook 'printen' op het eind.
# generieke stukken van URL's vervangen door {urlpartx} en ook deze op het eind noemen.

package require textutil::split
package require Tclx
package require ndv

interp alias {} splitx {} ::textutil::split::splitx

set DEBUG 0

proc main {argv} {
  lassign $argv prj_dir
  set_default_params
  set report_dir [file join $prj_dir report]
  file mkdir $report_dir
  set f [open [file join $report_dir trans-urls.org] w]
  foreach c_filename [lsort -nocase [glob -directory $prj_dir *.c]] {
    handle_c_file $f $c_filename
  }
  print_params $f
  close $f 
}

proc handle_c_file {f c_filename} {
  global DEBUG
  puts $f "* [file tail $c_filename]"
  set cur_trans "<none>"
  set in_concurrent 0
  set text [read_file $c_filename]
  # remove first 2 lines (procname and brace) and last line (brace)
  set lines [split $text "\n"]
  set lines [lrange $lines 2 end-1]
  set text [join $lines "\n"]
  set stmts [splitx $text {;\n}]
  foreach stmt $stmts {
    lassign [parse_stmt $stmt] fnname params
    if {$fnname == "lr_start_transaction"} {
      set cur_trans [:0 $params]
      puts $f "** Transaction: $cur_trans"
    } elseif {$fnname == "lr_end_transaction" } {
      set cur_trans "<none>"
    } elseif {($fnname == "web_url") || ($fnname == "web_submit_data")} {
      if {($cur_trans != "<none>") && !$in_concurrent} {
        lassign $params label url
        if {[ignore_url $url]} {
          # do nothing. 
        } else {
          puts $f "*** $fnname: [handle_label $label]: [handle_url $url]"
          # puts $f "*** $fnname: [handle_url "$label/"]: [handle_url $url]"  
        }        
      } else {
        # action outside of a transaction, not important.
      }
    } elseif {$fnname == "web_concurrent_start"} {
      set in_concurrent 1
    } elseif {$fnname == "web_concurrent_end"} {
      set in_concurrent 0    
    } elseif {[ignore_fncall $fnname]} {
      # ok, do nothing.
    } else {
      puts $f "*** WARNING, unhandled: $fnname"
    }
    if {$DEBUG} {
      # puts $f "Statement:"
      puts $f "** Name: $fnname"
      set i 1
      foreach param $params {
        puts $f "*** param $i: [string trim $param]"
        incr i
      }
      # puts $f "==================="
    }
  }
}

# parse statements of the form: fnname(param1, param2, ...)
proc parse_stmt {stmt} {
  set stmt [remove_comments [string trim $stmt]]
  if {[regexp {^([^\(\)]+)\((.*)\)$} $stmt z fnname strparams]} {
    # TODO comma's can be part of a string, need to take into account. Use CSV parsing lib?
    set params [splitx $strparams ","]
    set paramst {}
    foreach el $params {
      set el2 [string trim $el]
      check_quotes $el2
      lappend paramst $el2
    }
    return [list [string trim $fnname] $paramst]
  } else {
    return [list "" ""]
  }
}

# remove comments of the form /* comment */
# also remove lines starting with //
proc remove_comments {stmt} {
  regsub {/\*[^\*]+\*/} $stmt "" stmt
  set stmt [string trim $stmt]
  set lines [split $stmt "\n"]
  set lines2 {}
  foreach line $lines {
    if {[regexp {^//} [string trim $line]]} {
      # ignore line
    } else {
      lappend lines2 $line
    }
  }
  join $lines2 "\n"
}

proc ignore_fncall {fnname} {
  set ignore_list {"" lr_think_time web_add_cookie web_reg_find web_convert_param web_set_certificate_ex web_reg_save_param_regexp}
  foreach el $ignore_list {
    if {$el == $fnname} {
      return 1
    }
  }
  return 0
}

# force an error if:
# first character is a double quote, but last one isn't
# last character is a double quote, but first one isnt't.
# @pre str is already trimmed.
proc check_quotes {str} {
  set firstchar [string range $str 0 0]
  set lastchar [string range $str end end]
  if {$firstchar == "\""} {
    if {$lastchar == "\""} {
      # ok, both quotes
      # error "just atest"
    } else {
      error "Quotes not aligned: $str"
    }
  } else {
    if {$lastchar == "\""} {
      error "Quotes not aligned: $str"
    } else {
      # ok, both not quotes
    }
  }
}

# choice: use a dict (no array), should be easier to return/give as param.

proc set_default_params {} {
  global urlparams param_idx
  set urlparams [dict create \
"https://securepat01.rabobank.com/wps/myportal/rcc/dashboard/mydashboard" "dashboard" \
"https://securepat01.rabobank.com/wps/myportal/rtsec" "rtsec" \
"https://securepat01.rabobank.com" "secpat"]
  set param_idx 0
}

proc print_params {f} {
  global urlparams
  puts $f "* Substituted URL parameters"
  dict for {urlpart param} $urlparams {
    puts $f "** $param = $urlpart"
  }
}

proc handle_url {url} {
  global urlparams param_idx
  # first check if an existing param applies
  if {$param_idx == 3} {
    #breakpoint
  }
  dict for {urlpart param} $urlparams {
    regsub -all $urlpart $url "\{$param\}" url
  }
  if {$param_idx == 3} {
    #breakpoint
  }
  
  # then maybe add new params.
  # idea is to split on / and for each part which is longer than x characters, replace with a param.
  set parts [split $url "/"]
  set parts2 {}
  foreach part [lrange $parts 0 end-1] {
    if {[regexp {=} $part]} {
      lappend parts2 $part ; # don't substitute url request parameters and values.
    } else {
      # if {[string length $part] >= $MIN_REPLACE_LEN} {}
      if {[should_replace $part]} {
        incr param_idx
        set p_name "p$param_idx"
        dict set urlparams $part $p_name 
        lappend parts2 "\{$p_name\}"
      } else {
        lappend parts2 $part
      }
    }
  }
  # never replace last part
  lappend parts2 [lindex $parts end]
  set url [join $parts2 "/"]
  return $url
}

# we have long generated labels, replace by first n chars
proc handle_label {label} {
  string range $label 0 20
}

proc should_replace {part} {
  set MIN_REPLACE_LEN 20
  if {[string length $part] >= $MIN_REPLACE_LEN} {
    if {[regexp {^[A-Za-z]+$} $part]} {
      return 0 ; # only letters, no digits or special chars: probably a readable name, don't replace
    } else {
      return 1
    }
  } else {
    return 0
  }
}

proc ignore_url {url} {
  set ignore_res {webanalytics microsoft.com rabonet.com cloudfront.net}
  foreach re $ignore_res {
    if {[regexp $re $url]} {
      return 1
    }
  }
  return 0
}

main $argv
