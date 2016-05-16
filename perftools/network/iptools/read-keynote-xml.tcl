#!/usr/bin/env tclsh86

# read-keynote-xml.tcl
# determine URL's from Keynote powerpoints, saved as XML.

package require tdbc::sqlite3
package require Tclx
package require ndv
package require htmlparse

source lib-iptools.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]
# $log set_file "read-xenu-export.log"

proc main {argv} {
  set root_folder [det_root_folder] ; # based on OS.
  set db_name [file join $root_folder "aaa/akamai.db"]
  
  set conn [open_db $db_name]
  set table_def [make_table_def keynote_xml filename linenr url]
  log info "Creating table"
  create_table $conn $table_def 1 ; # 1: first drop the table.
  log info "Created table"
  # lookup_entries $conn $table_def "firebug" $wait_after
  read_xmls $conn $table_def "~/Dropbox/Philips/Input/Keynote"
  # db_eval $conn "create index ix_xenurep on xenurep (url)"
}

proc read_xmls {conn table_def src_dir} {
  db_eval $conn "begin transaction"
  dict_to_vars $table_def
  set stmt_insert [prepare_insert $conn $table {*}$fields]
  set i 0
  foreach filename [glob -directory $src_dir "*.xml"] {
    incr i
    log info "read_xml: $filename ($i/52)"
    read_xml $conn $table_def $filename $stmt_insert
  }
  db_eval $conn "commit"
}

proc read_xml {conn table_def filename stmt_insert} {
  set f [open $filename r]
  set linenr 0
  while {![eof $f]} {
    gets $f line
    incr linenr
    while {[regexp {^(.*?)>(https?://[^<]+)<(.*)$} $line z pre u post]} {
      set url [htmlparse::mapEscapes $u] ; # &amp; -> &
      if {[philips_url $url]} {
        set dct_insert [vars_to_dict filename linenr url]
        stmt_exec $conn $stmt_insert $dct_insert
      }
      set line "$pre$post"
    }
  }
  close $f
}

proc philips_url {url} {
  if {[regexp -nocase {microsoft} $url]} {
    return 0 
  }
  if {[regexp -nocase {openxmlformats} $url]} {
    return 0 
  }
  return 1
}

main $argv

