#!/usr/bin/env tclsh86

proc main {argv} {
  set outdir_root "/media/nico/Iomega HDD/media/Music/XRated"
  # use 12 noon so dlst does not skip a day too many.
  set sec_date [clock scan "2012-05-13 12:00:00" -format "%Y-%m-%d %H:%M:%S"]
  set now [clock seconds]
  while {$sec_date < $now} {
    download_x Rated $outdir_root $sec_date
    download_x Ray $outdir_root $sec_date
    set sec_date [expr $sec_date + 7 * 24 * 3600]
  }
}  
 
# 10-6-2014 deze gedaan, maar nu niet meer, alles is binnen.
proc download_old {argv} {
  # test: nog iets verder terugkijken.
  set sec_date [clock scan "2012-05-13 12:00:00" -format "%Y-%m-%d %H:%M:%S"]
  set beginning [clock scan "2012-01-01 12:00:00" -format "%Y-%m-%d %H:%M:%S"]
  while {$sec_date > $beginning} {
    download_x Rated $outdir_root $sec_date
    # 10-6-2014 X-Ray already have every old music file, first one at 2012-06-10.
    # download_x Ray $outdir_root $sec_date
    set sec_date [expr $sec_date - 7 * 24 * 3600]
  }
  
  download_extra Rated $outdir_root {
    "02/02/2012 22:00"
    "19/01/2012 22:00"
    "05/01/2012 22:00"
    "22/12/2011 22:00"
    "08/12/2011 19:00"
    "08/12/2011 22:00"
    "08/12/2011 21:00"
    "08/12/2011 20:00"
    "01/12/2011 22:00"
    "17/11/2011 22:00"
    "06/10/2011 22:00"
  }
}

proc download_extra {sub outdir_root lst_dates} {
  foreach date $lst_dates {
    set sec_date [clock scan $date -format "%d/%m/%Y %H:%M"]
    set hour [clock format $sec_date -format "%H"]
    puts "Download extra: $date $sub $outdir_root $sec_date $hour"
    download_x $sub $outdir_root $sec_date $hour
  }
}

# check if file to download already exists.
proc download_x {sub outdir_root sec_date {hour none}} {
  set str_date [clock format $sec_date -format "%Y-%m-%d"]
  set str_date2 [clock format $sec_date -format "%Y%m%d"]
  file mkdir [file join $outdir_root $str_date]
  if {$hour == "none"} {
    if {$sub == "Rated"} {
      set hour 21 
    } else {
      set hour 23 
    }
  }
  set to_path [file join $outdir_root $str_date "X${sub}-$str_date2-${hour}00.mp3"]
  set to_download 0
  if {[file exists $to_path]} {
    if {[file size $to_path] > 10000} {
      puts "Already downloaded: $to_path" 
    } else {
      if {[file size $to_path] == 64} {
        puts "Already downloaded, but not Xrated/ray: ignore: $to_path"
        set to_download 0
      } else {
        puts "Already downloaded, but too small: $to_path"
        set to_download 1
      }
    }
  } else {
    set to_download 1
    # exec -ignorestderr curl -o $to_path "http://streams.greenhost.nl/cz/cz/rod/$str_date2-2100.mp3" 
  }
  if {$to_download} {
    puts "Download: $to_path"
    exec -ignorestderr curl -o $to_path "http://streams.greenhost.nl/cz/cz/rod/$str_date2-${hour}00.mp3"
  }
}

# even X-ray oude files leegmaken, is geen XRay
# main_empty_xray
proc main_empty_xray {argv} {
  set outdir_root "/media/nico/Iomega HDD/media/Music/XRated"
  set sec_date [clock scan "2012-06-03 12:00:00" -format "%Y-%m-%d %H:%M:%S"]
  set beginning [clock scan "2012-01-01 12:00:00" -format "%Y-%m-%d %H:%M:%S"]
  while {$sec_date > $beginning} {
    #download_xrated $outdir_root $sec_date
    #download_xray $outdir_root $sec_date  
    # download_x Rated $outdir_root $sec_date
    # download_x Ray $outdir_root $sec_date
    set str_date [clock format $sec_date -format "%Y-%m-%d"]
    set str_date2 [clock format $sec_date -format "%Y%m%d"]
    set to_path [file join $outdir_root $str_date "XRay-$str_date2-2300.mp3"]
    if {[file exists $to_path]} {
      puts "Empty X-ray file: $to_path"
      set f [open $to_path w]
      puts $f "Emptied file, not XRay. Keep here to prevent downloading again."
      close $f
    }
    set sec_date [expr $sec_date - 7 * 24 * 3600]
  }
}

main $argv
