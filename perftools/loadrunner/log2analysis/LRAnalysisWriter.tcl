package require XOTcl
namespace import xotcl::*

xotcl::Class LRAnalysisWriter -parameter {directory fd}

LRAnalysisWriter instproc open_file {rootname} {
  my instvar fd
  my instvar directory
  file mkdir $directory
  set fd [open [file join $directory "$rootname.csv"] w]
  puts $fd [join [list date time url elapsed subelapsed] ,]
}

LRAnalysisWriter instproc close_file {} {
  my instvar fd
  close $fd
}

# @param args is collected dictionary
# @params -dt_start, -dt_stop: 2010-10-10 10:10:10.123
#  -omschrijving: korte tekst
# -ms_elapsed, -ms_subtime
# @todo dict_multi_get
LRAnalysisWriter instproc write_line {args} {
  my instvar fd
  regexp {^([^ ]+) ([^\.]+)(.*)$} [dict get $args -dt_start] z date_start time_start msec
  puts $fd [join [list $date_start $time_start [dict get $args -omschrijving] \
    [format %.3f [expr 0.001 * [dict get $args -ms_elapsed]]] [format %.3f [expr 0.001 * [dict get $args -ms_subtime]]]] ","]
}
        

