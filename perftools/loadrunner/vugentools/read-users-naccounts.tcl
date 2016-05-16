package require ndv

ndv::source_once lib_userresults.tcl

proc main {argv} {
  if {[llength $argv] != 2} {
    puts "syntax: <script> <inputfilename> <dbname>"
    exit 1
  }
  lassign $argv filename dbname
  set ts_cet [clock format [file mtime $filename] -format "%Y-%m-%d %H:%M:%S"]
  set db [get_results_db $dbname]
  set f [open $filename r]
  $db in_trans {
    while {![eof $f]} {
      gets $f line
      if {$line != ""} {
        lassign [split $line "\t"] user nacts
        $db insert user_naccounts [vars_to_dict user nacts filename ts_cet]
      }
    }
  }
}

main $argv
