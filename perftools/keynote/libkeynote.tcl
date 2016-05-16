# libkeynote.tcl - generic functions for importing and handling Keynote data.

# @note also used in migrations and scatter2db.
proc det_topdomain {domain} {
  # return $domain 
  # if it's something like www.xxx.co(m).yy, then return xxx.co(m).yy
  # otherwise if it's like www.xxx.yy, then return xxx.yy
  # maybe regexp isn't the quickest, try split/join first.
  set l [split $domain "."]
  set p [lindex $l end-1]
  if {($p == "com") || ($p == "co")} {
    join [lrange $l end-2 end] "." 
  } else {
    if {$domain == "images.philips.com"} {
      return "scene7" 
    } else {
      join [lrange $l end-1 end] "."
    }
  }  
}

# update checkfile wrt nanny process.
proc update_checkfile {checkfile} {
  if {$checkfile != ""} {
    set f [open $checkfile w]
    puts $f "[file tail [info script]] still alive at [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]"
    close $f
  }
}

proc format_dt {sec} {
  clock format $sec -format "%Y-%m-%d %H:%M:%S"
}

proc format_now {} {
  format_dt [clock seconds]
}

proc format_now_filename {} {
  clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"
}

# determine curl path based on platform.
proc curl_path {} {
  global tcl_platform
  if {$tcl_platform(platform) == "windows"} {
    return "c:/util/curl/curl.exe"
  } else {
    return "curl"
  }
}
