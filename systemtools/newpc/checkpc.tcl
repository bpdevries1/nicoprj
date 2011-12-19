# check of alles op pc is geinstalleerd.
# Versie: $Id$

# 13-7-2011 hier staan best specifieke dingen in, dus mogelijk dit script aanpassen bij elke nieuwe install.
# nu niet direct reden om generieke en specifieke te splitsen. Zou wel zo zijn als ik meerdere windows pc's zou hebben.

#met andere interp de perf toolset ook aanroepen.

#iets met handmatige checks.

package require Itcl
package require ndv ; # logging
package require cmdline 
package require csv ; # parse aliases
package require Tclx ; # recursive glob
package require tcom ; # read .lnk files

itcl::class CCheckPC {
	global env

	private common log
	# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
	set log [::ndv::CLogger::new_logger [file tail [info script]] info]

	private common PROJECT_DIR "c:/temp/install"
	private common USERNAME $env(USERNAME)
	
	# 13-7-2011 kan in onderstaande lijst geen ${USERNAME} gebruiken, omdat het tussen accolades staat...
	private common LST_PATHS {
		c:/bin/freeall.bat
		"C:/Documents and Settings/ndvreeze/.freemind/user.properties"
		"C:/Documents and Settings/ndvreeze/.jedit/jars/BufferTabs.jar"
		"C:/Documents and Settings/ndvreeze/Application Data/.thinkingrock/tr-2.2.1/config/Preferences/org/netbeans/core.properties"
		"C:/Documents and Settings/ndvreeze/Application Data/MySQL"
		"C:/Documents and Settings/ndvreeze/Teapot/repository/package/tcl/lib/struct_set-2.2.1"
		"C:/util/perf/lqn/LQN Solvers/lqns.exe"
		c:/util/4nt/4NT.exe
		C:/util/editor/pfe/pfe32.exe
		C:/util/totalcmd/TOTALCMD.EXE
		C:/bieb/ICT-books/Coders.at.Work.Sep.2009.pdf
		c:/cruiseresults
		c:/develop
		c:/install
		c:/MySQL
		c:/nico
		C:/nico/outlook/Personal.pst
		c:/perfeng
		c:/perftoolset
		c:/progs
		c:/projecten
		c:/util
		"C:/Documents and Settings/ndvreeze/Local Settings/Application Data/Microsoft/Outlook/outlook.ost"
	}
	
  # 7-10-2009 teacup verify doet 't wel, zegt nul fouten, toch return code 1. Laat eerst maar.
  private common LST_COMMANDS {
    "teacup verify"
  }

  # 10-10-2009: paar verwijderd uit PATH, progs doen het wel: jdk1.6, Haskell, LQN,Graphviz
  # 13-7-2011 Tcl85, python removed.
  private common LST_PATH {
    ruby
    "c:\\bin"
    cygwin    
  }
  
	public proc new {} {
		set result [uplevel {namespace which [CCheckPC \#auto]}]
		return $result	
	}
	
	private variable lst_errors
	private variable ar_done
	
	public method check_main {argc argv} {
		$log debug "argv: $argv"
		set options {
				{s          "Start programs (from start menu)"}
        {nm         "Don't check manual-todo file"}
		}
		set usage ": checkpc \[options] :"
		array set params [::cmdline::getoptions argv $options $usage]

		init
		
		check_all
		
		#if {$params(s)} {
		#	start_programs
		#}
		
    check_start_menu $params(s) 
    
		report_all
		
    # @todo weer aanzetten.
		if {!$params(nm)} {
      handle_manual
    }
	}
	
	private method init {} {
		set lst_errors {}
	}
	
	private method check_all {} {
		$log debug "check all"
		check_perftoolset
		check_paths_existing
    check_commands
    check_4nt_aliases
    check_env_path
	}
	
	private method start_programs {} {
		$log info "Start programs in start menu"
		# kijk in C:\Documents and Settings\ndvreeze\Menu Start
	}
	
	private method check_perftoolset {} {
		$log debug "check_perftoolset"
		
		# interp limit $i command -value 1000
		set check_install_bat "c:/perftoolset/testprj/demo/check-install.bat"
		# set check_install_bat "c:/perftoolset/testprj/demo/check-install.bat2"
		if {[file exists $check_install_bat]} {
      set i [interp create]
      interp eval $i set cib $check_install_bat
		  set res [interp eval $i {
        set old_pwd [pwd]
        # cd c:\\perftoolset\\testprj\\demo
        # cd [file dirname $check_install_bat]
        cd [file dirname $cib]
        # exec {check-install.bat}
        # exec [file tail $check_install_bat]
        puts "Executing ($cib): [file tail $cib] in dir [pwd]"
        exec [file tail $cib]
        cd $old_pwd
      }]
    } else {
      $log warn "check-install.bat not found: $check_install_bat"
      lappend lst_errors "perf toolset check-install.bat not found: $check_install_bat"
      set res ""
    }
		foreach line [split $res "\n"] {
			if {[regexp {^ERROR} $line]} {
				$log debug $line
				lappend lst_errors $line
			}
		}
		$log trace "res: $res"
	}
	
	private method check_paths_existing {} {
		foreach path $LST_PATHS {
			check_path_existing $path
		}
	}
	
  private method check_path_existing {path} {
    if {![file exists $path]} {
      lappend lst_errors "Path does not exist: $path"
      return 0
    } else {
      return 1 
    }
  }
  
  private method check_commands {} {
    foreach command $LST_COMMANDS {
      if {[catch [list exec {*}$command] res]} {
        # teacup verify gives "0 problems", is ok.
        if {![regexp {0 problems} $res]} {
          lappend lst_errors "Error executing command $command: $res"
        }
      }
    }
  }

  private method check_4nt_aliases {} {
    set f [open "c:/nico/settings/4dos/alias.dat" r]
    set text [read $f]
    close $f
    set lst_aliases [valid_lines $text ":"]
    foreach alias $lst_aliases {
      $log debug "checking: $alias"
      set lst_elements [::csv::split $alias " "]
      foreach el $lst_elements {
        set path_expanded [expand_path $el]
        # bij 4nt alias een @ ervoor
        regsub {^@} $path_expanded "" path_expanded
        if {[is_path $path_expanded]} {
          $log debug "checking alias elt: $el"
          if {![file exists $path_expanded]} {
            # alias vrij lang, dus newline --- toevoegen.
            lappend lst_errors "Alias to non-existing path: $alias ($el => $path_expanded)\n---" 
          }
        }
      }
    }
  }

  # check existence of all items in start menu: regular files or shortcuts/links
  # don't start the progs here, this is in a different place.
  private method check_start_menu {start_programs} {
		set start_menu_dir [det_start_menu_dir]
    if {$start_menu_dir == ""} {
      return 
    }
    set lst_checked [read_checked]
		# kijk in C:\Documents and Settings\ndvreeze\Menu Start
    set sh [::tcom::ref createobject "WScript.Shell"]
    for_recursive_glob filename [list $start_menu_dir] "*" {
      #$log debug "checking file in startmenu: $filename"      
      if {![file isfile $filename]} {
        continue ; # skip directories 
      }
      if {[string tolower [file extension $filename]] == ".lnk"} { 
        set lnk [$sh CreateShortcut [file nativename $filename]]
        set tp [$lnk TargetPath]
        #$log debug "$tp [$lnk Arguments] in dir: [$lnk WorkingDirectory]"
        if {$tp != ""} {
          if {[file exists $tp]} {
            if {$start_programs} {
              if {![::struct::set contains $lst_checked $filename]} {
                check_start_program $filename $lnk
              }
            }
          } else {
            lappend lst_errors "Link target in startmenu doesn't exist: $filename => $tp \n---"  
          }
        } else {
          $log debug "Empty link target for: $filename"
        }
      } else {
        if {[string tolower [file extension $filename]] != ".url"} {
          $log warn "Something other than link in startmenu: $filename"
        }
      }
    }
  }
  
	private method det_start_menu_dir {} {
		global env
		if {[file exists [file join "C:/Documents and Settings" $env(USERNAME) "Menu Start"]]} {
			return [file join "C:/Documents and Settings" $env(USERNAME) "Menu Start"]
		} elseif {[file exists [file join "C:/Documents and Settings" $env(USERNAME) "Start Menu"]]} {
			return [file join "C:/Documents and Settings" $env(USERNAME) "Start Menu"]
		} else {
			$log error "ERROR: Could not determine start menu"
			lappend	lst_errors "ERROR: Could not determine start menu"
      return ""
		}
	}
	
  private method check_start_program {filename lnk} {
    set tp [$lnk TargetPath]
    puts "===\nStart program: $filename => $tp"
    puts -nonewline "(y/n): "
    flush stdout
    gets stdin answer
    if {$answer == "y"} {
      puts "Executing $filename ..."
      exec $tp {*}[$lnk Arguments]
      puts "Done."
    }
    record_checked $filename
  }
  
  private method record_checked {filename} {
    set f [open [file join $PROJECT_DIR "checked-start-menu.txt"] a]
    puts $f $filename    
    close $f
  }
  
  private method read_checked {} {
    if {[file exists [file join $PROJECT_DIR "checked-start-menu.txt"]]} {
      set f [open [file join $PROJECT_DIR "checked-start-menu.txt"]  r]
      set text [read $f]
      close $f
      return [split $text "\n"]
    } else {
      return {} 
    }
  }
  
  # path als er een backslash inzit.
  private method is_path {str} {
    set res [regexp {\\} $str]
    if {[regexp {\*} $str]} {
      set res 0
    }
    return $res
  }

  # expand environment vars
  private method expand_path {path} {
    set result [regsub-eval-all {%([^%]+)%} $path {get_env \1}]
    return $result
  }
  
  private method get_env {par} {
    global env
    set res $par
    catch {set res $env($par)}
    return $res
  }
  
  # deze van: http://wiki.tcl.tk/987
  # snap 'em niet zo, ook niet ingedoken, werkt wel.
  private method regsub-eval-all {re string cmd} {
    subst [regsub -all $re [string map {\[ \\[ \] \\] \$ \\$ \\ \\\\} $string] "\[$cmd\]"]
  }
  
  private method check_env_path {} {
    global env
    foreach check_path $LST_PATH {
      if {[string first $check_path $env(PATH)] == -1} {
        lappend lst_errors "Not found in env(PATH): $check_path" 
      }
    }
  }
  
	private method report_all {} {
		puts "======================="
		puts "=== All errors:     ==="
		puts "======================="
		foreach item $lst_errors {
			puts $item
		}
		puts "======================="
		puts "Total errors: [llength $lst_errors]"
	}
	
	private method handle_manual {} {
		file mkdir $PROJECT_DIR
		set lst_done [read_manual_done]
		set lst_todo [read_manual_todo]
		# set lst_still_todo [::struct::set difference $lst_todo $lst_done]
		# set difference zorgt voor andere volgorde, dus anders doen:
		set lst_still_todo [::struct::list filterfor line $lst_todo {![::struct::set contains $lst_done $line]}]
		
		puts "======================="
		puts "=== Still todo:     ==="
		puts "======================="
		foreach line $lst_still_todo {
			puts $line
		}
	}
	
	private method read_manual_done {} {
		set manual_done_filename [file join $PROJECT_DIR "manual-done.txt"] 
		array unset ar_done
		if {[file exists $manual_done_filename]} {
			set f [open $manual_done_filename r]
			set text [read $f]
			close $f
			return [valid_lines $text]
		} else {
			set f [open $manual_done_filename w]
			puts $f "# add manual done items to this file"			
			close $f
			return {}
		}
	}
	
	private method read_manual_todo {} {
		$log debug "pwd: [pwd]"
		set f [open "manual-todo.txt" r]
		set text [read $f]
		close $f
		return [valid_lines $text]
	}
	
	# input: blob of text
	# output: valid lines, ie not empty, and not starting with #, also trimmed.
	private method valid_lines {text {comment_start "#"}} {
		# onderstaande kan ook vast in 1 regel, maar dit is helderder en debugt makkelijker.
		set lst [split $text "\n"]
		set lst [::struct::list map $lst {string trim}]
		set lst [::struct::list filterfor line $lst {(![regexp "^${comment_start}" $line]) && ($line != "")}] 
		return $lst
	}
	
}

proc main {argc argv} {
	set cc [CCheckPC::new]
	$cc check_main $argc $argv
	
}

main $argc $argv

