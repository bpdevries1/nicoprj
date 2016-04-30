# losse main-file om dynamisch aan te kunnen passen

file mkdir [file join [file dirname [info script]] log]
set time [clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]
set logname [file join [file dirname [info script]] log "copyfile-$time.log"]

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
  
  log info "Moving items: start"
  # handle_folder_name $namespace $src_folder $target_folder
   
  # load_test $namespace $src_folder $target_folder  $attachments_dir $mails_per_sec $runtime_sec $rampup_sec $max_pacing_msec $mail_types
  load_test $src_folder $target_folder $mails_per_sec $runtime_sec $rampup_sec $mail_types
  
  # test_stuff
  log info "Moving items: finished"
}

proc load_test {src_folder target_folder mails_per_sec runtime_sec rampup_sec mail_types} {
	global dir_ndx
	set dir_ndx 0
	#set fl_source [find_folder_path $namespace $src_folder]
	#set fl_target [find_folder_path $namespace $target_folder]
	
	# src_files - list of (cumulative frequency%, frequency, subject, msg com object)
	set src_files [det_src_files $src_folder $mail_types]
	log debug "src_files: $src_files"
	
	# test_choose_mails $src_files
	
	set start_test_sec [clock seconds]
	set end_test_sec [expr $start_test_sec + $runtime_sec]
	while {[clock seconds] < $end_test_sec} {
		set start_it_msec [clock milliseconds]
		set elapsed_start_sec [expr [clock seconds] - $start_test_sec]
		# set subj [copy_random_msg $src_files $fl_target $attachments_dir]
		set subj [copy_random_file $src_files $target_folder]
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
	  log info "Subject: $subj, count: $msg_counts($subj)"
	  incr totalcount $msg_counts($subj)
	}
	log info "Total messages sent: $totalcount"
	set nps [expr 1.0*$totalcount/([clock seconds] - $start_test_sec)]
	log info "#msg/sec: [format %.3f $nps]"
	log info "#msg/min: [format %.3f [expr 60.0*$nps]]"
}

proc det_wait_msec {rampup_sec mails_per_sec elapsed_start_sec start_it_msec end_it_msec} {
	if {$elapsed_start_sec < $rampup_sec} {
		#T = huidige tijd in sec, tijd bij de start van het mail aanmaken.
		#X = doel tps
		#R = ramup periode in seconden
		set discr [expr (1.0*$elapsed_start_sec*$mails_per_sec)**2 + (4.0*$mails_per_sec*$rampup_sec)]
		set pacing_msec [expr round(1000.0 * (-$elapsed_start_sec*$mails_per_sec + sqrt($discr)) / (2.0*$mails_per_sec))]
		#discr = (TX)^2 + 4XR
		#pacing = (-TX + sqrt(discr)) / (2X)
	} else {
		set curr_mails_per_sec $mails_per_sec
		set pacing_msec [expr round(1000.0 / $curr_mails_per_sec)]
	}
	log debug "current pacing msec: $pacing_msec"
	if {$pacing_msec == "Inf"} {
	  breakpoint
	}
	#if {$pacing_msec > $max_pacing_msec} {
	#  set pacing_msec $max_pacing_msec
	#}
	set wait_msec [expr $pacing_msec - ($end_it_msec - $start_it_msec)]
	log debug "time used to copy mail: [expr ($end_it_msec - $start_it_msec)]"
	log debug "current wait msec: $wait_msec"
	return $wait_msec
}

proc det_src_files {src_folder mail_types} {
  # mails: dict from subject to mail-com-object
  set files [get_files $src_folder]
  log debug "files: $files"
  set sum_freq [det_sum_freq $mail_types]
  log debug "sum_freq: $sum_freq"
  set res {}
  set cum_freq 0.0
  foreach {subject freq} $mail_types {
    set cum_freq [expr $cum_freq + (1.0 * $freq / $sum_freq)]
	lappend res [list $cum_freq $freq $subject [dict get $files $subject]]
  }
  log debug "Cumulative sum (should be 1.00): $cum_freq"
  return $res
}

proc get_files {src_folder} {
	set d [dict create]
	foreach filename [lsort [glob -directory $src_folder -type f *]] {
		dict set d [file tail $filename] $filename
	}
	return $d
}

proc det_sum_freq {mail_types} {
  set sum 0.0
  foreach {_ freq} $mail_types {
    set sum [expr $sum + $freq]
  }
  return $sum
}

proc copy_random_file {src_files target_dir} {
	log debug "copy_random_file - start"
	set file [choose_random_file $src_files]
	#log debug "mail chosen"
	copy_item $file $target_dir
	set subj [file tail $file]
	log debug "copy_random_file - end"
	return $subj
}

proc copy_item {file target_dir} {
	global dir_ndx
	log debug "copy_item - start"
	set ts [current_time_for_subject]
	set subject "Perftest-$ts-[file tail $file]"
	# file copy $file [file join $target_dir $subject]
	incr dir_ndx
	if {$dir_ndx > 14} {
	  set dir_ndx 1
	}
	set target_dir2 "$target_dir[format %02d $dir_ndx]"
	file mkdir $target_dir2
	file copy $file [file join $target_dir2 $subject]
	# ook mtime aanpassen
	file mtime [file join $target_dir2 $subject] [clock seconds]
	log perf "Created file - subject=$subject"
	log debug "copy_item - end"
}

# returns - mail com object.
proc choose_random_file {src_files} {
  set item [lindex $src_files 0]
  set rnd [expr rand()]
  foreach item $src_files {
    if {$rnd < [lindex $item 0]} {
	  return [lindex $item 3]
	}
  }
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

main $argv

file copy -force $logname [file join [file dirname [info script]] log "copyfile-last.log"]
