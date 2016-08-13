# TODO: need to put this setting/location somewhere. This could be a user
# setting in ~/.config/buildtool, next to location of eg R binary.
ndv::source_once ../../../autohotkey/ahklog/read-ahklogs-db.tcl
ndv::source_once ../../vugentools/vuser-report/vuser-report.tcl

task report {Create report of output.txt in script dir
  Copy output.txt to testruns dir, call perftools/autohotkey/ahklog/read-ahklogs-db.tcl
  and create html report.
} {{summary "Create summary report, with aggregate times and errors"}
  {full "Create full report, with each iteration/transaction."}
  {all "Both summary and full"}
} {
  global testruns_dir
  if {[regexp {<FILL IN>} $testruns_dir]} {
    puts "WARN: testruns_dir not set yet (in .bld/config.tcl): $testruns_dir"
    return
  }
  # opt available

  # first copy output.txt to restruns dirs, iff not already done.
  set logfilename output2/logfile.txt
  if {![file exists $logfilename]} {
    puts "WARN: no output.txt found"
    return
  }
  set subdir [file join $testruns_dir \
                  "ahk-[clock format [file mtime $logfilename] -format \
                  "%Y-%m-%d--%H-%M-%S"]"]
  set to_file [file join $subdir [file tail $logfilename]]
  if {![file exists $to_file]} {
    file mkdir $subdir
    file copy $logfilename $to_file
  }

  # then call read_logfile_dir; idempotency should already be arranged by read_logfile_dir
  set dbname [file join $subdir "ahklog.db"]
  read_logfile_dir $subdir $dbname

  # and finally make the report.
  vuser_report $subdir $dbname $opt
}

