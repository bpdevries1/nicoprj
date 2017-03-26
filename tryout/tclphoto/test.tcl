#! /usr/bin/env wish
package require img::jpeg

proc main_old1 {} {
  #set img [image create photo -file /home/nico/foto2.jpg]
#  set img [image create photo -file /home/nico/foto2.jpg -width 1300 -height 1000]

  # deze doet een crop, gen resize:
  # set img [image create photo -file /home/nico/foto2.jpg -width 130 -height 100]
  #set img2 [image create photo]
  # deze subsample 7 lijkt vrij goed om 4 foto's te tonen.
  #$img2 copy $img -subsample 7
  wm withdraw .

  set img [get_image ~/foto2.jpg 7]
  # -title oid kent 'ie niet.
  toplevel .top -width 1000 -height 800
  canvas .top.c
  pack .top.c -expand yes -fill both
  .top.c create image 0 0 -anchor nw -image $img
  set sw [winfo screenwidth .top]
  set menu_width 150
  set ww [expr $sw - $menu_width]
  set sh [winfo screenheight .top]
  set wh $sh
  wm geometry .top "${ww}x${wh}-0+0"  
  # maximise window
  #wm attributes .top -zoomed
}

# TODO:
# de windows/frames maken, en pas hierna de foto's erin. Dit moeten namelijk ook later weer anderen kunnen worden.
# dan wel vraag of de size al bekend is, zodat de scaling van de image goed is.
# evt create rectangle om eerst het frame weer leeg te maken. Gaat meestal wel goed, maar mss niet bij portrait foto.
# bij portrait moet je nog meer verkleinen. Maar je kunt zowel orig image size als de window size opvragen. Dan verhouding bepalen, afronden, en dit wordt dan de scaling factor.
# mss bij elke 4 foto's allen 4 cijfers in te typen, niet steeds tab tussendoor. Als je een fout maakt, dan net als met teletekst weer overnieuw beginnen.

proc main {} {
  global v1 v2 v3 v4
  
  wm withdraw .
  # maximise window
  # maximise window
  toplevel .top -width 1000 -height 800
  #canvas .top.c
  #pack .top.c -expand yes -fill both
  # .top.c create image 0 0 -anchor nw -image $img
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
  
  # set f1 [image_frame .top.f1 "~/foto2.jpg" v1]
  set f1 [image_frame2 .top.f1 v1]
  # pack $f1 -in .top -expand yes -fill both
  pack $f1 -side left -expand yes -fill both
  #pack $f1 -anchor nw -expand yes -fill both
  # pack $f1 -in . -expand yes -fill both

  set f2 [image_frame .top.f1 "~/foto.jpg" v2]
  # pack $f1 -in .top -expand yes -fill both
  pack $f2 -side left -expand yes -fill both

  set f3 [image_frame .top.f2 "~/foto2.jpg" v3]
  # pack $f1 -in .top -expand yes -fill both
  pack $f3 -side left -expand yes -fill both

  # set f4 [image_frame .top.f2 "~/foto3.jpg" v4]
  set f4 [image_frame2 .top.f2 v4]
  # pack $f1 -in .top -expand yes -fill both
  pack $f4 -side left -expand yes -fill both

  #grid $f1 -column 0 -row 0
  #grid $f2 -column 1 -row 0
  #grid $f3 -column 0 -row 1

  set v1 8
  set v2 9
  set v3 1
  set v4 6

  bind . <Key> {
    set keysym "You pressed %K"
    puts $keysym
  }

  update;                       # to be able to ask height/width of frames
  puts "f1.c.height: [winfo height $f1.c]"
  puts "f1.c.width: [winfo width $f1.c]"

  set_photo $f1 "~/foto2.jpg"
  set_photo $f4 "~/foto3.jpg"

  focus $f1.edit
}

proc get_image {filename subsample} {
  set img [image create photo -file $filename]
  set img2 [image create photo]
  # deze subsample 7 lijkt vrij goed om 4 foto's te tonen.
  $img2 copy $img -subsample $subsample
  return $img2
}

# get image for display on canvas, subsample calculated here.
proc get_image2 {filename canvas} {
  set img [image create photo -file $filename]
  set img2 [image create photo]
  # deze subsample 7 lijkt vrij goed om 4 foto's te tonen.

  set ch [winfo height $canvas]
  set cw [winfo width $canvas]
  set ih [image height $img]
  set iw [image width $img]

  puts "Canvas: $cw x $ch"
  puts "Image : $iw x $ih"
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
  
  puts "ss width: $sswidth, ss height: $ssheight => ss: $ss"
  
  set subsample 10;             # om verschil te zien.
  $img2 copy $img -subsample $ss
  return $img2
}


proc image_frame {parent filename var_name} {
  global v1 v2 v3 v4
  
  set img [get_image $filename 7]
  set f [frame [random_path $parent]]
  canvas $f.c
  $f.c create image 0 0 -anchor nw -image $img
  entry $f.edit -textvariable $var_name
  #bind $f.edit <Key> {
  #  set keysym "Edit - You pressed %K"
  #  puts $keysym
  #}
  bind $f.edit <Key> [list entry_command "%K"]
    
  pack $f.edit $f -side top -fill none -expand 0
  pack $f.c -side top -fill both -expand 1
  # pack $f.c -side top -expand 1

  #grid $f.c -column 0 -row 0 -fill both -expand 1
  #grid $f.edit -column 0 -row 1 -fill none -expand 0
  return $f
}

# hier nog geen filename, komt later.
proc image_frame2 {parent var_name} {
  global v1 v2 v3 v4
  
  # set img [get_image $filename 7]
  set f [frame [random_path $parent]]
  canvas $f.c
  # $f.c create image 0 0 -anchor nw -image $img
  entry $f.edit -textvariable $var_name
  #bind $f.edit <Key> {
  #  set keysym "Edit - You pressed %K"
  #  puts $keysym
  #}
  bind $f.edit <Key> [list entry_command "%K"]
  
  pack $f.edit $f -side top -fill none -expand 0
  pack $f.c -side top -fill both -expand 1
  # pack $f.c -side top -expand 1

  #grid $f.c -column 0 -row 0 -fill both -expand 1
  #grid $f.edit -column 0 -row 1 -fill none -expand 0
  return $f
}

proc set_photo {frame filename} {
  # set img [get_image $filename 7]
  set img [get_image2 $filename $frame.c]
  $frame.c create image 0 0 -anchor nw -image $img
}

proc random_path {parent} {
  set r [expr rand ()]
  regsub -all {\.} $r "" r
  return "$parent.f$r"
}

proc entry_command {key} {
  global v1 v2 v3 v4
  # puts "entry_command $args"
  puts "Key pressed: $key"
  if {$key ==  "Return"} {
    puts "Return pressed, do action!"
    foreach v {1 2 3 4} {
      puts "Value $v: [set v$v]"
    }
  }
}

main


