# find files in zips
package require vfs::zip

proc main {argv} {
  lassign $argv root_dir zip_file_spec file_spec min_size_kb
  find_files_zip $root_dir $zip_file_spec $file_spec $min_size_kb
}

proc find_files_zip {dir zip_file_spec file_spec min_size_kb} {
  foreach zipname [glob -nocomplain -directory $dir $zip_file_spec] {
    handle_zip $zipname $file_spec $min_size_kb
  }
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    find_files_zip $subdir $zip_file_spec $file_spec $min_size_kb
  }
}

proc handle_zip {zipname file_spec min_size_kb} {
  set mountpoint /vfs/zip
  vfs::zip::Mount $zipname $mountpoint
  find_files $zipname $mountpoint $file_spec $min_size_kb
  vfs::filesystem unmount $mountpoint
}

proc find_files {zipname dir file_spec min_size_kb} {
  foreach filename [glob -nocomplain -directory $dir $file_spec] {
    handle_file $zipname $filename $min_size_kb
  }
  foreach subdir [glob -nocomplain -directory $dir -type d *] {
    find_files $zipname $subdir $file_spec $min_size_kb
  }
}

proc handle_file {zipname filename min_size_kb} {
  if {[file size $filename] > [expr $min_size_kb * 1024]} {
    puts "$zipname/$filename - [file size $filename] bytes"
  }
}

main $argv

# C:\nico\develop\Tcl861\bin>tclsh c:\nico\find-files-zip.tcl c:\nico\install *.zip *.sh 0
# C:\nico\develop\Tcl861\bin>tclsh c:\nico\find-files-zip.tcl "Y:\02 Testen AT" TraceLogs*.zip DCA* 10000
