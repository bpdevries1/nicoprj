#!/usr/bin/env tclsh861

package require ndv

set_log_global info

proc main {argv} {
  lassign $argv root
  handle_dir [file normalize $root] 0
}

proc handle_dir {dir level} {
  log debug "handle_dir: $dir"
  if {$level > 30} {
    exit
  }
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    if {![ignore_dir $subdir]} {
      handle_dir $subdir [expr $level + 1]
    }
  }
  foreach filename [glob -nocomplain -directory $dir -type f *] {
    handle_file $filename
  }
}

proc handle_file {filename} {
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
  unix {.c .css .clj .cljs .csv .erb .graphml .html .java
        .js .json .license .md .mustache .py
        .r .rb .sh .slim .sql .tcl .textile .tsv .txt .xml ""}
  dos {.ahk .bat .cmd .vbs}
  ignore {.1 .dependencies .gen .log .mta .old .orig .out
         .pac .prj .tab .take1 .thuis .wrd}
  bin {.db .class .dat .doc .docm .docx .dll .eot .exe .ico .jar
       .jasper .jnilib .jrxml .png .so .svg .ttf .woff .xls .xlsm .xlsx .zip}
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

main $argv
