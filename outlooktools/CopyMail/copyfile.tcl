# puts "Tcl version: $tcl_version"

puts "copyfile.tcl - start"

# [2015-11-17 14:00:55] zvfs werkt alleen binnen wraptclsh, dus catch eromheen.
catch {lappend ::auto_path [file dirname [zvfs::list */tcom3.9/pkgIndex.tcl]]}
catch {lappend ::auto_path [file dirname [zvfs::list */ndv0.1.1/pkgIndex.tcl]]}

# package require tcom
package require ndv

puts "copyfile.tcl - packages loaded"

source copyfile-main.tcl

