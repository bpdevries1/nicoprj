package require struct::queue
package require ndv

require libio io
use libmacro

proc def_parser {topic body} {
  global parsers ;              # list of [dict topic proc_name]
  # [2016-08-09 21:08] unique_name - multiple parsers for same topic are possible.
  set proc_name [unique_name parse_$topic]
  lappend parsers [vars_to_dict topic proc_name]
  proc $proc_name {line linenr} $body
}

# args: either init, body or just body
# at start of body, res is set to empty, item contains item/dict just received.
# at end of body, res should be set to 0, 1 or more result items.
proc def_handler2 {in_topics out_topic args} {
  if {[:# $args] == 2} {
    lassign $args init body
  } else {
    lassign $args body
    set init {}
  }
  # iets met backtick, escape_body of zo zou aardig zijn, vgl clojure macro.
  set body2 [syntax_quote {~@$init
    set item [yield]
    while 1 {
      set res ""
      ~@$body
      set item [yield $res]
    }
  }]
  log debug "body2: $body2"
  # breakpoint
  def_handler $in_topics $out_topic $body2
}

proc def_handler2_old {in_topics out_topic args} {
  if {[:# $args] == 2} {
    lassign $args init body
  } else {
    lassign $args body
    set init {}
  }
  # iest met backtick, escape_body of zo zou aardig zijn, vgl clojure macro.
  set body2 "$init
set item \[yield\]
while 1 {
  set res \"\"
  $body
  set item \[yield \$res]
}"
  log debug "body2: $body2"
  def_handler $in_topics $out_topic $body2
}

# out_topic is identifying, key.
# in_topics needed to decide which handlers to call for a topic.
proc def_handler {in_topics out_topic body} {
  global handlers; # dict key=in-topic, value = list of [dict topic coro-name]
  if {$out_topic == ""} {
    set coro_name [unique_name coro_make_]
  } else {
    # set coro_name "coro_make_${out_topic}"
    set coro_name [unique_name coro_make_$out_topic]
  }
  # log debug "def_handler: coro_name: $coro_name"
  foreach in_topic $in_topics {
    dict lappend handlers $in_topic [dict create coro_name $coro_name topic $out_topic]
  }
  # now not a normal proc-def, but a coroutine.
  # apply is the way to convert a body to a command/'proc'.
  coroutine $coro_name apply [list {} $body]
}

proc unique_name {prefix} {
  global __unique_counter__
  incr __unique_counter__
  return "$prefix$__unique_counter__"
}

# main proc
# [2016-08-05 20:39] Another go at readlogfile, with knowledge of coroutines.
# specs could be a set of procs to handle reading the file.
# opt: dict with extra options, like db object.
proc readlogfile_coro {logfile {opt ""}} {
  global parsers ;              # list of proc-names.
  global handlers; # dict key=in-topic, value = list of [dict topic coro-name]
  set to_publish [struct::queue]
  $to_publish put [dict merge [dict create topic bof logfile $logfile] $opt]
  handle_to_publish $to_publish
  
  io/with_file f [open $logfile rb] {
    # still line based for now
    set linenr 0
    while {[gets $f line] >= 0} {
      incr linenr
      #log debug "read line: $line"
      handle_parsers $to_publish $logfile $line $linenr
      set sz [$to_publish size]
      #log debug "after parsers, #q: $sz"
      if {$sz > 0} {# log debug "top q item: [$to_publish peek]"}
      handle_to_publish $to_publish
    }
  }
  # handle eof topic
  $to_publish put [dict create topic eof logfile $logfile]
  handle_to_publish $to_publish
}

proc handle_parsers {to_publish logfile line linenr} {
  global parsers ;              # list of [dict topic proc_name]
  # first put through all parsers, and put in queue to_pub
  # to_publish is empty here.
  assert {[$to_publish size] == 0}
  # log debug "new line, nr = $linenr"

  foreach parser $parsers {
    # set res [$parser $line]
    # TODO: maybe also add full line as a key in the dict?
    set res [add_topic_file_linenr [[:proc_name $parser] $line $linenr] \
                 [:topic $parser] $logfile $linenr]
    # result should be a dict, including a topic field for pub/sub (coroutine?)
    # channels. Also, more than one parser could produce a result. A parser produces
    # max 1 result for 1 topic, handlers could split these into multiple results,
    # check for this.
    if {$res != ""} {
      $to_publish put $res
    }
  };                        # end-of-foreach
}

proc handle_to_publish {to_publish } {
  global handlers; # dict key=in-topic, value = list of [dict topic coro_name]
  while {[$to_publish size] > 0} {
    set item [$to_publish get]
    # log debug "handle_to_publish: item: $item"
    set topic [:topic $item]
    # could be there are no handlers for a topic, eg eof-topic. So use dict_get.
    foreach handler [dict_get $handlers $topic] {
      # log debug "Handling with handler: $handler"
      # set res [add_topic [[:coro_name $handler] $item] [:topic $handler]]
      set res [[:coro_name $handler] $item]
      # log debug "result of handler: $res"
      if {$res != ""} {
        if {[dict exists $res multi]} {
          # puts "=== PUTTING MULTIPLE RESULTS BACK ON QUEUE!!"
          foreach el [:multi $res] {
            $to_publish put [add_topic $el [:topic $handler]]
          }
        } else {
          $to_publish put [add_topic $res [:topic $handler]]
        }
      }
    };                      # end-of-foreach
  };                        # end-of-while to-publish
}

# post process all parser results to add topic, logfile and linenr
proc add_topic_file_linenr {item topic logfile linenr} {
  if {$item == ""} {
    return ""
  }
  dict merge $item [vars_to_dict topic logfile linenr]
}

# post process all handler/maker results to add just topic
proc add_topic {item topic} {
  log debug "add_topic: $item --- $topic"
  if {$item == ""} {
    return ""
  }
  dict merge $item [dict create topic $topic]
}

# helper for multiple results
# result is either:
# - empty string, nothing.
# - a dict with a single item
# - a dict with one key: multi, with has a list of dicts as values.
# @param resname - name of the var to add to
# @param args - list of values to add, all dicts.
proc res_add {resname args} {
  upvar $resname res
  set lst [res_items $res];     # list of current items, with 0, 1 or more items
  foreach el $args {
    lappend lst $el
  }
  switch [llength $lst] {
    0 {set res ""}
    1 {set res [:0 $lst]}
    default {set res [dict create multi $lst]}
  }
  log debug "add res result: [res_tostring $res]"
  return $res
}

proc res_items {res} {
  if {$res == {}} {
    return {}
  } else {
    if {[dict exists $res multi]} {
      return [:multi $res]
    } else {
      return [list $res]
    }
  }
}

proc res_tostring {res} {
  set tp [res_type $res]
  switch $tp {
    empty {return empty}
    single {return "single: $res"}
    multi {
      set str "multi:"
      foreach el [:multi $res] {
        append str "\n-> $el"
      }
      return $str
    }
  }
}

proc res_type {res} {
  if {$res == {}} {
    return empty
  } else {
    if {[dict exists $res multi]} {
      return multi
    } else {
      return single
    }
  }

  
}
