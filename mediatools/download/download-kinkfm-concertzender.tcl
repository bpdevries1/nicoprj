#!/usr/bin/env tclsh86

proc main {argv} {
  set outdir_root "/media/nico/Iomega HDD/media/Music/XRated"
  set sec_date [clock scan "2012-05-13 12:00:00" -format "%Y-%m-%d %H:%M:%S"]
  set now [clock seconds]
  while {$sec_date < $now} {
    download_xrated $outdir_root $sec_date    
    set sec_date [expr $sec_date + 7 * 24 * 3600]
  }
}

# check if file to download already exists.
proc download_xrated {outdir_root sec_date} {
  set str_date [clock format $sec_date -format "%Y-%m-%d"]
  set str_date2 [clock format $sec_date -format "%Y%m%d"]
  file mkdir [file join $outdir_root $str_date]
  set to_path [file join $outdir_root $str_date "XRated-$str_date2-2100.mp3"]
  set to_download 0
  if {[file exists $to_path]} {
    if {[file size $to_path] > 10000} {
      puts "Already downloaded: $to_path" 
    } else {
      puts "Already downloaded, but too small: $to_path"
      set to_download 1
    }
  } else {
    set to_download 1
    # exec -ignorestderr curl -o $to_path "http://streams.greenhost.nl/cz/cz/rod/$str_date2-2100.mp3" 
  }
  if {$to_download} {
    exec -ignorestderr curl -o $to_path "http://streams.greenhost.nl/cz/cz/rod/$str_date2-2100.mp3"
  }
}

main $argv
