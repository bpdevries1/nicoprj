package require ndv
package require tcom

ndv::source_once lib-copy.tcl

file mkdir [file join [file dirname [info script]] log]
set time [clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]
set logname [file join [file dirname [info script]] log "outlook-replier-$time.log"]

set debug 1

proc main {argv} {
  global argv0 debug
  lassign $argv config
  if {$config == ""} {
    puts "syntax: $argv0 <config.tcl>"
    exit 1
  }
  source $config
  reply_mails_loop $scrit_out_mailbox $scrit_handled_mailbox $scrit_in_mailboxes $template_file $check_freq_sec $check_max_mails $perc_change
}

proc reply_mails_loop {scrit_out_mailbox scrit_handled_mailbox scrit_in_mailboxes template_file check_freq_sec check_max_mails perc_change} {
  log debug "Getting ref to Outlook"
  set app [tcom::ref getactiveobject "Outlook.Application"]
  log debug "Getting namespace"
  set namespace [$app GetNamespace MAPI]
  set fl_out [find_folder_path $namespace $scrit_out_mailbox]
  set fl_handled [find_folder_path $namespace $scrit_handled_mailbox]
  set fls_in [find_folder_paths $namespace $scrit_in_mailboxes]
  while 1 {
    set start_msec [clock milliseconds]
    log debug "Calling reply mails"
    reply_mails $fl_out $fl_handled $fls_in $template_file $check_max_mails $perc_change
    wait_pacing $check_freq_sec $start_msec
  }
}

# param: scrit_in_mailboxes: dict with regex (for body) as key and mailbox name as value.
# returns: dict with same key, and outlook OLE object for folder.
proc find_folder_paths {namespace scrit_in_mailboxes} {
  set res [dict create]
  dict for {k v} $scrit_in_mailboxes {
    dict set res $k [find_folder_path $namespace $v]
  }
  return $res
}

proc reply_mails {fl_out fl_handled fls_in template_file check_max_mails perc_change} {
  set i 0
	tcom::foreach msg [$fl_out Items] {
    set fl_in [det_fl_in $msg $fls_in]
    if {$fl_in != ""} {
      reply_mail $msg $fl_handled $fl_in $perc_change $template_file
    } else {
      log warn "Cannot find inbound mail folder for message, move to handled: [$msg Subject]"
      $msg Move $fl_handled
    }
    incr i
    if {$i >= $check_max_mails} {
      return
    }
	}
}

# determine target inbound mailbox based on body of message
# return empty string if no regexp matches.
proc det_fl_in {msg fls_in} {
  set body [$msg Body]
  dict for {re fl} $fls_in {
    if {[regexp $re $body]} {
      return $fl
    }
  }
  return ""
}

proc reply_mail {msg fl_handled fl_in perc_change template_file} {
  log debug "reply_mail - start"
  set subject [$msg Subject]
  set msg2 [$msg Copy]
  set att [det_att_name $msg]
  if {[expr 100.0 * rand()] < $perc_change} {
    change_attachment $msg2 $template_file
  }
	try_eval {
		$msg2 Save
		log debug "saved mail"
		$msg2 Move $fl_in
		log debug "moved mail"
		log perf "Replied to mail: subject=$subject, att=$att"
	} {
	  log warn "Saving failed (Enterprise Vault?); delete copied message"
	  $msg2 Delete
	}
  # move file to handled, also if error occurs.
  $msg Move $fl_handled
  
  log debug "reply_mail - finished"
}

proc change_attachment {msg template_file} {
  log info "Changing attachment"

  delete_attachments $msg
  add_attachment $msg $template_file
}

proc delete_attachments {msg} {
	set attachments [$msg Attachments]
	set atts2 {}
	tcom::foreach att $attachments {
	  lappend atts2 $att
	}
	# log debug "copied ids of attachments to var"
	foreach att $atts2 {
		log debug "Deleting one attachment from the copied message: [$att DisplayName]"
		$att Delete
	}
}

proc add_attachment {msg filename} {
  set attachments [$msg Attachments]
  set olByValue 1
  $attachments Add $filename $olByValue 1 [file tail $filename]
}

proc det_att_name {msg} {
	set res "<none>"
	set attachments [$msg Attachments]
	tcom::foreach att $attachments {
	   set res [$att FileName]
	}
	return $res
}

main $argv

