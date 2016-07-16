set _tasks [dict create]

proc task {name desc body} {
  global _tasks
  set proc_name "task_$name"
  dict set _tasks $name [dict create firstline [first_line $desc] desc $desc]

  proc $proc_name {args} $body
  
}

proc first_line {str} {
  lindex [split $str "\n"] 0
}

task help {Help for tasks
  Syntax:
  help       - show help overview
  help <task> - show help for task
  help all   - show detailed help for all tasks
} {
  # all defined tasks, alphabetical.
  global _tasks
  puts "Build tool v0.1.0"

  lassign $args taskname
  if {$taskname == ""} {
    puts "Tasks:"
    set len [max [map {x {string length $x}} [dict keys $_tasks]]]
    foreach task [lsort [dict keys $_tasks]] {
      puts [format "%-${len}s   %s" $task [:firstline [dict get $_tasks $task]]]          
    }
  } elseif {$taskname == "all"} {
    puts "Tasks:"
    # set len [max [map {x {string length $x}} [dict keys $_tasks]]]
    foreach task [lsort [dict keys $_tasks]] {
      set el [dict get $_tasks $task]
      #puts [format "%-${len}s   %s" $task [:firstline $el]]
      #puts [:desc $el]
      puts "$task - [:desc $el]"
      puts "--------------------"
    }
  } else {
    set el [dict_get $_tasks $taskname]
    if {$el == {}} {
      puts "Task not found: $taskname"
    } else {
#      puts "Task: $taskname"
#      puts "=============="
      puts "$taskname -  [:desc $el]"
    }
  }
}

