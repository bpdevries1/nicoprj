# @todo voor viewstate gedaan, nu ook voor eventvalidation en valueexchange.
# deze voor valueexchange, kopie + aanpassingen van viewstate, later integreren.

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
    {action-outputdir.arg "gen-action-ve" "Directory met gegenereerde files (.c)"}
    {html-inputdir.arg "L:\\LSP\\Force BPR LSP\\VUGen scripts\\1action\\Hypotheek_Aanvraag_1action\\data" "Directory met input files (.c en .aspx)"}
    {html-outputdir.arg "gen-html-ve" "Directory met gegenereerde files (.c)"}
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
  # file delete -force $gendir
  file_delete_dir_contents $gendir
  file mkdir $gendir
  file delete "valueexchange-filtered.c"
  file delete "url-snapshot-ve.tsv"
  foreach request_c_file [glob -directory $inputdir "*.c"] {
    handle_action_file $request_c_file $gendir
  }
}

# delete files in dir, but not dir itself.
# not recursive for now.
proc file_delete_dir_contents {gendir} {
  foreach filename [glob -nocomplain -directory $gendir -type f *] {
    file delete -force $filename 
  }
}

# "URL=http://force2atk.acceptatie.frieslandbank.nl/WebForms/AanvraagAdministratie/Klantoverzichtscherm.aspx?valueExchange=aWQua2xh...dRPQ%3d%3d&",
# html: eExchange=aWQua2xh...dRPQ%3d%3d&amp;&quot;;\nwicket
# html url encoded: aWQua2xh...dRPQ   %253d%253d%26amp%3B%26quot%3B%3B%0d%0awicket 

# "URL=http://force2atk.acceptatie.frieslandbank.nl/WebForms/AanvraagAdministratie/OnderpandDialog.aspx?valueExchange=X19EV...XFHbmc9&&Anthem_CallBack=true",
# "Referer=http://force2atk.acceptatie.frieslandbank.nl/WebForms/AanvraagAdministratie/OnderpandDialog.aspx?valueExchange=X19EVH...WXFHbmc9&",
proc handle_action_file {request_c_filename gendir} {
  global ar_argv log html_text lst_valueexchange
  $log debug "Handle action file: $request_c_filename"
  # global ar_argv log lst_calls
  # set req_text [read_file $ar_argv(reqsrc)]
  set lst_valueexchange {}
  set req_text [read_file $request_c_filename]
  set req_text [action_preprocess $req_text]
  
  set to_subst $req_text

  # regsub -all {__VALUEEXCHANGE=([^&\"=,]+)} $to_subst {[add_to_list \1 1]} to_subst ; # "
  # regsub -all {Name=__VALUEEXCHANGE", "Value=([^&\"=,]+)} $to_subst {[add_to_list \1 2]} to_subst ; # "
#Snapshot=t1.inf

  #regsub -all {URL=([^"]+)[^()]+Snapshot=t([0-9]+).inf[^()]+valueExchange=([^&\"=,]+)} $to_subst {[add_to_list \1 \2 \3 1]} to_subst ; # "
  #regsub -all {URL=([^"]+)[^()]+Snapshot=t([0-9]+).inf[^()]+Name=valueExchange", "Value=([^&\"=,]+)} $to_subst {[add_to_list \1 \2 \3 2]} to_subst ; # "
  
  # 2-11-2010 in 2 fases: eerst calls uitfilteren, dan hierbinnen de value exchanges.
  # 2-11-2010 call moet nu beginnen met \t, zodat Action() hier uitvalt.
  # 2-11-2010 accolades om param heen, want is meestal meer dan 1 regel, anders bij subst alleen eerste regel.
  regsub -all {\t([^ ]+\([^)]+\))} $to_subst {[handle_action_call {\1}]} to_subst ; # "
  set fd [open debug.txt w]
  puts $fd $to_subst
  close $fd
  
  set req_text_substed [subst_no_variables $to_subst]

  # output even checken of alles gevonden is.
  # 	"Name=__VALUEEXCHANGE", "Value=/wEPDwUKL
  set f [open "valueexchange-filtered.c" a]
  puts $f $req_text_substed
  close $f
  
  # nu lst gevuld
  set i 1
  set fu [open "url-snapshot-ve.tsv" a]
  puts $fu "snapshot\turl"
  foreach {url snapshot valueexchange url_referer} $lst_valueexchange {
    set f [open [file join $gendir "valueexchange-[format %03d $i]-ss-t$snapshot-$url_referer.txt"] w]
    puts $f $valueexchange
    close $f
    incr i
    set url2 [file tail $url]
    regexp {^([^\?]+)} $url2 z url2
    puts $fu "t$snapshot\t$url2"
  }
  close $fu
}

proc handle_action_call {call} {
  global log lst_valueexchange
  # hier in principe max 1 valueexchange, en ook URL en snapshot te vinden.
  # $log debug "call: $call"
  # puts stderr "call(puts): $call"
  # @todo referer ook
  # zowel valueExchange=....&amp 
  # alsook Name=valueExchange", "Value={pValueExchange_3}"
  #regsub -all {URL=([^"]+)[^()]+Snapshot=t([0-9]+).inf[^()]+valueExchange=([^&\"=,]+)} $to_subst {[add_to_list \1 \2 \3 1]} to_subst ; # "
  #regsub -all {URL=([^"]+)[^()]+Snapshot=t([0-9]+).inf[^()]+Name=valueExchange", "Value=([^&\"=,]+)} $to_subst {[add_to_list \1 \2 \3 2]} to_subst ; # "
  if {![regexp {((URL)|(Action))=([^\n]+)\?valueExchange=([^&"]+)&} $call z z z z url valueexchange]} {
    # $log debug "RE1 geen result"
    # breakpoint
    if {![regexp {"Action=([^"]+)".*"Name=valueExchange", "Value=([^&"]+)",} $call z url valueexchange]} {
      # " geen valueexchange gevonden in deze call
      # $log debug "RE2 geen result"
      # in t11.inf zit valueexchange in de Body
      if {![regexp {"((URL)|(Action))=([^"]+)".*Body=.*valueExchange=([^&"]+)(&|")} $call zall z z z url valueexchange]} {
        # $log debug "RE3 geen result"
        if {[regexp {valueExchange} $call]} {
          $log warn "Toch wel valueexchange in call: $call" 
          breakpoint
        }
        return
      } else {
        # $log debug "RE3 gevonden, zall=***$zall***" 
      }
    }
  }
  # $log debug "url en ve gevonden: $url --- $valueexchange"
  # zoek referer value exchange en snapshot
  # set snapshot "notfound"
  if {![regexp {Snapshot=t([0-9]+).inf} $call z snapshot]} {
    set snapshot "notfound"
    breakpoint
  }
  if {[regexp {Referer=http[^\n]+valueExchange=([^&\"]+)&\"} $call z referer_valueexchange]} {
    # ; "
    add_to_list $url $snapshot $referer_valueexchange 1 "referer"
  }
  add_to_list $url $snapshot $valueexchange 1 "url"
}

# @param line: ctl00$ctl00$ctl00$PageContent$PageContent$ColumnLeft$ddlTypeContractant$dropDownList=HOOFDELIJKE_AANSPRAKELIJKE"
# param_name := pTypeContractant
# @note bij aanroep van deze proc zijn in fullname de $ door \004 vervangen.
# @note line eindigt nu met ", zodat comment er ook achter kan.
# @todo html_text weer als param meegeven.
# @todo lst_calls ook ala param?
# @param url_referer: 'url' of 'referer'
proc add_to_list {url snapshot valueexchange re url_referer} {
  global log lst_valueexchange
  
  # hier nog \004 in?
  # regsub -all "\004" $line "\$" line 
  lappend lst_valueexchange $url $snapshot $valueexchange $url_referer; # 't blijft een flatlist, met foreach gemakkelijker.
  return "<valueexchange added to list re=$re>"
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
  # file delete -force $gendir
  file_delete_dir_contents $gendir 
  file mkdir $gendir
  foreach html_file [glob -directory $inputdir "*.htm"] {
    handle_html_file $html_file $gendir
  }
}

# @post gegenereerde files zijn meteen url-encoded, om vergelijking met action files gemakkelijker te maken.
# wicketModalWindowSettings.src=&quot;KlantZoekDialog.aspx?valueExchange=UkxCLktsYW50dH...3d%3d&amp;&quot;;
# wicketModalWindowSettings.src=&quot;TussenpersoonZoekenSelligentDialog.aspx?valueExchange=d2hpdGVsY...9ZNXpiWT0%3d&amp;"
# wicketModalWindowSettings.src=&quot;/WebForms/AanvraagAdministratie/Products/DeelproductKeuzeDialog.aspx?valueExchange=SG9vZmR...ZTRQdz0%3d&amp;&quot;;\n
proc handle_html_file {html_file gendir} {
  global log
  set text [read_file $html_file]
  set i 0
  foreach {z valueexchange} [regexp -inline -all -nocase {VALUEEXCHANGE\" value="([^"]+)"} $text] {
    make_html_valueexchange [incr i] $html_file $gendir $valueexchange
  }
  foreach {z valueexchange} [regexp -inline -all -nocase {valueExchange":"([^"]+)\"} $text] { ; # "
    make_html_valueexchange [incr i] $html_file $gendir $valueexchange
  }
  foreach {z valueexchange} [regexp -inline -all -nocase {valueExchange=([^"&]+)&amp} $text] { ; # "
    make_html_valueexchange [incr i] $html_file $gendir $valueexchange
  }
  foreach {z valueexchange} [regexp -inline -all -nocase {valueExchange=([^"&]+)&\\\";} $text] { ; # "
    make_html_valueexchange [incr i] $html_file $gendir $valueexchange
  }
  # en het komt ook 1 of 2 keer voor binnen closeWithArgumentsCallback(' en ');
  foreach {z valueexchange} [regexp -inline -all -nocase {closeWithArgumentsCallback\('([^"'&]+)'\);} $text] { ; # "
    make_html_valueexchange [incr i] $html_file $gendir $valueexchange
  }
  
  if {[regexp -nocase valueexchange $text] && ($i == 0)} {
    $log warn "Unknown valueexchange found in $html_file"
    breakpoint
  }
}

proc make_html_valueexchange {i html_file gendir valueexchange} {
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
  file join $gendir "[file rootname [file tail $html_file]]-[format %02d $i]-$encoded.txt" 
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
  set f [open same-valueexchange.tsv w]
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

main $argc $argv