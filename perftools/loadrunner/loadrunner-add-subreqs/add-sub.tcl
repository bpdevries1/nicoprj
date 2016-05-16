package require ndv

::ndv::source_once lib_analysis.tcl

set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {} {
   # handle_file voorbeeld_script.c out
   handle_dir in out
   # handle_dir intest outtest
}

proc handle_dir {indir outdir} {
  foreach filename [glob -nocomplain -directory $indir -type f *.c] {
    handle_file $filename $outdir 
  }
  foreach subdir [glob -nocomplain -tails -directory $indir -type d *] {
    handle_dir [file join $indir $subdir] [file join $outdir $subdir] 
  }
  
}

proc handle_file {filename outdir} {
  global transname
  set transname "none"
  file mkdir $outdir
  set fo [open [file join $outdir [file tail $filename]] w]
  set fi [open $filename r]
  file_block_splitter $fi {^\t[A-Za-z].*((, )|;)$} handle_block $fo
  close $fi  
  close $fo
}

proc handle_block {text inblock fo} {
  global transname subtransnr log
  if {$inblock} {
    # puts $fo "// New block:"
    # puts $fo $text
    set methodname [det_methodname $text]
    $log debug "methodname: $methodname"
    # lr_start_transaction("01_A2C_FB01");
    if {$methodname == "lr_start_transaction"} {
      regexp {lr_start_transaction\(.(.+).\);} $text z transname
      set subtransnr 0
    }
    if {$methodname == "lr_end_transaction"} {
      set transname "none" 
    }
    if {[interesting $methodname $transname]} {
      incr subtransnr
      puts $fo 	"\tlr_start_sub_transaction(\"${transname}_[format %02d $subtransnr]\",\"${transname}\");\n"
      puts $fo $text
      puts $fo 	"\tlr_end_sub_transaction(\"${transname}_[format %02d $subtransnr]\", LR_AUTO);\n"
      puts $fo "\tlr_think_time(tt);\n"
    } else {
      puts $fo $text 
    }
  } else {
    # line outside of blocks: beginning or ending of the file. 
    puts $fo $text 
  }
}

proc det_methodname {text} {
  if {[regexp {\t([^\)\(]+)} $text z methodname]} {
    return $methodname 
  } else {
    error "unable to determnine methodname" 
  }  
}

proc interesting {methodname transname} {
  if {$transname == "none"} {
    return 0 
  }
  if {[lsearch -exact {sapgui_send_vkey sapgui_press_button sapgui_table_fill_data sapgui_select_tab} $methodname] > -1} {
    return 1 
  } else {
    return 0 
  }  
}

main