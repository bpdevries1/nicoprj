
# import procs from namespace into the main/global namespace.
# what can be a list of items/procs to import
proc use {ns {what *}} {
  if {$what == "*"} {
    namespace import ::${ns}::*
  } else {
    foreach el $what {
      namespace import ::${ns}::$el
    }
  }
}

# example: require libdatetime dt
# makes all commands in ns available as <as>/command
# same as Clojure; / is easier to type than ::
# eg: libdatetime::now is a command. After previous call, dt/now will be available

# should be able to find all exported commands in a namespace.
# until then:
proc require {ns as} {
  namespace import ::${ns}::*
  foreach el [namespace import] {
    set el_org [namespace origin $el]
    if {[namespace qualifiers $el_org] == "::$ns"} {
      # puts "Making alias for $el_org"
      interp alias {} "${as}/$el" {} $el_org
      # todo
      namespace forget $el
    } else {
      # puts "From other package, ignoring: $el_org"
    }
  }
}

