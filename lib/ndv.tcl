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
