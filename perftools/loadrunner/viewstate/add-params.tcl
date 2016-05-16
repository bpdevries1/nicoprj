# @todo toevoegen na elke request: web_reg_find("Text=\r\n\tInkomen\r\n", LAST); // check of html goed is.
# @todo addsubtransactions toevoegen, met meteen naam van de action.
# @todo testcode in aparte functies of zelfs aparte file?
package require ndv
package require Tclx
package require struct::list
package require math

::ndv::source_once urlencode.tcl
::ndv::source_once lib.tcl

# 25-7-2011 list of left boundary expression to ignore, i.e. not replace with a param.
# 29-7-2011 Action and Referer were also matched, with . and , also as allowed chars in text.
set LB_IGNORE [list {EVENTTARGET} {URL=} {Action} {Referer}]

set log [::ndv::CLogger::new_logger [file tail [info script]] info]

# globals:
# log 
# ar_html: index: snapshotnummer (zonder t), waarde: html van file, plain, niet decoded of encoded.
# ar_lst_save_param: index: snapshotnummer (zonder t), waarde: list van save-param teksten om _voor_ de action neer te zetten.
# ar_lst_clean_param: index: snapshotnummer (zonder t), waarde: list van clean-param teksten _na_ action neer te zetten.
# ar_paramname: index: full param text, waarde: paramname. Gebruikt voor hergebruik van paramnames.
# ar_last_use: index: paramname, value: snapshot number: in welk snapshot wordt de param voor het laatst gebruikt, zodat 'ie daarna opgeruimd kan worden.
proc main {argc argv} {
  global log ar_lst_save_param ar_argv

  set options {
    {action-inputdir.arg "L:\\LSP\\Force BPR LSP\\VUGen scripts\\1action\\Hypotheek_Aanvraag_1action" "Directory met input files (.c en .aspx)"}
    {html-inputdir.arg "data" "Directory met data files (.htm), relatief tov action-inputdir"}
    {action-outputdir.arg "gen-action" "Directory met gegenereerde files (.c), relatief tov action-inputdir"}
    {min_max_html_param_len.arg "250000" "Minimum waarde van max_html_param_len"} 
    {loglevel.arg "" "Zet globaal log level"}
    {debug "run in debugmode, more logging, breakpoints, also in result files"}
    {deletelog "Delete log before running"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  if {$ar_argv(deletelog)} {
    file delete "[file rootname [file tail [info script]]].log" 
  }
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  $log debug "ar_argv: [array get ar_argv]"
  $log info START

  lees_html [file join $ar_argv(action-inputdir) $ar_argv(html-inputdir)]
  handle_action_dir $ar_argv(action-inputdir) [file join $ar_argv(action-inputdir) $ar_argv(action-outputdir)]

  $log info FINISHED
  ::ndv::CLogger::close_logfile
}

proc lees_html {dir} {
  global ar_html log
  # NdV 15-7-2011 (Parlis-TK) naast .htm ook .html.
  # NdV 15-7-2011 naast .htm en .html ook andere dingen, zoals txt. Hier ook boeiende dingen in?
  # NdV 15-7 in de .inf kijken naar de bestandsnamen: FileName2=t6_activiteit.html
  # de inhoud aan elkaar plakken?
  set fd [open contents-all.txt w]
  foreach filename [glob -directory $dir -type f t*.inf] {
    if {[regexp {t([0-9]+)\.inf} $filename z snapshot]} {
      set ar_html($snapshot) ""
      $log debug "reading inf contents of: $filename"
      set f [open $filename r]
      while {![eof $f]} {
        gets $f line
        if {[regexp {^FileName[0-9]+=(.*)$} $line z filename2]} {
          $log debug "Found filename line: $line, fn2: $filename2"
          if {[is_text_file [file join $dir $filename2]]} {
            $log debug "reading contents of: $filename2"
            set text [read_file [file join $dir $filename2]]
            set ar_html($snapshot) "$ar_html($snapshot)\n$text"
            puts $fd "Contents of: $filename2:"
            puts $fd $text
          }
        }
      }
      close $f
    }
  }
  close $fd
}

proc is_text_file {filename} {
  if {[lsearch -exact [list .htm .html .txt] [string tolower [file extension $filename]]] >= 0} {
    return 1 
  } else {
    return 0 
  }
}

proc handle_action_dir {inputdir gendir} {
  global log
  $log info "handle_action_dir: $inputdir"
  file_delete_dir_contents $gendir
  file mkdir $gendir
  foreach request_c_file [glob -directory $inputdir "*.c"] {
    handle_action_file $request_c_file $gendir
  }
}

proc handle_action_file {request_c_filename gendir} {
  global log max_html_param_len
  $log debug "Handle action file: $request_c_filename"
  set max_html_param_len 0
  set req_text [read_file $request_c_filename]
  set req_text [action_preprocess $req_text]
  set to_subst $req_text
  # 5-11-2010 kan een ) in de call voorkomen, dus specifieker zoeken: ([^\)]*[^\)]*\)[^;])*\);  zie FSM van RE. 
  # zie regexp-fsm.png, gemaakt met http://osteele.com/tools/reanimator/???
  set lst_found [regexp -all -inline -indices {\t[^ \n(]+\(([^\)]*\)[^;])*[^\)]*\);} $to_subst]
  set req_text_substed [build_action_call $to_subst $lst_found handle_action_call_parse] ; # first procedural, later functional
  
  make_ar_lst_clean_param

  set lst_found [regexp -all -inline -indices {\t[^ \n(]+\(([^\)]*\)[^;])*[^\)]*\);} $req_text_substed]
  set req_text_substed [build_action_call $req_text_substed $lst_found handle_action_call_generate] ; # first procedural, later functional

  set req_text_substed [add_web_set_max_html_param_len $req_text_substed]
  
  set f [open [file join $gendir [file tail $request_c_filename]] w]
  puts $f "// Parameters added by [file tail [info script]] [clock format [clock seconds] -format "%d-%m-%Y %H:%M:%S"]\n"
  puts $f [break_lines $req_text_substed]
  close $f
  
  check_gen_file [file join $gendir [file tail $request_c_filename]]
}

# replace found calls with indices in lst_found with the results from handle_action_call_parse
# @param lst_found contains 2 pairs of indices for each match, because a subexpression in the regexp needs parenthesis.
# the subexpression is ignored in the foreach {z var}
proc build_action_call {text lst_found func} {
  set res ""
  set prev_idx_end -1 ; # so first unreplaced string start at index 0
  foreach {el z} $lst_found {
    lassign $el idx_start idx_end
    append res [string range $text $prev_idx_end+1 $idx_start-1]
    append res [$func [string range $text {*}$el]]
    set prev_idx_end $idx_end
  }
  append res [string range $text $prev_idx_end+1 end]
  return $res
}

proc handle_action_call_parse {call} {
  global log lst_valueexchange max_html_param_len
  if {[regexp {web_set_max_html_param_len\(\x22([0-9]+)\x22\);} $call z param_len]} {
    if {$param_len > $max_html_param_len} {
      set max_html_param_len $param_len 
    }
  }

  if {![regexp {Snapshot=t([0-9]+).inf} $call z snapshot]} {
    set snapshot "notfound"
    return $call
  }
  
  # 3-11-2010 base64 tekens (incl /+ en =, maar wel url encoded, dus ook met %
  # maar niet alles url-encoded.
  # 3-11-2010 iets kleiner dan 78, maar mogelijk nu ook te veel.
  # 5-11-2010 nu een eventvalidation met lengte 64, dus even op 60 zetten.
  # 16-7-2011 NdV in LB wil ik ook geen \t, naast de \n, ampersand en vraagteken. Ook in RB geen tab.
  # 21-7-2011 NdV voor TK-VLOS beurtstarttijd en anderen nodig, kijken hoe het gaat met 15 ipv 60 minimum.
  # 21-7-2011 NdV voor TK-VLOS ook tijden, met spatie, streepje en dubbele punt.
  # 28-7-2011 \x22 is een dubbele quote, kan jedit beter mee.
  # 29-7-2011 line below was not found, can also have a comma (,) in the text. And then a dot (.) is possiby possible also.
  # {REQUESTDIGEST", "Value=0x864E5021} 
  # set lst [regexp -all -inline -indices {([^\n\t&?]{1,40}[='\x22])([a-zA-Z0-9%/+ :-]{15,}=*)([\x22'&][^\n\t]{1,4})} $call]
  # set lst [regexp -all -inline -indices {([^\n\t&?]{1,40}[='\x22])([a-zA-Z0-9%/+ :.,-]{15,}=*)([\x22'&][^\n\t]{1,4})} $call]
  # Ziggo: ook accolades:
  set lst [regexp -all -inline -indices {([^\n\t&?]{1,40}[='\x22])([a-zA-Z0-9%/+ :.,\{\}-]{15,}=*)([\x22'&][^\n\t]{1,4})} $call]
  set call_text_substed [build_params_in_call $call $lst $snapshot] ; # first procedural, later functional
  return $call_text_substed
}

# @param lst: for each matched item, 4 pairs of start end: whole, lb, text, rb
proc build_params_in_call {call lst_found snapshot} {
  global log
  set res ""
  set prev_idx_end -1 ; # so first unreplaced string start at index 0
  
  # REQUESTDIGEST not always recognised?
  if {$snapshot == -10} {
    foreach {all_el lb_el text_el rb_el} $lst_found {
      lassign $all_el idx_start idx_end
      $log debug "### snapshot: $snapshot; text: [string range $call {*}$all_el]" 
    }
  }
  
  foreach {all_el lb_el text_el rb_el} $lst_found {
    lassign $all_el idx_start idx_end
    append res [string range $call $prev_idx_end+1 $idx_start-1]
    append res [replace_with_param $snapshot [string range $call {*}$lb_el] [string range $call {*}$text_el] [string range $call {*}$rb_el]]
    set prev_idx_end $idx_end
  }
  append res [string range $call $prev_idx_end+1 end]
  return $res  
}

# @note 28-7-2011 NdV if value is not found, back out of replacing with param, keep the original text.
# @param lb_action, rb_action: left and right boundaries in the action.c file (not the html!)
proc replace_with_param {snapshot lb_action text rb_action} {
  global log ar_html ar_lst_save_param ar_paramname ar_last_use ar_argv
  # @todo ar_paramname uit de global list halen, zoals hieronder.
  # global log ar_html ar_lst_save_param ar_last_use ar_argv
  $log debug "replacing text with param in t$snapshot, LB=$lb_action, RB=$rb_action"
  if {[string length $text] < 40} {
    $log debug "text: $text" 
  } else {
    $log debug "text plain  : [string range $text 0 20]...[string range $text end-20 end]" 
    $log debug "text decoded: [string range [url-decode $text] 0 20]...[string range [url-decode $text] end-20 end]"
  }
  if {[lb_ignore $lb_action]} {
    # 29-7-2011 NdV tried with lb and rb, and this is correct, fixed a bug. Was: just $text 
    return "$lb_action$text$rb_action"
  }
  if {$snapshot == 11} {
    # breakpoint 
    set fd [open "param-text-11.txt" a]
    puts $fd "lb: $lb_action"
    puts $fd "text:"
    puts $fd $text
    puts $fd "text decoded:"
    puts $fd [url-decode $text]
    close $fd
  }
  if {(($snapshot == 7) || ($snapshot == 6)) && ([regexp REQUESTDIGEST $lb_action])} {
    set f [open "parray.txt" a]
    puts $f "Contents at snapshot $snapshot: #elements: [llength [array names ar_paramname]]"
    $log debug "Contents at snapshot $snapshot: #elements: [llength [array names ar_paramname]]"
    foreach el [lsort [array names ar_paramname]] {
      puts $f "$el: $ar_paramname($el)" 
    }
    # breakpoint 
  }
  
  set html_snapshot 1
  while {$html_snapshot < $snapshot} {
    if {[array get ar_html $html_snapshot] != {}} {
      if {[string first $text $ar_html($html_snapshot)] >= 0} {
        $log debug "value of param found in snapshot $html_snapshot"
        return [do_replace_with_param $lb_action $rb_action $html_snapshot $snapshot plain $text]
      } elseif {[string first [url-decode $text] $ar_html($html_snapshot)] >= 0} {
        $log debug "value of param found in snapshot $html_snapshot"
        return [do_replace_with_param $lb_action $rb_action $html_snapshot $snapshot encoded [url-decode $text]]
      }
    } else {
      # geen snapshot van deze. 
    }
    incr html_snapshot 
  }
  
  # breakpoint ; # zou niet voor mogen komen.
  if {$ar_argv(debug)} {
    $log warn "breakpoint in replace_with_param, zou niet voor mogen komen."
    breakpoint
    return "$lb_action{In t$snapshot text not found: LB=$lb_action *** RB=$rb_action *** text=$text}$rb_action"
  } else {
    $log warn "param value not found: $text (lb=$lb_action, rb=$rb_action)"
    return "$lb_action$text$rb_action"
  }
}

proc lb_ignore {lb_action} {
  global LB_IGNORE
  foreach re $LB_IGNORE {
    if {[regexp $re $lb_action]} {
      return 1 
    }
  }
  return 0
}

# @note 28-7-2011 NdV if value is not found, back out of replacing with param, keep the original text.
# @note 28-7-2011 NdV method name should be different, do_X implies there is no backing out.
proc do_replace_with_param {lb_action rb_action html_snapshot snapshot enctype text} {
  # global log ar_lst_save_param ar_html ar_paramname ar_last_use max_html_param_len ar_argv
  global log ar_lst_save_param ar_html ar_last_use max_html_param_len ar_argv
  $log debug "do_replace_with_param: $lb_action *** $html_snapshot *** $snapshot *** $enctype"
  
  set ordinal 1
  set is_new 0
  lassign [det_lb_rb_html $text $ar_html($html_snapshot) "dummy" $enctype] lb rb z
  set index [det_index_lb_rb $text $ar_html($html_snapshot) $lb $rb]
  if {$index == -1} {
    $log warn "Backing out of replacing text with param: $lb_action, $rb_action, $html_snapshot, $snapshot"
    return "$lb_action$text$rb_action"
  } 
  lassign [det_paramname $lb_action $rb_action $enctype $html_snapshot $ordinal] paramname is_new
  
  if {$ar_argv(debug)} {
    if {$snapshot == 11} {
      $log debug "do_replace_with_param, snapshot 11: breakpoint"
      breakpoint 
    }
  }
  if {$paramname != ""} {
    set ar_last_use($paramname) $snapshot
    $log debug "set initial ar_last_use($paramname) to $snapshot"
    if {$is_new} {
      lappend ar_lst_save_param($html_snapshot) [det_save_param_cmd $html_snapshot $snapshot $paramname $enctype $text $ar_html($html_snapshot)] 
      if {[string length $text] > $max_html_param_len} {
        set max_html_param_len [string length $text] 
        $log debug "set max_html_param_len to $max_html_param_len"
      }
    }
    return "$lb_action{$paramname}$rb_action"
  } else {
    $log warn "no paramname found, return the same"
    return "$lb_action$text$rb_action"
  }
}

proc make_ar_lst_clean_param {} {
  global ar_lst_clean_param ar_last_use
  foreach paramname [array names ar_last_use] {
    lappend ar_lst_clean_param($ar_last_use($paramname)) "\tlr_save_string(\"\", \"$paramname\"); // free memory"
  }
}

# @note input text bevat soms ook al newlines en afgebroken strings, deze eerst weer samenvoegen.
# oorspronkelijk vugen linebreaks verwijderen
proc action_preprocess {req_text} {
  global log
 	regsub -all {\x22\n[ \t]+\x22} $req_text "" req_text
  return $req_text
}

proc det_paramname {lb_action rb_action enctype html_snapshot ordinal} {
  global ar_paramname log
  # breakpoint
  if {[array get ar_paramname "$lb_action***$rb_action***$enctype***$html_snapshot***$ordinal"] == {}} {
    set ar_paramname($lb_action***$rb_action***$enctype***$html_snapshot***$ordinal) [det_new_paramname $lb_action]
    set is_new 1
  } else {
    set is_new 0 
  }
  if {[array get ar_paramname "$lb_action***$rb_action***$enctype***$html_snapshot***$ordinal"] == {}} {
    $log debug "ar_paramname just set, but not found now, breakpoint"
    breakpoint
  }
  $log debug "returning paramname for: $lb_action***$rb_action***$enctype***$html_snapshot***$ordinal"
  set value [lindex [array get ar_paramname "$lb_action***$rb_action***$enctype***$html_snapshot***$ordinal"] 1]
  $log debug "value = $value"
  # list $ar_paramname("$lb_action***$rb_action***$enctype***$html_snapshot***$ordinal") $is_new
  list $value $is_new
}  

proc det_paramname_old {lb_action rb_action enctype html_snapshot ordinal} {
  global ar_paramname log
  # breakpoint
  if {[array get ar_paramname "$lb_action***$rb_action***$enctype***$html_snapshot***$ordinal"] == {}} {
    set ar_paramname($lb_action***$rb_action***$enctype***$html_snapshot***$ordinal) [det_new_paramname $lb_action]
    set is_new 1
  } else {
    set is_new 0 
  }
  if {[array get ar_paramname "$lb_action***$rb_action***$enctype***$html_snapshot***$ordinal"] == {}} {
    $log debug "ar_paramname just set, but now found now, breakpoint"
    breakpoint
  }
  $log debug "returning paramname for: $lb_action***$rb_action***$enctype***$html_snapshot***$ordinal"
  $log debug "value = [array get ar_paramname "$lb_action***$rb_action***$enctype***$html_snapshot***$ordinal"]"
  list $ar_paramname($lb_action***$rb_action***$enctype***$html_snapshot***$ordinal) $is_new
}  

proc det_new_paramname {lb} {
  global log
  $log debug "det_new_paramname: lb=$lb"

  global ar_paramname_next log
  if {[regexp -nocase valueExchange $lb]} {
    return "cValueExchange[incr ar_paramname_next(valueexchange)]"
  }
  if {[regexp -nocase viewstate $lb]} {
    return "cViewState[incr ar_paramname_next(viewstate)]"
  }
  # 17-7-2011 blijkbaar soms ook entvalidation, missen de eerste 2 letters.
  if {[regexp -nocase entvalidation $lb]} {
    return "cEventValidation[incr ar_paramname_next(eventvalidation)]"
  }
  if {[regexp {([0-9a-zA-Z]{3,}).$} $lb z pname]} {
    return "c$pname[incr ar_paramname_next($pname)]"
  } else {
    return "cOther[incr ar_paramname_next(other)]"
  }
}

# @param enctype: plain, encoded
# @param text is encoded als enctype=encoded
# @pre text is gevonden in html
# @sideeffects: unknown (28-7-2011)
proc det_save_param_cmd {snapshot_html snapshot_action paramname enctype text html} {
  global log
  # breakpoint
  lassign [det_lb_rb_html $text $html $paramname $enctype] lb rb pos
  $log debug "param_cmd: $paramname, LB=$lb, RB=$rb, partial text: [string range $html [expr $pos+[string length $text]-10] [expr $pos+[string length $text]+10]]"
  # @todo remove here, and get from param, should already be determined.
  set index [det_index_lb_rb $text $html $lb $rb]
  # breakpoint
  return "\t// get from snapshot t$snapshot_html, use in snapshot t$snapshot_action
	web_reg_save_param(\"$paramname\", 
		\"LB/IC=[escape_quotes $lb]\", 
		\"RB/IC=[escape_quotes $rb]\", 
		\"Ord=$index\", 
		\"Search=Body\", 
		\"RelFrameId=1\",[det_convert_string $enctype] 
		LAST);"    
}


# determine left and right boundaries of text in html
# @param text: text in the html (the needle)
# @param html: the html to search in (the haystack)
proc det_lb_rb_html {text html paramname enctype} {
  global log
  # eerst LB en RB bepalen
  set pos [string first $text $html]
  if {$pos < 0} {
    $log error "text niet in html gevonden, is preconditie! ($paramname $enctype)"
    error "text niet in html gevonden, is preconditie!"
  }
  # NdV 4-11-2010 LB zoeken van max 40 ipv 22. Dan specifiekere LB voor valueexchange: StatusOvergangDialog.aspx?valueExchange=
  if {![regexp {([^\n]+)$} [string range $html $pos-40 $pos-1] z lb]} {
    $log warn "lb not found"
    $log warn "breakpoint in det_save_param_cmd (1), zou niet voor mogen komen."

    breakpoint 
  }
  if {![regexp {([^\n]{1,4})} [string range $html [expr $pos+[string length $text]] [expr $pos+[string length $text]+5]] z rb]} {
    $log warn "rb not found"
    $log warn "breakpoint in det_save_param_cmd (2), zou niet voor mogen komen."
    breakpoint 
  }
  $log debug "param_cmd: $paramname, LB=$lb, RB=$rb, partial text: [string range $html [expr $pos+[string length $text]-10] [expr $pos+[string length $text]+10]]"
  set lb [process_lb $lb]
  list $lb $rb $pos  
}

# LB bij eventValidation soms te groot, met stukken van viewstate erin. Deze verwijderen.
#	"LB/IC=qf8MTThkUsspTT1XRW0\",\"eventValidation\":\"", 
proc process_lb {lb} {
  if {[regexp {(eventValidation.*)$} $lb z lb2]} {
    return $lb2
  } else {
    return $lb
  }    
}

proc det_convert_string {enctype} {
  if {$enctype == "plain"} {
    return "" 
  } else {
    return "\n\t\t\"Convert=HTML_TO_URL\"," 
  }
}

# volgende sequence kan voorkomen (val.exch t81->t82) : LB...LB...LB<text>RB. door searchpos tot voorbij de RB te zetten, wordt de volgende niet gevonden.
# kan wel anders zoeken, maar vraag is hoe VuGen hier mee omgaat.
# alternatieven:
# - grotere LB, die wel uniek is. => deze vooralsnog gekozen.
# - testen met VuGen, misschien wel goed.
# - hele html in een param, hier zelf mee zoeken.
# - [27-07-2011 NdV] voor VLOS (TK) was dit nodig, nu voorbij de LB zoeken, ipv RB, gaat hier goed.
# @todo nog wel bug, ord=9 wordt gezet, klopt niet, want is eerste match waarbij LB en RB kloppen.
# @note vraag: hoe gaat huidige RMM_functie hier mee om? => zoekt LB en eerst voorkomende RB, dus zou ook fout gaat.
# @return index, mostly 1, -1 if not found and not debugging. Breakpoint and error if debugging.
# @param lb, rb: left and right boundaries as found in HTML.
proc det_index_lb_rb {text html lb rb} {
  global log ar_argv
  set find_from 0
  set lb_length [string length $lb]
  set index 0
  set found_index -1
  while {1} {
    set lb_pos [string first $lb $html $find_from]
    if {$lb_pos < 0} {
      break 
    }
    set rb_pos [string first $rb $html [expr $lb_pos + $lb_length]]
    if {$rb_pos < 0} {
      break
    }
    incr index
    set found_text [string range $html [expr $lb_pos + $lb_length] $rb_pos-1]
    if {[string compare $text $found_text] == 0} {
      set found_index $index
      break 
    }
    # 27-07-2011 NdV kan een structuur LB...LB....LB...LBTextRB zijn, dus find-from niet na de RB doen, maar na de LB!
    # 27-07-2011 NdV wel de vraag of Loadrunner dit ook zo matcht...
    # set find_from [expr $rb_pos + [string length $rb_pos]]
    set find_from [expr $lb_pos + [string length $lb_pos]]
  }
  if {$found_index < 0} {
    $log error "Tekst ineens niet meer gevonden: LB=$lb, RB=$rb, text=$text, html=$html"
    if {$ar_argv(debug)} {
      $log warn "breakpoint in det_index_lb_rb, zou niet voor mogen komen."
      breakpoint
      error "Tekst ineens niet meer gevonden: LB=$lb, RB=$rb"
    } else {
      return -1 
    }
  }
  if {$found_index > 1} {
    $log info "Index groter dan 1 ($found_index) bij LB=$lb en RB=$rb" 
    # breakpoint
  }
  return $found_index
}

# replace " with \" and \ with \\
proc escape_quotes {str} {
  # 5-11-2010 NdV \ ook escape als dubbele
  string map {\x22 \\\x22 \\ \\\\} $str
}

# delete files in dir, but not dir itself.
# not recursive for now.
proc file_delete_dir_contents {gendir} {
  foreach filename [glob -nocomplain -directory $gendir -type f *] {
    file delete -force $filename 
  }
}

proc handle_action_call_generate {call} {
  global log lst_valueexchange ar_lst_save_param ar_lst_clean_param max_html_param_len ar_argv
  if {[regexp {web_set_max_html_param_len\(\x22([0-9]+)\x22\);} $call z param_len]} {
    set max [math::max $ar_argv(min_max_html_param_len) [expr round(1.2 * $max_html_param_len)]]
    return "\tweb_set_max_html_param_len\(\"$max\"\); // calculated max with minimum of $ar_argv(min_max_html_param_len)" 
  }
  # lr_think_time: dit is een transaction-boundary, deze dus aanmaken: wel met // zodat script goed blijft gaan.
  if {[regexp lr_think_time $call]} {
    return "\t// lr_end_transaction(\"\",LR_AUTO);\n\n$call\n\n\t// lr_start_transaction(\"\");"
  }  
  if {![regexp {Snapshot=t([0-9]+).inf} $call z snapshot]} {
    set snapshot "notfound"
    return $call
  }
  set res $call
  if {[array get ar_lst_save_param $snapshot] != {}} {
    set res "[join $ar_lst_save_param($snapshot) "\n\n"]\n\n$res"
  }
  if {[array get ar_lst_clean_param $snapshot] != {}} {
    set res "$res\n\n[join $ar_lst_clean_param($snapshot) "\n"]"
  }
  return $res
}

proc add_web_set_max_html_param_len {text} {
  global max_html_param_len ar_argv
  if {[regexp web_set_max_html_param_len $text]} {
    return $text ; # already there, return 
  } else {
    # add as first statement in main function, i.e. after first brace
    set max [math::max $ar_argv(min_max_html_param_len) [expr round(1.2 * $max_html_param_len)]]
    regsub {\{} $text "\{\n\tweb_set_max_html_param_len\(\"$max\"\); // calculated max with minimum of $ar_argv(min_max_html_param_len)"
  }
}

# check of alle voorkomens van viewstate, eventvalidation en valueexchange met een param zijn.
# @todo moet eigenlijk weer verdelen in calls, en web_reg_save_param overslaan, maar wil deze check juist 
# heel simpel, niet dezelfde eventuele fouten maken als bij parsen van de tekst, controle moet andere techniek gebruiken.
proc check_gen_file {filename} {
  global log ar_argv
  $log info "CHECK_GEN_FILE: $filename"
  set text [read_file $filename]
  $log debug "len text: [string length $text]"
  foreach keyword {eventvalidation requestdigest valueexchange viewstate} {
    # 27-7-2011 NdV hd max 15 tekens tussen keyword en de =, teruggebracht naar 3, dan geen false positive (hopelijk alle negatives nog wel)
    # 28-7-2011 NdV Soms (zie onder bij req.digest) toch ook 9 chars ertussen.
		# "Name=__REQUESTDIGEST", "Value=0xF5A1F0D0DA3B7B92B0B0961DF6F9124477186E93274CF9EECD5430AD37B1B7FB532D2EB3BE642C5802DE7159EA38A42A1220534D09C6C3101F9B4F41D91712A9,27 Jul 2011 06:55:14 -0000", ENDITEM, 
    foreach {ind_whole ind_str} [regexp -inline -all -indices -nocase -- "$keyword\[^=:\n\]{0,9}\[=:\](\[^\n\]{15})" $text] {
      if {[regexp {[{}]} [string range $text {*}$ind_str]]} {
        # mooi, accolade duidt op parameter gebruik. 
      } else {
        set str_whole [string range $text {*}$ind_whole]
        set str_value [string range $text {*}$ind_str]
        if {[regexp {__VIEWSTATE} $str_value]} {
          # VIEWSTATE\" id=\"__VIEWSTATE\"
          # @note exception: this line is part of a web_reg_save_param, not an error 
        } else {
          $log warn "value without param in line [llength [split [string range $text 0 [lindex $ind_whole 0]] "\n"]]: $str_whole"
          if {$ar_argv(debug)} {
            breakpoint
          }
        }
      }
    }
  }
}

# vervang lange 'body' regels door een aantal kortere, waarbij de line-breaks gedaan worden bij ampersands (&)
proc break_lines {text} {
  set lres {}
  foreach line [split $text "\n"] {
    if {[regexp {Body=} $line] && [string length $line] > 100} {
      lappend lres [join [split $line "&"] "\"\n\t\t\"&"]
    } else {
      lappend lres $line 
    }
    # breakpoint
  }
  return [join $lres "\n"]
}

main $argc $argv

