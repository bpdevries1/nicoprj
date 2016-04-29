#!/usr/bin/env tclsh86

package require textutil::split
package require Tclx
package require ndv
package require csv

interp alias {} splitx {} ::textutil::split::splitx

set DEBUG 0
set parprefix "lwpar"

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "logs/[file tail [info script]]-[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"].log"

# TODO
# - naam dit script aanpassen -> genereert nu ook een script met correlatie web_reg_save_param_regexp's.

# Manual actions
# - vuser_init
# - certificate
# - user list (param)
# - set log to full
# - proxy

# CHECK
# - web_reg_save_param_regexp binnen een concurrent group? Kan fouten geven? Mogelijk ook bij recording opgeven, dat dingen als json als hoofd object worden gezien.

proc main {argv} {
  global prj_dir
  lassign $argv prj_dir
  set_default_params
  set report_dir [file join $prj_dir report]
  file mkdir $report_dir
  file mkdir [file join $prj_dir generated]
  foreach filename [glob -nocomplain -directory [file join $prj_dir generated] -type f *] {
    file delete $filename
  }
  
  set f [open [file join $report_dir trans-urls.org] w]
  set file_open 1
  try_eval {
    foreach c_filename [lsort -nocase [glob -directory $prj_dir *.c]] {
      if {![ignore_file [file tail $c_filename]]} {
          handle_c_file $f $c_filename
      }
    }
    # then replace values with params
    foreach c_filename [lsort -nocase [glob -directory $prj_dir *.c]] {
      if {![ignore_file [file tail $c_filename]]} {
          replace_values_c_file $f $c_filename
      }
    }
    print_params $f
  } {
    # when an error occurs, close the output file
    puts $f "errorresult: $errorResult"
    puts $f "errorCode: $errorCode"
    puts $f "errorInfo: $errorInfo"
    puts $f "An error occured, close the file"
    close $f
    set file_open 0
  }
  if {$file_open} {
    close $f 
  }
}

proc replace_values_c_file {f c_filename} {
  global prj_dir urlparams
  # multiple regexp's can be added to one file, so check first.
  # this is not the most efficient, but should be fast enough.
  set gen_name [file join $prj_dir generated [file tail $c_filename]]
  set text [read_file $c_filename]
  set fo [open $gen_name w]
  dict for {urlpart param} $urlparams {
    regsub -all $urlpart $text "\{$param\}" text
  }
  puts $fo $text
  close $fo
}

proc ignore_file {c_filename} {
  if {[file tail $c_filename] == "pre_cci.c"} {
    return 1
  }
  return 0
}

proc handle_c_file {f c_filename} {
  global DEBUG
  log info "handle_c_file: $c_filename"
  puts $f "* [file tail $c_filename]"
  set cur_trans "<none>"
  set in_concurrent 0
  set text [read_file $c_filename]
  # remove first 2 lines (procname and brace) and last line (brace)
  set lines [split $text "\n"]
  set lines [lrange $lines 2 end-1]
  set text [join $lines "\n"]
  set stmts [splitx $text {;\n}]
  log debug "#stmts: [:# $stmts]"
  # TODO web_urls etc in concurrent actions toch ook behandelen?
  foreach stmt $stmts {
    lassign [parse_stmt $stmt] fnname params
    if {$fnname == "lr_start_transaction"} {
      set cur_trans [:0 $params]
      puts $f "** Transaction: $cur_trans"
    } elseif {$fnname == "lr_end_transaction" } {
      set cur_trans "<none>"
    } elseif {($fnname == "web_url") || ($fnname == "web_submit_data") || ($fnname == "web_custom_request")} {
      # log debug "Function to handle: $fnname (params: $params)"
      log debug "Function to handle: $fnname"
      if {[regexp {retrieveLoansClients} $stmt]} {
        log debug "Function to handle: $fnname (params: $params)"
      }
      
      if {($cur_trans != "<none>") && !$in_concurrent} {
        lassign $params label url
        if {[ignore_url $url]} {
          # do nothing. 
          log debug "ignore_url: $url"
        } else {
          set label2 [handle_label $label]
          set url2 [handle_url $url]
          puts $f "*** $fnname: $label2: $url2"
          log debug "*** $fnname: $label2: $url2"
        }        
      } else {
        log debug "outside transaction, not important"
        log trace $stmt
      }
    } elseif {$fnname == "web_concurrent_start"} {
      set in_concurrent 1
    } elseif {$fnname == "web_concurrent_end"} {
      set in_concurrent 0    
    } elseif {[ignore_fncall $fnname]} {
      # ok, do nothing.
    } else {
      puts $f "*** WARNING, unhandled: $fnname"
      log warn "Unhandled: $fnname"
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
    ## TODO comma's can be part of a string, need to take into account. Use CSV parsing lib?
    # set params [splitx $strparams ","]
    set params [csv::split $strparams]
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
# last character is a double quote, but first one isn't.
# @pre str is already trimmed.
proc check_quotes {str} {
  set firstchar [string range $str 0 0]
  set lastchar [string range $str end end]
  if {$firstchar == "\""} {
    if {$lastchar == "\""} {
      # ok, both quotes
      # error "just atest"
    } else {
      breakpoint
      error "Quotes not aligned: $str"
    }
  } else {
    if {$lastchar == "\""} {
      breakpoint
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
"https://securepat01.rabobank.com" "host"]
  set param_idx 0
}

proc print_params {f} {
  global urlparams
  puts $f "* Substituted URL parameters"
  dict for {urlpart param} $urlparams {
    puts $f "** $param = $urlpart"
    print_param_details $f $urlpart $param
  }
}

# find first .htm file in data subdir where urlpart is found. Then find the request where this .htm is a response of. Print both to the output as org level 3.
proc print_param_details {f urlpart param} {
  global parprefix
  set first_file [find_first_occ $urlpart] ; # returns something like t27.htm
  set c_file [find_snapshot $first_file] ; # returns something like login.c
  puts $f "*** first found in snapshot: $first_file"
  puts $f "*** in action/c: $c_file"
  if {[regexp "^${parprefix}\\d+$" $param]} {
    # only for generated params.
    if {$c_file == "<not found>"} {
      puts $f "**** WARNING: generated param, but not found in file"
    } else {
      add_save_param_regexp $f $c_file $first_file $urlpart $param
    }
  }
}

# @param c_file - file to add regexp to (in generated folder)
# @param first_file - output file (html, json) in data-folder where param was first found
# @param urlpart - param/text that was found.
# @param param - name of the parameter, eg p1.
# @post - c_file in generated dir is updated with a web_reg_save_param_regexp in the right place.
proc add_save_param_regexp {f c_file first_file urlpart param} {
  global prj_dir gen_file_idx
  # multiple regexp's can be added to one file, so check first.
  # this is not the most efficient, but should be fast enough.
  set gen_name [file join $prj_dir generated [file tail $c_file]]
  if {![file exists $gen_name]} {
    file copy [file join $prj_dir $c_file] $gen_name
  }
  
  set text [read_file [file join $prj_dir data $first_file]]
  # if {![regexp "(.{5})${urlpart}(.{5})" $text z pre post]} {}
  if {![regexp "(\[^\\n\]{1,5})${urlpart}(\[^\\n\]{1,5})" $text z pre post]} {
    error "urlpart ($urlpart) not found in first_file ($first_file)"
  }
  # set re "${pre}(\[^/\]+?)${post}"
  set re [make_regexp $pre $post]
  set res [regexp -inline -all $re $text]
  if {$res == {}} {
    error "text not found again with build RE ($re), urlpart ($urlpart) not found in first_file ($first_file)"
  }
  # find match number and put in statement
  set idx 1
  set found 0
  foreach {z m} $res {
     if {$m == $urlpart} {
       # match found
       set found 1
       break
     }
     incr idx
  }
  if {!$found} {
    puts $f "**** Matched found for RE, but none are equal to orig text"
  }
  
  # error "text found diff with build RE ($re) is not the same, in first_file ($first_file): urlpart: $urlpart. New part: $part2"
  # puts $f "**** text found diff with build RE ($re) is not the same, in first_file ($first_file): urlpart: $urlpart. New part: $part2"
  
  # part is found again, so build new file.
  set temp_name "$gen_name.TEMP"
  set fo [open $temp_name w]

  set text [read_file $gen_name]
  set lines [split $text "\n"]
  puts $fo [join [lrange $lines 0 1] "\n"]
  set lines [lrange $lines 2 end-1]
  set text [join $lines "\n"]
  set stmts [splitx $text {;\n}]
  set stmts2 {}
  set snapshot_name [det_snapshot_name $first_file]
  foreach stmt $stmts {
    if {[string first $snapshot_name $stmt] >= 0} {
      lappend stmts2 [det_save_param_regexp $param $re $idx $urlpart]
    }
    lappend stmts2 $stmt
  } 
  puts $fo [join $stmts2 ";\n"]
  close $fo
  incr gen_file_idx
  file rename $gen_name "$gen_name.$gen_file_idx"
  file rename $temp_name $gen_name
}

# bij maken regexp's:
# single quote vervangen door . Ook met backslash pakt VuGen het niet.
# double quote vervangen door \"
proc make_regexp {pre post} {
  regsub -all {'} $pre "." pre
  regsub -all {'} $post "." post

  regsub -all {\"} $pre "\\\"" pre
  regsub -all {\"} $post "\\\"" post

  set re "${pre}(\[^/\]+?)${post}"
  return $re
}

proc det_snapshot_name {first_name} {
  return "Snapshot=[file rootname $first_name].inf"
}

proc det_save_param_regexp {param re idx urlpart} {
  return "// Added generated param: $param (orig value: $urlpart)
        web_reg_save_param_regexp(\"ParamName=$param\",
            \"RegExp=$re\",
            \"Ordinal=$idx\",
            LAST)"
}

proc find_first_occ {urlpart} {
  set htm_files [find_ordered_htm_files]
  foreach htm_file $htm_files {
    set text [read_file $htm_file]
    if {[string first $urlpart $text] > -1} {
      return [file tail $htm_file]
    }
  }
  return "<not found in htm file>"
}

proc find_ordered_htm_files {} {
  global prj_dir
  set lst [glob -directory [file join $prj_dir data] *.htm*]
  set nrs {}
  foreach el $lst {
    if {[regexp {t(\d+)\.htm} [file tail $el] z nr]} {
      lappend nrs $nr
    }
  }
  set res {}
  foreach nr [lsort -integer $nrs] {
    # set htm_file [file join $prj_dir data "t$nr.htm"]
    set htm_file [:0 [glob -directory [file join $prj_dir data] "t$nr.htm*"]]
    lappend res $htm_file
    # puts $htm_file
  }
  # error "break"
  return $res
}

# @param filename "t27.htm"
# @result login.c
proc find_snapshot {filename} {
  global prj_dir
  if {[regexp {t(\d+)\.htm} $filename z nr]} {
    set needle "Snapshot=t$nr.inf"
    foreach filename [lsort [glob -directory $prj_dir "*.c"]] {
      if {[ignore_file [file tail $filename]]} {
        continue
      }
      set text [read_file $filename]
      if {[string first $needle $text] > -1} {
        return [file tail $filename]
      }
    }
    return "<not found>"
  } else {
    return "<not found>"
  }
}

proc handle_url {url} {
  global urlparams param_idx parprefix
  log debug "handle_url: $url"
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
        # set p_name "p$param_idx"
        # set p_name "par$param_idx"
        set p_name "$parprefix$param_idx"
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
  set keep_res {secureuat-rabobank-com.rabonet.com }
  foreach re $keep_res {
    if {[regexp $re $url]} {
      return 0
    }
  }

  set ignore_res {webanalytics microsoft.com rabonet.com cloudfront.net}
  foreach re $ignore_res {
    if {[regexp $re $url]} {
      return 1
    }
  }
  return 0
}

main $argv
