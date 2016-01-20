# puts "Tcl version: $tcl_version"

# lappend ::auto_path [file dirname [zvfs::list */Bwidget1_8/pkgIndex.tcl]]

# [2015-11-17 14:00:55] zvfs werkt alleen binnen wraptclsh, dus catch eromheen.
catch {lappend ::auto_path [file dirname [zvfs::list */tcom3.9/pkgIndex.tcl]]}
# lappend ::auto_path [file dirname [zvfs::list */ndv0.1.1/pkgIndex.tcl]]
# ndv laadt ook andere packages, dus eerst even zonder, toch alleen voor dingen als logging.

package require tcom
# package require ndv

# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

file mkdir [file join [file dirname [info script]] log]
set time [clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]
set logname [file join [file dirname [info script]] log "movemail-$time.log"]

proc main {argv} {
  global argv0
  # global namespace 
  lassign $argv config
  if {$config == ""} {
    puts "syntax: $argv0 <config.tcl>"
    exit 1
  }
  source $config
  
  # start applicatie
  # set app [optcl::new Outlook.Application]
  # set app [::tcom::ref getactiveobject "Outlook.Application"]
  set app [tcom::ref getactiveobject "Outlook.Application"]
  set namespace [$app GetNamespace MAPI]
  
  log info "Moving items: start"
  # handle_folder_name $app $namespace "/Nico.de.Vreeze@rabobank.com/Diversen/Test"
  # handle_folder_name $app $namespace "Nico.de.Vreeze@rabobank.com/Diversen/Test"
  handle_folder_name $app $namespace $src_folder $target_folder
  log info "Start - After 500"
  after 500
  log info "Middle - After 500"
  after 500
  log info "Moving items: finished"
}

proc handle_folder_name {app namespace src_folder target_folder} {
	# fl_source = @ff.find_folder_path(ns, folder_name)
	set fl_source [zoekFolderPad $namespace $src_folder]
	
	# #{fl_source.name}
	log info "Found folder, name = [$fl_source Name]"
	
	# set fl_target [zoekFolderPad $namespace "Nico.de.Vreeze@rabobank.com/Diversen/Test2"]
	set fl_target [zoekFolderPad $namespace $target_folder]
	#fl_target = @ff.find_folder_path(ns, "/Nico.de.Vreeze@rabobank.com/Diversen/Test2")
	#handle_items_test(myApp, fl_source, fl_target)
	handle_items_test $app $fl_source $fl_target
}

proc handle_items_test {app fl_source fl_target} {
	log info "#items in [$fl_source Name]: [[$fl_source Items] Count]"
	tcom::foreach msg [$fl_source Items] {
		copy_item_test $msg $fl_target
	}
}

proc copy_item_test {msg fl_target} {
	# show_message $msg
	set msg2 [$msg Copy]
	$msg2 Subject "Test NdV - [$msg Subject]"
	# log info "Todo: Attachments"
	set attachments [$msg2 Attachments]
	tcom::foreach att $attachments {
	  set filename "c:\\PCC\\Nico\\aaa\\Test NdV.pdf"
	  $att SaveAsFile $filename
	  $attachments Add $filename [$att Type] 1 "Test NdV.pdf"
	  $att Delete
	}
	set ok 0
	catch {
		$msg2 Save
		$msg2 Move $fl_target
		set ok 1
	} 
	if {!$ok} {
	  log warn "Saving failed (Enterprise Vault?)"
	  $msg2 Delete
	}
}

#### voorlopig even alles in 1 file ######

proc zoekFolderPad {ns pad} {
  # set folders [$ns : Folders]
  log debug "namespace: $ns"
  set f $ns
  # breakpoint
  set parts [split $pad "/"]
  foreach part $parts {
	 set folders [$f Folders]
     set f [zoekFolder $folders $part]
  }
  log info "Found folder path: [$f Name]"
  return $f
}

# zoek folder 1 niveau diep
proc zoekFolder {folders naam} {
  log debug "zoekfolder: $naam (folders: $folders)"
  # set i [$folders : count]
  tcom::foreach folder $folders {
    # log info "found folder: [$folder Name]"
	if {[$folder Name] == $naam} {
		return $folder
	}
  }
  log warn "niet gevonden: $naam"
  return 0
}

proc log {level str} {
	global logname
	set f [open $logname a]
	puts $f "\[[current_time]\] \[$level\] $str"
	close $f
}

proc current_time {} { 
  set msec [clock milliseconds]
  set sec [expr $msec / 1000]
  set msec2 [expr $msec % 1000]
  return "[clock format $sec -format "%Y-%m-%d %H:%M:%S.[format %03d $msec2] %z"]"
}

main $argv

file copy -force $logname [file join [file dirname [info script]] log "movemail-last.log"]
