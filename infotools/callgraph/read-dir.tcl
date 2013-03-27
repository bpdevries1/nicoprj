#!/home/nico/bin/tclsh86

package require ndv
package require tdbc::sqlite3

# default log object is now created in CLogger.
# set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

# @todo ook ymorlib function inlezen, en calls bepalen.
# dan tijdens graph-make bepalen wat je wilt tonen.

proc main {argv} {
  global conn stmts
  log info "Started"
  
  log debug "argv: $argv"
  set options {
      {dir.arg "" "Source directory to read"}
      {db.arg "callgraph.db" "SQLite DB to put callgraph info in (relative to <dir>"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
  
  set src_dir $ar_argv(dir)
  set db_name [file join $src_dir $ar_argv(db)]
  set conn [create_db $db_name]
  $conn begintransaction
  set stmts [prepare_statements $conn]
  handle_dir_rec $src_dir "*.ahk" handle_ahk

  # @todo remove all (non-)calls where callee is not in function table.
  remove_non_calls $conn
  
  $conn commit
  $conn close
  
}

proc create_db {db_name} {
  file delete $db_name
  set conn [tdbc::sqlite3::connection create db $db_name]
  db_eval $conn "create table file (path)"
  db_eval $conn "create table function (path, name, linenr, params)"
  db_eval $conn "create table call (path, linenr, caller, callee, params)"
  # evt nog indexen.
  
  return $conn
}

proc prepare_statements {conn} {
  # dict create ins_file [$conn prepare "insert into file (path) values (:path)"]
  dict create ins_file [prepare_insert $conn file path] \
              ins_function [prepare_insert $conn function path name linenr params] \
              ins_call [prepare_insert $conn call path linenr caller callee params]
}

# @param args: field names
proc prepare_insert {conn tablename args} {
  # $conn prepare "insert into $tablename ([join $args ", "]) values ([join [map {par {return ":$par"}} $args] ", "])"
  $conn prepare [create_insert_sql $tablename {*}$args]
}

proc create_insert_sql {tablename args} {
  return "insert into $tablename ([join $args ", "]) values ([join [lmap par $args {symbol $par}] ", "])"
}

proc handle_ahk {path root_dir} {
  global stmts
  log info "handle_ahk: filename: $path"
  [dict get $stmts ins_file] execute [vars_to_dict path]
  set caller "<file>"
  # use \x7b and \x7d instead of {}, otherwise paren-matching in jEdit fails. (Vi? Emacs?)
  set linenr 0
  foreach line [split [read_file $path] "\n"] {
    incr linenr
    if {[is_comment $line]} {
      continue 
    }
    if {[regexp {^([a-zA-Z_0-9]+) ?\(([^()]*)\) *\x7b *$} $line z name params]} {
      # start of function def
      if {[is_keyword $name]} {
        # nothing 
      } else {
        [dict get $stmts ins_function] execute [vars_to_dict path name linenr params]
        set caller $name
      }
    } elseif {[regexp {^\x7d *$} $line]} {
      # end of function def
      set caller "<file>"
    } else {
      foreach call [det_calls $line] {
        lassign $call callee params
        # @todo call kan over meerdere lines gaan. In de praktijk nodig? 
        [dict get $stmts ins_call] execute [vars_to_dict path linenr caller callee params]
      }
    }
  }
}

proc is_comment {line} {
  regexp {^[ \t]*;} $line 
}

# copied from AhkDoc: should put in library
proc is_keyword {fn} {
  if {[lsearch -exact {for if while} [string tolower $fn]] >= 0} {
    return 1 
  } else {
    return 0 
  }
}

# example calls:
#     set_resolution(srun, trans_dummy, 1024, 768, 16, 0) ; width, height, colordepth=16, fail_on_error = 0.    
#     log_qwinsta(srun)
#    params := get_params_from_file("params.csv", A_ComputerName)
#    if (do_na_2e_di()) { -> moet nog.
#  srun := init()
#
# NOT: (objects):     trans_dummy.finish()
#
# Dus open-haakje met hiervoor een identifier en hierna evt params evt gevolgd door sluithaakje (of multiline)
# params zijn nog niet zo belangrijk.
# @todo deze eigenlijk recursief uitvoeren, en lijst van calls opbouwen. Dan ook meteen if/while ondervangen.
proc det_calls {line} {
  if {[regexp {do_na_2e_di} $line]} {
    # breakpoint 
  }
  if {[regexp {([a-zA-Z_0-9]+) *\((.*)$} $line z callee rest]} {
    if {[is_keyword $callee]} {
      # return {}
      # recur with rest
      det_calls $rest
    } else {
      # set params ""
      # return 1
      return [list [list $callee ""]]
    }
  } else {
    return {}
  }
}

proc remove_non_calls {conn} {
  # log warn "todo: remove_non_calls" 
  db_eval $conn "delete from call where callee not in (select name from function)"
}

#######################################
# Tcl ndv lib functions 
#######################################

proc symbol {str} {
  return ":$str" 
}

main $argv
