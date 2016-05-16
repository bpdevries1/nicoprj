# library functions, verplaatsen naar ndv-lib 

# subst uitvoeren zonder variabelen te vervangen, ofwel $ negeren
# subst met -novariables werkt niet (goed)
# vervang eerst $ door een \004
# 26-12-2011 put this proc in ~/nicoprj/lib/generallib.tcl
proc subst_no_variables {text} {
  # 4-11-2010 NdV: testje, lijkt wel goed te gaan. 
  return [subst -novariables $text]
  
  global log
  set special_char [det_special_char $text]
  regsub -all {\$} $text $special_char text2
  try_eval {
    set text3 [subst $text2]
  } {
    breakpoint 
  }
  regsub -all $special_char $text3 "\$" text4
  return $text4
}

proc det_special_char {text} {
  # eerst simpel, maar 2 niveaus
  if {![regexp "\004" $text]} {
    return "\004" 
  }
  if {![regexp "\005" $text]} {
    return "\005" 
  }
  puts "char(4) en char(5) komen al voor"
  breakpoint
}

# delete files in dir, but not dir itself.
# not recursive for now.
proc file_delete_dir_contents {gendir} {
  foreach filename [glob -nocomplain -directory $gendir -type f *] {
    file delete -force $filename 
  }
}

proc handle_action_dir {inputdir globpattern gendir file_procname} {
  global log
  $log info "handle_action_dir: $inputdir"
  file_delete_dir_contents $gendir
  file mkdir $gendir
  foreach request_c_file [glob -directory $inputdir $globpattern] {
    # handle_action_file $request_c_file $gendir
    $file_procname $request_c_file $gendir
  }
}


