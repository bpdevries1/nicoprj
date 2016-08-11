#!/usr/bin/env tclsh

# Build tool, mainly for VuGen scripts and libraries
# [2016-08-10 22:53] Starting to be useful for other kinds of projects (ahk, tcl, clj)

package require term
package require term::ansi::code::attr
package require term::ansi::send
term::ansi::send::import

package require ndv

set_log_global info

ndv::source_once task.tcl configs.tcl prjgroup.tcl prjtype.tcl selectfiles.tcl backup.tcl \
    inifile.tcl init.tcl lr_params.tcl templates.tcl parse.tcl \
    syncrepo.tcl regsub.tcl files.tcl text.tcl comment.tcl domains.tcl \
    vuser_init.tcl globals_h.tcl checks.tcl clean.tcl trans.tcl \
    steps.tcl report.tcl

proc main {argv} {
  set dir [file normalize .]
  set tname [task_name [lindex $argv 0]]
  if {$tname == ""} {set tname help}
  set trest [lrange $argv 1 end]
  if {[in_bld_subdir? $dir]} {
    puts "In buildtool subdir, exiting: $dir"
    return
  }
  if {[is_prjgroup_dir $dir]} {
    handle_prjgroup_dir $dir $tname $trest
  } else {
    # [2016-08-10 21:11] TODO: later call this one 'handle_project_dir'. Not now, still confusing name.
    handle_script_dir $dir $tname $trest
  }
}

proc handle_script_dir {dir tname trest} {
  global as_prjgroup buildtool_env
  if {($tname == "init") || ([current_version] == [latest_version])} {
    # TODO: repodir en repolibdir zetten vanuit config.tcl in .bld dir.
    #set repodir [file normalize "../repo"]
    #set repolibdir [file join $repodir libs]
    if {[file exists [buildtool_env_tcl_name]]} {
      uplevel #0 {source [buildtool_env_tcl_name]}
    } else {
      puts "do bld init-env!"
      return
    }
    puts "env: $buildtool_env"
    if {$tname != "init"} {
      uplevel #0 {source [config_tcl_name]}
      source_prjtype
    }
    set as_prjgroup 0
    set_origdir ; # to use by all subsequent tasks.
    task_$tname {*}$trest
    mark_backup $tname $trest
    check_temp_files
  } else {
    puts "Update config version with init -update"
  }
}

# source all tcl files in bldprjlib iff defined.
proc source_prjtype {} {
  global bldprjlib
  if {![info exists bldprjlib]} {
    log info "No prjtype specific build lib"
    return
  }
  # use lsort to have option to source in specific order if needed
  foreach libfile [lsort [glob -nocomplain -directory $bldprjlib *.tcl]] {
    # ndv::source_once?
    source $libfile
  }
}

# [2016-07-31 12:07] Also handle non-vugen dirs, eg to do regsub.
# TODO: for most actions, performing on non-vugen dir makes no sense.
# [2016-08-10 21:13] TODO: this one is the same as handle_script_dir, remove soon.
proc handle_default_dir_old {dir tname trest} {
  global as_project
  if {($tname == "init") || ([current_version] == [latest_version])} {
    # TODO: repodir en repolibdir zetten vanuit config.tcl in .bld dir.
    #set repodir [file normalize "../repo"]
    #set repolibdir [file join $repodir libs]
    if {$tname != "init"} {
      source [config_tcl_name]      
    }
    set as_project 0
    set_origdir ; # to use by all subsequent tasks.
    task_$tname {*}$trest
    mark_backup $tname $trest
    check_temp_files
  } else {
    puts "Update config version with init -update"
  }
}

proc handle_project_dir_old {dir tname trest} {
  global as_project
  # in a container dir with script dirs as subdirs.
  #set repodir [file normalize "repo"]
  #set repolibdir [file join $repodir libs]
  # [2016-07-30 15:30] not sure if source is needed here.
  source [config_tcl_name]
  set as_project 1
  # TODO: check of task wel in project scope gedaan kan/mag worden. put iig niet.
  if {$tname == "put"} {
    puts "Put action cannot be done in project scope, only script scope"
    exit 1
  }
  if {$tname == "project"} {
    task_$tname {*}$trest
  } else {
    foreach scriptdir [get_current_script_dirs $dir] {
      puts "In $scriptdir"
      cd $scriptdir
      handle_script_dir $scriptdir $tname $trest
      cd ..
    }
    cd $dir
  }
}

proc main_old {argv} {
  global repodir repolibdir as_project lr_include_dir
  set lr_include_dir [det_lr_include_dir]
  
  # maybe add some checks
  if {($argv == "") || [:0 $argv] == "help"} {
    task_help {*}[lrange $argv 1 end]
    exit 1
  }
  set dir [file normalize .]
  set tname [task_name [lindex $argv 0]]
  set trest [lrange $argv 1 end]
  if {[is_script_dir $dir]} {
    set repodir [file normalize "../repo"]
    set repolibdir [file join $repodir libs]
    set as_project 0
    set_origdir ; # to use by all subsequent tasks.
    task_$tname {*}$trest
    mark_backup $tname $trest
    check_temp_files
  } elseif {[is_project_dir $dir]} {
    # in a container dir with script dirs as subdirs.
    set repodir [file normalize "repo"]
    set repolibdir [file join $repodir libs]
    set as_project 1
    # TODO: check of task wel in project scope gedaan kan/mag worden. put iig niet.
    if {$tname == "put"} {
      puts "Put action cannot be done in project scope, only script scope"
      exit 1
    }
    if {$tname == "project"} {
      task_$tname {*}$trest

    } else {
      foreach scriptdir [get_current_script_dirs $dir] {
        puts "In $scriptdir"
        cd $scriptdir
        task_$tname {*}$trest
        mark_backup $tname $trest
        check_temp_files
        cd ..
      }
      cd $dir
    }
  } else {
    puts "Not a vugen script dir: $dir"
  }
}



# project functions, set and setcurrent
task project {Define and use projects
  Syntax:
  project set <prj> <script> [<script> ..] - Define a project including several scripts.
  project setcurrent <prj>                 - Set a project as current
} {
  if {![is_project_dir .]} {
    puts "Not a project dir, leaving"
    exit 1
  }
  lassign $args sub_action project
  set scripts [lrange $args 2 end]
  if {$sub_action == "set"} {
    set f [open "$project.prj" w]
    puts $f [join $scripts ";"]
    close $f
    # [2016-07-23 23:16] also make current.
    file copy -force "$project.prj" "current.prj"
  } elseif {$sub_action == "setcurrent"} {
    file copy -force "$project.prj" "current.prj"
  }
}

# project dir iff it contains minimal one script dir
proc is_project_dir_old {dir} {
  set res 0
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    if {[is_script_dir $subdir]} {
      set res 1
      break
    }
  }
  return $res
}

# A script dir is a VuGen script dir, which contains vuser_init.c
# TODO: could also be a TruClient dir which (maybe) does not have vuser_init.c?
proc is_script_dir_old {dir} {
  if {[file exists [file join $dir vuser_init.c]]} {
    return 1
  }
  return 0
}

# perform some tests. For now only show if libs are up-to-date
task test {Perform tests on script
  Calls following tasks: libs, check, check_configs, check_lr_params.
} {
  task_libs {*}$args
  task_check {*}$args
  task_check_configs {*}$args
  task_check_lr_params {*}$args
}

proc puts_warn {srcfile linenr text} {
  puts "[file tail  $srcfile] \($linenr\) WARN: $text"
}


# deze werkt nog niet op windows, zowel onder cygwin als 4NT.
proc puts_colour {colour str} {
  send::sda_fg$colour
  puts $str
  # 5-12-2015 oude kleur te bewaren?
  # ::term::ansi::send::sda_reset - alles op orig, wil je dit?
  # ::term::ansi::send::sda_fgdefault - zet 'em op zwart, wil je niet.
  send::sda_fgwhite
}

proc buildtool_dir {} {
  global argv0
  # set res [file dirname [file normalize [info script]]]
  # [2016-08-10 22:31] info script does not work now, because this proc is called from
  # .bld/config.tcl, and returns .bld dir.
  set res [file dirname [file normalize $argv0]]
  log debug "buildtool_dir: $res"
  return $res
}

# return true iff dir is .bld dir or subdir of this.
proc in_bld_subdir? {dir} {
  foreach el [file split $dir] {
    if {$el == ".bld"} {
      return 1
    }
  }
  return 0
}

if {[this_is_main]} {
  main $argv  
} else {
  puts "not main"  
}


if 0 {
opdrachten vanaf de cmdline:
bld run : run vugen test vanaf cmdline, evt met cmdline opties.
bld lint : checks uitvoeren op source code.

bld deploy : in ALM neerzetten, voor later.
bld compile : compile uitvoeren zoals binnen vugen

bld new <prjname> - nieuwe dir maken met file scaffolding. Evt met opties voor web ding of iets anders. Deze scaffolding dan wel ergens neerzetten.

  
  bld check - nog meer doen: ongebruikte params? wil met oude scripts nog wel eens gebeuren.
  bld check - heb ergens (loadrunner doc?) lijst van uitgangspunten en checks -> deze hier checken dus.

  
[2016-07-16 14:56] Tasks om oud script om te zetten? Waarsch best lastig.
  
bld save-as <nwe script naam> - ook iets wat je nu uit Vugen zelf doet.

Basisidee/uitgangspunt(en):
* Als een file in repo staat, is het lib, en in principe overal hetzelfde. Een globals.h zet je normaal niet in de repo, hooguit als skeleton.
* In repo een libs dir, maar ook een skeleton, evt binnen deze meerdere soorten skeletons.
* Eerst simpel en werkbaar maken, minimal viable workable solution.
* Uiteindelijk alle Vugen GUI acties via deze tool, maar zeker niet in het begin.
* Kijken in welk type project je zit: VuGen, AHK, Clojure, Tcl, ???
* tools om auto correlatie te doen, ook al eerder dingen voor gemaakt. Maar mss wel aardig dat dit een wrapper is, en dat je met bld help al deze dingen kunt zien.

Alle bld regsubs die je nog eens als pattern wilt:

bld regsub "\n([A-Za-z0-9_.,-][A-Za-z0-9_ .,-]+)\n" "\n    rb_web_reg_find(\"Text=\\1\");\n"
- deze gebruikt om tekst uit een response - gekopieerd in de source - in een rb_web_reg_find te zetten.

Generieke functies voor vervangen lr_*_transaction naar rb_*_transaction:
bld regsub "lr_start_transaction\(([^())]+)\);" "rb_start_transaction(\\1);"
bld regsub "lr_end_transaction\(([^()]+), ?LR_AUTO\);" "rb_end_transaction(\\1, TT);"
bld regsub "lr_think_time\(([^()]+)\);" "// lr_think_time(\\1);"

bld regsub "log_always_trans" "// log_always_trans"

Deze 4 om bestaande dotcom script om te zetten naar rb_trans.
bld regsub "lr_start_transaction\(lr_eval_string\(\"DotCom_(.+?)_\{cache\}\"\)\);" "rb_start_transaction(tr = trans_name(\"\\1\"));"
bld regsub "addDynaTraceHeader(".+?");\n" ""
bld regsub "lr_end_transaction\(lr_eval_string\(\"DotCom_(.+?)_\{cache\}\"\), LR_AUTO\);" "rb_end_transaction(tr, TT);"
bld regsub "lr_think_time\(TT\);" "// lr_think_time(TT);"

Deze voor RCC/CBW
bld regsub "lr_start_transaction\(transaction\);" "rb_start_transaction(transaction);"
bld regsub "lr_start_transaction\(transactie\);" "rb_start_transaction(transactie);"

bld regsub "set_dynatrace_headers\(transaction, vuserId\);" "// set_dynatrace_headers(transaction, vuserId);"
bld regsub "lr_end_transaction\(transaction, LR_AUTO\);" "rb_end_transaction(transaction, TT);"

bld regsub "lr_think_time\(TT\);" "// lr_think_time(TT);"
bld regsub "log_always_trans" "// log_always_trans"

# 2e param weg bij rb_start_transaction:
# rb_start_transaction(tr, vuserId); => rb_start_transaction(tr);
# bld regsub "rb_start_transaction\(lr_eval_string\(\"DotCom_(.+?)_\{cache\}\"\)\);" "rb_start_transaction(tr = trans_name(\"\\1\"));"
bld regsub "tr, vuserId" "tr"

# [2016-04-04 09:41:02] Voor RCC, ivm CDN gebruik.
bld regsub "https://{host}/rcc/DashboardLightThemeStatic/themes/DL2/ext" "https://{cdnhost}/{cdnprefix}"

}
