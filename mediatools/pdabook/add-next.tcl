#!/home/nico/bin/tclsh

package require ndv
package require Tclx

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argc argv} {
  global log
  set options {
      {di.arg "html" "Input directory with html files"}
      {do.arg "out" "Output directory with html files"}
      {nextword.arg "Volgende" "Link name for next chapter/file"}
      {loglevel.arg "" "Zet globaal log level"}
  }
  set usage ": [file tail [info script]] \[options] :"
  array set ar_argv [::cmdline::getoptions argv $options $usage]
 
  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel)  
  }

  set indir $ar_argv(di)
  set outdir $ar_argv(do)
  $log debug "indir: $ar_argv(di)"
  $log debug "outdir: $ar_argv(do)"
  file mkdir $outdir
  
  set prev_filename ""
  set i 0
  foreach filename [lsort [glob -directory $indir -tails *.htm*]] {
    if {$prev_filename != ""} {
      #set f [open [file join $indir $prev_filename] r]
      set text [read_file [file join $indir $prev_filename]]
      #close $f
      regsub {</body>} $text "<a href=\"$filename\">$ar_argv(nextword)</a></body>" text
      set f [open [file join $outdir $prev_filename] w]
      puts $f $text
      close $f      
    }
    set prev_filename $filename
    incr i
  }
  # laatste file gewoon kopieren
  file copy [file join $indir $prev_filename] $outdir
  $log debug "Handled $i files"
}

main $argc $argv
