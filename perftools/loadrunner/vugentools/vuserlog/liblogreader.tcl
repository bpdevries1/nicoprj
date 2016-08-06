package require struct::queue

require libio io

proc def_parser {topic body} {
  global parsers ;              # list of [dict topic proc_name]
  # zo geen meerdere parsers die hetzelfde topic opleveren, maar kan later in een
  # handler naar meerdere topics luisteren, en wil dan mss ook wel weten welke topic
  # het precies is.
  # evt check of je dit topic al hebt, kan later nog.
  set proc_name "parse_$topic"
  # lappend parsers [dict create topic $topic proc_name $proc_name]
  lappend parsers [vars_to_dict topic proc_name]
  # set body "$body1\n"
  proc $proc_name {line linenr} $body
}

# out_topic is identifying, key.
# in_topics needed to decide which handlers to call for a topic.
proc def_handler {in_topics out_topic body} {
  global handlers; # dict key=in-topic, value = list of [dict topic coro-name]

  set coro_name "coro_make_${out_topic}"
  # log debug "def_handler: coro_name: $coro_name"
  foreach in_topic $in_topics {
    dict lappend handlers $in_topic [dict create coro_name $coro_name topic $out_topic]
  }
  # now not a normal proc-def, but a coroutine.
  # apply is the way to convert a body to a command/'proc'.
  coroutine $coro_name apply [list {} $body]
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
    # max 1 result for 1 topic, handlers could split these.
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
      set res [add_topic [[:coro_name $handler] $item] [:topic $handler]]
      # log debug "result of handler: $res"
      if {$res != ""} {
        $to_publish put $res
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
  if {$item == ""} {
    return ""
  }
  dict merge $item [dict create topic $topic]
}
