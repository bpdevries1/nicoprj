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


source [file join $env(CRUISE_DIR) checkout script lib CLogger.tcl]

itcl::class CWasServerAnalyse {
	private common log
	set log [CLogger::new_logger ws_mach_an info]


	public method analyse {reslogs_dir machine_name server_name} {
		 $log debug "start"

		if {![have_input_files $reslogs_dir $machine_name $server_name]} {
			 $log debug "Don't have inputfiles for ${machine_name}.${server_name}, returning"
			return 
		}
	
		# log "jmeter_loc: $jmeter_loc" debug ws_mach_an
		 $log debug "reslogs_dir: $reslogs_dir"
		 $log debug "machine_name: $machine_name"
		 $log debug "server_name: $server_name"
		
		# log "logdirname: $logdirname" debug ws_mach_an
		# log "dirmachines: $dirmachines" debug ws_mach_an
		 $log debug "cctimestamp: $cctimestamp"
		 $log debug "testrun: $testrun"
		
		# set analyse_prop_name [file join $reslogs_dir analyse.prop]
	
		set waslog [CWasLog #auto]
		# $waslog set_filename $reslogs_dir $logdirname
		$waslog set_filename $reslogs_dir $machine_name $server_name
	
		# set anprop [::CAnalysePropFile::new_analyse_prop_file $analyse_prop_name $testbuild $testrun]
		# set anprop [::CAnalysePropFile::new_analyse_prop_file $analyse_prop_name $cctimestamp $testrun]
		set anprop [::CAnalysePropFile::new_analyse_prop_file]
		set group was_mach_an
	
		if {[$waslog exists]} {
	
			 $log debug "counting lines of full was.log..."
			set nlines [$waslog det_nlines]
			$anprop set_property ${machine_name}.${server_name}.systemout.nregels $nlines $group
		
			 $log debug "filtering starttime..."
			# $waslog filter_starttime $dirmachines $anprop
			$waslog filter_starttime $machine_name $server_name $anprop
	
			 $log debug "filtering exceptions..."
			$waslog filter_exceptions
	
			 $log debug "counting exceptions..."
			$waslog count_exceptions
	
			 $log debug "counting nlines exceptions..."
			set nlines_exception [$waslog det_nlines_exception]
			$anprop set_property ${machine_name}.${server_name}.systemout_exceptie.nregels $nlines_exception $group
	
			 $log debug "filtering url times..."
	
			$waslog filter_url_times
		} else {
			$anprop set_property ${machine_name}.${server_name}.systemout.nregels -1 $group
			$anprop set_property ${machine_name}.${server_name}.systemout_exceptie.nregels -1 $group
		}
	
		$anprop writefile
	
		 $log debug "finished"
	}

	public method analyse_old {jmeter_loc reslogs_dir logdirname dirmachines cctimestamp testrun} {
		 $log debug "start"

		if {![have_input_files $reslogs_dir $logdirname]} {
			 $log debug "Don't have inputfiles for $logdirname, returning"
			return 
		}
	
		 $log debug "jmeter_loc: $jmeter_loc"
		 $log debug "reslogs_dir: $reslogs_dir"
		 $log debug "logdirname: $logdirname"
		 $log debug "dirmachines: $dirmachines"
		 $log debug "cctimestamp: $cctimestamp"
		 $log debug "testrun: $testrun"
		
		# set analyse_prop_name [file join $reslogs_dir analyse.prop]
	
		set waslog [CWasLog #auto]
		$waslog set_filename $reslogs_dir $logdirname
	
		# set anprop [::CAnalysePropFile::new_analyse_prop_file $analyse_prop_name $testbuild $testrun]
		# set anprop [::CAnalysePropFile::new_analyse_prop_file $analyse_prop_name $cctimestamp $testrun]
		set anprop [::CAnalysePropFile::new_analyse_prop_file]
		set group was_mach_an
	
		if {[$waslog exists]} {
	
			 $log debug "counting lines of full was.log..."
			set nlines [$waslog det_nlines]
			$anprop set_property $logdirname.systemout.nregels $nlines $group
		
			 $log debug "filtering starttime..."
			$waslog filter_starttime $dirmachines $anprop
	
			 $log debug "filtering exceptions..."
			$waslog filter_exceptions
	
			 $log debug "counting exceptions..."
			$waslog count_exceptions
	
			 $log debug "counting nlines exceptions..."
			set nlines_exception [$waslog det_nlines_exception]
			$anprop set_property $logdirname.systemout_exceptie.nregels $nlines_exception $group
	
			 $log debug "filtering url times..."
	
			$waslog filter_url_times
		} else {
			$anprop set_property $logdirname.systemout.nregels -1 $group
			$anprop set_property $logdirname.systemout_exceptie.nregels -1 $group
		}
	
		$anprop writefile
	
		 $log debug "finished"
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
	 $log debug "$argv0: start"
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



