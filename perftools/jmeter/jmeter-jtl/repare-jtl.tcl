proc main {argv} {
  # out_filename is relative on dir_name
  lassign $argv dir_name filter out_filename
  set fo [open [file join $dir_name $out_filename] w]
  puts_header $fo
  foreach filename [glob -directory $dir_name -type f $filter] {
    handle_input $filename $fo 
  }
  
  puts_footer $fo
  
  close $fo
}

proc puts_header {fo} {
  puts $fo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<testResults version=\"1.2\">"
}

proc puts_footer {fo} {
  puts $fo "</testResults>"
}

proc handle_input {filename fo} {
  set f [open $filename r]
  while {![eof $f]} {
    gets $f line
    # <httpSample t="2430" lt="2426" ts="1350721801764" s="true" lb="Behandelaar ophalen" rc="200" rm="OK" tn="Thread Group 1-2" dt="text" de="utf-8" by="555" ng="2" na="2" hn="P3738"/>

# DB: <sample t="23" it="59977" lt="0" ts="1355757120587" s="true" lb="01_Ploeglijst" tn="DC1VCWSQL105 1-1" dt="" by="654814" sc="1" ec="0">
    if {[regexp {(<httpSample.+?)/?>$} $line z text]} {
      puts $fo "[replace_label_line $text]/>"
      # puts $fo $line 
    } elseif {[regexp {(<sample.+?)/?>} $line z text]} {
      puts $fo "[replace_label_line $text]/>"
    }
  }
  close $f
}

# @param text: <httpSample t="2430" lt="2426" ts="1350721801764" s="true" lb="Behandelaar ophalen" rc="200" rm="OK" tn="Thread Group 1-2" dt="text" de="utf-8" by="555" ng="2" na="2" hn="P3738"
# @result: <httpSample t="2430" lt="2426" ts="1350721801764" s="true" lb="Behandelaar ophalen" rc="200" rm="OK" tn="Thread Group 1-2" dt="text" de="utf-8" by="555" ng="2" na="2" hn="P3738"
# @note replace label so ID's will be removed.
proc replace_label_line {text} {
  if {[regexp {^(.*lb=\x22)([^\x22]+)(\x22.*)$} $text z pre label post]} {
    return "$pre[replace_label $label]$post"
  } else {
    # no label
    return $text
  }
}

proc replace_label {label} {
  # return "replace: $label" 
  if {[regexp {^(.*?)\d+ *$} $label z label2]} {
    return "${label2}id" 
  } else {
    return $label
  }
}

proc handle_input_old {filename fo} {
  set f [open $filename r]
  while {![eof $f]} {
    gets $f line
    if {[regexp {<httpSample.+/>} $line]} {
      puts $fo $line 
    } elseif {[regexp {(<httpSample.+)>} $line z text]} {
      puts $fo "$text/>"
    }
  }
  close $f
}


main $argv
