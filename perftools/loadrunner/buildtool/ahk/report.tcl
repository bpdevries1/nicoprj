# TODO: need to put this setting/location somewhere. This could be a user
# setting in ~/.config/buildtool, next to location of eg R binary.
ndv::source_once ../../vugentools/vuserlog/read-vuserlogs-db.tcl
ndv::source_once ../../vugentools/vuser-report/vuser-report.tcl

task report {Create report of output.txt in script dir
  Copy output.txt to testruns dir, call vugentools/vuserlog/read-vuserlogs-db.tcl
  and create Html report.
} {{summary "Create summary report, with aggregate times and errors"}
  {full "Create full report, with each iteration/transaction."}
  {all "Both summary and full"}
  {ssl "Read SSL logs into DB"}
} {
  global testruns_dir
  if {[regexp {<FILL IN>} $testruns_dir]} {
    puts "WARN: testruns_dir not set yet (in .bld/config.tcl): $testruns_dir"
    return
  }
  # opt available

  # first copy output.txt to restruns dirs, iff not already done.
  if {![file exists output.txt]} {
    puts "WARN: no output.txt found"
    return
  }
  set subdir [file join $testruns_dir \
                  "vugen-[clock format [file mtime output.txt] -format \
                  "%Y-%m-%d--%H-%M-%S"]"]
  set to_file [file join $subdir output.txt]
  if {![file exists $to_file]} {
    file mkdir $subdir
    file copy output.txt $to_file
  }

  # then call read_logfile_dir; idempotency should already be arranged by read_logfile_dir
  set dbname [file join $subdir "vuserlog.db"]
  read_logfile_dir $subdir $dbname [:ssl $opt] split_transname

  # and finally make the report.
  vuser_report $subdir $dbname $opt
}

