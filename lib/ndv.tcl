# ndv.tcl - base library file to source other files

# write installation timestamp to stdout
# TODO: maybe not always, dependent on package require param?
source [file join [file dirname [info script]] _installed_datetime.tcl] 
puts stderr "package ndv installed on: $_installed_datetime"

proc test_log {} {
  # info frame quite useful, could use again.
  puts [info frame [expr [info frame] - 1]]
  catch {log info "test"} res
  puts "res: $res"
}

# there are some inter dependencies, so explicitly source other files in the right order.
source [file join [file dirname [info script]] source_once.tcl]

source [file join [file dirname [info script]] CLogger.tcl]

# [2016-07-23 21:32] CHtmlHelper needs CLogger on load. For now, source CLogger both
# here and at the end.
source [file join [file dirname [info script]] CHtmlHelper.tcl] 

# database files in subdir 
source [file join [file dirname [info script]] db AbstractSchemaDef.tcl]

source [file join [file dirname [info script]] db CDatabase.tcl]

source [file join [file dirname [info script]] db CClassDef.tcl] 

source [file join [file dirname [info script]] random.tcl]

catch {source [file join [file dirname [info script]] music-random.tcl]} ; # deze heeft random.tcl nodig en ook CDatabase.tcl 

source [file join [file dirname [info script]] fp.tcl]
source [file join [file dirname [info script]] general.tcl]

# NdV 22-11-2010 in generallib staan dict_get_multi en array_values, nodig in scheids.
source [file join [file dirname [info script]] generallib.tcl]

source [file join [file dirname [info script]] breakpoint.tcl]

# 14-3-2013 added libdot.tcl
source [file join [file dirname [info script]] libdot.tcl]

# 17-3-2013 added libsqlite.tcl
source [file join [file dirname [info script]] libsqlite.tcl]

# 27-3-2013 added libdict.tcl
source [file join [file dirname [info script]] libdict.tcl]

# 27-7-2013 added libdb.tcl (as replacement to be for libsqlite.tcl and db/* (mysql) libraries.
source [file join [file dirname [info script]] libdb.tcl]

# 2-8-2013 added libcsv.tcl
source [file join [file dirname [info script]] libcsv.tcl]

# 6-9-2013 added libcyg.tcl
source [file join [file dirname [info script]] libcyg.tcl]

# 12-10-2013 added libfp.tcl (test needed that functions do not overlap/name clash)
source [file join [file dirname [info script]] libfp.tcl]

# 26-01-2014 added listc - list comprehensions
source [file join [file dirname [info script]] listc.tcl]

# 4-5-2016 have had CPRogresscalculator for a long time, but not included
source [file join [file dirname [info script]] CProgressCalculator.tcl]

# [2016-06-15 10:45:26] add date/time functions
source [file join [file dirname [info script]] libdatetime.tcl]

# [2016-07-09 09:49] namespace functions, compare Clojure
source [file join [file dirname [info script]] libns.tcl]

# [2016-07-23 21:31] CLogger as the last one, because ir defines proc log, which is
# defined before in Tclx.

source [file join [file dirname [info script]] CLogger.tcl]

