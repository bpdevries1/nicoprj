#!/home/nico/bin/tclsh

# install package ndv under tcl lib directory
set package_name ndv
set package_version 0.1.1

# history
# version date     notes
# 0.1              initial version with logger, htmlhelper and xmlhelper
# 0.1.1   8-1-2010 logger: added set_log_level_all

# 16-1-2010 niet meer doen, gebruik vaste pkgIndex.tcl
#pkg_mkIndex . *.tcl

# lib_root D:/DEVELOP/TCL85/lib/tcl8.5 => D:/DEVELOP/TCL85/lib
proc main {} {
  global package_name package_version
  
  set lib_root [file dirname [info library]]
  
  set lib_install [file join $lib_root "$package_name-$package_version"]
  
  copy_dir $lib_install .
  copy_dir $lib_install db
  copy_dir $lib_install js *
  
  if {0} {
    file mkdir $lib_install
    foreach filename [glob *.tcl] {
      puts "copy $filename => $lib_install"
      file copy -force $filename $lib_install
    }
    
    # todo recursive maken, db subdir nu even handmatig.
    file mkdir [file join $lib_install db]
    foreach filename [glob db/*.tcl] {
      puts "copy $filename => $lib_install/db"
      file copy -force $filename [file join $lib_install db]
    }
    
    file mkdir [file join $lib_install js]
    foreach filename [glob js/*.tcl] {
      puts "copy $filename => $lib_install/js"
      file copy -force $filename [file join $lib_install js]
    }
  }
}

proc copy_dir {lib_install subdir {pattern *.tcl}} {
  file mkdir [file join $lib_install $subdir]
  foreach filename [glob -directory $subdir $pattern] {
    puts "copy $filename => $lib_install/$subdir"
    file copy -force $filename [file join $lib_install $subdir]
  }
}

main
