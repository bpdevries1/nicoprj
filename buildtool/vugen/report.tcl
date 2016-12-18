# [2016-08-18 15:01:52] Version for VuGen

source [file join [perftools_dir] report read-report-dir.tcl]

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
  {testruns "Create report for all runs in testruns dir for project"}
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
    if {[:step $opt]} {
      copy_step_result_files $subdir
    }
  }
  read_report_run_dir $subdir $opt; # in perftools/report/read-report-dir.tcl
  if {[:testruns $opt]} {
    # call for every dir in testruns dir.
    foreach subdir [glob -directory $testruns_dir -type d *] {
      read_report_run_dir $subdir $opt
    }
  }
}

proc copy_step_result_files {target_dir_root} {
  set src_dir [file join "result1/iteration1"]
  set target_dir [file join $target_dir_root $src_dir]
  file mkdir $target_dir
  foreach filename [glob -nocomplain -directory $src_dir *.inf] {
    file copy $filename [file join $target_dir [file tail $filename]]
    set ref_file [step_get_ref_file $filename]
    set ref_path [file join $src_dir $ref_file]
    if {[file exists $ref_path]} {
      file copy $ref_path [file join $target_dir [file tail $ref_path]]
    }
  }
}

