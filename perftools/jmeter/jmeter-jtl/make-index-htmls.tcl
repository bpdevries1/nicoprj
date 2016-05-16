# convert an access log file to sqlite db.

package require Tclx

# own package
package require ndv

# lines
# <httpSample t="2430" lt="2426" ts="1350721801764" s="true" lb="Behandelaar ophalen" rc="200" rm="OK" tn="Thread Group 1-2" 
# dt="text" de="utf-8" by="555" ng="2" na="2" hn="P3738"/>
set log [::ndv::CLogger::new_logger [file tail [info script]] debug]

proc main {argv} {
  puts "argv: $argv"
  lassign $argv rootdir
  puts "rootdir: $rootdir"
  handle_root $rootdir  
}

proc handle_root {rootdir} {
  set froot [open [file join $rootdir index.html] w]
  puts $froot "<html><body>"
  # set dirs_todo [lsort [glob -nocomplain -type d -directory $rootdir *]]
  set dirs_todo [list $rootdir]
  while {[llength $dirs_todo] > 0} {
    set dir [lindex $dirs_todo 0]
    puts "Handling dir: $dir"
    set dirs_todo [lrange $dirs_todo 1 end]
    foreach subdir [lsort [glob -nocomplain -type d -directory $dir *]] {
      lappend dirs_todo $subdir 
    }
    set files [det_graph_files $dir]
    if {[llength $files] > 0} {
      puts $froot "<a href=\"[make_href $rootdir $dir]\">$dir</a><br/>"
      make_index_html $dir $files
    }
  } 
  puts $froot "</body></html>"
  close $froot
}

proc det_graph_files {dir} {
  set res {}
  foreach file [glob -tails -nocomplain -directory $dir -type f *.png] {
    lappend res $file 
  }
  foreach file [glob -tails -nocomplain -directory $dir -type f *.gif] {
    lappend res $file 
  }
  puts "found files: $res"
  lsort $res  
}

# make index.html ref.
proc make_href {rootdir dir} {
  # remove rootdir from dir, so we keep relative path
  # set path [string range $dir [string length $rootdir]+1 end]
  return "[rel_path $rootdir $dir]/index.html"
}

proc make_index_html {dir files} {
  set f [open [file join $dir index.html] w]
  puts $f "<html><body>"
  foreach file $files {
    puts $f "<h3>$file</h3><img src=\"$file\"/>"
  }
  puts $f "</body></html>"
  close $f
}

proc rel_path {rootdir path} {
  string range $path [string length $rootdir]+1 end
}

proc log {args} {
  # global log
  variable log
  $log {*}$args
}

main $argv
