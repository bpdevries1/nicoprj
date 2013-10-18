#!/usr/bin/env tclsh86

# readlog-atg.tcl

package require tdbc::sqlite3
package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
$log set_file "[file tail [info script]].log"

proc main {argv} {
  global conn stmt_insert
  lassign $argv root_dir
  set db_name [file join $root_dir "atglogs.db"]
  set conn [open_db $db_name]
  set table_def [make_table_def atglogs filename server serverstore linenr ts level class thread message]
  create_table $conn $table_def 1
  set stmt_insert [prepare_insert_td $conn $table_def]
  # @todo handle_dir_rec : vaste params aan mee te geven? of curried functie maken?
  handle_dir_rec $root_dir "*.log" read_logfile
  log info "All files read, closing"
  $conn close
  log info "Closed, exiting"
  # @todo vraag of 'ie zonder de exit ook stopt...
  exit
}

# @todo dit is ook soort pattern, met handle_prev(ious). Is hier een functie (macro?) van te maken?
proc read_logfile {filename rootdir} {
  global conn stmt_insert
  log info "Read logfile: $filename"
  set f [open $filename r]
  set dct_msg {}
  set ignore_lines 0
  set linenr 0
  # app05-s1.log
  # login.jsp|prodl-app05|store4|a23-
  if {[regexp {app(\d\d)-s(\d).log} $filename z srv st]} {
    set server "prod1-app$srv"
    set serverstore "store$st"
  } else {
    error "Cannot determine server/store from filename" 
  }
  db_in_trans $conn {
    while {![eof $f]} {
      gets $f line
      incr linenr
      # 2013-06-02 00:02:26,933 ERROR [org.apache.catalina.core.ContainerBase.[jboss.web].[localhost].[/c].[jsp]] Servlet.service() for servlet jsp threw exception
      # java.lang.NullPointerException
      # @note class kan ook [] bevatten, maar geen spatie.
      # @note message kan leeg zijn.
      # 2013-06-02 22:58:58,810 INFO  [nucleusNamespace.CDLS service] Successfully connected CDLS service
      # 2013-06-02 18:14:12,637 ERROR [org.apache.catalina.core.ContainerBase.[jboss.web].[localhost].[/].[Status Servlet]] Servlet.service() for servlet Status Servlet threw exception
      # @note er komen (toch) spaties in de class voor, net als []. Lijkt dat '] ' wel het einde aangeeft.
      
      # shop logs:
      # 2013-10-16 14:04:14,442 ERROR [nucleusNamespace.atg.commerce.search.catalog.QueryFormHandler] (ajp-0.0.0.0-8409-1) beforeSearch() can not execute paged request with no previously saved request       
      if {[regexp {^([^ ]+ [^ ]+) ([A-Z]+) +\[(.+)\] \(([^\(\)]+)\) (.*)$} $line z ts level class thread message]} {
        handle_prev $conn $stmt_insert $dct_msg
        # set dct_msg [dict create filename $filename ts $ts level $level class $class message $message]                
        set dct_msg [vars_to_dict filename server serverstore linenr ts level class thread message]
        set ignore_lines 0
      } elseif {$ignore_lines} {
        # nothing
      } elseif {[regexp {^\tat } $line]} {
        dict append dct_msg message "\n$line"
        set ignore_lines 1
      } else {
        # normal line to add to message
        dict append dct_msg message "\n$line"
      }
    }
    handle_prev $conn $stmt_insert $dct_msg
  }
  close $f
  log info "Finished reading logfile: $filename"
  # exit ; # for testing.
}

proc handle_prev {conn stmt_insert dct_msg} {
  if {$dct_msg != {}} {
    stmt_exec $conn $stmt_insert $dct_msg
  }
}

main $argv

