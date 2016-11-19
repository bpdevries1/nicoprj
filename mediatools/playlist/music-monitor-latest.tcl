#!/home/nico/bin/tclsh

# [2016-11-11 22:50] tclsh861 not yet in env when @reboot in crontab.
#!/usr/bin/env tclsh861

# #!/home/nico/bin/tclsh

package require ndv
package require Tclx
package require struct::list

# ::ndv::source_once ../db/MusicSchemaDef.tcl
::ndv::source_once [file join [file dirname [info script]] .. db MusicSchemaDef.tcl]
::ndv::source_once [file join [file dirname [info script]] .. lib libmusic.tcl]

# [2016-11-17 21:25] wil bij deze geen subdir logs: dus ofwel expliciet aangeven, ofwel geen log.
set_log_global warn {filename /home/nico/log/music-monitor-tcl.log append 1}

proc main {argv} {
  # 14-1-2012 keep db and conn as global, their values can changes with a reconnect.
  global db conn stderr argv0 SINGLES_ON_SD

  set options {
    {debug "Show debug output"}
    {loglevel.arg "info" "Set loglevel for all (debug, info, ...)"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set opt [getoptions argv $options $usage]
  array set ar_argv $opt 

  if {$ar_argv(loglevel) != ""} {
    ::ndv::CLogger::set_log_level_all $ar_argv(loglevel) 
  }
  
  db_connect
  
  show_latest $opt
}

# show everything from today.
proc show_latest {opt} {
  global conn
  set today [clock format [clock seconds] -format "%Y-%m-%d"]
  set query "select kind, datetime, path
from played p
join album a on a.generic = p.generic
where datetime >= '$today'
union
select kind, datetime, path
from played p
join musicfile m on m.generic = p.generic
where datetime >= '$today'
order by datetime"
  set res [pg_query_dicts $conn $query]
  puts "Played today: $today"
  foreach row $res {
    puts "[:kind $row]: [:datetime $row]: [:path $row]"
  }
}

proc db_connect {} {
  global db conn log
  set db [get_db_from_schemadef]
  log debug "before get_connection"
  set conn [$db get_connection]
  log debug "finished"
}

main $argv

