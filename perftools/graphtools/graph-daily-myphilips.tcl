#!/usr/bin/env tclsh86

package require Tclx
package require ndv

set log [::ndv::CLogger::new_logger [file tail [info script]] info]
$log set_file "[file tail [info script]].log"

set script_dir [file dirname [info script]]
ndv::source_once [file join $script_dir R-wrapper.tcl]
foreach libname [glob -nocomplain -directory $script_dir lib*.tcl] {
  ndv::source_once $libname
}

proc main {argv} {
  log debug "argv: $argv"
  set options {
    {rootdir.arg "c:/projecten/Philips/KNDL" "Directory that contains db"}
    {outrootdir.arg "c:/projecten/Philips/MyPhilips/daily/graphs" "Directory for output graphs"}
    {pattern.arg "MyPhilips-*" "Pattern of scripts to handle"}
    {outformat.arg "png" "Output format (all, png or svg)"}
    {loglevel.arg "info" "Log level (debug, info, warn)"}
    {combineddb.arg "c:/projecten/Philips/MyPhilips/daily/daily.db" "DB with combined data from all shops"}
    {actions.arg "all" "List of actions to execute (comma separated)"}
    {combinedactions.arg "all" "List of actions to execute on combined DB (comma separated)"}
    {periods.arg "all" "Periods to make graphs for (2w, 6w, 2d, 1y, all=1y,6w,2d)"}
    {keepcmd "Keep R command file with timestamp"}
    {incr "Incremental: only create graphs if they do not exist yet"}
  }
  set usage ": [file tail [info script]] \[options] :"
  set dargv [getoptions argv $options $usage]
  log set_log_level [:loglevel $dargv]
  make_graphs $dargv
  make_graphs_myphilips $dargv
}

proc make_graphs_myphilips {dargv} {
  make_graphs_myphilips_dir [file join [:rootdir $dargv] "MyPhilips-BR"] $dargv
}
  
proc make_graphs_myphilips_dir {dir dargv} {  
  # cloudfront, only for BR now.
  set scriptname [file tail $dir]
  set r [Rwrapper new $dargv]
  $r init $dir keynotelogs.db
  $r set_outputroot [file normalize [file join [from_cygwin [:outrootdir $dargv]] [file tail $dir]]]
  $r set_outformat [:outformat $dargv]

  # @note 2013-10-01 was even voor Hakim.
  # and date_cet >= '2013-10-01'
  $r query "select i.date_cet date, l.location location, count(*) number, avg(0.001*i.element_delta) loadtime, avg(0.001*(i.element_delta-i.system_delta)) loadtime_nc
            from pageitem i 
              left join location l on i.ip_address like l.ip_range
            where i.topdomain = 'cloudfront.net'
            and i.ts_cet < (select max(date_cet) from scriptrun)
            and 1*i.page_seq = 1
            group by 1, 2"

  $r qplot title "$scriptname - Average loadtime for Cloudfront elements per location" \
            x date y loadtime xlab "Date" ylab "Load time (seconds)" \
            ymin 0 geom line-point colour location \
            width 11 height 7 \
            legend.position bottom \
            legend.direction horizontal
            
  $r qplot title "$scriptname - Average loadtime (excl client time) for Cloudfront elements per location" \
            x date y loadtime_nc xlab "Date" ylab "Load time (seconds)" \
            ymin 0 geom line-point colour location \
            width 11 height 7 \
            legend.position bottom \
            legend.direction horizontal

  $r qplot title "$scriptname - Daily #items for Cloudfront elements per location" \
            x date y number xlab "Date" ylab "Daily #items" \
            ymin 0 geom line-point colour location \
            width 11 height 7 \
            legend.position bottom \
            legend.direction horizontal

  $r doall
  $r cleanup
  $r destroy  
  
}

main $argv
