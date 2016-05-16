proc get_root_dir {} {
  return {c:\pcc\nico\vugen}
}

proc get_dirs_to_check {} {
  # maybe add UC5/6 as well, but 3-7-2015 not in scope.
  list Transact_Valuta_UC1_FXSPOT Transact_Valuta_UC2_FXFORWARD Transact_Valuta_UC3_MMLOAN
}

proc get_filenames_to_check {} {
  # globals.h not sure yet if they need to be the same.
  # vuser_init is mainly the same, but not completely, ie the usecase needs to be set somewhere.
  
  # NOT:  UserCheck.c -> wil deze functionaliteit sowieso anders, dus geen effort steken in gelijk trekken.
  list vugen.h globals.h \
       Push.c Nexel.c CacheControl.c CRAS_certificate_login.c \
       selectuserid.c trimparam.c \
       configfile.c configlog.c dynatrace.c errorcheck.c functions.c \
       .gitignore
}

proc ignore_specific {filename} {
  set res {^timestamp$}
  foreach re $res {
    if {[regexp $re $filename]} {
      return 1
    }
  }
  return 0
}
