package require ndv
package require Tclx
package require struct::list

::ndv::source_once urlencode.tcl
::ndv::source_once lib.tcl

# @todo soms met herformattering alleen een & op een regel. Hoe komt dit en hier goed mee omgaan.

# DONE
# @todo rdl_ kan ook als prefix voorkomen bij radioButtonList -> andere opzet gekozen.
# @todo prefixes sowieso variabel: soms met underscore, soms ook niet. Alles incl underscore verwijderen, en standaard prefixen.

# evt todo
# @todo met web_reg_save_param mee kunnen geven de hoeveelste occurence gebruikt moet worden? -> dit kan.

set log [::ndv::CLogger::new_logger [file tail [info script]] info]

set PARAM_TYPES {dropDownList radioButtonList textBox}
set PARAM_PREFIX "pgen_"

proc main {argc argv} {
  # global log ar_argv
  global log

  $log debug "argv: $argv"
  set options {
    {inputdir.arg "input" "Directory met input files (.c en .aspx)"}
    {outputdir.arg "gen" "Directory met gegenereerde files (.c)"}
    {preprocess.arg "auto" "Zet elke parameter op een aparte regel in reqsrc/reqgen (yes, no, auto)"}
    {loglevel.arg "" "Zet globaal log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  $log debug "ar_argv: [array get ar_argv]"
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  $log info START

  handle_dir $ar_argv(inputdir) $ar_argv(outputdir) $ar_argv(preprocess)

  $log info FINISHED
  ::ndv::CLogger::close_logfile
}

proc handle_dir {inputdir gendir preprocess} {
  foreach request_c_file [glob -nocomplain -directory $inputdir "*.c"] {
    handle_file $request_c_file $gendir $preprocess
  }
}

# @todo bepalen of preprocess nodig is.
proc handle_file {request_c_filename gendir preprocess} {
  global ar_argv log html_text lst_calls
  # global ar_argv log lst_calls
  # set req_text [read_file $ar_argv(reqsrc)]
  set req_text [read_file $request_c_filename]
  if {$preprocess == "auto"} {
    set preprocess [det_preprocess $request_c_filename]
  }
  
  if {$preprocess == "yes"} {
    set req_text [preprocess $req_text]
  }
  # set html_text [read_file $ar_argv(html)]
  set html_filename [det_html_filename $request_c_filename]
  if {![file exists $html_filename]} {
    $log warn "File does not exist: $html_filename, returning"
    return
  }
  set html_text [read_file $html_filename]

  set lst_calls {}
  
  # @note zowel quote als ampersand escapen, anders krijg je dubbele quotes...
  regsub -all {\"&([^"=]+=[^"]*\")} $req_text {\"\&[replace_with_param \1]} req_text_replaced1 ; # "

	# web_submit_data
  #	"Name=ctl00$ctl00$ctl00$PopupContent$Content$ColumnLeft$ddl_onderpand$dropDownList", "Value=10000022", ENDITEM,
  # naar replace_with_param_wsd: "Name=ctl00$ctl00$ctl00$PopupContent$Content$ColumnLeft$ddl_onderpand$dropDownList", "Value=10000022", ENDITEM,
  regsub -all {(\"Name=[^"=]+\", +\"Value=[^"]*\", +ENDITEM,)} $req_text_replaced1 {[replace_with_param_wsd {\1}]} req_text_replaced2 ; # "

  # @note vraag of dit lukt, met hele html_text meegeven aan replace_with_param
  # @todo werkt nu niet, want subst_no_vars, dus $html_text wordt eerst vervangen door \004html_text. Niet direct een oplossing.
  # regsub -all {\"&([^"=]+=[^"]*\")} $req_text {\"\&[replace_with_param \1 $html_text]} req_text_replaced ; # "
  $log debug "req_text_replaced2: $req_text_replaced2"
  set req_text_substed [subst_no_variables $req_text_replaced2]
  $log debug "req_text_substed: $req_text_substed"

  set funname [det_funname $req_text]
  
  # set fr [open $ar_argv(reqgen) w]
  set fr [open [det_req_gen_filename $request_c_filename $gendir] w]
  puts $fr "  ${funname}();\n"
  puts $fr $req_text_substed
  puts $fr "\n[call_dropDownList_functions $lst_calls]"
  close $fr
  
  # regsub {\*} $ar_argv(fungen) $funname fungen
  # set ff [open $ar_argv(fungen) w]
  # set ff [open $fungen w]
  set ff [open [det_fun_gen_filename $funname $gendir] w]
  output_function $ff $lst_calls $funname
  close $ff
}

proc det_html_filename {request_c_filename} {
  file join "[file rootname $request_c_filename].aspx"
}

proc det_req_gen_filename {request_c_filename gendir} {
  file join $gendir [file tail $request_c_filename]
}

proc det_fun_gen_filename {funname gendir} {
  file join $gendir "${funname}.c"
}

# @note determine if file needs to be preprocessed, i.e. if newlines and quotes need to be added
proc det_preprocess {request_c_filename} {
  global log
  set text [read_file $request_c_filename]
  if {[regexp {\"\n[ \t]+\"\&} $text]} {
    $log info "$request_c_filename: found quote-newline-quote-ampersand, no preprocessing needed"
    return "no"
  } elseif {[regexp {web_submit_data} $text]} {
    $log info "$request_c_filename: found web_submit_data, no preprocessing needed"
    return "no" 
  } else {
    $log info "$request_c_filename: need to preprocess this file"
    return "yes"
  }
}

# @param line: ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$ddlTypeContractant$dropDownList=HOOFDELIJKE_AANSPRAKELIJKE"
# param_name := pTypeContractant
# @note bij aanroep van deze proc zijn in fullname de $ door \004 vervangen.
# @note line eindigt nu met ", zodat comment er ook achter kan.
# @todo html_text weer als param meegeven.
# @todo lst_calls ook ala param?
proc replace_with_param {line {html_text2 ""}} {
  global log lst_calls html_text
  # global log lst_calls
  # $log debug "html_text: $html_text"
  
  regsub -all "\004" $line "\$" line
  if {![regexp {^([^=]+)=(.*)\"$} $line z fullname value]} {
    # "name bestaat uit stukken gescheiden  door $. Kies de laatste die niet een standaard naam als dropDownList heeft.
    error "Not a valid param=value expression: $line"
  }
  if {![regexp {^ctl00} $fullname]} {
    return $line
  }
  if {[regexp "\{" $value]} {
    # niet aanpassen, is al een parameter
    return $line
  }
  # set paramname [det_paramname $fullname]
  lassign [det_paramname_type $fullname] paramname paramtype
  lassign [find_param_$paramtype $fullname $paramname $value $line $html_text] find_result comment reqline lst_boundaries
  
  if {$find_result} {
    foreach boundary $lst_boundaries {
      lassign $boundary LB RB srcline
      lappend lst_calls [list $paramname $paramtype $LB $RB $comment $reqline $srcline]
    }
    set result "$fullname={$paramname}\" // value: $value"
  } else {
    # $log debug "no source found for: $line, change nothing"
    # return $line
    if {$value == ""} {
      set result "$fullname={$paramname}\" // empty value, param not found, add parameter manually!"
    } else {
      set result "$fullname={$paramname}\" // value: $value: not found in source html! Add parameter manually!"
    }
  }
  $log debug "replace_with_param: line: $line, result: $result"
  return $result
} ; # accolade matched wel, door quote niet goed.

# Versie voor web_submit_data
# @param line: "Name=ctl00$ctl00$ctl00$PopupContent$Content$ColumnLeft$ddl_onderpand$dropDownList", "Value=10000022", ENDITEM,
# param_name := pTypeContractant
# @note bij aanroep van deze proc zijn in fullname de $ door \004 vervangen.
# @note line eindigt nu met ", zodat comment er ook achter kan.
# @todo html_text weer als param meegeven.
# @todo lst_calls ook ala param?
proc replace_with_param_wsd {line {html_text2 ""}} {
  global log lst_calls html_text
  # global log lst_calls
  # $log debug "html_text: $html_text"
  
  regsub -all "\004" $line "\$" line
  if {![regexp {\"Name=([^"=]+)\", +\"Value=([^"]*)\", ENDITEM,} $line z fullname value]} {
    # "name bestaat uit stukken gescheiden  door $. Kies de laatste die niet een standaard naam als dropDownList heeft.
    error "Not a valid param=value expression: $line"
  }
  if {![regexp {^ctl00} $fullname]} {
    $log debug "replace_with_param_wsd: line: $line, fullname: $fullname, returning"
    return $line
  }
  if {[regexp "\{" $value]} {
    # niet aanpassen, is al een parameter
    return $line
  }
  # set paramname [det_paramname $fullname]
  lassign [det_paramname_type $fullname] paramname paramtype
  lassign [find_param_$paramtype $fullname $paramname $value $line $html_text] find_result comment reqline lst_boundaries
  
  if {$find_result} {
    foreach boundary $lst_boundaries {
      lassign $boundary LB RB srcline
      lappend lst_calls [list $paramname $paramtype $LB $RB $comment $reqline $srcline]
    }
    # return "$fullname={$paramname}\" // value: $value"
    set result "\"Name=$fullname\", \"Value={$paramname}\", ENDITEM,  // value: $value"
  } else {
    # $log debug "no source found for: $line, change nothing"
    # return $line
    if {$value == ""} {
      # return "$fullname={$paramname}\" // empty value, param not found, add parameter manually!"
      set result "\"Name=$fullname\", \"Value={$paramname}\", ENDITEM,  // empty value, param not found, add parameter manually!"
    } else {
      # return "$fullname={$paramname}\" // value: $value: not found in source html! Add parameter manually!"
      set result "\"Name=$fullname\", \"Value={$paramname}\", ENDITEM,  // value: $value: not found in source html! Add parameter manually!"
    }
  }
  $log debug "replace_with_param_wsd: line: $line, result: $result"
  return $result
} ; # accolade matched wel, door quote niet goed.

# @return [list paramname paramtype]
proc det_paramname_type {fullname} {
  global log PARAM_TYPES PARAM_PREFIX
  set lst [lreverse [split $fullname "$"]]
  if {[llength $lst] >= 2} {
    lassign $lst paramtype paramname ; # rest van de lijst wordt niet toegekend aan vars. 
  } else {
    error "No good param name found: $fullname"
    $log debug "No good param name found, return fullname: $fullname"
    set paramtype "unknown"
    set paramname $fullname
  }
  # korte prefix met underscore ook verwijderen
  regsub {^(.{1,3}_)} $paramname "" paramname
  regsub {^(ddl)|(rbl)|(tb)} $paramname "" paramname
  return [list "${PARAM_PREFIX}$paramname" $paramtype]
}

# @return [list result LB RB]
# return > 0 als gevonden, LB en RB dan gevuld.
# de lastigste, oplossen met hulp C functie (van Pim/Raymond)
proc find_param_dropDownList {fullname paramname value reqline html_text} {
  global log 
  # in eerste instantie niet gevonden.
  # return [list 0 "Niet gezocht, type param ddl (fullname=$fullname)" $reqline {}]
  if {0} {
  <select name="ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$ddlTypeContractant$dropDownList" id="ctl00_ctl00_ctl00_PageContent_PageContent_ColumnLeft_ddlTypeContractant_dropDownList" class="dropdownlist" onchange="javascript:Anthem_FireCallBackEvent(this,event,'ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$ddlTypeContractant$dropDownList','',false,'','','',true,PageChanged,null,null,true,true);return false;">
		<option selected="selected" value="HOOFDELIJKE_AANSPRAKELIJKE">Hoofdelijk aansprakelijke</option>
		<option value="ERVEN">Erven van</option>
		<option value="VERZEKERDE">Verzekeringsnemer / verzekerde</option>
		<option value="BEGUNSTIGDE">Begunstigde</option>

	</select>  
  }
  # value niet zoeken, maar hele stuk tussen <select> en </select> teruggeven.
  set lst_boundaries {}
  lappend lst_boundaries [list "<select name=\"${fullname}\"" "</select>" "ddl: standaard"]
  return [list 1 "ddl: gebruik standaard LB en RB en roep C-functie aan" $reqline $lst_boundaries]  
}

# @return [list result LB RB]
# return > 0 als gevonden, LB en RB dan gevuld.
proc find_param_radioButtonList {fullname paramname value reqline html_text} {
  global log 
  # vorige oplossing was niet goed, moet ook met RB kijken naar selected
  # name="ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$rblPersoneel$radioButtonList" value="False" checked="checked"
  set lst_boundaries {}
  lappend lst_boundaries [list "name=\"${fullname}\" value=\"" "\" checked=\"checked\"" "rbl: standaard"]
  return [list 1 "rbl: gebruik standaard LB en RB" $reqline $lst_boundaries]  
}

# @return [list result LB RB]
# return > 0 als gevonden, LB en RB dan gevuld.
proc find_param_textBox {fullname paramname value reqline html_text} {
  global log 
  # eerst zoeken op oude manier, met value
  set res [find_param_value $fullname $paramname $value $reqline $html_text]
  lassign $res find_result comment reqline lst_boundaries
  if {$find_result} {
    return $res 
  }
  # standaard constructie, wel in comment vermelden.
  set lst_boundaries {}
  lappend lst_boundaries [list "name=\"${fullname}\" type=\"text\" value=\"" "\"" "Geen source line"]
  if {$value == ""} {
    return [list 1 "textBox value is leeg, gebruik standaard LB" $reqline $lst_boundaries]
  } else {
    return [list 1 "textBox value ($value) niet gevonden, gebruik standaard LB" $reqline $lst_boundaries]
  }
}

proc unknown {args} {
  global log
  $log warn "unknown called with args: $args"
  set procname [lindex $args 0]
  if {[regexp {^find_param_} $procname]} {
    find_param_unknown {*}[lrange $args 1 end] 
  } else {
    # eigenlijk de oorspronkelijk unknown gebruiken.
    error "unknown called with args: $args"
  }
}

# @return [list result LB RB]
# return > 0 als gevonden, LB en RB dan gevuld.
proc find_param_unknown {fullname paramname value reqline html_text} {
  global log 
  $log warn "Niet gevonden, type param onbekend (fullname=$fullname): $$reqline"
  return [list 0 "Niet gevonden, type param onbekend (fullname=$fullname)" $reqline {}]
}

# @return [list result LB RB]
# return > 0 als gevonden, LB en RB dan gevuld.
# als value leeg is, dat meteen 0 retourneren.
proc find_param_value {fullname paramname value reqline html_text} {
  global log PARAM_PREFIX
  # eerst alleen aantal keer gevonden.
  # @todo checken op standaard waarden als false etc.
  set result 0
  set lst_boundaries {}
  if {$value == ""} {
    return [list 0 "Value is leeg" $reqline $lst_boundaries] 
  }
  # en wordt zo alles gevonden?
  set decoded_value [url-decode $value]
  set lst [regexp -all -inline "(\[^\n\]{2,100})${decoded_value}(\[^\n\]{1,1})" $html_text]
  set n_found 0
  foreach {srcline LB RB} $lst {
    set result 1
    incr n_found
    lappend lst_boundaries [list $LB $RB $srcline] 
  }
  # kijk of param name voorkomt in een van de LB's
  # set paramname2 [string range $paramname 1 end] ; # weer zonder initiele 'p'
  set paramname2 [string range $paramname [string length $PARAM_PREFIX] end] ; # weer zonder initiele 'pgen_'
  set lst_boundaries2 [struct::list filterfor el $lst_boundaries {
    [regexp $paramname2 [lindex $el 0]] > 0
  }]
  if {[llength $lst_boundaries2] == 1} {
    set comment "Aantal gevonden voor $paramname: $n_found => 1 met LB ~ $paramname2"
    set lst_boundaries $lst_boundaries2
  } else {
    set comment "Aantal gevonden voor $paramname: $n_found => [llength $lst_boundaries2] met LB ~ $paramname2"
  }
  
  # check of LB's meerdere keren voorkomen.
  foreach boundary $lst_boundaries {
    set LB [lindex $boundary 0]
    # $log debug "LB: $LB"
    set n [regexp -all $LB $html_text]
    if {$n > 1} {
      append comment "\nLB occurs more than once (#$n): $LB"
    }
  }
  
  list $result $comment $reqline $lst_boundaries
}

proc output_function {ff lst_calls funname} {
  global ar_argv
  puts $ff "${funname}()
{"
	foreach call $lst_calls {
    lassign $call param_name paramtype LB RB comment reqline srcline
    # multiline comments regelen:
    regsub -all "\n" $comment "\n  // " comment
    puts $ff "  // $comment
  // request line: $reqline
  // source line: $srcline
  web_reg_save_param(\"$param_name\",
		\"LB=[escape_quotes $LB]\",
		\"RB=[escape_quotes $RB]\",
		\"NOTFOUND=EMPTY\",
		LAST);
"
  }

  puts $ff "	return 0;
}"
  
}

# voor elke dropdownlist (ddl) een C-functie aanroepen die verdere parsing doet.
proc call_dropDownList_functions {lst_calls} {
  join [struct::list map [struct::list filter $lst_calls is_dropDownList] dropDownList_c_call] "\n"
}

proc is_dropDownList {call} {
  string equal [lindex $call 1] "dropDownList" 
}

proc dropDownList_c_call {call} {
  lassign $call param_name paramtype LB RB comment reqline srcline
  return "    RMM_Sub_Reg_SaveParam(\"$param_name\", \"<option selected=\\\"selected\\\" value=\\\"\", \"\\\">\");"
}

proc escape_quotes {str} {
  regsub -all {\"} $str {\"} str ; # "
  return $str  
}

# @todo bepalen wanneer & niet met newline vervangen moet worden.
# @note input text bevat soms ook al newlines en afgebroken strings, deze eerst weer samenvoegen.
proc preprocess {req_text} {
  global log
  # bron:  		"&ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$ddlTypeContractant$dropDownList=HOOFDELIJKE_AANSPRAKELIJKE&ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$rblPersoneel$radioButtonList=False&ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$tbAchternaam$textBox=Blanken"
  # doel:  		"&ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$ddlTypeContractant$dropDownList=HOOFDELIJKE_AANSPRAKELIJKE"
 	#	"&ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$rblPersoneel$radioButtonList=False"
 	#	"&ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$tbAchternaam$textBox=Blanken"
  
 	# oorspronkelijk vugen linebreaks verwijderen
 	regsub -all {\"\n[ \t]+\"} $req_text "" req_text ; # "
 	
 	# line breaks toevoegen
 	regsub -all {&} $req_text "\"\n    \"\&" req_text
  
 	# enkele & op een regel weer bij voorgaande
 	regsub -all {\"\n[ \t]+\"\&\"} $req_text "&\"" req_text
 	
 	# te lange regels (viewstate) weer afbreken op de vugen manier.
 	# repetition count (500) is max 255, dus in 2 stukken.
 	while {[regsub -all {(\n[\t ]+\"[^\"]{250}[^\"]{250})([^\"]+)} $req_text "\\1\"\n\t\t\"\\2" req_text]} {}
 	
 	#$log debug "req_text: $req_text"
  #exit
  return $req_text
}

# @note bepaal functie naam uit 	web_custom_request("Persoonsgegevens.aspx_2", 
proc det_funname {req_text} {
  if {[regexp {web_custom_request\(\"([^"]+)\"} $req_text z funname]} {
    regsub -all {\.} $funname "_" funname
    return "${funname}_saveParams"
  } elseif {[regexp {web_submit_data\(\"([^\"]+)\",} $req_text z funname]} {
    regsub -all {\.} $funname "_" funname
    return "${funname}_saveParams"
  } else {
    return "Onbekend"
  }
}



main $argc $argv