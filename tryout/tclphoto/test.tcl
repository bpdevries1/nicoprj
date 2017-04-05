#! /usr/bin/env wish
package require img::jpeg

# TODO:
# * mss bij elke 4 foto's alleen 4 cijfers in te typen, niet steeds tab tussendoor. Als je een fout maakt, dan net als met teletekst weer overnieuw beginnen.
# * 4 items in een lus maken, niet hardcoded.
# * tags veld erbij.
# * Cijfer als label, en met ctrl-cijfer.

# Overwegingen:
# * conflicterend: wil ook tags kunnen zien en editten, moet wel los veld zijn. Kan mss Ctrl-<cijfer> doen om labels te zetten, en met tabs dan gewoon de tags.
# * of je moet (net als vi) in modal of edit mode zitten. In modal geef je met cijfers alles weer, in edit kun je alles met tabs doen. Vraag dan wel hoe je wisselt. Je kunt bij volgende 4 foto's weer automatisch in modal-mode komen.

proc main {} {
  # global v1 v2 v3 v4 v
  global photo_value frame photo_tags photo_filename

  create_windows

  foreach i {1 2 3 4} {
    set photo_value($i) [expr $i + 6]
    set photo_tags($i) "tag[expr $i + 6]"
  }

  # [2017-03-27 21:49] update here is quite essential, otherwise no photo is shown.
  update;                       # to be able to ask height/width of frames

  set photo_filename(1) "~/foto2.jpg"
  set photo_filename(2) "~/foto.jpg"
  set photo_filename(3) "~/foto3.jpg"
  set photo_filename(4) "~/foto2.jpg"
  
  foreach i {1 2 3 4} {
    set_photo $frame($i) $photo_filename($i)
  }
  
  # focus $frame(1).edit
  focus $frame(1) ; # werkt wel, en is ook nodig om keypresses te zien.
}

# pas vullen na refactor: alles op frame
proc create_windows {} {
  global frame
  
  wm withdraw .
  toplevel .top
  set sw [winfo screenwidth .top]
  set menu_width 150
  set menu_height 30
  set ww [expr $sw - $menu_width]
  set sh [winfo screenheight .top]
  set wh [expr $sh - $menu_height]
  wm geometry .top "${ww}x${wh}-0+0"  

  frame .top.f1
  frame .top.f2

  pack .top.f1 .top.f2 -side top -expand 1 -fill both

  for {set i 1} {$i <= 4} {incr i} {
    set row [expr ($i + 1) / 2]
    set frame($i) [image_frame .top.f$row photo_value($i)]
    pack $frame($i) -side left -expand yes -fill both
  }
  
}

# get image for display on canvas, subsample calculated here.
proc get_image {filename canvas} {
  set img [image create photo -file $filename]
  set img2 [image create photo]

  set ch [winfo height $canvas]
  set cw [winfo width $canvas]
  set ih [image height $img]
  set iw [image width $img]

  #puts "Canvas: $cw x $ch"
  #puts "Image : $iw x $ih"
  #Canvas: 765 x 490
  #Image : 5312 x 2988

  # use ceil so scaling factor will not be too low, and therefore image not too big.
  set sswidth [expr 1.0 * $iw / $cw]
  set ssheight [expr 1.0 * $ih / $ch]

  if {$sswidth < $ssheight} {
    set ss $sswidth
  } else {
    set ss $ssheight
  }

  set ss [expr round(ceil($ss))]
  
  #puts "ss width: $sswidth, ss height: $ssheight => ss: $ss"
  
  $img2 copy $img -subsample $ss
  return $img2
}

# hier nog geen filename, komt later.
proc image_frame {parent var_name} {
  # global v1 v2 v3 v4 v
  # global photo_value
  
  # set img [get_image $filename 7]
  set f [frame [random_path $parent]]
  canvas $f.c
  # $f.c create image 0 0 -anchor nw -image $img
  entry $f.edit -textvariable $var_name
  #bind $f.edit <Key> {
  #  set keysym "Edit - You pressed %K"
  #  puts $keysym
  #}
  foreach w [list $f $f.edit] {
    bind $w <Key> [list entry_command "$w-%K"]
    # [2017-03-27 22:20] modifier key lezen is niet zo gemakkelijk, zo specifiek met Ctrl-q werkt ook.
    bind $w <Control-q> quit_command
  }
  
  pack $f.edit $f -side top -fill none -expand 0
  pack $f.c -side top -fill both -expand 1
  # pack $f.c -side top -expand 1

  #grid $f.c -column 0 -row 0 -fill both -expand 1
  #grid $f.edit -column 0 -row 1 -fill none -expand 0
  return $f
}

proc set_photo {frame filename} {
  # set img [get_image $filename 7]
  set img [get_image $filename $frame.c]
  $frame.c create image 0 0 -anchor nw -image $img
}

proc random_path {parent} {
  set r [expr rand ()]
  regsub -all {\.} $r "" r
  return "$parent.f$r"
}

proc entry_command {key} {
  global photo_value
  # puts "entry_command $args"
  puts "Key pressed: $key"
  if {[regexp Return  $key]} {
    puts "Return pressed, do action!"
    foreach i {1 2 3 4} {
      # puts "Value $i: [set v$i]"
      puts "Value v($i): $photo_value($i)"  
    }
    
  }
}

proc quit_command {} {
  puts "QUIT!"
  exit
}

main


