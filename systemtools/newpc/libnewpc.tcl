# uses by both bootstrap.tcl and check-machine.tcl

# recursively follow symlinks, until file is not a link anymore.
proc file_link_final {filename} {
    set res [file_link $filename]
    if {$res == ""} {
	return $filename
    } else {
	return [file_link_final $res]
    }
}

# return file where link points to, or empty string iff linkname is not a link
proc file_link {linkname} {
  set res ""
  catch {
    set res [file link $linkname]
  }
    if {$res == ""} {
	return $res
    } else {
	# return $res
	return [file normalize [file join $linkname .. $res]]
    }
}

proc init_logger {argv} {
    if {[lsearch $argv "--recursive"] >= 0} {
	# don't delete log
    } else {
	file delete bootstrap.log
    }
}

proc logger {args} {
    set f [open bootstrap.log a]
    puts $f "\[[pid]\] [join $args " "]"
    puts "\[[pid]\] [join $args " "]"
    close $f
}

proc exec_sudo {args} {
  do_exec sudo {*}$args
}

proc do_exec {args} {
  log debug "executing: $args"
  set res -1
  catch {
    set res [exec {*}$args]
  } result options
  log debug "res: $res"
  log debug "result: $result"
  log debug "options: $options"
  set exitcode [det_exitcode $options]
  log debug "exitcode: $exitcode"
  return $exitcode
}

proc det_exitcode {options} {
  if {[dict exists $options -errorcode]} {
    set details [dict get $options -errorcode]
  } else {
    set details ""
  }
  if {[lindex $details 0] eq "CHILDSTATUS"} {
    set status [lindex $details 2]
    return $status
  } else {
    # No errorcode, return 0, as no error has been detected.
    return 0
  }
}

proc which {binary} {
  set res ""
  catch {
    set res [exec which $binary]
  }
  return $res
}

