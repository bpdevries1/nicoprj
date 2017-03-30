task linter {Check source files like a linter.
} {
  # TODO: alle .c files (en .h evt ook.)
  foreach filename [get_source_files] {
    lint_file $filename
  }
}

proc lint_file {filename} {
  log debug "Handling file: $filename"
  set statements [read_source_statements $filename]
  if {$filename == "transaction.c"} {
    # breakpoint
  }
  # breakpoint
  # check var initialise can be done by checking each statement. Other things like free/= NULL combinations require checking multiple statements.
  # for free/null, maybe a macro can be used. Then the check just needs to be that free() is not used directly anymore.
  foreach stmt $statements {
    set lines [stmt_lines $stmt]
    if {[regexp {^([^=\(\)]+);} $lines z line]} {
      if {[regexp {break|return|continue|\+\+} $line]} {
        # continue
      } else {
        stmt_warn "Possible var declaration without assignment" $filename $stmt
      }
    }
    if {[regexp {\mfree\M} $lines]} {
      stmt_warn "Use of free, use rb_free" $filename $stmt
    }
  }
}

proc stmt_warn {msg filename stmt} {
  set lines [stmt_lines $stmt]
  puts stderr "$msg: $lines ($filename:[:linenr_start $stmt])"        
} 

proc stmt_lines {stmt} {
  string trim [join [:lines $stmt] "\n"]
}
