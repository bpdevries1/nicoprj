#!/usr/bin/env tclsh

package require ndv
ndv::source_once liblogreader.tcl

require libdatetime dt
require libio io

set_log_global info

proc main {argv} {
  set testfilename "/tmp/logreader-test.log"
  make_testfile $testfilename
  # of toch een losse namespace waar deze dingen in hangen?
  def_parsers
  def_handlers
  log info "Calling readlogfile"
  readlogfile_coro $testfilename [dict create db "my-db-object"]
  log info "Finished readlogfile"
}

proc make_testfile {testfilename} {
  io/with_file f [open $testfilename w] {
    for {set nr 101} {$nr <= 111} {incr nr} {
      # puts $f "\[[dt/now]] line: $linenr, "
      puts $f "nr: $nr - some more text"
    }
  }
}

proc def_parsers {} {
  def_parser nrline {
    if {[regexp {nr: (\d+)} $line z nr]} {
      vars_to_dict nr line
    } else {
      return ""
    }
  }
}

proc def_handlers {} {
  def_handler {nrline eof} even {
    log debug "even-handler: started"
    set nitems 0
    set item [yield]
    set eof 0
    while {!$eof} {
      log debug "even-handler: item: $item"
      if {[:topic $item] == "eof"} {
        set eof 1
        set res ""
      } else {
        incr nitems
        if {$nitems % 2 == 0} {
          set res [dict merge $item [dict create nitems $nitems]]
        } else {
          if {$nitems == 3} {
            # generate 3 results
            set el [dict merge $item [dict create nitems $nitems]]
            set l [list]
            foreach i {1 2 3} {
              lappend l $el
            }
            set res [dict create multi $l]
            # puts "yielding MULTI: $res"
          } else {
            set res ""            
          }
        }
      }
      set item [yield $res]
    }
  }

  # 'inserter' handler, just for side effects, yields no new results.
  def_handler {bof even} {} {
    log debug "puts-handler: started"
    set db "<none>"
    set item [yield]
    while 1 {
      if {[:topic $item] == "bof"} {
        set db [:db $item]
      } else {
        #puts "********************************"
        puts "*** Even handler item: $item, db: $db ***"
        #set m [:multi $item]
        #puts "*** m: $m ***"
        #puts "********************************"
      }
      set item [yield]
    }
  }

}

if {[this_is_main]} {
  main $argv  
}


