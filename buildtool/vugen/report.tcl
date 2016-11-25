# TODO: need to put this setting/location somewhere. This could be a user
# setting in ~/.config/buildtool, next to location of eg R binary.

# [2016-08-18 15:01:52] Version for VuGen

#ndv::source_once ../../vugentools/vuserlog/read-vuserlogs-db.tcl
#ndv::source_once ../../vugentools/vuser-report/vuser-report.tcl

# TODO: better way to find perftools_dir, maybe in config-env.
set perftools_dir [file normalize [file join \
                                       [file dirname [info script]] .. .. perftools]]
source [file join $perftools_dir report read-report-dir.tcl]

task report {Create report of output.txt in script dir
  Copy output.txt to testruns dir, call vugentools/vuserlog/read-vuserlogs-db.tcl
  and create Html report.
} {
  {clean "Delete DB and generated reports before starting"}
  {summary "Create summary report, with aggregate times and errors"}
  {full "Create full report, with each iteration/transaction."}
  {step "Include all steps in full report"}
  {all "Both summary and full"}
  {ssl "Read SSL logs into DB"}
  {logdotpng "Create PNG for read log process"}
} {
  global testruns_dir
  if {[regexp {<FILL IN>} $testruns_dir]} {
    puts "WARN: testruns_dir not set yet (in .bld/config.tcl): $testruns_dir"
    return
  }
  # opt available
  log debug "Report for VuGen"
  
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
  read_report_run_dir $subdir $opt
}

