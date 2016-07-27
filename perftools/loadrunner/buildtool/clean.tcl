
# TODO: options to clean several things: non-script files, only .idx files (and shunra), recorder file, replay files (subdirs), _orig dirs. And -all to do it all. If no options given, just show the help.
# 'clean' is for file(system) actions. Use remove for text within files.
task clean {Delete non script files
  Delete files: *.idx *.log git-add-commit.sh output.* *.tmp TransactionsData.db *.bak TransactionsData.db Iteration* result1 data.
} {
  set dir [file normalize .]
  if {[is_script_dir $dir]} {
    clean_script $dir
  } else {
    puts "Not a vugen script."
  }
}

proc clean_script {dir} {
  set glob_patterns {*.idx *.log git-add-commit.sh output.* *.tmp TransactionsData.db *.bak TransactionsData.db Iteration* result1 data}
  puts "Cleaning script dir: [file normalize $dir]"
  foreach glob_pattern $glob_patterns {
    foreach filename [glob -nocomplain -directory $dir $glob_pattern] {
      delete_path $filename
    }
  }
}

