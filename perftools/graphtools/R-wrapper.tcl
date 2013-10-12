package require TclOO 

package require struct::set

oo::class create Rwrapper {

  constructor {} {
    # nothing.
  }

  method init {a_dir db} {
    my variable f cmdfilename dir
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
  }
  
  method now {} {
    clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S" 
  }
  
  # replace ' with " before writing.
  method write {cmd} {
    my variable f
    regsub -all {\'} $cmd "\42" cmd2
    puts $f $cmd2
  }
  
  method query {query} {
    my variable f
    puts $f "query = \"$query\""
    my write "df = db.query.dt(db, query)
              print(head(df))"
  }
  
# @todo + minimum (Y) value.  
  
  method qplot {dct} {
    set d [my det_plot_dct $dct]
    my write "p = qplot([:xvar $d], [:yvar $d], data=df, geom='[:geom $d]', colour=[:colour $d]) +"
    if {[:geom2 $d] != ""} {
      my write "geom_point(data=df, aes(x=[:xvar $d], y=[:yvar $d], shape=[:colour $d])) +" 
    }
    if {([:geom $d] == "point") || ([:geom2 $d] == "point")} {
      my write "scale_shape_manual(values=rep(1:25,5)) +" 
    }
    my write "scale_y_continuous(limits=c([:ymin $d], [:ymax $d])) +"
    my write "labs(title = '[:title $d]', x='[:xlab $d]', y='[:ylab $d]')
      ggsave('[:title $d].png', dpi=100, width=[:width $d], height=[:height $d], plot=p)"
  }
  
  # @todo set default values for un-specified values by the user: geom, colour, facet.
  method det_plot_dct {dct} {
    my dset dct xvar [ifp [= [:x $dct] "date"] "date_psx" [:x $dct]]
    if {[:x $dct] == "date"} {
      my dset dct xvar "date_psx"
    } else {
      my dset dct xvar [:x $dct]
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

