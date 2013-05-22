#!/usr/bin/env tclsh86

package require ndv

proc main {argv} {
  # Idea is to use find (maybe) grep to search for some items in all project dirs, then sort/filter the results.
  set root_dirs [list "~/perftoolset" "~/nicoprj" "~/nicoprjbb"]
  set search_terms [list xls tsv csv db sql excel data graph]
  set outfile "~/aaa/find-prj.txt"
  file delete $outfile
  foreach dir $root_dirs {
    foreach term $search_terms {
      exec find [file normalize $dir] -name "*$term*" >>$outfile 
    }
  }
  # search term 'db' finds git objects, so filter them out.
  exec grep -v "\.git" <$outfile | grep -v "\.class" | sort -u  >$outfile.unique
}

main $argv
