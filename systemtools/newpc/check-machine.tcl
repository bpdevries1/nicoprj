#! /usr/bin/env tclsh

package require ndv

set_log_global info

proc main {argv} {
  set options {
    {install "Install new packages (using apt-get, use sudo)"}
    {extra.arg "" "Check extra stuff, eg for PC or laptop. use 'list' to show options"}
    {config "Check config with repo using configrepo.tcl"}
  }
  set usage ": [file tail [info script]] \[options]"
  set opt [getoptions argv $options $usage]
  check_machine $opt
}

proc check_machine {opt} {
  global tcl_platform
  set os [string tolower $tcl_platform(os)]
  check_os_$os $opt

  if {[:extra $opt] != ""} {
    if {[:extra $opt] == "list"} {
      puts "Extra checks: pc, laptop"
    } else {
      set extras [split [:extra $opt] ","]
      foreach extra $extra {
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
      puts "Not found: $tool"
      if {[:install $opt]} {
        foreach apt $aptlist {
          puts "sudo apt-get install $apt"
          set res [exec_sudo apt-get install $apt]
          if {$res != 0} {
            puts "result: $res"
            puts "Install probably failed: $apt"
          }
        }
      } else {
        puts "Use -install to install: $aptlist"
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

proc exec_sudo {args} {
  do_exec sudo {*}$args
}

proc do_exec {args} {
  log debug "executing: $args"
  set res -1
  catch {
    set res [exec {*}$args]
  } result options
  log debug "res: $res"
  log debug "result: $result"
  log debug "options: $options"
  set exitcode [det_exitcode $options]
  log debug "exitcode: $exitcode"
  return $exitcode
}

proc det_exitcode {options} {
  if {[dict exists $options -errorcode]} {
    set details [dict get $options -errorcode]
  } else {
    set details ""
  }
  if {[lindex $details 0] eq "CHILDSTATUS"} {
    set status [lindex $details 2]
    return $status
  } else {
    # No errorcode, return 0, as no error has been detected.
    return 0
  }
}

proc which {binary} {
  set res ""
  catch {
    set res [exec which $binary]
  }
  return $res
}

main $argv
