# Eentry points:
# * init - initialise readers, handlers, called when sourcing this file.
# * can_read? - is this namespace/module able to read the file given?
# * read_sourcefile - read sourcefile into db

# OLD:
# * define_logreader_handlers - define parsers and handlers
# * readlogfile_new_coro $logfile [vars_to_dict db ssl split_proc]
#   - this one calls readlogfile_coro, as defined in liblogreader.tcl, not here.

package require ndv
# ndv::source_once liblogreader.tcl

set perftools_dir [file normalize [file join [file dirname [info script]] .. .. perftools]]

# TODO: use source_once with absolute path?
source [file join $perftools_dir logdb liblogreader.tcl]
#source [file join $perftools_dir logdb librunlogreader.tcl]

require libdatetime dt
require libio io
use libmacro;                   # syntax_quote

namespace eval ::vugensource {
  
  namespace export init can_read? read_sourcefile

  proc can_read? {filename} {
    # read .c and .h files, but not generated ones.
    set tail [file tail $filename]
    if {[regexp {^combined} $tail]} {
      return 0
    }
    set ext [file extension $tail]
    if {[lsearch -exact {.c .h} $ext] >= 0} {
      return 1
    }
    return 0
  }

  proc read_sourcefile {filename db} {
    set mtime [clock format [file mtime $filename] -format "%Y-%m-%d %H:%M:%S %z"]
    set size [file size $filename]
    set path $filename
    set name [file tail $path]
    set language "C"

    # TODO: read lines
    $db in_trans {
      set sourcefile_id [$db insert sourcefile [vars_to_dict path name mtime \
                                                    size language]]
      readlogfile_coro $filename [vars_to_dict db sourcefile_id]
    }
  }

  proc init {} {
    # reset_parsers_handlers ; # TODO: needed?
    def_parsers
    def_handlers
  }

proc def_parsers {} {

  def_parser_regexp include_line {^#include "([^\"\"]+)"} {callee}
  
  # TODO: include function definitions, including lines.
  # Also parts outside of function definitions, to determine calls.



}

proc def_handlers {} {

  def_handler {bof eof include_line} statement {
    # init code
    set file_item [dict create]
  } {
    # body/loop code
    switch [:topic $item] {
      bof {
        set file_item $item
      }
      eof {
        set file_item [dict create]
      }
      include_line {
        log debug "Statement handler"
        # breakpoint
        set linenr_start [:linenr $item]
        set linenr_end [:linenr $item]
        set stmt_type include
        set text [:line $item]
        res_add res [dict merge $file_item $item [vars_to_dict linenr_start \
                                                  linenr_end stmt_type text]]
      }
    }
  }
  
  # [2016-08-09 22:29] introduced a bug here by not calling split_proc in insert-trans_line
  # but in trans split_proc is called, and this is used in report. Could also remove fields
  # in trans_line, also split_proc still is somewhat of a hack now.
  def_insert_handler statement
  #def_insert_handler trans
  #def_insert_handler error
  
}

# Specific to this project, not in liblogreader.
# combination of item and file_item
proc def_insert_handler {table} {
  def_handler [list bof $table] {} [syntax_quote {
    if {[:topic $item] == "bof"} { # 
      set db [:db $item]
      set file_item [dict remove $item db]
    } else {
      $db insert ~$table [dict remove [dict merge $file_item $item] topic]
    }
  }]
}


} ; # end-of-namespace

::vugensource::init

return ::vugensource
