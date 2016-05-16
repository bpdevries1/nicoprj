proc get_root_dir {} {
  return {c:\pcc\nico\vugen}
}

proc get_dirs_to_check {} {
  list ClientReporting RCC_LoansWidget
}

proc get_filenames_to_check {} {
  # vuser_init is mainly the same, but not completely, i.e. the usecase needs to be set somewhere.
  
  # NOT:  UserCheck.c -> wil deze functionaliteit sowieso anders, dus geen effort steken in gelijk trekken.
  # 26-8-2015 NdV globals.h nu niet, hier ook specifieke dingen in. Mss later wel.
  list vugen.h \
       CacheControl.c CRAS_certificate_login.c \
       selectuserid.c trimparam.c \
       configfile.c configlog.c dynatrace.c errorcheck.c functions.c \
       .gitignore
}

proc ignore_specific {filename} {
  return 0
}
