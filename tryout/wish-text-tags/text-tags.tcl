# deze uit config lezen of dynamisch opbouwen?
proc main {argv} {
  global filename
  lassign $argv lists_tcl filename
  # set filename [lindex $argv 0]
  source $lists_tcl
  wm geometry . +300+300
  frame .fbuttons
  entry .entry -textvariable entry_text
  bind .entry <Key> {entry_entered %K}
  text .text 
  pack .fbuttons .entry -side top -anchor w -fill both -expand 0
  pack .text -side top -anchor w -fill both -expand 1
  
  set lists [get_lists]
  set cbs [make_cbs $lists] ; # return list of containers/frames
  pack {*}$cbs -in .fbuttons -side left -anchor n
}  

proc make_cbs {lists} {
  global siblings lst_cb_all lb_all
  set res {}
  set i 0
  foreach lst $lists {
    incr i
    set f .[string tolower [lindex $lst 0]]
    frame $f
    lappend res $f
    label $f.lb -text [lindex $lst 0]
    pack $f.lb -in $f -side top -anchor w
    # checkbutton $f.all -text "All"
    # puts "Creating cb-all: $f.all"
    #checkbutton $f.all$i -text "[lindex $lst 0]-All" -command "select_all $f.all$i"
    #pack $f.all$i -in $f -side top -anchor w
    # checkbutton $f.all -text "[lindex $lst 0]-All" -command "select_all $f.all" -variable cbvar($f.all)
    checkbutton $f.all -text "All" -command "select_all $f.all" -variable cbvar($f.all)
    lappend lst_cb_all $f.all
    set lb_all($f.all) $f.lb
    pack $f.all -in $f -side top -anchor w
    foreach el [lrange $lst 1 end] {
      set cb "$f.[string tolower $el]"
      lappend siblings($f.all) $cb
      checkbutton $cb -text $el -variable cbvar($cb)
      pack $cb -in $f -side top -anchor w
    }
  }
  return $res
}

proc select_all {btn} {
  global cbvar siblings 
  # puts "select_all called for: $btn, current value=$cbvar($btn)"
  foreach sib $siblings($btn) {
    set cbvar($sib) $cbvar($btn) 
  }
  # haal alle siblings van deze button en zet ze op dezelfde waarde.
  # set val 
  # 
}

proc entry_entered {key} {
  global cbvar siblings entry_text lst_cb_all lb_all
  if {$key == "Return"} {
    # puts "return entered: $key"
    # puts "entry_text: $entry_text"
    # set text "\[<timestamp>\]"
    set text "\[[clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]]"
    foreach cb_all $lst_cb_all {
      set res {}
      foreach sib $siblings($cb_all) {
        if {$cbvar($sib)} {
          lappend res [$sib cget -text] ; # waarsch stuk na laatste . 
        }
      }
      set lb [$lb_all($cb_all) cget -text]
      append text " \[$lb:[join $res ","]\]"
    }
    append text " $entry_text"
    # puts "text to put: $text" 
    .text insert end "$text\n"
    add_text_to_file $text
    set entry_text ""
  }
}

proc add_text_to_file {text} {
  global filename
  set f [open $filename a]
  puts $f $text  
  close $f
}

main $argv

