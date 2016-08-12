# Miscellaneous procs
proc puts_warn {srcfile linenr text} {
  puts "[file tail  $srcfile] \($linenr\) WARN: $text"
}

