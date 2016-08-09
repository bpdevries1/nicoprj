# libmacro.tcl - macro like facilities for Tcl. Compare lisp/clojure.

# package require ndv ; # for now, breakpoint

namespace eval ::libmacro {
  namespace export syntax_quote

  # replace ~$var elements with actual value of var in surrounding scope (uplevel)
  # TODO: (maybe) replace ~[cmd x] constructs?
  # TODO: (maybe) replace ~@$lst, splice operator.
  # TODO: implementation very similar to libfp/eval_closure, so combine something, but first make it work.
  proc syntax_quote {form} {
    set indices [regexp -all -indices -inline {(~@?\$)([A-Za-z0-9_]+)} $form]
    # begin at the end, so when changing parts at the end, the indices at the start stay the same.
    # instead of checking if var usage in body occurs in param list, could also try to eval the var and if it succeeds, take the value. However, the current method seems more right.
    foreach {range_name range_prefix range_total} [lreverse $indices] {
      set varname [string range $form {*}$range_name]
      set prefix [string range $form {*}$range_prefix]
      upvar 1 $varname value
      # set body [string replace $body {*}$range_total $value]
      # TODO: or check value and decide what needs to be done, surround with quotes, braces, etc.
      if {$prefix == {~$}} {
        # standard unquote (~)
        set form [string replace $form {*}$range_total [list $value]]  
      } elseif {$prefix == {~@$}} {
        # unquote splice (~@)
        set form [string replace $form {*}$range_total $value]  
      } else {
        error "Unknown range_prefix: $range_prefix (form: $form)"
      }
    }
    return $form
  }
  
}
