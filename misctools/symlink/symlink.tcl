#! /usr/bin/env tclsh

proc main {argv} {
  lassign $argv cmd
  set alias_line [get_alias $cmd]
  if {$alias_line != ""} {
    puts $alias_line    
  }
  set which [get_which $cmd]
  puts "which: $which"
  follow_links $which
}

proc get_alias {cmd} {
  # execute showalias.sh for now, maybe can exec bash directly
  set res ""
  set showalias [file normalize [file join [info script] .. showalias.sh]]
  catch {
    set res [exec $showalias $cmd]
  }
  return $res
}

proc get_which {cmd} {
  set res ""
  catch {
    set res [exec which $cmd]
  }
  return $res
}

proc follow_links {filename} {
  set target [file_link $filename]
  while {$target != ""} {
    puts "$filename -> $target"
    set filename $target
    set target [file_link $filename]
  }
}

# return file where link points to, or empty string iff linkname is not a link
proc file_link {linkname} {
  set res ""
  catch {
    set res [file link $linkname]
  }
  if {$res == ""} {
    return $res
  } else {
    # return $res
    return [file normalize [file join $linkname .. $res]]
  }
}


main $argv
