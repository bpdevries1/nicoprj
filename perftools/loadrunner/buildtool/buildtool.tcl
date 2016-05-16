#!/usr/bin/env tclsh

# Build tool, mainly for VuGen scripts and libraries

# TODO:
# Build tool: bv bij functions.c wel nieuwe spul in repo zetten met put, maar ook benieuwd of andere projecten nog andere changes hebben. Eerder ook met nycsync gewerkt, zou hier ook een oplossing kunnen zijn. Alleen lijkt het dan weer beter iets als git te gebruiken.
# Neig nu wel naar de nycsync oplossing: bij zowel git als unison met config files toch nog omslachtig. Met Unison wel dezelfde functionaliteit: geen versiebeheer, alleen maar kijken waar iets is gewijzigd. Met git zou het gecompliceerd worden, want dan 2 masters mogelijk, heb ook al git voor het gewone versie beheer van het script, dat is dus geen optie.

package require term
package require term::ansi::code::attr
package require term::ansi::send
term::ansi::send::import

package require ndv

ndv::source_once configs.tcl lr_params.tcl

# deze mogelijk  nog dynamisch, of in config file.
set lr_include_dir {C:\Program Files (x86)\HP\LoadRunner\include}

proc main {argv} {
  global repodir repolibdir as_project
  # maybe add some checks
  if {$argv == ""} {
    help
    exit 1
  }
  set dir [file normalize .]
  set tname [lindex $argv 0]
  set trest [lrange $argv 1 end]
  if {[is_script_dir $dir]} {
    set repodir [file normalize "../repo"]
    set repolibdir [file join $repodir libs]
    set as_project 0
    task_$tname {*}$trest
  } elseif {[is_project_dir $dir]} {
    set repodir [file normalize "repo"]
    set repolibdir [file join $repodir libs]
    set as_project 1
    # todo check of task wel in project scope gedaan kan/mag worden. put iig niet.
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
        cd ..
      }
      cd $dir
    }
  } else {
    puts "Not a vugen script dir: $dir"
  }
}

proc get_current_script_dirs {dir} {
  split [string trim [read_file [file join $dir "current.prj"]]] ";"
}

# TODO tasks dynamisch afleiden uit deze source file. Evt deftask ipv proc task_gebruiken voor admin, dan ook met help erbij.
proc task_help {} {
  global repolibdir
  puts "Build tool v0.1.0"
  puts "Tasks:"
  set tasks {
    "help" "Print this help"
    "libs" "Overview of lib files, including status"
    "put <lib> \[-force\]" "Put a local lib file in the repo ($repolibdir)"
    "get <lib> \[-force\]" "Get a repo ($repolibdir) lib file to local"
    "diff <lib>" "Show differences between local version and repo version"
    "test \[<lib>\] \[-full\]" "Perform some tests (libs, check_sources for now)"
    "check \[<lib>\] \[-full\]" "Perform some checks on sources (eg location of #includes)"
    "regsub <from> <to> \[-do\]" "Perform regexp replacements, -do to really do it"
    "project set <prj> [list of scripts]" "Define a project including several scripts."
    "project setcurrent <prj>" "Set a project as current"
    "clean" "Clean temporary files"
  }

  # cmd desc
  # bepaal lengte, beter met reduce functie, of met max/map combi.
  set len 0
  foreach {task desc} $tasks {
    set l [string length $task]
    if {$l > $len} {
      set len $l
    }
  }
  foreach {task desc} $tasks {
    puts [format "%-${len}s   %s" $task $desc]
  }
}

# project functions, set and setcurrent
# TODO: check of je in een project dir zit.
proc task_project {args} {
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
  } elseif {$sub_action == "setcurrent"} {
    file copy -force "$project.prj" "current.prj"
  }
}

proc task_clean {} {
  set dir [file normalize .]
  if {[is_script_dir $dir]} {
    clean_script $dir
  } else {
    puts "Not a vugen script."
  }
}

# project dir iff it contains minimal one script dir
proc is_project_dir {dir} {
  set res 0
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    if {[is_script_dir $subdir]} {
      set res 1
      break
    }
  }
  return $res
}


proc is_script_dir {dir} {
  if {[file exists [file join $dir vuser_init.c]]} {
    return 1
  }
  return 0
}

proc clean_script {dir} {
  set glob_patterns {*.idx *.log git-add-commit.sh output.* *.tmp TransactionsData.db *.bak TransactionsData.db Iteration* result1 data}
  puts "Cleaning script dir: [file normalize $dir]"
  foreach glob_pattern $glob_patterns {
    foreach filename [glob -nocomplain -directory $dir $glob_pattern] {
      delete_path $filename
    }
  }
}

proc delete_path {pathname} {
  puts "Deleting: $pathname"
  if {[file isdirectory $pathname]} {
    # force nodig, dir is mogelijk niet leeg of heeft subdirs.
    file delete -force $pathname  
  } else {
    file delete $pathname  
  }
}

# put lib file from working/script directory into repository
proc task_put {args} {
  global repolibdir
  # puts "args: $args"
  file mkdir $repolibdir
  lassign [det_force $args] args force
  foreach libfile $args {
    if {[file exists $libfile]} {
      set repofile [file join $repolibdir $libfile]
      if {[file exists $repofile]} {
        # TODO: only put newer files. Maybe add -force option.
        if {[file mtime $libfile] > [file mtime $repofile]} {
          # ok, newer file
          puts "Putting newer lib file to repo: $libfile"
          file copy -force $libfile $repofile
        } else {
          if {$force} {
            puts "\[FORCE\] Putting older lib file to repo: $libfile"
            file copy -force $libfile $repofile
          } else {
            puts "Local file $libfile is not newer than repo file: do nothing"  
          }
        }
      } else {
        # ok, new lib file
        puts "Putting new lib file to repo: $libfile"
        file copy $libfile $repofile
      }
    } else {
      puts "Local lib file not found: $libfile"
    }
  }
}

# get lib file from repository into working/script directory
proc task_get {args} {
  global repolibdir
  # puts "args: $args"
  file mkdir $repolibdir
  lassign [det_force $args] args force
  foreach libfile $args {
    set repofile [file join $repolibdir $libfile]
    if {[file exists $repofile]} {
      if {[file exists $libfile]} {
        # TODO: only get newer files from repo. Maybe add -force option.
        if {[file mtime $libfile] < [file mtime $repofile]} {
          # ok, newer file in repo
          puts "Getting newer repo file: $repofile"
          file copy -force $repofile $libfile
        } else {
          if {$force} {
            puts "\[FORCE\] Getting older repo file: $repofile"
            file copy -force $repofile $libfile
          } else {
            puts "Repo file $libfile is not newer than local file: do nothing"  
          }
        }
      } else {
        # ok, new repo file, not yet in local prj dir.
        puts "Getting new repo file: $repofile"
        file copy $repofile $libfile
      }
    } else {
      puts "Repo lib file not found: $repofile"
    }
  }
}

proc det_force {lst} {
  set force 0
  set res {}
  foreach el $lst {
    if {$el == "-force"} {
      set force 1
    } else {
      lappend res $el
    }
  }
  list $res $force
}

proc det_full {lst} {
  set full 0
  set res {}
  foreach el $lst {
    if {$el == "-full"} {
      set full 1
    } else {
      lappend res $el
    }
  }
  list $res $full
}

# args are ignored, but needed for task_check.
proc task_libs {args} {
  global as_project
  set repo_libs [get_repo_libs]
  # puts "repo_libs: $repo_libs"
  set source_files [lsort [get_source_files]]
  set included_files [det_includes_files [filter_ignore_files $source_files]]
  set all_files [lsort -unique [concat $source_files $included_files]]
  set diff_found 0
  # also check if all included files exist.
  foreach srcfile $all_files {
    set st "ok"
    if {$srcfile == "globals.h"} {
      # ignore
    } elseif {[in_lr_include $srcfile]} {
      # default loadrunner include file, ignore.
    } elseif {[file extension $srcfile] == ".h"} {
      set st [show_status $srcfile]
    } elseif {[lsearch -exact $included_files $srcfile] >= 0} {
      # puts "in included: $srcfile"
      set st [show_status $srcfile]
    } elseif {[lsearch -exact $repo_libs $srcfile] >= 0} {
      # puts "in repo: $srcfile"
      set st [show_status $srcfile]
    } else {
      # puts "ignore: $srcfile"
    }
    if {$st != "ok"} {
      set diff_found 1
    }
  }
  if {$diff_found} {
    puts "\n*** FOUND DIFFERENCES ***"
  } else {
    if {!$as_project} {
      puts "\nEverything up to date"  
    }
  }
}

proc get_repo_libs {} {
  global repolibdir
  glob -nocomplain -tails -directory $repolibdir -type f *
}

proc get_source_files {} {
  concat [glob -nocomplain -tails -directory . -type f "*.c"] \
      [glob -nocomplain -tails -directory . -type f "*.h"]
}

# delete combined_* files from list.
# maybe later use FP filter command
proc filter_ignore_files {source_files} {
  set res {}
  foreach src $source_files {
    if {[regexp {^combined_} $src]} {
      # ignore
    } elseif {$src == "pre_cci.c"} {
      # ignore
    } else {
      lappend res $src
    }
  }
  return $res
}

proc det_includes_files {source_files} {
  set res {}
  foreach source_file $source_files {
    lappend res {*}[det_includes_file $source_file]
  }
  lsort -unique $res
}

proc det_includes_file {source_file} {
  set res {}
  set f [open $source_file r]
  while {[gets $f line] >= 0} {
    if {[regexp {^#include "(.+)"} $line z include]} {
      # uts "FOUND include stmt: $include, line=$line"
      lappend res $include
    }
  }
  close $f
  return $res
}

proc in_lr_include {srcfile} {
  global lr_include_dir
  file exists [file join $lr_include_dir $srcfile]
}

proc show_status {libfile} {
  global repolibdir as_project
  set repofile [file join $repolibdir $libfile]
  if {[file exists $repofile]} {
    if {[file exists $libfile]} {
      if {[file mtime $libfile] < [file mtime $repofile]} {
        set status "repo-new"
      } elseif {[file mtime $libfile] > [file mtime $repofile]} {
        set status "local-new"
      } else {
        set status "ok"
      }
    } else {
      set status "only in repo"
    }
  } else {
    if {[file exists $libfile]} {
      set status "only local"
    } else {
      set status "included file not found"
    }
  }
  # in project scope zo weinig mogelijk uitvoer naar stdout.
  if {$status != "ok" || !$as_project} {
    puts "\[$status\] $libfile"  
  }
  
  return $status
}

proc task_diff {libfile} {
  set st [show_status $libfile]
  puts "local: [file_info $libfile]"
  puts "repo : [file_info [repofile $libfile]]"
  if {[regexp {new} $st]} {
    diff_files $libfile [repofile $libfile]
  } else {
    # no use to do diff
  }
}

proc diff_files {file1 file2} {
  set res "<none>"
  try_eval {
    set temp_out "__TEMP__OUT__"
    set res [exec -ignorestderr diff $file1 $file2 >$temp_out]
  } {
    # diff always seems to fail, possibly exit-code.
    # puts "diff failed: $errorResult"
  }
  if {$res == "<none>"} {
    set res [read_file $temp_out]
  }
  file delete $temp_out
  puts $res
}

proc file_info {libfile} {
  if {[file exists $libfile]} {
    return "[clock format [file mtime $libfile] -format "%Y-%m-%d %H:%M:%S"], [file size $libfile] bytes"
  } else {
    return "-"
  }
}

proc repofile {libfile} {
  global repolibdir
  file join $repolibdir $libfile
}

# perform some tests. For now only show if libs are up-to-date
proc task_test {args} {
  task_libs {*}$args
  task_check {*}$args
  task_check_configs {*}$args
  task_check_lr_params {*}$args
}

proc task_check {args} {
  lassign [det_full $args] args full
  if {$args != {}} {
    foreach libfile $args {
      check_file $libfile $full
    }
  } else {
    foreach srcfile [filter_ignore_files [get_source_files]]	{
      check_file $srcfile $full
    }
    check_script
  }
}

proc check_file {srcfile full} {
  check_file_includes $srcfile
  if {$full} {
    check_file_todos $srcfile
    check_file_comments $srcfile
  }
  # [2016-02-05 17:29:15] TODO: Wil eigenlijk in globals.h een zeer beperkt aantal globals. Beter om te definieren waar ze gebruikt worden, zoals cachecontrol etc.
  # check_globals
}

proc check_file_includes {srcfile} {
  set other_found 0
  set in_comment 0
  set f [open $srcfile r]
  set linenr 0
  while {[gets $f line] >= 0} {
    incr linenr
    set lt [line_type $line]
    if {$lt == "comment_start"} {
      set in_comment 1
    }
    if {$lt == "comment_end"} {
      set in_comment 0
    }
    if {!$in_comment} {
      if {$lt == "include"} {
        if {$other_found} {
          # puts "$srcfile \($linenr\) WARN: #include found after other statements: $line"
          puts_warn $srcfile $linenr "#include found after other statements: $line"
        }
      }
      if {$lt == "other"} {
        set other_found 1
      }
    }
  }
  close $f
}

# [2016-02-05 11:16:37] Deze niet std, levert te veel op, evt wel losse task.
proc check_file_todos {srcfile} {
  set f [open $srcfile r]
  set linenr 0
  while {[gets $f line] >= 0} {
    incr linenr
    if {[regexp {TODO} $line]} {
      puts_warn $srcfile $linenr "TODO found: $line"
    }
  }
  close $f
}

# [2016-02-05 11:14:23] deze niet std uitvoeren, levert te veel op. Mogelijk wel los, maar dan een task van maken.
proc check_file_comments {srcfile} {
  set f [open $srcfile r]
  set linenr 0
  while {[gets $f line] >= 0} {
    incr linenr
    set lt [line_type $line]
    if {$lt == "comment"} {
      # [2016-02-05 11:10:41] als er een haakje inzit, is het waarschijnlijk uitgecommente code.
      if {[regexp {[\(\)]} $line]} {
        puts_warn $srcfile $linenr "Possible out-commented code found: $line"
      }
    }
  }
  close $f
}


proc puts_warn {srcfile linenr text} {
  puts "[file tail  $srcfile] \($linenr\) WARN: $text"
}

# check script scope things, eg all .c/.h files in dir are included in the script. Also for .config files.
proc check_script {} {
  # puts "check_script called"
  set src_files [filter_ignore_files [concat [glob -nocomplain -tails -directory . -type f "*.c"] \
                                          [glob -nocomplain -tails -directory . -type f "*.h"] \
                                          [glob -nocomplain -tails -directory . -type f "*.config"]]]
  set prj_text [read_file [lindex [glob *.usr] 0]]
  foreach src_file $src_files {
    if {[string first $src_file $prj_text] == -1} {
      puts "Sourcefile not in script.usr file: $src_file"
    } else {
      # puts "Ok: $src_file found in script.usr"
    }
  }
}

# TODO comment blocks
proc line_type {line} {
  set line [string trim $line]
  if {$line == ""} {
    return empty
  }
  if {[regexp {^//} $line]} {
    return comment
  }
  if {[regexp {^/\*} $line]} {
    return comment_start
  }
  if {[regexp {\*/$} $line]} {
    return comment_end
  }
  if {[regexp {^\#} $line]} {
    if {[regexp {^\#include} $line]} {
      return include
    } else {
      return directive
    }
  }
  return other
}

# args can only be -do, to really perform the replacements. Should be at the end, could be that regexps have/are -do.
# if not really, create a file.__TEMP__ with the new version. Then perform a diff on both.
# TODO: als -do is meegegeven, dan actie opslaan (in repo, want ook voor andere scripten). dan optie om deze te tonen en te kiezen.
# en mss ook een naam te geven.
proc task_regsub {from to args} {
  set really 0
  puts "from: $from, to: $to, args: $args"
  if {[lindex $args 0] == "-do"} {
    set really 1
    puts "Really perform replacements!"
  }
  # vervang meegegeven \n op cmdline in echte newline voor regsub:
  regsub -all {\\n} $to "\n" to2
  set origdir "_orig.[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]"
  foreach srcfile [filter_ignore_files [get_source_files]]	{
    regsub_file $srcfile $from $to2 $origdir $really
  }
}

proc regsub_file {srcfile from to origdir really} {
  set text [read_file $srcfile]
  set nreplaced [regsub -all $from $text $to text2]
  if {$nreplaced == 0} {
    # nothing, no replacements done.
  } else {
    puts "$srcfile - $nreplaced change(s):"
    set tempfile "$srcfile.__TEMP__"
    set f [open $tempfile w]
    puts $f $text2
    close $f
    set temporig "$srcfile.__ORIG__"
    set f [open $temporig w]
    puts $f $text
    close $f
    diff_files $temporig $tempfile
    if {$really} {
      puts "really perform replacement, orig files in _orig dir"
      file delete $temporig
      file mkdir $origdir
      # file rename $srcfile [file join _orig $srcfile]
      file rename $srcfile [file join $origdir $srcfile]
      file rename $tempfile $srcfile
    } else {
      file delete $temporig
      file delete $tempfile
    }
  }
}

proc task_totabs {args} {
  # default 4 tabs, kijk of in args wat anders staat.
  if {[:# $args] == 1} {
    lassign $args tabwidth
  } else {
    set tabwidth 4
  }
  set origdir "_orig.[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]"
  file mkdir $origdir
  foreach srcfile [filter_ignore_files [get_source_files]]	{
    totabs_file $srcfile $origdir $tabwidth
  }
}

# TODO: alleen file aanpassen als er echt iets is aangepast.
# TODO: y_core.c checken, niet mijn eigen file.
proc totabs_file {srcfile origdir tabwidth} {
  set orig_file [file join $origdir [file tail $srcfile]]
  set temp_file "$srcfile.__TEMP__"

  set fi [open $srcfile r]
  set fo [open $temp_file w]
  set changed 0
  while {[gets $fi line] >= 0} {
    set line2 [totabs_line $line $tabwidth]
    puts $fo $line2
    if {$line != $line2} {
      set changed 1
    }
  }
  close $fi
  close $fo

  if {$changed} {
    file rename $srcfile $orig_file
    file rename $temp_file $srcfile
  } else {
    # keep orig, remove temp
    file delete $temp_file
  }
}

proc totabs_line {line tabwidth} {
  regexp {^([ \t]*)(.*)$} $line z spaces rest
  set width 0
  foreach ch [split $spaces ""] {
    if {$ch == " "} {
      incr width
    } else {
      # tab
      set width [expr (($width / $tabwidth) + 1) * $tabwidth]
    }
  }
  set ntabs [expr $width / 4]
  set nspaces [expr $width - ($ntabs * 4)]
  return "[string repeat "\t" $ntabs][string repeat " " $nspaces]$rest"
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

main $argv

if 0 {
opdrachten vanaf de cmdline:
bld deps : haalt nieuwste libs of vanuit repo-dir. Check in globals.h of mogelijk alle .c/.h files welke includes erin staan.
bld help : toont commando's
bld run : run vugen test vanaf cmdline, evt met cmdline opties.
bld lint : checks uitvoeren op source code.

bld deploy : in ALM neerzetten, voor later.
bld libs : overview of library files, also showing if up-to-date with repo. Kijken of van alle files het type is te achterhalen, en of het een lib is of kan zijn. Ook deels afh van script, of het bij actions staat of extra files. Een actionfile kan ook lib zijn, bv inloggen, of CacheControl. Dit moet ook kunnen, wil flexibel zijn, bestaande scripten zo goed mogelijk kunnen bedienen. Dan actions alleen noemen als ze in repo zitten. Files bij extra iets meer kans, maar globals niet, en config files ook niet. Config is mss meer een skeleton verhaal. Ook kijken welke ge-include worden.
bld diff <libfile> : toont verschillen lokale versie van lib met repo versie. Gebruik cmdline diff.
bld compile : compile uitvoeren zoals binnen vugen

bld new <prjname> - nieuwe dir maken met file scaffolding. Evt met opties voor web ding of iets anders. Deze scaffolding dan wel ergens neerzetten.
bld task <specifiek> - specifieke user defined task. Maar ook met bld <specifiek>. En in bld help moeten deze specifieke ook getoond worden.
bld repl - start repl waarin je bovenstaande taken kunt uitvoeren zonder steeds bld te typen. Maar dan weer history etc zelf regelen, anders in bash/4NT. Eigenlijk een tcl shell waarin je dit script gesourced hebt.
bld version - versie van deze tool. Of niet zo belangrijk.
bld showdeps - toon alle includes vanuit alle files. Eigenlijk een grep en wat je ook in de dotfile tool hebt.
bld graphdeps - deze graphviz/dot tool voor huidige script.
bld replace <from-regexp> <to-regexp> - vervang tekst in files, mss nog opgeven in welke files? bv optionele param glob-pattern. Deze al vaker nodig gehad, ook voor clojure.
 -> deze bv voor start_transaction dingen, maar zijn eigenlijk standaard patronen. Je zou kunnen zeggen dat als je deze aanroept met 1 param, dat dit dan zo'n pattern is, maar is wel tricky. Je kunt bv door-routes naar regsub task.
bld regsub - betere naam ipv replace? En dan replace voor std patterns gebruiken?
  bld replace <pattern>, bv bld replace transaction - vervang recorded transaction door rb_transaction_start etc.


  
  Nog wat om lr_start_transaction om te zetten naar rb_start_transaction.

  mss wil je een soort script, die meerdere regsubs achter elkaar uitvoert.

  bld todo - show todo's in source (met sourcefile en mss stukje context)

  bld check - nog meer doen: ongebruikte params? wil met oude scripts nog wel eens gebeuren.
  bld check - heb ergens (loadrunner doc?) lijst van uitgangspunten en checks -> deze hier checken dus.
  
  bld regsub show - voorgaande regsubs tonen om nog eens te doen.
  bld regsub do <nr> - een voorgaande uitvoeren.
  bld regsub del <nr> - een voorgaande deleten.
  meest gebruikte of laatst gebruikte bovenaan zetten?

  zou bepaalde acties op hele VuGen dir kunenn doen, dat je bv checkt of alle scripts goed zijn en up-to-date met lib. Maar vaak met een subset bezig, en dan wil je alleen die checken. Dit dan ergens definieren. Opties:
  * een subdir maken met config-file hierin met namen van andere scripten. Mss beetje overkill?
  * in Vugen-dir iets als bld setcurrent DotCom*. Maar dan ook de recs. Deze evt eerst verplaatsen. Maar met tabgebruik in cmdline ook wel expliciet de 4 dirs te zetten. Een setcurrent komt altijd in de plaats van de vorige.
  
bld add(action) - voeg action toe, dus een file, maar ook opnemen in de 'script' van Vugen, nog even kijken hoe.

bld check - heb hier al wat, ook inbouwen check dat alle files ge-include zijn, alle .c en .h files moeten ergens in het script voorkomen, als action of additional. Deze moet in .usr zitten.
  
specifieke tasks:
bld tabs - overal tabs/spaces goed zetten, evt ook in de libs, zou in libs sowieso goed moeten staan.
  bld format - format overal goed zetten, wat algemener dan tabs. Wel oppassen dat je libs niet-van-mij overslaat. Hoe dit bij te houden, eerst hardcoded, of in config in repo.
ook bij format: canonical form maken van config files. VuGen slaat deze nu vaak op in niet-sorted volgorde, waardoor diff heel lastig is.  
<iets met splitsen recorded session in losse actions?> bv elke transactie wordt een action?
bld rename <action-from> <action-to> - file renamen, inclusief in het script.
bld save-as <nwe script naam> - ook iets wat je nu uit Vugen zelf doet.

projecten om acties op scripts te combineren. Niet alle taken te combineren, zoals put (van lib). Get kan evt wel. Vooral voor test, evt ook running van scripts.

# set a project, also if new scripts are added to project.
bld project set dotcom scr1 scr2 scr3 scr4

# set as current
bld project setcurrent dotcom 

wel checken of dit een project dir is, met subdirs als scriptdir.

# next actions in root will be scoped to this project.
  
  
check specifieke tools, vooral in vugen/loadrunner dirs.

specifieke zit vooral in de #includes. Deze tool ook redelijk zo voor AHK te gebruiken. Vanuit tcl ook te compileren als nodig.

iets om lib in repo te zetten. Maar wil je dit wel vanuit een project? vooralsnog met bld put.

basis om te bouwen lijkt heel simpel:
{*}$argv uitvoeren, met mss andere voor unknown, vergelijk :keyword oplossing. Deze kan gechained worden. Of je geeft eerst een stacktrace.
params/arg stuk hier evt ook bij. Dat te optionele params aan taken kunt meegeven.

evt extra taken ook in repo neerzetten? Of deze juist bij tool houden?

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

[2016-02-10 12:50:41] TODO: bld put lib
-> repo ook in git zetten. Doe nu gac/bld put, wil dan eigenlijk dezelfde commit met log comment.
mss iets van:
bld put <lib> <commit msg>

}
