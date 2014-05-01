# ndv.tcl - base library file to source other files

# there are some inter dependencies, so explicitly source other files in the right order.
source [file join [file dirname [info script]] source_once.tcl] 
source [file join [file dirname [info script]] CLogger.tcl] 
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

