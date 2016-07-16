# args can only be -do, to really perform the replacements. Should be at the end, could be that regexps have/are -do.
# if not really, create a file.__TEMP__ with the new version. Then perform a diff on both.
# TODO: als -do is meegegeven, dan actie opslaan (in repo, want ook voor andere scripts). dan optie om deze te tonen en te kiezen.
# en mss ook een naam te geven.
# TODO: optie om replace wel/niet in libs uit te voeren, of alleen in actions. Default mss ook alleen in actions.
task regsub {Regular epression replace
  Syntax: regsub <from> <to> [-do]
  Without -do, perform a dry run.
} {
  # TODO: use cmdline parsing, put options in front.
  lassign $args from to
  set args [lrange $args 2 end]
  set really 0
  puts "from: $from, to: $to, args: $args"
  if {[lindex $args 0] == "-do"} {
    set really 1
    puts "Really perform replacements!"
  }
  # vervang meegegeven \n op cmdline in echte newline voor regsub:
  regsub -all {\\n} $to "\n" to2
  set origdir "_orig.[clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"]"
  foreach srcfile [filter_ignore_files [get_source_files]]	{
    regsub_file $srcfile $from $to2 $origdir $really
  }
}

proc regsub_file {srcfile from to origdir really} {
  set text [read_file $srcfile]
  set nreplaced [regsub -all $from $text $to text2]
  if {$nreplaced == 0} {
    # nothing, no replacements done.
  } else {
    puts "$srcfile - $nreplaced change(s):"
    set tempfile "$srcfile.__TEMP__"
    set f [open $tempfile w]
    puts $f $text2
    close $f
    set temporig "$srcfile.__ORIG__"
    set f [open $temporig w]
    puts $f $text
    close $f
    diff_files $temporig $tempfile
    if {$really} {
      puts "really perform replacement, orig files in _orig dir"
      file delete $temporig
      file mkdir $origdir
      # file rename $srcfile [file join _orig $srcfile]
      file rename $srcfile [file join $origdir $srcfile]
      file rename $tempfile $srcfile
    } else {
      file delete $temporig
      file delete $tempfile
    }
  }
}

