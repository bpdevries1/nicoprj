#!/home/nico/bin/tclsh

#package require Tclx
#package require csv
#package require sqlite3

# own package
package require ndv

#::ndv::source_once "platform-$tcl_platform(platform).tcl" ; # load platform specific functions. 
# ::ndv::source_once "graphdata-lib.tcl" "find-overlaps.tcl" "split-columns.tcl"
#::ndv::source_once "graphdata-lib.tcl" "find-overlaps.tcl"

ndv::source_once "data2sqlite.tcl" "graphsqlite.tcl"

# set db [ndv::graphdata::data2sqlite::main $argv]
lassign [ndv::graphdata::data2sqlite::main $argv] db argv2
# breakpoint
ndv::graphdata::graphsqlite::main [concat [list -db $db] $argv2]

