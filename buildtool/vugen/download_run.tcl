# [2016-08-18 15:01:52] Version for VuGen

# source [file join [perftools_dir] report read-report-dir.tcl]

# TODO: some hardcoded dirnames here, should read from config and/or determine dynamically.

task download_run {Download run from PC/ALM
  Call get-ALM-PC-testruns.tcl and unzip vugenlog to testruns dir for further processing
  with task report.
} {
  {testruns.arg "" "Download 'all' or given runs (csv) in testruns dir for project"}
} {
  global testruns_dir
  if {[regexp {<FILL IN>} $testruns_dir]} {
    puts "WARN: testruns_dir not set yet (in .bld/config.tcl): $testruns_dir"
    return
  }
  # opt available
  log debug "Download for VuGen"
  
  download_testruns $opt
}

proc download_testruns {opt} {
  global testruns_dir alm_domain alm_project
  set get_runs [file join [perftools_dir] loadrunner almpc get-ALM-PC-testruns.tcl]
  set almroot_dir [det_almroot_dir]
  if {[:testruns $opt] == "all"} {
    # call for every dir in testruns dir.
    log warn "Not implemented yet: download all"
    return
  } else {
    foreach run [split [:testruns $opt] ","] {
      set subdir [file join $testruns_dir "run${run}"]
      if {[file exists $subdir]} {
        set nfiles [llength [glob -nocomplain -directory $subdir *]]
        if {$nfiles > 0} {
          log info "Testrun $run already downloaded and unzipped before: $run, nfiles: $nfiles"
          continue
        }
      } else {
        log info "Subdir does not exists, so check ALM: $subdir"
      }
      # [2017-01-14 21:09:25] call get-ALM-PC-tests with exec (not with source and Tcl call for now)
      set alm_dir [file join $almroot_dir $run]
      if {[file exists $alm_dir]} {
        log info "Testrun $run already downloaded before: $run"
      } else {
        log info "Exec: tclsh $get_runs -firstrunid $run -lastrunid $run"
        set res [exec -ignorestderr tclsh $get_runs -domain $alm_domain -project $alm_project -firstrunid $run -lastrunid $run]
        puts $res
      }
      # and then unzip.
      # file mkdir $subdir
      unzip_file [file join $alm_dir VuserLog.zip] $subdir
    }
  }
}

proc det_almroot_dir {} {
  global alm_domain alm_project
  if {[catch {set alm_domain}]} {
    log warn "set alm_domain and alm_project in [config_tcl_name]"
    exit
  }
  # return [file join "c:/PCC/Nico/ALMdata" RI Ri_Shared_Environment]
  return [file join "c:/PCC/Nico/ALMdata" $alm_domain $alm_project]
}

proc unzip_file {zipfile dir} {
  global env
  log info "unzip $zipfile => $dir"
  set zipfile_win [det_win_file $zipfile]
  if {![file exists $zipfile_win]} {
    puts "zipfile does not exist: $zipfile"
    return
  }
  # file mkdir [file dirname $zipfile]
  file delete -force $dir
  file mkdir $dir
  set old_dir [pwd]
  cd $dir
  set old_path $env(PATH)
  set env(PATH) {c:\PCC\Util\cygwin\bin}
  puts "current dir: [pwd]"
  
  # exec "C:/PCC/Util/cygwin/lib/p7zip/7z.exe" x -tzip $zipfile
  # TODO: determine unzip.exe location dynamically.
  exec c:/PCC/util/cygwin/bin/unzip.exe $zipfile
  # file delete $zipfile_win
  cd $old_dir
  set env(PATH) $old_path
}  

proc unzip_old {filename target_dir} {
	puts "Unzipping $filename => $target_dir"
	try_eval {
		set output [exec /usr/bin/unzip $filename -d $target_dir]
		set result 1
	} {
		# print error info?
		set result 0
	}
	# als 't niet goed gaat, knalt 'ie wel, en wordt delete ook niet gedaan...
	# exit ; # for now, just one.
	return $result
}

proc det_win_file {cygwin_file} {
  if {[regexp {^/c/(.*)$} $cygwin_file z rest]} {
    return "c:/$rest"
  } else {
    # error "Cannot convert to windows name: $cygwin_file"
    # log warn "Possibly already windows name: $cygwin_file"
    return $cygwin_file
  }
}
