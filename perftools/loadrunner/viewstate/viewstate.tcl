# @todo
# voor viewstate gedaan, nu ook voor eventvalidation en valueexchange.

package require ndv
package require Tclx
package require struct::list

::ndv::source_once urlencode.tcl
::ndv::source_once lib.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  # global log ar_argv
  global log

  $log debug "argv: $argv"
  set options {
    {action-inputdir.arg "L:\\LSP\\Force BPR LSP\\VUGen scripts\\1action\\Hypotheek_Aanvraag_1action" "Directory met input files (.c en .aspx)"}
    {action-outputdir.arg "gen-action" "Directory met gegenereerde files (.c)"}
    {html-inputdir.arg "L:\\LSP\\Force BPR LSP\\VUGen scripts\\1action\\Hypotheek_Aanvraag_1action\\data" "Directory met input files (.c en .aspx)"}
    {html-outputdir.arg "gen-html" "Directory met gegenereerde files (.c)"}
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

  handle_action_dir $ar_argv(action-inputdir) $ar_argv(action-outputdir)
  handle_html_dir $ar_argv(html-inputdir) $ar_argv(html-outputdir)
  compare_files $ar_argv(action-outputdir) $ar_argv(html-outputdir)
  $log info FINISHED
  ::ndv::CLogger::close_logfile
}

proc handle_action_dir {inputdir gendir} {
  global log
  $log info "handle_action_dir: $inputdir"
  file_delete_dir_contents $gendir
  file mkdir $gendir
  file delete "viewstate-filtered.c"
  file delete "url-snapshot.tsv"
  foreach request_c_file [glob -directory $inputdir "*.c"] {
    handle_action_file $request_c_file $gendir
  }
}

# @todo bepalen of preprocess nodig is.
proc handle_action_file {request_c_filename gendir} {
  global ar_argv log html_text lst_viewstate
  $log debug "Handle action file: $request_c_filename"
  # global ar_argv log lst_calls
  # set req_text [read_file $ar_argv(reqsrc)]
  set lst_viewstate {}
  set req_text [read_file $request_c_filename]
  set req_text [action_preprocess $req_text]
  
  set to_subst $req_text

  # regsub -all {__VIEWSTATE=([^&\"=,]+)} $to_subst {[add_to_list \1 1]} to_subst ; # "
  # regsub -all {Name=__VIEWSTATE", "Value=([^&\"=,]+)} $to_subst {[add_to_list \1 2]} to_subst ; # "
#Snapshot=t1.inf

  #regsub -all {((URL)|(Action))=([^"]+)[^()]+Snapshot=t([0-9]+).inf[^()]+__VIEWSTATE=([^&\"=,]+)} $to_subst {[add_to_list \4 \5 \6 1]} to_subst ; # "
  #regsub -all {((URL)|(Action))=([^"]+)[^()]+Snapshot=t([0-9]+).inf[^()]+Name=__VIEWSTATE", "Value=([^&\"=,]+)} $to_subst {[add_to_list \4 \5 \6 2]} to_subst ; # "
  # 3-11-2010 NdV mogelijk kan een '=' ook onderdeel zijn van de viewstate. Had 'em niet in action, wel in html. Met onderstaande RE's wel alles gematched.
  regsub -all {((URL)|(Action))=([^"]+)[^()]+Snapshot=t([0-9]+).inf[^()]+__VIEWSTATE=([^&\",]+)} $to_subst {[add_to_list \4 \5 \6 1]} to_subst ; # "
  regsub -all {((URL)|(Action))=([^"]+)[^()]+Snapshot=t([0-9]+).inf[^()]+Name=__VIEWSTATE", "Value=([^&\",]+)} $to_subst {[add_to_list \4 \5 \6 2]} to_subst ; # "
  set req_text_substed [subst_no_variables $to_subst]

  # output even checken of alles gevonden is.
  # 	"Name=__VIEWSTATE", "Value=/wEPDwUKL
  set f [open "viewstate-filtered.c" a]
  puts $f $req_text_substed
  close $f
  
  # nu lst gevuld
  set i 1
  set fu [open "url-snapshot.tsv" a]
  puts $fu "snapshot\turl"
  foreach {url snapshot viewstate} $lst_viewstate {
    set f [open [file join $gendir "viewstate-[format %03d $i]-ss-t$snapshot.txt"] w]
    puts $f $viewstate
    close $f
    incr i
    regexp {^([^\?]+)} [file tail $url] z url2
    puts $fu "t$snapshot\t$url2"
  }
  close $fu
}

# @param line: ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$ddlTypeContractant$dropDownList=HOOFDELIJKE_AANSPRAKELIJKE"
# param_name := pTypeContractant
# @note bij aanroep van deze proc zijn in fullname de $ door \004 vervangen.
# @note line eindigt nu met ", zodat comment er ook achter kan.
# @todo html_text weer als param meegeven.
# @todo lst_calls ook ala param?
proc add_to_list {url snapshot line re} {
  global log lst_viewstate
  
  # hier nog \004 in?
  # regsub -all "\004" $line "\$" line 
  if {[regexp {^ViewState} $line]} {
    # door Vugen al ViewState123 etc van gemaakt.
    return "<viewstate NOT added to list re=$re>"
  } else {
    lappend lst_viewstate $url $snapshot $line ; # 't blijft een flatlist, met foreach gemakkelijker.
    return "<viewstate added to list re=$re>"
  }
} ; # accolade matched wel, door quote niet goed.

# @todo bepalen wanneer & niet met newline vervangen moet worden.
# @note input text bevat soms ook al newlines en afgebroken strings, deze eerst weer samenvoegen.
proc action_preprocess {req_text} {
  global log
 	# oorspronkelijk vugen linebreaks verwijderen
 	regsub -all {\"\n[ \t]+\"} $req_text "" req_text ; # "
 	
 	#$log debug "req_text: $req_text"
  #exit
  return $req_text
}

proc handle_html_dir {inputdir gendir} {
  global log
  $log info "handle html dir: $inputdir"
  file_delete_dir_contents $gendir
  file mkdir $gendir
  foreach html_file [glob -directory $inputdir "*.htm"] {
    handle_html_file $html_file $gendir
  }
}

# @pre een html_file bevat max 1 viewstate
# @post gegenereerde files zijn meteen url-encoded, om vergelijking met action files gemakkelijker te maken.
proc handle_html_file {html_file gendir} {
  global log
  set text [read_file $html_file]
  if {[regexp -nocase viewstate $text]} {
    if {[regexp -nocase {id=\"__VIEWSTATE\" value="([^"]+)"} $text z viewstate]} {
      make_html_viewstate [incr i] $html_file $gendir $viewstate
      #set fo [open [det_html_gen_name $html_file $gendir] w]
      #puts $fo [url-encode $viewstate]
      #close $fo
    } elseif {[regexp {\"viewState":"([^"]+)\"} $text z viewstate]} {
       # lastig, viewstate eindigt op 0%3d');"  begin is wel met " ; # "
      make_html_viewstate [incr i] $html_file $gendir $viewstate
      #set fo [open [det_html_gen_name $html_file $gendir] w]
      #puts $fo [url-encode $viewstate]
      #close $fo
    } else {
      $log warn "Unknown viewstate found in $html_file" 
    }
  } else {
    if {[file size $html_file] > 200} {
      $log warn "No viewstate found in $html_file"
    } else {
      # really small file, no worries. 
    }
  }
}

proc make_html_viewstate {i html_file gendir valueexchange} {
  set fo [open [det_html_gen_name $i $html_file $gendir unencoded] w]
  puts $fo $valueexchange
  close $fo
  set encoded [url-encode $valueexchange]
  if {$encoded != $valueexchange} {
    set fo [open [det_html_gen_name $i $html_file $gendir encoded] w]
    puts $fo $encoded
    close $fo
  }
}

proc det_html_gen_name {i html_file gendir encoded} {
  # file join $gendir "[file rootname [file tail $html_file]].txt"
  file join $gendir "[file rootname [file tail $html_file]]-[format %02d $i]-$encoded.txt" 
}
# @pre een html_file bevat max 1 viewstate
# @post gegenereerde files zijn meteen url-encoded, om vergelijking met action files gemakkelijker te maken.
proc handle_html_file_old {html_file gendir} {
  global log
  set text [read_file $html_file]
  if {[regexp -nocase viewstate $text]} {
    if {[regexp -nocase {id=\"__VIEWSTATE\" value="([^"]+)"} $text z viewstate]} {
      set fo [open [det_html_gen_name $html_file $gendir] w]
      puts $fo [url-encode $viewstate]
      close $fo
    } elseif {[regexp {\"viewState":"([^"]+)\"} $text z viewstate]} {
       # lastig, viewstate eindigt op 0%3d');"  begin is wel met " ; # "
      set fo [open [det_html_gen_name $html_file $gendir] w]
      puts $fo [url-encode $viewstate]
      close $fo
    } else {
      $log warn "Unknown viewstate found in $html_file" 
    }
  } else {
    if {[file size $html_file] > 200} {
      $log warn "No viewstate found in $html_file"
    } else {
      # really small file, no worries. 
    }
  }
}

# compare both sets of generated files
# all files in gen-action should be found in gen-html
proc compare_files {action_dir html_dir} {
  global log
  $log info "Comparing files"
  # eerst brute force aanpak, misschien iets nodig met cdc's
  set lst_action_files [glob -directory $action_dir *]
  foreach action_file $lst_action_files {
    set ar_text($action_file) [read_file $action_file]
    set ar_found($action_file) 0
  }
  set lst_html_files [glob -directory $html_dir *]
  foreach html_file $lst_html_files {
    set ar_text($html_file) [read_file $html_file] 
  }
  set f [open same-viewstate.tsv w]
  puts $f "first\tsecond"
  set lst_all_files [concat $lst_action_files $lst_html_files]
  for {set i 0} {$i < [llength $lst_all_files]} {incr i} {
    for {set j [expr $i + 1]} {$j < [llength $lst_all_files]} {incr j} {
      set fn1 [lindex $lst_all_files $i]
      set fn2 [lindex $lst_all_files $j]
      if {$ar_text($fn1) == $ar_text($fn2)} {
        puts $f "$fn1\t$fn2" 
        if {([file dirname $fn1] == $action_dir) && ([file dirname $fn2] == $html_dir)} {
          if {[det_snapshot $fn1] > [det_snapshot $fn2]} {
            set ar_found($fn1) 1
          }
        }
      }
    }
  }
  close $f
  
  # warning voor elke action file die niet gevonden is.
  foreach action_file $lst_action_files {
    if {$ar_found($action_file) == 0} {
      $log warn "No html file for action file: $action_file"
    }
  }
}

proc det_snapshot {filename} {
  if {[regexp {t([0-9]+)(-|\.)} $filename z snapshot]} {
    return $snapshot 
  } else {
    error "Cannot determine snapshot from filename: $filename" 
  }
}

# delete files in dir, but not dir itself.
# not recursive for now.
proc file_delete_dir_contents {gendir} {
  foreach filename [glob -nocomplain -directory $gendir -type f *] {
    file delete -force $filename 
  }
}

main $argc $argv