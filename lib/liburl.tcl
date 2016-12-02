package provide ndv 0.1.1

# TODO: maybe det_valuetype is too specific, and should be extracted from url->params.

namespace eval ::liburl {
  namespace export url-encode url-decode url->parts url->params det_valuetype

# source: http://wiki.tcl.tk/14144
proc init-url-encode {} {
    variable map
    variable alphanumeric a-zA-Z0-9
    for {set i 0} {$i <= 256} {incr i} { 
        set c [format %c $i]
        if {![string match \[$alphanumeric\] $c]} {
            set map($c) %[format %.2x $i]
        }
    }
    # These are handled specially
    array set map { " " + \n %0d%0a }
}
init-url-encode

# source: http://wiki.tcl.tk/14144
proc url-encode {string} {
    variable map
    variable alphanumeric

    # The spec says: "non-alphanumeric characters are replaced by '%HH'"
    # 1 leave alphanumerics characters alone
    # 2 Convert every other character to an array lookup
    # 3 Escape constructs that are "special" to the tcl parser
    # 4 "subst" the result, doing all the array substitutions

    regsub -all \[^$alphanumeric\] $string {$map(&)} string
    # This quotes cases like $map([) or $map($) => $map(\[) ...
    regsub -all {[][{})\\]\)} $string {\\&} string
    return [subst -nocommand $string]
}

# source: http://wiki.tcl.tk/14144
proc url-decode str {
    # rewrite "+" back to space
    # protect \ from quoting another '\'
    set str [string map [list + { } "\\" "\\\\"] $str]

    # prepare to process all %-escapes
    regsub -all -- {%([A-Fa-f0-9][A-Fa-f0-9])} $str {\\u00\1} str

    # process \u unicode mapped chars
    return [subst -novar -nocommand $str]
}

# return list of url params
# each element is a tuple: type,name,value,valuetype as dict
# package uri can only provide full query string, so not really helpful here.
proc url->params {url} {
  if {[regexp {^[^?]*\?(.*)$} $url z params]} {
    set res [list]
    foreach pair [split $params "&"] {
      # lappend res [split $pair "="]
      lassign [split $pair "="] nm val
      lappend res [dict create type namevalue name $nm value $val \
                      valuetype [det_valuetype $val]]
    }
    return $res
  } else {
    return [list]
  }
}

# TODO: several date/time formats.
proc det_valuetype {val} {
  set base64_min_length 32;     # should test, maybe configurable.
  if {$val == ""} {
    return empty
  }
  if {[regexp {^\d+$} $val]} {
    # integer, check if it could be an epoch time.
    if {($val > "1400000000") && ($val < "3000000000")} {
      return "epochsec: [clock format $val]"
    }
    if {($val > "1400000000000") && ($val < "3000000000000")} {
      return "epochmsec: [clock format [string range $val 0 end-3]]"
    }
    return integer
  }
  foreach stringtype {boolean xdigit double} {
    if {[string is $stringtype $val]} {
      return $stringtype
    }
  }
  # still here, so look deeper.
  # json
  if 0 {
    [2016-11-29 12:36:21] now one body like below, not matched as json, something with backslashes and quotes.
    Body = {\TradingEntities\:null,\RegimeEligibilities\:null,\P }
    and much more.
  }
  if {![catch {json::json2dict $val}]} {
    # also no catch with eg Snapshot = t8.inf [json], so check it is at least surrounded with braces
    if {[regexp {^\{.*\}$} $val]} {
      return json  
    }
  }

  # TODO: should check, not working yet, something with escaping backslashes and quotes.
  if {[regexp TradingEntityReportedRegimes $val]} {
    # log debug "Check jsonexi"
    # breakpoint
  }
  
  # base64 - val should have minimal length
  if {[string length $val] >= $base64_min_length} {
    if {[regexp {^[A-Za-z0-9+/]+$} $val]} {
      return base64
    }
  }


  # url and/or html encoded?

  return string;              # default, if nothing else.
}


}


