# saveas - save a newly recorded script to another directory.
# like the save-as function in VuGen, only copy script files, not recording logs and data directory.

task saveas {Save a newly recorded script to another directory
  Syntax: saveas <new-prj-dir} {
} {
  lassign $args target
  # puts "TODO: save-as: $target"
  if {$target == ""} {
    puts "Syntax: saveas <new-prj-dir>"
    return
  }
  set target_dir [file normalize [file join .. $target]]
  if {[file exists $target_dir]} {
    puts "Target dir already exists: $target_dir"
    return
  }
  set current_dir [file tail [file normalize .]]
  file mkdir $target_dir
  foreach filename [get_project_files] {
    if {$filename == "ScriptUploadMetadata.xml"} {
      set text [read_file $filename]
      regsub -all $current_dir $text $target text2
      write_file [file join $target_dir $filename] $text2 
    } elseif {[file extension $filename] == ".usr"} {
      file copy $filename [file join $target_dir "$target.usr"]
    } else {
      file copy $filename [file join $target_dir $filename]  
    }
  }
}

