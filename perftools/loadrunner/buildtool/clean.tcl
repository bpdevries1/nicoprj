
# TODO: options to clean several things: non-script files, only .idx files (and shunra), recorder file, replay files (subdirs), _orig dirs. And -all to do it all. If no options given, just show the help.
# 'clean' is for file(system) actions. Use remove for text within files.
task clean {Delete non script files
  THIS ACTION CANNOT BE UNDONE (with undo)
  Delete files base on option(s) given.
  Do buildtool clean to see options.
} {
  set dir [file normalize .]
  if {[is_script_dir $dir]} {
    clean_script $dir $args
  } else {
    puts "Not a vugen script."
  }
}

proc clean_script {dir argv} {
  # breakpoint
  set options {
    {idx "Delete .idx files"}
    {log "Delete output.* TransactionData.db, replay.har, shunra.shunra, mdrv.log"}
    {tmp "Delete .tmp files"}
    {bak "Delete .bak files"}
    {orig "Delete _orig directories"}
    {res "Delete result1/data directories"}
    {all "delete all of the above"}
  }
  set usage ": clean \[options]"
  if {$argv == ""} {
    set argv "-help"
  }
  set opt [getoptions argv $options $usage]
  # breakpoint
  
  # set glob_patterns {*.idx *.log git-add-commit.sh output.* *.tmp TransactionsData.db *.bak TransactionsData.db Iteration* result1 data}
  set patterns [det_glob_patterns $opt]
  puts "Cleaning script dir: [file normalize $dir]"
  foreach pattern $patterns {
    puts "Cleaning pattern: $pattern"
    foreach filename [glob -nocomplain -directory $dir $pattern] {
      delete_path $filename
    }
  }
}

proc det_glob_patterns {opt} {
  set res {}
  if {[:all $opt]} {
    set opt [dict create idx 1 log 1 tmp 1 bak 1 orig 1 res 1]
  }
  if {[:idx $opt]} {
    lappend res "*.idx"
  }
  if {[:log $opt]} {
    lappend res "output.*" TransactionsData.db replay.har shunra.shunra mdrv.log logs
  }
  if {[:tmp $opt]} {
    lappend res "*.tmp"
  }
  if {[:bak $opt]} {
    lappend res "*.bak"
  }
  if {[:orig $opt]} {
    # [2016-07-30 15:00] glob should work with subdirs like this.
    lappend res "[config_dir]/_orig*"
  }
  if {[:res $opt]} {
    lappend res result1 data
  }
  return $res
}

# TODO: deleting logs directoy does not work. Could do: if isdir and force fails, do per file in dir.
proc delete_path {pathname} {
  puts "Deleting: $pathname"
  # return ; # test
  if {[file isdirectory $pathname]} {
    # force nodig, dir is mogelijk niet leeg of heeft subdirs.
    catch {file delete -force $pathname}  
  } else {
    catch {file delete $pathname}  
  }
}

