#!/usr/bin/env tclsh86

proc main {argv} {
  foreach filename [glob *.mp3] {
    if {[regexp {Pimsleur ([^ ]+) (\d) - (\d+).mp3} $filename z lang series track]} {
      puts "about to exec: mp3info -a Pimsleur -l \"$lang-$series\" -n $track -t \"Unit $track\" \"$filename\""
      # exec mp3info -a Pimsleur -l \"$lang-$series\" -n $track -t \"Unit $track\" \"$filename\""
      exec {*}[list mp3info -g 12 -a Pimsleur -l "$lang-$series" -n $track -t "Unit $track" $filename]
      exec {*}[list id3v2 -g 12 -a Pimsleur -A "$lang-$series" -T $track -t "Unit $track" $filename]
    } else {
      puts "Ignore: $filename" 
    }
  }
}

main $argv

