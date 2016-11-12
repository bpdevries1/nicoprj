#! /usr/bin/env tclsh

# this one should work with regular tclsh, not activeTcl specifically.
# goal is we have a working ActiveTcl shell with a working package ndv,
# including all other needed packages, like control.

source libnewpc.tcl

proc main {argv} {
    global argv0
    init_logger $argv
    # first make sure we are using ActiveTcl
    #puts "argv0: $argv0"
    set exe [info nameofexecutable]
    logger "Exe: $exe"
    set exe_final [file_link_final $exe]
    logger "Exe final: $exe_final"
    if {[regexp {Active} $exe_final]} {
	logger "Already have ActiveTcl: $exe_final"
    } else {
	handle_active_tcl $exe_final
	# only once recur, so check --recursive here.
	if {[lsearch $argv "--recursive"] >= 0} {
	    logger "Already called recursive, don't do again"
	    exit 1
	} else {
	    logger "Calling tclsh recursive: ~/bin/tclsh"
	    set res [exec -ignorestderr ~/bin/tclsh $argv0 {*}$argv --recursive]
	    puts "res of rec exec: \n$res"
	    exit ; # niet na terugkomst hierin nog dingen uitvoeren.
	}
    }

    # check and install other packages, like control
    install_other_packages
    
    # then check if package ndv is available.
    install_package_ndv
}

proc handle_active_tcl {exe_final} {
    # log "Handle active tcl: TODO"
    set l [glob -nocomplain -directory /opt -type d ActiveTcl*]
    if {[llength $l] == 0} {
	logger "Manually install ActiveTcl in /opt"
	exit 1
    }
    set dir [lindex [lsort $l] end]
    set exe [file join $dir bin tclsh]
    if {![file exists $exe]} {
	logger "Cannot find tcl executable: $exe, solve manually"
	exit 1
    }
    file mkdir ~/bin
    file delete ~/bin/tclsh
    file link -symbolic ~/bin/tclsh $exe
}

proc install_other_packages {} {
    # 12-11-2016 only these are extra needed in ActiveTcl for package ndv
    foreach pkg {control tdbc tdbc::sqlite3} {
	install_package $pkg
    }
}

proc install_package {pkg} {
    set res 0
    catch {
	package require $pkg
	set res 1
    }
    if {$res} {
	logger "Tcl package ok: $pkg"
    } else {
	logger "Installing Tcl package: $pkg"
	set exe [file_link_final [info nameofexecutable]]
	set teacup [file normalize [file join $exe .. teacup]]
	set res ""
	catch {set res [exec -ignorestderr sudo $teacup install $pkg]} error_msg
	logger "result of install: $res"
	logger "error_msg: $error_msg"
    }
}

# use install.tcl script, should work with bootstrap.
proc install_package_ndv {} {
    global argv0
  # ~/bin/tclsh ./install.tcl 
    set res 0
    catch {
	package require ndv
	set res 1
    } error_res
    if {!$res} {
	logger "error: $error_res"
	logger "package ndv not installed yet, do now:"
	# exec ~/bin/tclsh ~/nicoprj/lib/install.tcl
	set install_tcl [file normalize [file join $argv0 .. .. .. lib install.tcl]]
	logger "install_tcl: $install_tcl"
	set old_dir [pwd]
	cd [file dirname $install_tcl]
	exec -ignorestderr ~/bin/tclsh $install_tcl
	cd $old_dir
    }
}

main $argv
