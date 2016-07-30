set _tasks [dict create]

use libfp

proc task {name desc body} {
  global _tasks
  set proc_name "task_$name"
  dict set _tasks $name [dict create name $name firstline [first_line $desc] desc $desc]

  proc $proc_name {args} $body
  
}

# [2016-07-30 12:24] new version to automatically set options.
# TODO: maybe make options/params optional, then need to use args as param
# proc task2 {name desc options params body} {}
# params: name desc [options [params]] body
# so name, desc and body are mandatory. Options and params are optional. If params are given, options should also be given.
proc task2 {args} {
  global _tasks
  set args [lassign $args name desc]
  set body [lindex $args end]
  set args [lrange $args 0 end-1]
  lassign $args options params
  set proc_name "task_$name"
  dict set _tasks $name [dict create name $name firstline [first_line $desc] \
                             desc [make_desc $name $desc $options $params]]
  # [2016-07-30 14:11] Use [list] to ensure options and usage are given as single
  # arguments to getoptions.
  set body2 "set opt \[getoptions args [list $options] [list [usage $name $params]]\]\n$body"
  proc $proc_name {args} $body2
  #log debug "task2 defined: $proc_name"
  #breakpoint
}

proc first_line {str} {
  lindex [split $str "\n"] 0
}

# Add a syntax line after first line based on options.
# TODO: also need a place to add parameters after options, like file(s) or action(s)
proc make_desc {name desc options params} {
  set optstr [getoptions _ $options [usage $name $params] help]
  # set helpstr "\nSyntax: $name \[options\] $params\n$optstr\n"
  set helpstr "\nSyntax: $optstr\n"
  # if {![regsub {\n} $desc $helpstr desc]} {}
  append desc $helpstr
  return $desc
}

proc usage {name params} {
  return "$name \[options\] $params"
}

task help {Help for tasks
  Syntax:
  help          - show help overview
  help <task>   - show help for task
  help all      - show detailed help for all tasks
  help <regexp> - show help for all tasks where either name or description matches regexp. 
} {
  global _tasks
  puts "Build tool v0.1.0\n"

  lassign $args task_string
  set taskname [task_name $task_string]
  if {$taskname == ""} {
    puts "Tasks:"
    set len [max {*}[map {x {string length $x}} [dict keys $_tasks]]]
    foreach task [lsort [dict keys $_tasks]] {
      puts [format "%-${len}s   %s" [task_str $task] [:firstline [dict get $_tasks $task]]]          
    }
  } elseif {$taskname == "all"} {
    puts "Tasks:"
    foreach task [lsort [dict keys $_tasks]] {
      set el [dict get $_tasks $task]
      puts "[task_str $task] - [:desc $el]"
      puts "--------------------"
    }
  } else {
    set lst [find_tasks $_tasks $taskname]
    set lst [lsort -index 1 $lst]; # this sorts on 2nd element in the dict, the name value.
    if {$lst == {}} {
      puts "No tasks matching found: [task_str $taskname]"
    } else {
      foreach el $lst {
        puts "[task_str [:name $el]] -  [:desc $el]"        
      }
    }
  }
}

# convert internal task name to string to be presented.
# for now only from _ to -
# this one is idempotent
proc task_str {task_name} {
  regsub -all {_} $task_name "-"
}

# convert task string (as presented and given by user) to internal task name.
# for now only from - to _
# this one is idempotent.
proc task_name {task_str} {
  regsub -all -- {-} $task_str "_"
}

# find all tasks where task matches regexp re. So check both the name and the description.
proc find_tasks {tasks re} {
  # could use -stride to handle the dict as a list, and sort on the keys:
  #   set tasks [lsort -stride 2 $tasks]
  # [2016-07-21 21:05] fn is the closure variant, just made. Needs more test-cases in test-libfp.tcl. fn is a bit like a macro, it preps the body before evaluating.
  filter [fn x {regexp $re $x}] [dict values $tasks]
}

