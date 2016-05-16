#!/usr/bin/env tclsh86

# #!/usr/bin/env tclsh86

# jtl-sqlite.tcl - convert a jtl file to sqlite db.

package require sqlite3
package require xml
package require Tclx

# own package
package require ndv

# lines
# <httpSample t="2430" lt="2426" ts="1350721801764" s="true" lb="Behandelaar ophalen" rc="200" rm="OK" tn="Thread Group 1-2" 
# dt="text" de="utf-8" by="555" ng="2" na="2" hn="P3738"/>
set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[info script].log"

proc main {argv} {
  log debug "argv: $argv"
  lassign $argv jtlfile dbfile
  log debug "jtlfile: $jtlfile"
  log debug "dbfile: $dbfile"
  create_db $dbfile
  # handle_jtl $jtlfile
  handle_jtl_whole_file $jtlfile
  finish_db
}

proc create_db {dbfile} {
  file delete -force $dbfile
  sqlite3 db $dbfile
  
  #set fields [list t lt ts s lb rc rm tn dt de by ng na hn]
  set fields [list t lt ts s lb rc rm tn dt de by ng na hn ec it sc]
  db eval "create table httpsample ([join $fields ", "])"
  db close
  sqlite3 db $dbfile
  log debug "Created db: $dbfile"
}

proc finish_db {} {
  log debug "Create index on ts:"
  db eval "create index ix_ts on httpsample (ts)"
  log debug "Create index on lb:"
  db eval "create index ix_lb on httpsample (lb)"
  log debug "Creating indexes finished, closing db"
  db close
}

proc handle_jtl_whole_file {jtlfile} {
  db eval "begin transaction"
  # set parser [::xml::parser -final 0 -elementstartcommand [list httpsample count] -defaultcommand xml_default -errorcommand xml_error]
  # set parser [::xml::parser -final 0 -elementstartcommand httpsample -defaultcommand xml_default -errorcommand xml_error]
  # 29-10-2012 NdV met -final 0 gaat het helemaal fout, snapt 'ie niets meer. op wiki.tcl.tk wel iets dat dit niet echt goed zou werken, klopt dus wel (http://wiki.tcl.tk/1950)
  # [2013-06-28 13:38:22] -errorcommand wordt niet gesnapt, nu even weg. Linux, tcl86.
  # set parser [::xml::parser -elementstartcommand httpsample -defaultcommand xml_default -errorcommand xml_error]
  set parser [::xml::parser -elementstartcommand [list httpsample count] -defaultcommand xml_default]
  set f [open $jtlfile r]
  log debug "Reading file: $jtlfile"
  set text [read $f]
  log debug "Reading file finished, now parsing text"
  try_eval {
    $parser parse $text
  } {
    log debug "error: $errorResult"
    log debug "Maybe no close tag, because JMeter still running"
  }
  log debug "Parsing text finished"
  db eval "commit"
  close $f
  $parser free
}

proc handle_jtl {jtlfile} {
  db eval "begin transaction"
  # set parser [::xml::parser -final 0 -elementstartcommand [list httpsample count] -defaultcommand xml_default -errorcommand xml_error]
  # set parser [::xml::parser -final 0 -elementstartcommand httpsample -defaultcommand xml_default -errorcommand xml_error]
  # set parser [::xml::parser -elementstartcommand [list httpsample count] -defaultcommand xml_default -errorcommand xml_error]
  # 29-10-2012 NdV op Linux geen -errorcommand. xml parser is ook 2.6, dus wel raar.
  # 29-10-2012 moet op Linux -parser tcl opgeven, anders std expat, en deze geeft vage meldingen.
  # 29-10-2012 @todo evt na aantal parses de parser opnieuw maken, want op Windows geen geheugen meer na 2 mio records.
  # set parser [::xml::parser -parser tcl -elementstartcommand [list httpsample count] -defaultcommand xml_default]
  # 18-12-2012 op Windows juist niet parser tcl?
  set parser [::xml::parser -elementstartcommand [list httpsample count] -defaultcommand xml_default]
  set f [open $jtlfile r]
  while {![eof $f]} {
    gets $f line
    log debug "parsing line: $line"
    breakpoint
    try_eval {
      $parser parse $line
    } {
      log debug "error: $errorResult"
      if {[regexp unclosedelement $errorResult]} {
        # ok, bekende fout 
      } else {
        # best veel breakpoints bij inlezen loadtest-run, dus weg.
        # breakpoint
      }
    }
    log debug "going to next line"
  }
  close $f
  $parser free
  db eval "commit"
  log debug "Parsing finished"
}

proc httpsample2 {name attlist args} {
  if {1} {
    if {$name == "httpSample"} {
      # log debug "Found tag: $name"
      set sql [make_sql $attlist]
      # log debug "sql: $sql"
      db eval $sql
    } elseif {$name == "sample"} {
      set sql [make_sql $attlist]
      # log debug "sql: $sql"
      db eval $sql
    } else {
      log debug "Unknown tag: $name ($attlist, $args)" 
    }
  }
}

proc httpsample {varName name attlist args} {
  upvar #0 $varName var
  if {$name == "httpSample"} {
    log debug "Found tag: $name"
    incr var
    if {[expr $var % 1000] == 0} {
      log debug "Handled $var httpsamples"
      db eval "commit"
      db eval "begin transaction"
    }
    set sql [make_sql $attlist]
    # log debug "sql: $sql"
    try_eval {
      db eval $sql
    } {
      log debug "error: $errorResult"
      breakpoint
    }
  } elseif {$name == "sample"} {
    log debug "Found tag: $name"
    incr var
    if {[expr $var % 1000] == 0} {
      log debug "Handled $var httpsamples"
      db eval "commit"
      db eval "begin transaction"
    }
    set sql [make_sql $attlist]
    # log debug "sql: $sql"
    try_eval {
      db eval $sql
    } {
      log debug "error: $errorResult"
      breakpoint
    }
  } else {
    log debug "Unknown tag: $name ($attlist, $args)" 
  }
}

proc xml_default {data} {
  log debug "XML default, data=$data" 
}

proc xml_error {errorcode errormsg} {
  log debug "XML reading error, code=$errorcode, msg=$errormsg" 
}

proc make_sql {attlist} {
  # attlist: list of pairs volgens tcl docs
  # niet dus: gewoon platte lijst, met om en om name en value.
  set cols {}
  set vals {}
  foreach {name val} $attlist {
    # lappend cols [lindex $el 0]
    lappend cols $name
    # set val [lindex $el 1]
    # lege string wordt ook als double gezien: niet goed
    if {$val == ""} {
      lappend vals "\"$val\""
    } elseif {[string is double $val]} {
      lappend vals $val
    } else {
      lappend vals "\"$val\""
    }
  }
  return "insert into httpsample ([join $cols ", "]) values ([join $vals ", "])"
}

proc log {args} {
  # global log
  variable log
  $log {*}$args
}

main $argv
