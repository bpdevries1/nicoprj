#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

set script_dir [file dirname [info script]]
ndv::source_once [file join $script_dir R-wrapper.tcl]

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {dir.arg "c:/projecten/Philips/KNDL/Mobile-landing-US" "Directory to make graphs for/in (in daily/graphs)"}
    {dbname.arg "keynotelogs.db" "DB name within dir to use"}
    {outformat.arg "png" "Output format (all, png or svg)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {keepcmd "Keep R command file with timestamp"}
    {incr "Incremental: only create graphs if they do not exist yet"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  set r [Rwrapper new $dargv]
  $r main {
    graph_mobile_us $r $dargv
  }
}

proc graph_mobile_us {r dargv} {
  $r query "select 0.001*page_bytes nkbytes, 0.001*delta_user_msec load_msec, 1*element_count nelts
            from page
            where ts_cet > '2014-03-10'
            and 1*error_code=200
            and 1*content_errors = 0
            and 1*page_succeed = 1"
  $r qplot title "Mobile US - page load time vs page_bytes" \
            x nkbytes y load_msec xlab "#kbytes" ylab "Load time (sec)" \
            geom point colour nelts \
            width 11 height 6

  $r query "select p.ts_cet ts, 0.001*p.page_bytes nkbytes, 0.001*p.delta_user_msec load_msec, r.agent_inst, r.profile_id, r.network
            from page p join scriptrun r on r.id = p.scriptrun_id
            where p.ts_cet > '2014-03-10'
            and 1*p.error_code=200
            and 1*p.content_errors = 0
            and 1*p.page_succeed = 1"
            
  foreach colour {agent_inst profile_id network} {
    $r qplot title "Mobile US - page load time vs page_bytes per $colour" \
              x nkbytes y load_msec xlab "#kbytes" ylab "Load time (sec)" \
              geom point colour $colour \
              width 11 height 6 \
              legend {avgtype avg avgdec 3 position right direction vertical}
    $r qplot title "Mobile US - page load time per $colour" \
              x ts y load_msec xlab "Date/time" ylab "Load time (sec)" \
              geom point colour $colour \
              width 11 height 6 \
              legend {avgtype avg avgdec 3 position right direction vertical}
  }
 
  $r qplot title "Mobile US - page weight per network" \
            x ts y nkbytes xlab "Date/time" ylab "#kbytes" \
            geom point colour network \
            width 11 height 6 \
            legend {avgtype avg avgdec 3 position right direction vertical}
  
 
}

main $argv

