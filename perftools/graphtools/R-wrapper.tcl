package require TclOO 

package require struct::set

oo::class create Rwrapper {

  constructor {a_dargv} {
    my variable dargv
    set dargv $a_dargv
  }

  method init {a_dir db} {
    my variable f cmdfilename dir stacked_cmds
    set dir $a_dir
    set cmdfilename "R-[my now].R"
    set f [open [file join $dir $cmdfilename] w]
    my write "
      setwd('$dir')
      sink('R-output.txt')
      print('R started')
      source('~/nicoprj/R/lib/ndvlib.R')
      load.def.libs()
      db = db.open('$db')"
    set stacked_cmds {}
  }
  
  method now {} {
    clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S" 
  }
  
  # replace ' with " before writing.
  method write {cmd} {
    my variable f
    # regsub -all {\'} $cmd "\42" cmd2
    # puts $f $cmd2
    puts $f [my replace_quotes $cmd]
  }
  
  method replace_quotes {cmd} {
    regsub -all {\'} $cmd "\42" cmd2
    return $cmd2
  }
  
  method query {query} {
    my variable f stacked_cmds
    # puts $f "query = \"$query\""
    set stacked_cmds {} ; # when a new query starts, other cmds on the stack can be removed, not used anymore, overwritten.
    lappend stacked_cmds "query = \"$query\""
    lappend stacked_cmds "df = db.query.dt(db, query)
              print(head(df))" 
    # my write 
  }

  method melt {value_vars} {
    my variable stacked_cmds
    # my write "df = melt(df, measure.vars=c("resp_bytes", "element_count", "domain_count", "content_errors", "connection_count"))
    lappend stacked_cmds [my replace_quotes "df = melt(df, measure.vars=c([join [lmap el $value_vars {str "'" $el "'"}] ", "]))"]
    lappend stacked_cmds "print(head(df))"
    lappend stacked_cmds "print(tail(df))"
  }
  
  # @todo idee: ook als args mee kunnen geven, dan 2 opties:
  # - als dct zoals nu, met accolades, dan geen backslash nodig bij einde regel.
  # - direct als params, dan wel backslash nodig, maar geen [list], en parameter substitutie.
  # - of: parameter substitutie binnen qplot doen, maar mss gevaarlijk.
  method qplot {dct} {
    my variable dargv dir stacked_cmds f
    set d [my det_plot_dct $dct]
    if {([:incr $dargv]) && [file exists [file join $dir [:pngname $d]]]} {
      log debug "File already exists, incr: return: [file join $dir [:pngname $d]]"
      return 
    }
    my write "print(concat('Making graph: ', '[:pngname $d]'))"
    if {[:query $d] != ""} {
      my query [:query $d] 
    }
    if {[:melt $d] != ""} {
      my melt [:melt $d] 
    }
    foreach cmd $stacked_cmds {
      puts $f $cmd ; # replace quotes already done where needed (not with query!)
    }
    set stacked_cmds {}
    my write "p = qplot([:xvar $d], [:yvar $d], data=df, geom='[:geom $d]', colour=[:colour $d]) +"
    if {[:geom2 $d] != ""} {
      my write "geom_point(data=df, aes(x=[:xvar $d], y=[:yvar $d], shape=[:colour $d])) +" 
    }
    if {([:geom $d] == "point") || ([:geom2 $d] == "point")} {
      my write "scale_shape_manual(values=rep(1:25,5)) +" 
    }
    my write "scale_y_continuous(limits=c([:ymin $d], [:ymax $d])) +"
    if {[:facet $d] != ""} {
      my write "facet_grid([:facet $d] ~ ., scales='free_y') +" 
    }
    my write "labs(title = '[:title $d]', x='[:xlab $d]', y='[:ylab $d]')
      ggsave('[:pngname $d]', dpi=100, width=[:width $d], height=[:height $d], plot=p)"
    my write "print(concat('Made graph: ', '[:pngname $d]'))"
  }
  
  # @todo set default values for un-specified values by the user: geom, colour, facet.
  method det_plot_dct {dct} {
    my dset dct xvar [ifp [= [:x $dct] "date"] "date_psx" [:x $dct]]
    if {[:x $dct] == "date"} {
      my dset dct xvar "date_psx"
    } else {
      my dset dct xvar [:x $dct]
    }
    if {[:melt $dct] != ""} {
      my dset dct y value
      my dset dct colour variable
    }
    
    my dset dct yvar [:y $dct]
    my dset dct xlab [:x $dct]
    my dset dct ylab [:y $dct]
    if {[regexp -- {^(.+)-(.+)$} [:geom $dct] z g1 g2]} {
      dict set dct geom $g1
      dict set dct geom2 $g2
    } else {
      my dset dct geom "point"
    }
    my dset dct ymin "min(df\$[:yvar $dct])"
    my dset dct ymax "max(df\$[:yvar $dct])"
    my dset dct title "No title"
    my dset dct pngname "[:title $dct].png"
    return $dct
  }
  
  method dset {dct_name key value} {
    upvar $dct_name dct
    if {[dict_get $dct $key] == ""} {
      dict set dct $key $value 
    }
  }
  
  method doall {} {
    my variable f cmdfilename dir
    my write "db.close(db)
              print('R finished')
              sink()"
    close $f
    file copy -force [file join $dir $cmdfilename] [file join $dir "R-latest.R"]
    set rbinary [my det_rbinary]
    set script [file normalize [file join $dir "R-latest.R"]] 
    try_eval {
      log info "Exec R: $rbinary $script"
      exec $rbinary $script
      log info "Exec R finished"
    } {
      log_error "Error while executing R"
      log error "Error while executing R"
      # continue?
    }
  }
  
  method det_rbinary {} {
    global tcl_platform
    # @todo find R binary for windows in a better way.
    switch $tcl_platform(platform) {
      unix {return "/usr/bin/Rscript"}
      windows {return "c:/develop/R/R-2.15.3/bin/Rscript.exe"}
      default {error "Don't know how to find R binary for platform: $tcl_platform(platform)"} 
    }
  }
  
  method cleanup {} {
    # may todo: remove commands file. 
  }
  
}
