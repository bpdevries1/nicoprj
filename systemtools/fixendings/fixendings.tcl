#!/usr/bin/env tclsh861

package require ndv

set_log_global info

proc main {argv} {
  global unknowns
  lassign $argv root
  # set fr [open /tmp/rename-files.sh w]
  set fr [open [file join [temp_dir] rename-files.sh] w]
  set unknowns [dict create]
  handle_dir [file normalize $root] $fr 0
  flush $fr ; # should not be needed.
  close $fr
  log warn "Unknown extensions: [lsort  [dict keys $unknowns]]"
}

proc temp_dir {} {
	global tcl_platform
	if {$tcl_platform(platform) == "windows"} {
		return "c:/temp"
	} else {
		return /tmp
	}
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
  # met -k optie blijft mtime al hetzelfde.
  # set mtime [file mtime $filename]
  set size [file size $filename]
  if {$tp == "unix"} {
    log debug "-> unix: $filename"
    exec -ignorestderr [unix_tool_path dos2unix] -k -q $filename
  } elseif {$tp == "dos"} {
    log debug "-> dos: $filename"
    exec -ignorestderr [unix_tool_path unix2dos] -k -q $filename
  } elseif {$tp == "bin"} {
    log debug "binary: $filename"
  } elseif {$tp == "ignore"} {
    log debug "ignore: $filename"
  } else {
    log warn "Unknown: $filename"
    dict set unknowns [string tolower [file extension $filename]] 1
    add_rename $fr $filename
  }
  set size2 [file size $filename]
  if {$size != $size2} {
    log info "Changed: $filename ($size->$size2 bytes)"
  }
}

proc unix_tool_path {tool} {
	global tcl_platform
	if {$tcl_platform(platform) == "windows"} {
		return "C:/PCC/Util/cygwin/bin/$tool.exe"
	} else {
		return $tool
	}
}

# maybe hidden files auto ignored?

set dir_ignores {.git bin node_modules obj target}

proc ignore_dir {dir} {
  global dir_ignores
  if {[lsearch $dir_ignores [file tail $dir]] >= 0} {
    return 1
  }
  return 0
}

set extensions {
  unix {.awk .c .can .cron .css .clj .cljs .csv .dot .erb .graphml .groovy
    .hs .hsql .htm .html .java .jmx
    .js .json .license .lqn .lqnprop .lqntmp .m .markdown .md .mdl .mf .mm
    .mustache .mysql .opts .org .p .params .pl .plot .properties .py .restart
    .r .rb .rd .sh .showinfo .slim .sql .sudo .tcl .textile .tsv .txt .types .wiki
    .xml .xmlinc .xmlpart .xmltmp .xsl ""}
  dos {.ahk .aspx .bat .cf .cmd .cs .ini .vbs}
  ignore {.$$$ .1 .bak .config .dependencies .gen
    .http .log .mta .old .orig .oud .out
    .pac .patch .php .prj .profile .rss .settings
    .tab .take1 .template .thuis .wrd}
  bin {.csproj .db .class .dat .doc .docm .docx .dll .emf .eot .exe
    .fig .flo .gif .gz .hi .ico .jar
    .jasper .jnilib .jpg .jpeg .jrxml .nxd .nxj .o .pdf .png .ps .resx
    .sln .so .suo .svg .sq3 .tar .tgz .trace .ttf
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
    # if git mv fails, do default mv (eg file not in git)
    puts $fr "mv \"$filename\" \"$newname\""
  } else {
    puts $fr "# Unknown new ext, returning: $filename"
  }
}

main $argv
