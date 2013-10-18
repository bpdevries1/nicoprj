package require TclOO 

package require struct::set

# @todo filefacet: filename ook als soort facet doen: voor bepaalde kolom een graph/file per kolom-waarde, soort facet dus.
# @todo in theorie ook meerdere kolommen: dan voor elke combi van waarden een file.

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
    my write [my pprint "setwd('$dir')
      sink('R-output.txt')
      print('R started')
      source('~/nicoprj/R/lib/ndvlib.R')
      load.def.libs()
      db = db.open('$db')"]
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
    # puts $f [my indent [my replace_quotes $cmd]]
    puts $f [my replace_quotes $cmd]
  }
  
  method write2 {cmd} {
    my write "  $cmd" 
  }
  
  method replace_quotes {cmd} {
    regsub -all {\'} $cmd "\42" cmd2
    return $cmd2
  }
  
  method indent {str} {
    # @todo first start all at line 1, maybe indent for queries and plot commands.
    # @todo maybe not use this function.
  }
  
  # start first line at col 0, next at col 2.
  method pprint {str} {
    set str [string trim $str]
    # remove all spaces from start of lines
    while {[regsub -all {\n } $str "\n" str]} {}
    # put 2 spaces in front of every line but the first
    regsub -all {\n} $str "\n  " str
    return $str
  }
  
  method query {query} {
    my variable f stacked_cmds
    # puts $f "query = \"$query\""
    set stacked_cmds {} ; # when a new query starts, other cmds on the stack can be removed, not used anymore, overwritten.
    lappend stacked_cmds [my pprint "query = \"$query\""]
    lappend stacked_cmds "df = db.query.dt(db, query)"
    lappend stacked_cmds "print(head(df))" 
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
  method qplot {args} {
    my variable dargv dir stacked_cmds f d
    set d [my plot_prepare {*}$args]
    set colour [ifp [= "" [:colour $d]] "" ", colour=as.factor([:colour $d]), shape=as.factor([:colour $d])"] 
    my write "p = qplot([:xvar $d], [:yvar $d], data=df, geom='[:geom $d]' $colour) +"
    my write-if-filled :geom2 "geom_point(data=df, aes(x=[:xvar $d], y=[:yvar $d], shape=as.factor([:colour $d]))) +"

    my write_scales $colour
    my write_facet
    my write_legend
    my write_labs

    my write "ggsave('[:pngname $d]', dpi=100, width=[:width $d], height=[:height $d], plot=p)"
    # ook voor SVG wel dimensies opgeven, anders vierkant en blijft vierkant.
    my write "ggsave('[:svgname $d]', dpi=100, width=[:width $d], height=[:height $d], plot=p)"
    # my write "ggsave('[:pngname $d].svg', plot=p)"
    my write "print(concat('Made graph: ', '[:pngname $d]'))"
  }

  method plot_prepare {args} {
    # my variable dargv dir stacked_cmds f d
    my variable dargv stacked_cmds f d
    set dct [ifp [= 1 [llength $args]] [lindex $args 0] $args]
    set d [my det_plot_dct $dct]
    log debug "dct: $dct"
    log debug "d: $d"
    if {([:incr $dargv]) && [file exists [file join $dir [:pngname $d]]]} {
      log debug "File already exists, incr: return: [file join $dir [:pngname $d]]"
      return 
    }
    my write "\nprint(concat('Making graph: ', '[:pngname $d]'))"
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
    return $d
  }

  method write_scales {colour} {
    my variable d
    # @note scale_colour should be put before scale_shape, in order for guides(ncol) to work.
    #       doesn't matter if guides is put first.    
    if {$colour != ""} {
      my write2 "scale_colour_discrete(name='[:colour $d]') +"
    }
    if {([:geom $d] == "point") || ([:geom2 $d] == "point")} {
      my write2 "scale_shape_manual(name='[:colour $d]', values=rep(1:25,5)) +"
    }
    my write2 "scale_y_continuous(limits=c([:ymin $d], [:ymax $d])) +"
    # @todo check type of x-var and x.breaks value: dates, times, or something else?
    my write-if-filled :x.breaks "scale_x_datetime(minor_breaks = date_breaks('[:x.breaks $d]')) +"    
    # also possible: breaks instead of minor_breaks, and labels:
    # last_plot() + scale_x_datetime(breaks = date_breaks("10 days"), labels = date_format("%d/%m"))
  }
  
  method write_facet {} {
    my variable d
    if {[:facet $d] != ""} {
      my write2 "facet_grid([:facet $d] ~ ., scales='free_y') +" 
    }
  }

  method write_legend {} {
    my variable d
    # @todo als pos=bottom en dir=vertical, dan checken hoeveel 'kleuren' er zijn. Als veel, dan grafiek groter maken.
    #       berekening in Tcl (dan ook query in tcl) of in R (beter, als dit kan).
    my write-if-filled :legend.position "theme(legend.position='[:legend.position $d]') +"
    my write-if-filled :legend.direction "theme(legend.direction='[:legend.direction $d]') +"
    my write-if-filled :legend.ncol "guides(col = guide_legend(ncol = [:legend.ncol $d])) +"
    my write-if-filled :legend.nrow "guides(col = guide_legend(nrow = [:legend.nrow $d])) +"
  }

  method write_labs {} {  
    my variable d
    my write2 "labs(title = '[:title $d]', x='[:xlab $d]', y='[:ylab $d]')"
  }

  method write-if-filled {key expr} {
    my variable d
    if {[$key $d] != ""} {
      my write2 $expr 
    }
  }

  method det_plot_dct {dct} {
    if {[:x $dct] == "date"} {
      my dset dct xvar "date_psx"
    } elseif {[:x $dct] == "ts"} {
      my dset dct xvar "ts_psx"
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
    my dset dct pngname "[my sanitise [:title $dct]].png"
    my dset dct svgname "[my sanitise [:title $dct]].svg"
    return $dct
  }
  
  method sanitise {filename} {
    regsub -all {[/:\\\?~;<>]} $filename "_" filename
    return $filename
  }
  
  method dset {dct_name key value} {
    upvar $dct_name dct
    if {[dict_get $dct $key] == ""} {
      dict set dct $key $value 
    }
  }
  
  method doall {} {
    my variable f cmdfilename dir dargv
    my write [my pprint "\n# Finished\ndb.close(db)
              print('R finished')
              sink()"]
    close $f
    if {[:keepcmd $dargv]} {
      file copy -force [file join $dir $cmdfilename] [file join $dir "R-latest.R"]
    } else {
      file rename -force [file join $dir $cmdfilename] [file join $dir "R-latest.R"]
    }
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

