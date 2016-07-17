# //Filter out some production URLs
# add filter lines just after the comment (// Filter out), or just before return 0;
# replace all settings with info in domains.ini
# this proc also belongs to domains.tcl
proc vuser_init_update_domains {domains_ini} {
  # alle huidige ignore lines helemaal weg en vervangen door domains_ini, op alfabet.
  set replaced 0
  set fi [open vuser_init.c r]
  set fo [open [tempname vuser_init.c] w]
  fconfigure $fo -translation crlf
  while {[gets $fi line] >= 0} {
    if {[regexp {Filter out some production URLs} $line]} {
      puts $fo $line
      puts_ignore_domain_lines $fo $domains_ini
      set replaced 1
    } elseif {[regexp {return 0;} $line]} {
      if {!$replaced} {
        puts_ignore_domain_lines $fo $domains_ini
        set replaced 1
      }
      puts $fo $line
    } elseif {[regexp {web_add_auto_filter} $line]} {
      # ignore line
    } else {
      puts $fo $line
    }
  }
  close $fi
  close $fo
  commit_file vuser_init.c
}

# this proc also belongs to domains.tcl
proc puts_ignore_domain_lines {fo ini} {
  foreach line [lsort [ini_lines $ini ignore]] {
    if {$line != ""} {
      puts $fo "\tweb_add_auto_filter\(\"Action=Exclude\", \"HOSTSUFFIX=${line}\", LAST);"      
    }
  }
}
