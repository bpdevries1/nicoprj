# losse main-file om dynamisch aan te kunnen passen
package require ndv
package require tcom

ndv::source_once lib-copy.tcl

file mkdir [file join [file dirname [info script]] log]
set time [clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]
set logname [file join [file dirname [info script]] log "copymail-$time.log"]

set debug 1

proc main {argv} {
  global argv0 debug
  log info "main: start"
  lassign $argv config
  if {$config == ""} {
    puts "syntax: $argv0 <config.tcl>"
    exit 1
  }
  source $config
  
  # start applicatie
  # set app [optcl::new Outlook.Application]
  # set app [::tcom::ref getactiveobject "Outlook.Application"]
  log debug "Getting ref to Outlook"
  set app [tcom::ref getactiveobject "Outlook.Application"]
  log debug "Getting namespace"
  set namespace [$app GetNamespace MAPI]
  
  log info "Moving items: start"
  # handle_folder_name $namespace $src_folder $target_folder
   
  # load_test $namespace $src_folder $target_folder  $attachments_dir $mails_per_sec $runtime_sec $rampup_sec $max_pacing_msec $mail_types
  load_test $namespace $src_folder $target_folders $attachments_dir $mails_per_sec $runtime_sec $rampup_sec $mail_types
  
  # test_stuff
  log info "Moving items: finished"
}

proc load_test {namespace src_folder target_folders attachments_dir mails_per_sec runtime_sec rampup_sec mail_types} {
	set fl_source [find_folder_path $namespace $src_folder]
	# set fl_target [find_folder_path $namespace $target_folder]
	
	# src_mails - list of (cumulative frequency%, frequency, subject, msg com object)
	set src_mails [det_src_mails $fl_source $mail_types]
	log debug "src_mails: $src_mails"

  set target_obj_folders [det_target_obj_folders $target_folders $namespace]
  
	# test_choose_mails $src_mails
	
	set start_test_sec [clock seconds]
	set end_test_sec [expr $start_test_sec + $runtime_sec]
	while {[clock seconds] < $end_test_sec} {
		set start_it_msec [clock milliseconds]
		set elapsed_start_sec [expr [clock seconds] - $start_test_sec]
		# set subj [copy_random_msg $src_mails $fl_target $attachments_dir]
    set subj [copy_random_msg $src_mails $target_obj_folders $attachments_dir]
		incr msg_counts($subj)
		set end_it_msec [clock milliseconds]
		# set wait_msec [expr round((1000.0 * $pacing_sec) - ($end_it_msec - $start_it_msec))]
		set elapsed_sec [expr [clock seconds] - $start_test_sec]
		# set wait_msec [det_wait_msec $rampup_sec $mails_per_sec $elapsed_sec $start_it_msec $end_it_msec $max_pacing_msec]
		set wait_msec [det_wait_msec $rampup_sec $mails_per_sec $elapsed_start_sec $start_it_msec $end_it_msec]
		if {$wait_msec > 0} {
		  after [expr round($wait_msec)]
		}
	}
	set totalcount 0
	foreach subj [lsort [array names msg_counts]] {
	  # log info "Subject: $subj, count: $msg_counts($subj)"
    log info "#$msg_counts($subj) - $subj"
	  incr totalcount $msg_counts($subj)
	}
	log info "Total messages sent: $totalcount"
	set nps [expr 1.0*$totalcount/([clock seconds] - $start_test_sec)]
	log info "#msg/sec: [format %.3f $nps]"
	log info "#msg/min: [format %.3f [expr 60.0*$nps]]"
}

# return dict - key = msg_type (mail/fax), value = list of target folders as outlook COM objects.
proc det_target_obj_folders {target_folders namespace} {
  set d [dict create]
  foreach {msg_type lst} $target_folders {
    set lst_folder_objects {}
    foreach path $lst {
      lappend lst_folder_objects [find_folder_path $namespace $path]
    }
    dict set d $msg_type $lst_folder_objects
  }
  return $d
}

proc det_src_mails {fl_source mail_types} {
  # mails: dict from subject to mail-com-object
  set mails [get_mails $fl_source]
  log debug "mails: $mails"
  set sum_freq [det_sum_freq $mail_types]
  log debug "sum_freq: $sum_freq"
  set res {}
  set cum_freq 0.0
  foreach {subject freq msg_type} $mail_types {
    set cum_freq [expr $cum_freq + (1.0 * $freq / $sum_freq)]
    lappend res [list $cum_freq $freq $subject [dict get $mails $subject] $msg_type]
  }
  log debug "Cumulative sum (should be 1.00): $cum_freq"
  return $res
}

proc get_mails {fl} {
	set d [dict create]
	tcom::foreach msg [$fl Items] {
		dict set d [$msg Subject] $msg
	}
	return $d
}

proc copy_random_msg {src_mails target_obj_folders attachments_dir} {
	log debug "copy_random_msg - start"
	# set mail [choose_random_mail $src_mails]
  lassign [choose_random_mail $src_mails] mail msg_type
  set fl_target [choose_random_target $msg_type $target_obj_folders]
	log debug "mail chosen"
	copy_item $mail $msg_type $fl_target $attachments_dir
	set subj [$mail Subject]
	log debug "copy_random_msg - end"
  return $subj
}

proc choose_random_target {msg_type target_obj_folders} {
  set lst_folders [dict get $target_obj_folders $msg_type]
  set rnd [expr rand()]
  set len [llength $lst_folders]
  lindex $lst_folders [expr round(floor($rnd * $len))]  
}

# msg_type - mail or fax. With fax, special handling for setting subject.
# fl_target - chosen random target directory for mail type.
proc copy_item {mail msg_type fl_target attachments_dir} {
	log debug "copy_item - start"
	set msg2 [$mail Copy]
	log debug "mail copied"
	# TODO subject en attachment name unique
	set ts [current_time_for_subject]
	# set subject "Perftest-$ts-[$mail Subject]"
  set subject [det_subject [$mail Subject] $ts $msg_type]
  
	$msg2 Subject $subject
	log debug "Mail subject set"
	# ga bij attachments uit van orig mail, verandert niet. Haal bij doel-mail eerst alle attachments weg.
	set attachments [$mail Attachments]
	set attachments2 [$msg2 Attachments]
	# TODO: als >1 attachment, dan vanaf de tweede iets erbij bij Subject.
	set idx 0
	# eerst lijst van attachments, dan delete, anders zitten lijst doorlopen en deleten elkaar in de weg.
	set atts2 {}
	tcom::foreach att $attachments2 {
	  lappend atts2 $att
	}
	log debug "copied ids of attachments to var"
	foreach att $atts2 {
		log debug "Deleting one attachment from the copied message: [$att DisplayName]"
		$att Delete
	}
	log debug "deleted orig attachments from copied mail"
	if 1 {
		tcom::foreach att $attachments {
		  incr idx
		  # set filename "c:\\PCC\\Nico\\aaa\\Test NdV.pdf"
		  # set filename [file join $attachments_dir "Test NdV.pdf"]
		  # subject eindigt mogelijk al met .pdf
		  set filename [det_att_filename $attachments_dir $subject $idx $att] 
		  # log debug "Attachment filename: $filename"
		  $att SaveAsFile $filename
		  # $attachments2 Add $filename [$att Type] 1 "${subject}.pdf"
		  set pos [$att Position]
		  if {$pos == 0} {
		    set pos 1
		  }
		  log debug "Adding attachment on position: $pos"
		  $attachments2 Add $filename [$att Type] $pos [file tail $filename]
		  # $att Delete
		  file delete $filename
		}
	}
	log debug "added attachments"
	try_eval {
		$msg2 Save
		log debug "saved mail"
		$msg2 Move $fl_target
		log debug "moved mail"
		log perf "Created mail - subject=$subject"
	} {
	  log warn "Saving failed (Enterprise Vault?); delete copied message"
	  $msg2 Delete
	}
	log debug "copy_item - end"
}

# set subject
# orig for fax: Fax sent (3p) to '+31307124088' @+31307124088
proc det_subject {orig_subject ts msg_type} {
  if {$msg_type == "fax"} {
    # special handling
    # vraag of het nodig is, Fax sent staat in subject en blijft er ook in staan.
    return "$orig_subject-Perftest-$ts"
  } else {
    # return "Perftest-$ts-$orig_subject"
    return "Perftest-$ts-$orig_subject"    
  }
}

proc det_att_filename {attachments_dir subject idx att} {
  set rootname [file rootname $subject]
  # set extension [file extension $subject]
  set extension [file extension [$att FileName]]
  if {$extension == ""} {
    set extension ".pdf"
  }
  if {$idx == 1} {
    set suffix ""
  } else {
    set suffix "-$idx"
  }
  file join $attachments_dir "$rootname$suffix$extension"
}

# returns - mail com object.
proc choose_random_mail {src_mails} {
  set item [lindex $src_mails 0]
  set rnd [expr rand()]
  foreach item $src_mails {
    if {$rnd < [lindex $item 0]} {
      return [list [lindex $item 3] [lindex $item 4]]
    }
  }
}

proc find_folder_path {ns pad} {
  # set folders [$ns : Folders]
  log debug "namespace: $ns"
  set f $ns
  # breakpoint
  set parts [split $pad "/"]
  foreach part $parts {
	 set folders [$f Folders]
     set f [find_folder $folders $part]
  }
  log info "Found folder path: [$f Name]"
  return $f
}

# zoek folder 1 niveau diep
proc find_folder {folders naam} {
  log debug "find_folder: $naam (folders: $folders)"
  # set i [$folders : count]
  tcom::foreach folder $folders {
    log debug "found folder: [$folder Name]"
	if {[$folder Name] == $naam} {
		return $folder
	}
  }
  log warn "niet gevonden: $naam"
  return 0
}

proc log {level str} {
	global logname debug
	if {$debug || ($level != "debug")} {
		set f [open $logname a]
		set logstring "\[[current_time]\] \[$level\] $str"
		puts $f $logstring
		close $f
		puts $logstring
	}
}

proc current_time {} { 
  set msec [clock milliseconds]
  set sec [expr $msec / 1000]
  set msec2 [expr $msec % 1000]
  return "[clock format $sec -format "%Y-%m-%d %H:%M:%S.[format %03d $msec2] %z"]"
}

proc current_time_for_subject {} { 
  set msec [clock milliseconds]
  set sec [expr $msec / 1000]
  set msec2 [expr $msec % 1000]
  return "[clock format $sec -format "%Y-%m-%d--%H-%M-%S.[format %03d $msec2]"]"
}

########## procs for testing the script - start ###########

proc test_stuff {} {
  set d [dict create a 1 b 2]
  log info "dict value: [:a $d]"
  log info "Start - After 500"
  after 500
  log info "Middle - After 500"
  after 500
}

proc handle_folder_name {namespace src_folder target_folder} {
	set fl_source [find_folder_path $namespace $src_folder]
	log info "Found folder, name = [$fl_source Name]"
	set fl_target [find_folder_path $namespace $target_folder]
	handle_items_test $fl_source $fl_target
}

proc handle_items_test {fl_source fl_target} {
	log info "#items in [$fl_source Name]: [[$fl_source Items] Count]"
	tcom::foreach msg [$fl_source Items] {
		copy_item_test $msg $fl_target
	}
}

proc copy_item_test {msg fl_target} {
	# show_message $msg
	set msg2 [$msg Copy]
	$msg2 Subject "Test NdV - [$msg Subject]"
	set attachments [$msg2 Attachments]
	tcom::foreach att $attachments {
	  # set filename "c:\\PCC\\Nico\\aaa\\Test NdV.pdf"
	  set filename "Test NdV.pdf"
	  $att SaveAsFile $filename
	  $attachments Add $filename [$att Type] 1 "Test NdV.pdf"
	  $att Delete
	}
	try_eval {
		$msg2 Save
		$msg2 Move $fl_target
	} {
	  log warn "Saving failed (Enterprise Vault?); delete copied message"
	  $msg2 Delete
	}
}


proc test_choose_mails {src_mails} {
	for {set i 0} {$i < 1000} {incr i} {
		set mail [choose_random_mail $src_mails]
		# log debug "Mail subject: [$mail Subject]"
		incr mail_counts([$mail Subject])
	}
	foreach subj [lsort [array names mail_counts]] {
	  log debug "Subject: $subj, count: $mail_counts($subj)"
	}
}

########## procs for testing the script - end ###########

main $argv

file copy -force $logname [file join [file dirname [info script]] log "copymail-last.log"]
