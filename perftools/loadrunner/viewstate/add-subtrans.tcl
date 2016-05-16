# @todo
# toevoegen na elke request: web_reg_find("Text=\r\n\tInkomen\r\n", LAST); // check of html goed is.
package require ndv
package require Tclx
package require struct::list
package require math

::ndv::source_once urlencode.tcl
::ndv::source_once lib.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

# globals:
# log 
# ar_html: index: snapshotnummer (zonder t), waarde: html van file, plain, niet decoded of encoded.
# ar_lst_save_param: index: snapshotnummer (zonder t), waarde: list van save-param teksten om _voor_ de action neer te zetten.
# ar_lst_clean_param: index: snapshotnummer (zonder t), waarde: list van clean-param teksten _na_ action neer te zetten.
# ar_paramname: index: full param text, waarde: paramname. Gebruikt voor hergebruik van paramnames.
# ar_last_use: index: paramname, value: snapshot number: in welk snapshot wordt de param voor het laatst gebruikt, zodat 'ie daarna opgeruimd kan worden.
proc main {argc argv} {
  global log ar_lst_save_param ar_argv

  $log debug "argv: $argv"
  set options {
    {action-inputdir.arg "C:\\nico\\test_aanvraag_zc\\gen1" "Directory met input files (.c en .aspx)"}
    {action-outputdir.arg "inclsub" "Directory met gegenereerde files (.c), relatief tov action-inputdir"}
    {loglevel.arg "" "Zet globaal log level"}
    {deletelog "Delete log before running"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]

  $log debug "ar_argv: [array get ar_argv]"
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }
  if {$ar_argv(deletelog)} {
    file delete "[file rootname [file tail [info script]]].log" 
  }
  ::ndv::CLogger::set_logfile "[file rootname [file tail [info script]]].log"
  $log info START

  handle_action_dir $ar_argv(action-inputdir) [file join $ar_argv(action-inputdir) $ar_argv(action-outputdir)]

  $log info FINISHED
  ::ndv::CLogger::close_logfile
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
  global log max_html_param_len cur_trans cur_count
  $log debug "Handle action file: $request_c_filename"
  set max_html_param_len 0
  set req_text [read_file $request_c_filename]
  # set req_text [action_preprocess $req_text]
  
  # set to_subst $req_text
  # 5-11-2010 kan een ) in de call voorkomen, dus specifieker zoeken: ([^\)]*[^\)]*\)[^;])*\);  zie FSM van RE. 
  # zie regexp-fsm.png, gemaakt met http://osteele.com/tools/reanimator/???
  
  # 2 phase: 1. count requests within transaction, 2. if count > 1, add subtrans.
  set cur_trans "<none>"
  set cur_count -1
  foreach {call} [regexp -all -inline {\t[^ \n(]+\(([^\)]*\)[^;])*[^\)]*\);} $req_text] {
    handle_call_phase1 $call
  }
  # now ar_count_trans(trans) is filled, on to phase 2
  regsub -all {(\t[^ \n(]+\(([^\)]*\)[^;])*[^\)]*\);)} $req_text {[handle_action_call {\1}]} to_subst
  # breakpoint
  set req_text_substed [subst_no_variables $to_subst]
  # set req_text_substed $to_subst ; # voor test.
  
  set f [open [file join $gendir [file tail $request_c_filename]] w]
  puts $f "// Subtransactions added by [file tail [info script]] [clock format [clock seconds] -format "%d-%m-%Y %H:%M:%S"]\n"
  puts $f $req_text_substed
  close $f
}

proc handle_call_phase1 {call} {
  global log ar_count_trans cur_trans cur_count 
  if {[regexp {lr_start_transaction\(\x22([^\x22]+)\x22\)} $call z trans]} {
    set cur_trans $trans
    set cur_count 0
  } elseif {[regexp {lr_end_transaction\(\x22([^\x22]+)\x22} $call z trans]} {
    if {$trans != $cur_trans} {
      $log warn "start_trans != end_trans: $cur_trans <=> $trans" 
      breakpoint
    }
    set ar_count_trans($cur_trans) $cur_count
    set cur_trans "<none>"
    set cur_count 0
  } elseif {[regexp {(web_custom_request)|(web_url)|(web_submit_data)} $call]} {
    incr cur_count 
  }
}

proc handle_action_call {call} {
  global log ar_count_trans cur_trans
  # $log debug "call: $call"
  if {[regexp {lr_start_transaction\(\x22([^\x22]+)\x22\)} $call z trans]} {
    set cur_trans $trans
    return $call
  }
  # x22 is de dubbele quote.
  if {[regexp {((web_custom_request)|(web_url)|(web_submit_data))\(\x22([^\x22]+)\x22} $call z z z z z req_name]} {
    $log debug "ar_count_trans($cur_trans) = $ar_count_trans($cur_trans)"
    if {$ar_count_trans($cur_trans) <= 1} {
      # $log debug "$cur_trans/$req_name is only req, no sub trans"
      return $call
    } else {
      set res "\tlr_start_sub_transaction(\"$req_name\",\"$cur_trans\");
$call
\tlr_end_sub_transaction\(\"$req_name\", LR_AUTO\);"
      # $log debug "res: $res"
      return $res
    }
  } else {
    return $call    
  }
}

# @note input text bevat soms ook al newlines en afgebroken strings, deze eerst weer samenvoegen.
# oorspronkelijk vugen linebreaks verwijderen
proc action_preprocess_old {req_text} {
  global log
 	regsub -all {\x22\n[ \t]+\x22} $req_text "" req_text
  return $req_text
}

# delete files in dir, but not dir itself.
# not recursive for now.
proc file_delete_dir_contents {gendir} {
  foreach filename [glob -nocomplain -directory $gendir -type f *] {
    file delete -force $filename 
  }
}

main $argc $argv

