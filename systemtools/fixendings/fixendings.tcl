#!/usr/bin/env tclsh861

package require ndv

set_log_global info

proc main {argv} {
  global unknowns
  lassign $argv root
  set fr [open /tmp/rename-files.sh w]
  set unknowns [dict create]
  handle_dir [file normalize $root] $fr 0
  flush $fr ; # should not be needed.
  close $fr
  log warn "Unknown extensions: [lsort  [dict keys $unknowns]]"
}

proc handle_dir {dir fr level} {
  log debug "handle_dir: $dir"
  if {$level > 30} {
    exit
  }
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    if {![ignore_dir $subdir]} {
      handle_dir $subdir $fr [expr $level + 1]
    }
  }
  foreach filename [glob -nocomplain -directory $dir -type f *] {
    handle_file $fr $filename
  }
}

proc handle_file {fr filename} {
  global unknowns
  set tp [det_type $filename]
  if {$tp == "unix"} {
    log debug "-> unix: $filename"
    exec -ignorestderr dos2unix -k -q $filename
  } elseif {$tp == "dos"} {
    log debug "-> dos: $filename"
    exec -ignorestderr unix2dos -k -q $filename
  } elseif {$tp == "bin"} {
    log debug "binary: $filename"
  } elseif {$tp == "ignore"} {
    log debug "ignore: $filename"
  } else {
    log warn "Unknown: $filename"
    dict set unknowns [string tolower [file extension $filename]] 1
    add_rename $fr $filename
  }
}

# maybe hidden files auto ignored?
proc ignore_dir {dir} {
  if {[file tail $dir] == ".git"} {
    log warn ".git dir given to ignore_dir: $dir"
    return 1
  }
  return 0
}



set extensions {
  unix {.awk .c .can .cron .css .clj .cljs .csv .dot .erb .graphml .groovy
    .hsql .htm .html .java .jmx
    .js .json .license .lqn .lqnprop .lqntmp .m .markdown .md .mdl .mm
    .mustache .mysql .org .p .params .pl .plot .properties .py .restart
    .r .rb .sh .showinfo .slim .sql .sudo .tcl .textile .tsv .txt .wiki
    .xml .xmlinc .xmlpart .xmltmp .xsl ""}
  dos {.ahk .aspx .bat .cf .cmd .ini .vbs}
  ignore {.$$$ .1 .dependencies .gen .log .mta .old .orig .oud .out
         .pac .prj .profile .tab .take1 .template .thuis .wrd}
  bin {.db .class .dat .doc .docm .docx .dll .emf .eot .exe .fig .flo .ico .jar
    .jasper .jnilib .jrxml .pdf .png .ps .so .svg .trace .ttf
    .woff .xls .xlsm .xlsx .war .zip}
}

proc det_type {filename} {
  global extensions
  set ext [string tolower [file extension $filename]]
  foreach {tp exts} $extensions {
    if {[lsearch $exts $ext] >= 0} {
      return $tp
    }
  }
  if {[regexp {~$} $ext]} {
    return ignore
  }
  return unknown
}

# make script to rename files X.ext.ext2 to X-ext2.ext in git
proc add_rename {fr filename} {
  set ext2 [string range [file extension $filename] 1 end]
  set root1 [file rootname $filename]
  set ext [file extension $root1]
  set root2 [file rootname $root1]
  set newname "$root2-$ext2$ext"
  if {[regexp {netwerk-finite-naast-cpu} $filename]} {
    # breakpoint
  }
  if {$ext == ""} {
    puts "Empty ext, returning: $newname"
    puts $fr "# Empty new ext, returning: $filename"
    return
  }
  if {[det_type $newname] != "unknown"} {
    puts $fr "git mv \"$filename\" \"$newname\""  
  } else {
    puts $fr "# Unknown new ext, returning: $filename"
  }
}

main $argv
