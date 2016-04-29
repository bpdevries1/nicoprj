#!/usr/bin/env tclsh

# clean up VuGen directory (current dir)

# TODO: ook subdirs opschonen?
# TODO: op c:\PCC\Nico\VuGen loslaten, dan meteen alle subdirs doen?
# dingen als data en result1 kunnen tijdens scripten/correleren wel handig zijn. Idee om dingen te verwijderen als je er klaar mee bent, 
# bv na 2 weken of een maand. Als het echt belangrijk is, elders veilig stellen.
# of dingen op C: gewoon laten staan, maar niet backuppen naar g: of h:
set glob_patterns {*.idx *.log git-add-commit.sh output.* *.tmp TransactionsData.db *.bak TransactionsData.db Iteration* result1 data}

set really 1

proc main {argv} {
  lassign $argv main_dir
  clean_dir $main_dir
}

proc clean_dir {dir} {
  puts "Handling: $dir"
  if {[is_project_dir $dir]} {
    clean_project $dir
  } else {
    # find subdirs and clean.
    foreach subdir [glob -nocomplain -directory $dir -type d *] {
      clean_dir $subdir
    }
  }
}

proc is_project_dir {dir} {
  if {[file exists [file join $dir vuser_init.c]]} {
    return 1
  }
  return 0
}

proc clean_project {dir} {
  puts "Cleaning project dir: $dir"
  global glob_patterns
  foreach glob_pattern $glob_patterns {
    foreach filename [glob -nocomplain -directory $dir $glob_pattern] {
      delete_path $filename
    }
  }
}

proc delete_path {pathname} {
  global really
  puts "Deleting: $pathname"
  if {[file isdirectory $pathname]} {
	  if {$really} {
      # force nodig, dir is mogelijk niet leeg of heeft subdirs.
      file delete -force $pathname  
	  } else {
      puts "Dry run: $pathname"
	  }
  } else {
	  if {$really} {
      file delete $pathname  
	  } else {
      puts "Dry run: $pathname"
	  }
  
  }
}

main $argv
