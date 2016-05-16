proc get_root_dir {} {
  return {c:\pcc\nico\vugen}
}

proc get_dirs_to_check {} {
  # maybe add UC5/6 as well, but 3-7-2015 not in scope.
  list RCC_LoansWidget RCC_CashBalancingWidget
}

proc get_filenames_to_check {} {
  # vuser_init is mainly the same, but not completely, ie the usecase needs to be set somewhere.
  # 28-7-2015 NdV just one dir here now, so not relevant.
  
  # NOT:  UserCheck.c -> wil deze functionaliteit sowieso anders, dus geen effort steken in gelijk trekken.
  # globals.h nu niet, hier ook specifieke dingen in. Mss later wel.
  list vugen.h \
       CacheControl.c CRAS_certificate_login.c \
       selectuserid.c trimparam.c \
       configfile.c configlog.c dynatrace.c errorcheck.c functions.c \
       .gitignore
}

proc ignore_specific {filename} {
  return 0
}
