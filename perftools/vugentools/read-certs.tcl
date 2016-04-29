package require ndv

ndv::source_once lib_userresults.tcl

proc main {argv} {
  if {[llength $argv] != 2} {
    puts "syntax: <script> <inputdirname> <dbname>"
    exit 1
  }
  lassign $argv dirname dbname
  
  set db [get_results_db $dbname]
  $db in_trans {
    foreach filename [glob -directory $dirname *.pem] {
      set user [det_user $filename]
      set ts_cet [clock format [file mtime $filename] -format "%Y-%m-%d %H:%M:%S"]
      $db insert user_naccounts [vars_to_dict user filename ts_cet]
    }
  }
}

proc det_user {filename} {
  if {[regexp {client(\d+)\.pem} $filename z user]} {
    return $user
  }
  error "Could not determine user from filename: $filename"
}

main $argv
