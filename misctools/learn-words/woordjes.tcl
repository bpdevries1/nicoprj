#!/usr/bin/env wish861

# woordjes.tcl: simpel programma om woordjes te leren
# syntax: tclsh woordjes.tcl <woordenlijst.txt>

# Later: optie om aan te geven dat de woorden gewoon op volgorde moeten, is soms nodig...
# TODO: titlebar met filename, nu leeg.

# Notes
# 16-8-2015 reread -> gewoon door Again te klikekn, leest file dan ook opnieuw in.

set SHOWTEXT "Show (space)"
set CORRECTTEXT "Correct (J)"
set FALSETEXT "False (N)"

set SHOWKEY "<space>"
set CORRECTKEY "j"
set FALSEKEY "n"

## tclX nodig voor random functie
# package require Tclx
package require ndv

proc main {argc argv} {
  global filename direction
  
  set options {
    {dir.arg "~/projecten/talen/japans" "Directory with words.wrd files"}
    {file.arg "jap-eng.wrd" "File within dir with words"}
    {rev "Reverse words"}
  }

  set usage ": [file tail [info script]] \[options] \[file.wrd\]"
  set dargv [getoptions argv $options $usage]
  if {[:0 $argv] != ""} {
    dict set dargv file [:0 $argv]
  }

  srandom [clock seconds]

  cd [:dir $dargv]
  set filename [file normalize [file join [:dir $dargv] [:file $dargv]]]
  maakUI

  setTitle [file tail $filename]
  if {[:rev $dargv]} {
    set direction normal
    leesWoordenReverse $filename
  } else {
    set direction reverse
    leesWoorden $filename
  }
  startLeren  
}

proc maakUI {} {
  global SHOWTEXT CORRECTTEXT FALSETEXT SHOWKEY CORRECTKEY FALSEKEY

	frame .menuframe
	frame .wordsframe
	frame .commandframe
  frame .statusframe
	# menubutton .filemenu -text Open -command OpenFile
  button .openstdbutton -text Open -command OpenFile
  button .openrevbutton -text "Open reverse" -command OpenFileReverse
  button .editbutton -text "Edit" -command EditFile
  # 7-8-2015 again and reverse should be enabled always, if user wants to, (s)he should be able too!

  
  button .againbutton -text Again -command LearnAgain
  button .revbutton -text Reverse -command LearnReverse

	frame .wordframe
	frame .transframe
	label .wordlabel -text "Word        "
	label .translabel -text Translation
	label .word -textvariable word -fg blue -font [list "MS Sans Serif" 16] -anchor w
	label .trans -textvariable trans -fg blue -font [list "MS Sans Serif" 16] -anchor w
	button .showbutton -text $SHOWTEXT -command toonVertaling -state disabled
	button .correctbutton -text $CORRECTTEXT -command cmdCorrect -state disabled
	button .falsebutton -text $FALSETEXT -command cmdFalse -state disabled

  # status widgets
  label .rondelabel -text Ronde
  label .ronde -textvariable ronde
  label .totaallabel -text Totaal
  label .totaal -textvariable ntotaal
  label .goedlabel -text Goed
  label .goed -textvariable ngoed
  label .foutlabel -text Fout
  label .fout -textvariable nfout

	pack .showbutton .correctbutton .falsebutton -in .commandframe -side left -fill x -expand 1
	pack .wordlabel -in .wordframe -side left -fill none -expand 0
	pack .word -in .wordframe -side left -expand 1 -fill x -anchor w
	pack .translabel -in .transframe -side left -fill none -expand 0
	pack .trans -in .transframe -side left -expand 1 -fill x -anchor w
	pack .wordframe .transframe -in .wordsframe -side top -fill x -expand 1
	pack .openstdbutton .openrevbutton .editbutton .againbutton .revbutton -in .menuframe -side left

  pack .rondelabel .ronde .totaallabel .totaal .goedlabel .goed .foutlabel .fout -in .statusframe -side left -fill x -expand 1
	pack .menuframe .wordsframe .commandframe .statusframe -side top -fill x

  wm geometry . +600+300
}

proc OpenFile {} {
  global filename
  set fn [tk_getOpenFile]
  if {[file exists $fn]} {
    set filename [file normalize  $fn]
    setTitle [file tail $filename]
    leesWoorden $filename
    startLeren
  }
}

proc OpenFileReverse {} {
  set filenaam [tk_getOpenFile]
  setTitle [file tail $filenaam]
  leesWoordenReverse $filenaam
  startLeren
}

proc EditFile {} {
  global filename
  exec /usr/bin/gedit $filename &
}

proc setTitle filename {
  wm title . [file tail $filename]
}

proc LearnAgain {} {
  global filename direction
  if {$direction == "normal"} {
    leesWoorden $filename
  } else {
    leesWoordenReverse $filename
  }
  startLeren
}

proc LearnReverse {} {
  global direction
  reverseWLijstAlles
  if {$direction == "normal"} {
    set direction reverse
  } else {
    set direction normal
  }
  startLeren
}

proc reverseWLijstAlles {} {
  global wlijstalles

  set l {}
  foreach el $wlijstalles {
	   lappend l [list [lindex $el 1] [lindex $el 0]]
  }

  set wlijstalles $l
}

# lees woordenlijst in
# woordenlijst in een 2D array inlezen
proc leesWoorden {filenaam} {
  global wlijstalles

  set f [open $filenaam r]
  set wlijstalles {}
  while {![eof $f]} {
    gets $f line
    if {[regexp "^(.*)\t(.*)$" $line z van naar]} {
      lappend wlijstalles [list $van $naar]
    }
  }
  close $f
}

# lees woordenlijst in andersom
# woordenlijst in een 2D array inlezen
proc leesWoordenReverse {filenaam} {
  global wlijstalles

  set f [open $filenaam r]
  set wlijstalles {}
  while {![eof $f]} {
    gets $f line
    if {[regexp "^(.*)\t(.*)$" $line z van naar]} {
      lappend wlijstalles [list $naar $van]
    }
  }
  close $f  
}

proc startLeren {} {
  global wlijst wlijstalles ronde

  # 7-8-2015 NdV enable buttons always.
  # .againbutton configure -state disabled
  # .revbutton configure -state disabled

  set ronde 0
  set wlijst $wlijstalles

  startRonde
}

proc startRonde {} {
  global wlijst foutlijst ronde ntotaal ngoed nfout

  incr ronde
  set ntotaal [llength $wlijst]
  set nfout 0
  set ngoed 0
  set foutlijst {}
  toonWoord
}

proc toonWoord {} {
  global wlijst foutlijst ronde ntotaal ngoed nfout word trans huidigElement
  global SHOWKEY CORRECTKEY FALSEKEY

  if {[expr $ngoed + $nfout] < $ntotaal} {
    # nog in huidige ronde
    # set idx [random [llength $wlijst]]
    set idx [random_int [llength $wlijst]]
    set huidigElement [lindex $wlijst $idx]
    set wlijst [lreplace $wlijst $idx $idx]
    set word [lindex $huidigElement 0]
    set trans ""
    .showbutton configure -state active
    .correctbutton configure -state disabled
    .falsebutton configure -state disabled

	  bind all $SHOWKEY toonVertaling
  	bind all $CORRECTKEY ""
	  bind all $FALSEKEY ""
    
  } else {
    # start evt. volgende ronde.
    set wlijst $foutlijst
    if {[llength $wlijst] > 0} {
      startRonde
    } else {
      tk_dialog .dlgKlaar "Finished" "Finished learning the words." {} 0 Ok 
      set word ""
      set trans ""

      bind all $SHOWKEY ""
      bind all $CORRECTKEY ""
      bind all $FALSEKEY ""

     # 7-8-2015 NdV always active, so no need to set. 
     #.againbutton configure -state active
     #.revbutton configure -state active

    }
  }
}

proc toonVertaling {} {
  global huidigElement trans
  global SHOWKEY CORRECTKEY FALSEKEY

  set trans [lindex $huidigElement 1]
  .showbutton configure -state disabled
  .correctbutton configure -state normal
  .falsebutton configure -state normal

  bind all $SHOWKEY ""
  bind all $CORRECTKEY cmdCorrect
  bind all $FALSEKEY cmdFalse
 
}

proc cmdCorrect {} {
  global ngoed
  incr ngoed
  toonWoord
}

proc cmdFalse {} {
  global nfout foutlijst huidigElement
  incr nfout
	lappend foutlijst $huidigElement
  toonWoord
}

main $argc $argv

