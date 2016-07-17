task totabs {Convert spaces to tabs
  Syntax: totabs [ntabs] - convert n tabs to a single tab. Default is 4.
  Handle all source files.
} {
  # default 4 tabs, kijk of in args wat anders staat.
  if {[:# $args] == 1} {
    lassign $args tabwidth
  } else {
    set tabwidth 4
  }
  foreach srcfile [get_source_files]	{
    totabs_file $srcfile $tabwidth
  }
}

proc totabs_file {srcfile tabwidth} {
  set fi [open $srcfile r]
  set fo [open [tempname $srcfile] w]
  fconfigure $f -translation crlf
  while {[gets $fi line] >= 0} {
    puts $fo [totabs_line $line $tabwidth]
  }
  close $fi
  close $fo
  commit_file $srcfile
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

task fixcrlf {Fix line endings
  Syntax: fixcrlf [<filename> ..]
  Fix line endings for filenames. Handle all source files if none given.
  Use Windows line endings (CRLF), as both VuGen and PC/ALM run on Windows.
} {
  if {$args == {}} {
    set lst [get_source_files]
  } else {
    set lst $args
  }
  foreach filename $lst {
    fixcrlf_file $filename
  }
}

proc fixcrlf_file {filename} {
  set text [read_file $filename]
  set fo [open [tempname $filename] w]
  fconfigure $fo -translation crlf
  puts -nonewline $fo $text
  close $fo
  commit_file $filename
}

