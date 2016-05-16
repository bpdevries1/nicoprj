# wasservers.machine.analyse.tcl
# param1: waar loopt jmeter, nt, was of db?
# param2: directory waar logs in staan.
# param3: logdirname, bv. WSVR_XXX_1
# param4: koppeling logdir aan server name, bv. extwas1.WSVR_OL116U76_1

package require Itcl

# class maar eenmalig definieren
if {[llength [itcl::find classes CWasServerAnalyse]] > 0} {
	return
}

source [file join $env(CRUISE_DIR) checkout lib perflib.tcl]
source [file join $env(CRUISE_DIR) checkout analyse CAnalysePropFile.tcl]
source [file join $env(CRUISE_DIR) checkout analyse CWasLog.tcl]

addLogger ws_mach_an
setLogLevel ws_mach_an info

itcl::class CWasServerAnalyse {

	public method analyse {reslogs_dir machine_name server_name} {
		log "start" debug ws_mach_an

		if {![have_input_files $reslogs_dir $machine_name $server_name]} {
			log "Don't have inputfiles for ${machine_name}.${server_name}, returning" debug serv_mach_an
			return 
		}
	
		# log "jmeter_loc: $jmeter_loc" debug ws_mach_an
		log "reslogs_dir: $reslogs_dir" debug ws_mach_an
		log "machine_name: $machine_name" debug ws_mach_an
		log "server_name: $server_name" debug ws_mach_an
		
		# log "logdirname: $logdirname" debug ws_mach_an
		# log "dirmachines: $dirmachines" debug ws_mach_an
		log "cctimestamp: $cctimestamp" debug ws_mach_an
		log "testrun: $testrun" debug ws_mach_an
		
		# set analyse_prop_name [file join $reslogs_dir analyse.prop]
	
		set waslog [CWasLog #auto]
		# $waslog set_filename $reslogs_dir $logdirname
		$waslog set_filename $reslogs_dir $machine_name $server_name
	
		# set anprop [::CAnalysePropFile::new_analyse_prop_file $analyse_prop_name $testbuild $testrun]
		# set anprop [::CAnalysePropFile::new_analyse_prop_file $analyse_prop_name $cctimestamp $testrun]
		set anprop [::CAnalysePropFile::new_analyse_prop_file]
		set group was_mach_an
	
		if {[$waslog exists]} {
	
			log "counting lines of full was.log..." debug ws_mach_an
			set nlines [$waslog det_nlines]
			$anprop set_property ${machine_name}.${server_name}.systemout.nregels $nlines $group
		
			log "filtering starttime..." debug ws_mach_an
			# $waslog filter_starttime $dirmachines $anprop
			$waslog filter_starttime $machine_name $server_name $anprop
	
			log "filtering exceptions..." debug ws_mach_an
			$waslog filter_exceptions
	
			log "counting exceptions..." debug ws_mach_an
			$waslog count_exceptions
	
			log "counting nlines exceptions..." debug ws_mach_an
			set nlines_exception [$waslog det_nlines_exception]
			$anprop set_property ${machine_name}.${server_name}.systemout_exceptie.nregels $nlines_exception $group
	
			log "filtering url times..." debug ws_mach_an
	
			$waslog filter_url_times
		} else {
			$anprop set_property ${machine_name}.${server_name}.systemout.nregels -1 $group
			$anprop set_property ${machine_name}.${server_name}.systemout_exceptie.nregels -1 $group
		}
	
		$anprop writefile
	
		log "finished" debug ws_mach_an
	}

	public method analyse_old {jmeter_loc reslogs_dir logdirname dirmachines cctimestamp testrun} {
		log "start" debug ws_mach_an

		if {![have_input_files $reslogs_dir $logdirname]} {
			log "Don't have inputfiles for $logdirname, returning" debug serv_mach_an
			return 
		}
	
		log "jmeter_loc: $jmeter_loc" debug ws_mach_an
		log "reslogs_dir: $reslogs_dir" debug ws_mach_an
		log "logdirname: $logdirname" debug ws_mach_an
		log "dirmachines: $dirmachines" debug ws_mach_an
		log "cctimestamp: $cctimestamp" debug ws_mach_an
		log "testrun: $testrun" debug ws_mach_an
		
		# set analyse_prop_name [file join $reslogs_dir analyse.prop]
	
		set waslog [CWasLog #auto]
		$waslog set_filename $reslogs_dir $logdirname
	
		# set anprop [::CAnalysePropFile::new_analyse_prop_file $analyse_prop_name $testbuild $testrun]
		# set anprop [::CAnalysePropFile::new_analyse_prop_file $analyse_prop_name $cctimestamp $testrun]
		set anprop [::CAnalysePropFile::new_analyse_prop_file]
		set group was_mach_an
	
		if {[$waslog exists]} {
	
			log "counting lines of full was.log..." debug ws_mach_an
			set nlines [$waslog det_nlines]
			$anprop set_property $logdirname.systemout.nregels $nlines $group
		
			log "filtering starttime..." debug ws_mach_an
			$waslog filter_starttime $dirmachines $anprop
	
			log "filtering exceptions..." debug ws_mach_an
			$waslog filter_exceptions
	
			log "counting exceptions..." debug ws_mach_an
			$waslog count_exceptions
	
			log "counting nlines exceptions..." debug ws_mach_an
			set nlines_exception [$waslog det_nlines_exception]
			$anprop set_property $logdirname.systemout_exceptie.nregels $nlines_exception $group
	
			log "filtering url times..." debug ws_mach_an
	
			$waslog filter_url_times
		} else {
			$anprop set_property $logdirname.systemout.nregels -1 $group
			$anprop set_property $logdirname.systemout_exceptie.nregels -1 $group
		}
	
		$anprop writefile
	
		log "finished" debug ws_mach_an
	}

	private method have_input_files {reslogs_dir machine_name server_name} {
		if {[file exists [file join $reslogs_dir "${machine_name}.${server_name}.SystemOut.log"]]} {
			return 1
		} else {
			return 0
		}
	}

	private method have_input_files_old {reslogs_dir logdirname} {
		if {[file exists [file join $reslogs_dir "$logdirname.SystemOut.log"]]} {
			return 1
		} else {
			return 0
		}
	}
}

proc main {argc argv} {
	global argv0
	log "$argv0: start" debug ws_mach_an
	check_params $argc $argv

	set jmeter_loc [lindex $argv 0]
	set reslogs_dir [lindex $argv 1]
	set logdirname [lindex $argv 2]
	set dirmachines [lindex $argv 3]
  set cctimestamp [lindex $argv 4]
  set testrun [lindex $argv 5]
  
	set wasserv_an [CWasServerAnalyse #auto]
	$wasserv_an analyse $jmeter_loc $reslogs_dir $logdirname $dirmachines $cctimestamp $testrun
}

proc check_params {argc argv} {
	global argv0
	if {$argc != 6} {
		fail "syntax: tclsh $argv0 <jmeter_loc> <reslogs_dir> <logdirname> <dirmachines> <cctimestamp> <testrun>; got: $argv"
	}
}

# aanroepen vanuit Tcl, deze voor debugging.
if {[file tail $argv0] == [file tail [info script]]} {
  main $argc $argv
}


