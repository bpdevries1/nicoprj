task find_step {Find t<xx>.inf with the step as in source
  Look in result1/iteration1 for .inf files with the given text on a line with StepName
} {
  set step [join $args " "]
  foreach filename [glob -nocomplain -directory "result1/iteration1" *.inf] {
    set text [read_file $filename]
    # StepName=Url: System Features
    if {[regexp -line "^StepName=\[^:\]+: $step.*$" $text line]} {
      set ref_file [get_ref_file $filename]
      puts "[file tail $filename]: $line -> $ref_file"
    }
  }
}

# find FileName1 in .inf file.
# FileName1=t8.html
proc get_ref_file {filename} {
  set text [read_file $filename]
  if {[regexp -line {^FileName1=(.+)$} $text z ref]} {
    return $ref
  } else {
    return "FileName1 not found"
  }
}

# TODO: use this for generating a (HTML) table with srcfile/srcline, stepname, stepnr (t<xx) and ref to main (html,js,json) file and maybe supporting file.

