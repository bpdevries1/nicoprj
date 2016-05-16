package require ndv
package require Tclx
package require struct::list
package require math

::ndv::source_once lib.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

# globals:
# log 
proc main {argc argv} {
  global log ar_lst_save_param ar_argv

  $log debug "argv: $argv"
  set options {
    {action-inputdir.arg "C:\\nico\\Hypotheek_Aanvraag_Dev_20101110" "Directory met input files (.c en .aspx)"}
    {action-outputdir.arg "webregfind" "Directory met gegenereerde files (.c), relatief tov action-inputdir"}
    {file-globpattern.arg "A*.c" "Glob pattern for filenames"}
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

  handle_action_dir $ar_argv(action-inputdir) $ar_argv(file-globpattern) [file join $ar_argv(action-inputdir) $ar_argv(action-outputdir)] handle_action_file

  $log info FINISHED
  ::ndv::CLogger::close_logfile
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
  
  regsub -all {([ \t]+[^ \n(]+\(([^\)]*\)[^;])*[^\)]*\);)} $req_text {[handle_action_call {\1}]} to_subst
  # breakpoint
  set req_text_substed [subst_no_variables $to_subst]
  # set req_text_substed $to_subst ; # voor test.
  
  set f [open [file join $gendir [file tail $request_c_filename]] w]
  puts $f "// web_reg_find added by [file tail [info script]] [clock format [clock seconds] -format "%d-%m-%Y %H:%M:%S"]\n"
  puts $f $req_text_substed
  close $f
}

proc handle_action_call {call} {
  global log ar_count_trans cur_trans
  # $log debug "call: $call"
  # x22 is de dubbele quote.
  if {[regexp {((web_custom_request)|(web_url)|(web_submit_data))\(\x22([^\x22]+)\x22} $call z z z z z req_name]} {
    # sowieso een web_reg_find toevoegen, ook al is er al een. de bestaande zijn vaak de defaults, alleen op de titel.
    set res "\n\t// web_reg_find(\"Text=invullen\", \"Fail=NotFound\", LAST);

$call"
    # $log debug "res: $res"
    return $res
  } else {
    return $call    
  }
}

main $argc $argv

