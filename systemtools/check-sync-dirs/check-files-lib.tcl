package require struct::list
package require fileutil

# ar_dir_svn:key = filename
# ar_dir_svn:value = list of directories
proc read_dir_repo {filename_repo_dir} {
  global ar_dir_svn
  set f [open $filename_repo_dir r]
  while {![eof $f]} {
    gets $f line
    if {$line != ""} {
       set filename [file tail $line]
       # puts "repo filename: $filename"
       set dirname [file dirname $line]
       if {[array get ar_dir_svn $filename] != {}} {
          set lst $ar_dir_svn($filename)
          lappend lst $dirname
          set ar_dir_svn($filename) $lst
       } else {
         set ar_dir_svn($filename) [list $dirname]
       }
    }
  }
  close $f
  # puts "repo: [lsort [array names ar_dir_svn]]"
}

proc same_file_char {same_file} {
  if {$same_file} {
    return "==" 
  } else {
    return "!=" 
  }
}

proc format_time {filename} {
  clock format [file mtime $filename] -format "%Y-%m-%d %H:%M:%S"
}

proc det_lst_same_name {filename} {
  global ar_dir_svn
  set filetail [file tail $filename]
  # puts "filetail: $filetail"
  # 28-5-2010 NdV gebruik array names ipv array get om met exact te kunnen zoeken, en geen last van [] te hebben.
  if {[array names ar_dir_svn -exact $filetail] != {}} {
    return [::struct::list mapfor el $ar_dir_svn($filetail) {
      list $el [file size [file join $el $filetail]] [file mtime [file join $el $filetail]]
    }]
  } else {
    return {} 
  }
}

proc det_same_file_lst {filename lst_fileinfo} {
  expr [llength [::struct::list filterfor el $lst_fileinfo {
    [det_same_file $filename [lindex $el 0]]
  }]] > 0
}

# return 1 if sizes are the same
proc det_same_file {filename dirname} {
  if {[file size $filename] == [file size [file join $dirname [file tail $filename]]]} {
    # also check contents
    expr [string compare [::fileutil::cat $filename] [::fileutil::cat [file join $dirname [file tail $filename]]]] == 0
  } else {
    return 0 
  }
}

proc dirinfo_to_str {di filename} {
  lassign $di dirname size mtime
  return "[file nativename [file join $dirname $filename]] $size [format_time [file join $dirname $filename]]"
}

