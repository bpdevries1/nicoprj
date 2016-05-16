package require XOTcl
namespace import xotcl::*

xotcl::Class ExtendedAnalysisWriter -parameter {directory fd}

ExtendedAnalysisWriter instproc open_file {rootname} {
  my instvar fd
  my instvar directory
  file mkdir $directory
  set fd [open [file join $directory "$rootname.tsv"] w]
  puts $fd [join [list starttime epoch_starttime description elapsed subtime] "\t"]
}

ExtendedAnalysisWriter instproc close_file {} {
  my instvar fd
  close $fd
}

# @param args is collected dictionary
# @params -dt_start, -dt_stop: 2010-10-10 10:10:10.123
#  -omschrijving: korte tekst
# -ms_elapsed, -ms_subtime
# @todo dict_multi_get
ExtendedAnalysisWriter instproc write_line {args} {
  my instvar fd
  regexp {^([^\.]+)(.*)$} [dict get $args -dt_start] z dt_start msec
  set epochtime "[clock scan $dt_start -format "%Y-%m-%d %H:%M:%S"]$msec"
  puts $fd [join [list $dt_start $epochtime [dict get $args -omschrijving] \
    [format %.3f [expr 0.001 * [dict get $args -ms_elapsed]]] [format %.3f [expr 0.001 * [dict get $args -ms_subtime]]]] "\t"]
}


