#! /usr/bin/env tclsh

source libnewpc.tcl

proc main {argv} {
    check_executable
    
    check_package_ndv
    
    set_log_global info

    
  set options {
    {install "Install new packages (using apt-get, use sudo)"}
    {extra.arg "" "Check extra stuff, eg for PC or laptop. use 'list' to show options"}
      {config "Check config with repo using configrepo.tcl"}
  }
  set usage ": [file tail [info script]] \[options]"
    set my_argv $argv ; # so only my_argv changes, not main/global argv
    set opt [getoptions my_argv $options $usage]
  check_machine $opt
}

# check if the tclsh is ActiveTcl. If not, (try to) restart with ActiveTcl
proc check_executable {} {
    global argv0 argv
    
    if {[regexp {Active} [file_link_final [info nameofexecutable]]]} {
	logger "Already ActiveTcl, continue"
    } else {
	set exe "~/bin/tclsh"
	if {[file exists $exe]} {
	    logger "Calling tclsh recursive: $exe"
	    set res [exec -ignorestderr $exe $argv0 {*}$argv]
	    logger "res of rec exec: \n$res"
	   
	    exit 0 ; # don't continue in this exe/script.
	} else {
	    logger "No ~/bin/tclsh found, run bootstrap.tcl"
	    exit 1
	}
    }
}

proc check_package_ndv {} {
    set res 0
    catch {
	package require ndv
	set res 1
    }
    if {$res == 0} {
	logger "Could not load package ndv, run bootstrap.tcl"
	exit 1
    }
}

proc check_machine {opt} {
  global tcl_platform
  set os [string tolower $tcl_platform(os)]
  check_os_$os $opt

  if {[:extra $opt] != ""} {
    if {[:extra $opt] == "list"} {
      logger "Extra checks: pc, laptop"
    } else {
      set extras [split [:extra $opt] ","]
      foreach extra $extras {
        check_os_${os}_${extra} $opt  
      }
    }
  }
  if {[:config $opt]} {
    exec -ignorestderr ../configrepo/configrepo.tcl
  }
}

proc check_os_linux {opt} {
  set tools_aptget {
    unison unison
    gedit gedit
    krusader krusader
    7z p7zip-full
    git git
    mount.nfs nfs-common
    mpg321 mpg321
    vlc {vlc-nox vlc}
    emacs emacs
    psql {postgresql postgresql-contrib}
    pgadmin3 pgadmin3
    keepassx keepassx
    java openjdk-8-jre-headless
    xdotool xdotool
    autojump autojump
    dropbox nautilus-dropbox
    libreoffice libreoffice
    rlwrap rlwrap
    xchm xchm
    nmon nmon
    inotifywait inotify-tools
    sqlite3 sqlite3
  }
  #     bladibla bladibal
  check_apt_get $opt $tools_aptget
}

proc check_apt_get {opt tools_aptget} {
  foreach {tool aptlist} $tools_aptget {
    set path [which $tool]
    if {$path == ""} {
      logger "Not found: $tool"
      if {[:install $opt]} {
        foreach apt $aptlist {
          logger "sudo apt-get install $apt"
          set res [exec_sudo apt-get --yes install $apt]
          if {$res != 0} {
            logger "result: $res"
            logger "Install probably failed: $apt"
          }
        }
      } else {
        logger "Use -install to install: $aptlist"
      }
    } else {
      log debug "Ok: $tool found in $path"
    }
  }
}

proc check_os_linux_pc {opt} {
  log info "Check extra linux stuff for PC"
  check_apt_get $opt {
    ktorrent ktorrent
  }
}

proc check_os_linux_laptop {opt} {
  log info "Check extra linux stuff for LAPTOP"
}

proc check_os_windows {opt} {
  
}


main $argv
