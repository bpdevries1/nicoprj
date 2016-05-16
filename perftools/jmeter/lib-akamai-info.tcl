# lib-akamai-info.tcl - determine Akamai specific info from http result header.

proc det_cacheable {resulttext} {
  det_header_field $resulttext "X-Check-Cacheable"
}

proc det_expires {resulttext} {
  set res [det_header_field $resulttext "Expires"]
  if {$res == "<none>"} {
    return $res 
  } else {
    set sec -1
    catch {set sec [clock scan $res]}
    if {$sec == -1} {
      return "<unable to parse: $res>" 
    } else {
      return [clock format $sec -format "%Y-%m-%d %H:%M:%S" -gmt 1]
    }
  }
}

proc det_expiry {resulttext} {
  set exp [det_header_field $resulttext "Expires"]
  set now [det_header_field $resulttext "Date"]
  if {($exp == "<none>") || ($now == "<none>")} {
    return "<none>" 
  } else {
    set sec_exp -1
    set sec_now -1
    catch {set sec_exp [clock scan $exp]}
    catch {set sec_now [clock scan $now]}
    if {$sec_exp == -1} {
      return "<unable to parse Expires: $exp>" 
    } elseif {$sec_now == -1} {
      return "<unable to parse Date: $now>"
    } else {
      set sec_diff [expr $sec_exp - $sec_now]
      if {$sec_diff < 0} {
        return "past" 
      } elseif {$sec_diff <= 3600} {
        return "<1hr" 
      } else {
        return ">1hr" 
      }
    }
  }
}

# X-Cache: TCP_HIT from a195-10-36-81.deploy.akamaitechnologies.com (AkamaiGHost/6.11.2.2-10593690) (-)
proc det_cachetype {resulttext} {
  set res [det_header_field $resulttext "X-Cache"]
  if {$res == "<none>"} {
    return $res 
  } else {
    if {[regexp {^([^ ]+)} $res z tp]} {
      return $tp 
    } else {
      return $res 
    }
  }
}

# Cache-Control: max-age=86400
proc det_maxage {resulttext} {
  set res [det_header_field $resulttext "Cache-Control"]
  if {$res == "<none>"} {
    return $res 
  } else {
    if {[regexp {max-age=([^\n]+)} $res z age]} {
      return $age 
    } else {
      return "<none>" 
    }
  }
}

proc det_cachekey {resulttext} {
  if {[regexp {X-Cache-Key: ([^\n]+)} $resulttext z ck]} {
    set cachekey $ck 
  } else {
    set cachekey "<none>" 
  }
  return $cachekey  
}

proc det_akamaiserver {resulttext} {
  if {[regexp { from ([^ ]+)} $resulttext z aksrv]} {
    set akamaiserver $aksrv    
  } else {
    set akamaiserver "<none>" 
  }
  return $akamaiserver  
}

proc det_httpresultcode {resulttext} {
  if {[regexp {HTTP/[^ ]+ ([0-9]+)} $resulttext z httpresultcode]} {
    return $httpresultcode 
  } else {
    return "<none>" 
  }
}

proc det_header_field {resulttext fieldname} {
  set re "$fieldname: (\[^\\n\]+)"
  if {[regexp $re $resulttext z value]} {
    return $value 
  } else {
    return "<none>" 
  }
}


