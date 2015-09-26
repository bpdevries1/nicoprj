#!/usr/bin/env tclsh

# clean up VuGen directory (current dir)

# TODO: ook subdirs opschonen?
set glob_patterns {*.idx *.log git-add-commit.sh output.* *.tmp TransactionsData.db *.bak}

proc main {argv} {
  global glob_patterns
  foreach glob_pattern $glob_patterns {
    foreach filename [glob -nocomplain $glob_pattern] {
	  puts "Deleting: $filename"
	  file delete $filename
	}
  }
}

main $argv