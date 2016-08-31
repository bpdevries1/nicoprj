package require TclOO 

package require struct::set
package require ndv

# have procs like '=' and ifp available at global namespace.
use libfp

# CExecLimit gewoon in ndv lib?

# ndv::source_once [file join [info script] .. .. .. lib CExecLimit.tcl]

# @todo filefacet: filename ook als soort facet doen: voor bepaalde kolom een graph/file per kolom-waarde, soort facet dus.
# @todo in theorie ook meerdere kolommen: dan voor elke combi van waarden een file.

# @todo bij facet: bepalen hoeveel facets er zijn en obv hiervan de hoogte van de graph: hight = constant1 + constant2 * #facets.
# @todo BUG: als geen colour meegegeven, en line-point als geom, gaat het fout: shape=as.factor()
# @todo BUG: point-line werkt niet zoals line-point: alleen point zichtbaar, geen line.
# @todo als je maar 1 lijn tekent (evt wel >1 facet) dan evt ook de average ergens in de graph zetten. Mss toch als legend/colour, of
#       als label in de graph zelf (of eronder)
# @todo BUG: als je combi van meerdere plots per query en legend.avg gebruikt, doe wel elke keer dft,df 'query', maar df wordt hierdoro
#       steeds breder, en je krijgt dubbele velden, en waarsch wordt dan de verkeerde geselecteerd. Dus je moet de df weer resetten op
#       wat 'ie was, of je moet de naam van het df dat je plot anders regelen. Dat je de ene df 'df.query' blijft noemen, en steeds df.plot
#       opnieuw bepaalt.
# @todo in R-wrapper bepalen hoe hoog graph moet worden. height.percolour/perfacet op default zetten, afh plaatsing legend en ook #columns
#       bepalen of deze meegenomen moeten worden. Bv ook als er veel colours zijn, en de hoogte groter moet worden dan voor een facet.
# @todo order van legend moet (soms, altijd?) net andersom, bv met guides(colour = guide_legend(reverse = TRUE), shape = guide_legend(reverse = TRUE)), maar werkt nog niet zo.
# @todo [1-3-2014] BUG lijkt dat dict var's soms een waarde houden van de vorige graph. Bv 'df.avail' wordt gebruik bij legend.avg en sqldf, terwijl je al met loading times bezig bent, en avail helemaal niet als veld in deze df zit.
# @todo [1-3-2014] BUG top 10 die je wilt tonen werkt (waarsch) alleen in combi met legend.avg, deze ook op 0 zetten dan?

if 0 {
Instance vars for RWrapper:
* dargv - bij constructor gezet, blijft hierna constant, wel vaker gebruikt, is prima.
* outputroot - bij init een default, en speciale method om te zetten: set_outputroot
* outformats - method: set_outformat
* dir - in init gezet
* fcmd - eenmalig voor command-file.
* cmdfilename - in init gezet
* Routput - in init gezet.
* Rlatest - in init gezet.
* stacked_cmds - in init op {} gezet. Bij query gevuld, ook eerst op leeg gezet. In melt() aangevuld. In plot_prepare() uitgevoerd en hierna op leeg gezet.
* d - bij qplot opnieuw gezet, als resultaat van plot_prepare. In plot_prepare als result van det_plot_dct gezet.
}


oo::class create Rwrapper {

  constructor {a_dargv} {
    my variable dargv
    set dargv $a_dargv
    log debug "Rwrapper constructed with: $dargv"
  }

  # @note dit kan main aanroep zijn. Na construct meteen (en alleen) deze.
  method main {body} {
    my variable dargv
    my init [:dir $dargv] [file join [:dir $dargv] [:dbname $dargv]]
    my set_outformat [:outformat $dargv]

    uplevel $body
    
    my doall
    my cleanup
    my destroy
  }
  
  # @todo remove need for a_dir and db, everything should be set in dargv given to constructor.
  method init {a_dir db {a_file_addition ""}} {
    my variable fcmd cmdfilename dir stacked_cmds Routput Rlatest
    # set dir $a_dir
    log debug "RWrapper initialised with: $a_dir"
    set dir [file normalize [from_cygwin $a_dir]] ; # for R need Unix style (/) dir. 
    set cmdfilename "R-[my now].R"
    set fcmd [open [file join $dir $cmdfilename] w]
    set Routput "R-output${a_file_addition}-[my format_now_filename].txt"
    set Rlatest "R-latest${a_file_addition}.R"
	# TODO: heb naast deze pprint nu ook format_code of zo (ivm buildtool). Vergelijkbaar?
    my write [my pprint "setwd('$dir')
      zz = file('$Routput', open = 'wt')
      # sink('$Routput')
      # sink('$Routput', type = 'message')
      sink(zz)
      # cannot split the message stderr stream (, split=TRUE)
      sink(zz, type = 'message')
      # source('~/nicoprj/R/lib/ndvlib.R')
	  source('[my find_file ndvlib.R ~/nicoprj/R/lib {C:\PCC\Nico\nicoprj\perftools\graph\R\lib}]')
      print.log('R started')
      load.def.libs()
      db = db.open('$db')"]
    set stacked_cmds {}
    my set_outputroot $dir ; # default output-dir is same as DB
  }
  
  method set_outputroot {a_dir} {
    my variable outputroot
    set outputroot $a_dir
    file mkdir $outputroot
  }
  
  method set_outformat {a_format} {
    my variable outformats
    if {$a_format == "all"} {
      set outformats [list png svg] 
    } else {
      set outformats [list $a_format]
    }
  }
  
  method query {query} {
    my variable fcmd stacked_cmds
    # puts $fcmd "query = \"$query\""
    set stacked_cmds {} ; # when a new query starts, other cmds on the stack can be removed, not used anymore, overwritten.
    lappend stacked_cmds [my pprint "query = \"$query\""]
    lappend stacked_cmds "print.log(\"Query - start\")"
    # lappend stacked_cmds "df = db.query.dt(db, query)"
    # 2-3-2014 add Date field after sqldf has been done. Sqldf doesn't like Date fields anymore (since update 1-3-2014).
    lappend stacked_cmds "df = db.query(db, query)"
    lappend stacked_cmds "print.log(\"Query - finished\")"
    # lappend stacked_cmds "print(head(df))" 
    lappend stacked_cmds [my cmds_write_df df]
    # my write 
  }

  method dbexec {query} {
    my variable fcmd
    # @note 25-2-2014 query can contain single quotes, so cannot use write, so use write2.
    my write "print.log('Query - start')"
    puts $fcmd "db.exec(db, \"$query\")"
    my write "print.log('Query - finished')"
  }
  
  method melt {value_vars} {
    my variable stacked_cmds
    # my write "df = melt(df, measure.vars=c("resp_bytes", "element_count", "domain_count", "content_errors", "connection_count"))
    lappend stacked_cmds [my replace_quotes "df = melt(df, measure.vars=c([join [lmap el $value_vars {str "'" $el "'"}] ", "]))"]
    #lappend stacked_cmds "print(head(df))"
    #lappend stacked_cmds "print(tail(df))"
    #my write_df df.plot
    lappend stacked_cmds [my cmds_write_df df]
  }
  
  # @note: ook als args mee kunnen geven, dan 2 opties:
  # - als dct (zoals nu), met accolades, dan geen backslash nodig bij einde regel.
  # - direct als params, dan wel backslash nodig, maar geen [list], en parameter substitutie.
  # beide kunnen nu, in plot_prepare opgelost.
  method qplot {args} {
    my variable dargv dir stacked_cmds fcmd d outputroot outformats
    set d [my plot_prepare {*}$args]
    if {$d == {}} {
      # graph already exists and in incr(emental) mode: return.
      log debug "Graph already exists, not creating again: [:title $d]"
      return 
    }
    
    # df has a value here (when executed in R), check if not empty
    my write "if (nrow(df) > 0) {"
    
      my preprocess
      log debug "Graph does not exist, so creating: [:title $d]"
      set colour [ifp [= "" [:colour $d]] "" ", colour=as.factor([:colour $d]), shape=as.factor([:colour $d])"] 
      # set colour [ifp [= "" [:colour2 $d]] "" ", colour=as.factor([:colour2 $d]), shape=as.factor([:colour2 $d])"] 
      my write "print.log('Starting qplot')"
      my write "p = qplot([:xvar $d], [:yvar $d], data=df.plot, geom='[:geom $d]' $colour) +"
      my write-if-filled :geom2 "geom_point(data=df.plot, aes(x=[:xvar $d], y=[:yvar $d], shape=as.factor([:colour $d]))) +"

      my write_scales $colour
      my write_facet
      my write_legend
      my write_extra
      my write_hline
      
      # for now labs as the latest, is not followed by '+'
      my write_labs
      my write "print.log('ggsave - start')"
      my write_ggsave
      my write "print.log('ggsave - finished')"
      
    # end of check df
    my write "} else {print.log('WARNING: Dataframe df is empty, continue with next graph')}"
  }

  # free format plot command.
  # the cmds parameter should contain direct R/ggplot commands.
  # precondition for these command: a dataframe df.plot is available.
  # postcondition for these commands: a var 'p' with the plot should be made, so it can be saved.
  method myplot {args} {
    my variable dargv dir stacked_cmds fcmd d outputroot outformats
    set d [my plot_prepare {*}$args]
    if {$d == {}} {
      # graph already exists and in incr(emental) mode: return.
      log debug "Graph already exists, not creating again: [:title $d]"
      return 
    }
    
    # df has a value here (when executed in R), check if not empty
    my write "if (nrow(df) > 0) {"
    
      my preprocess ; # geen legend.avg meegeven, dan std df.plot gemaakt.
      
      log debug "Graph does not exist, so creating: [:title $d]"
      # set colour [ifp [= "" [:colour $d]] "" ", colour=as.factor([:colour $d]), shape=as.factor([:colour $d])"] 
      # set colour [ifp [= "" [:colour2 $d]] "" ", colour=as.factor([:colour2 $d]), shape=as.factor([:colour2 $d])"] 
      my write "print.log('Starting myplot')"
      my write "[:cmds $d] +"
      
      #my write "p = qplot([:xvar $d], [:yvar $d], data=df.plot, geom='[:geom $d]' $colour) +"
      #my write-if-filled :geom2 "geom_point(data=df.plot, aes(x=[:xvar $d], y=[:yvar $d], shape=as.factor([:colour $d]))) +"

      #my write_scales $colour
      #my write_facet
      #my write_legend
      #my write_extra
      #my write_hline
      
      # for now labs as the latest, is not followed by '+'
      # evt hierin checken wat gezet is, sowieso moet er iets bij, want vorige regel heeft een '+'. Of eerst de regels opbouwen en dan join met +.
      my write_labs 
      my write_ggsave
      
    # end of check df
    my write "} else {print.log('WARNING: Dataframe df is empty, continue with next graph')}"
  }
  
  method plot_prepare {args} {
    # my variable dargv dir stacked_cmds fcmd d
    my variable dargv dir stacked_cmds fcmd d outputroot
    set dct [ifp [= 1 [llength $args]] [lindex $args 0] $args]
    set d [my det_plot_dct $dct]
    log debug "dct: $dct"
    log debug "d: $d"
    set pngname [file join $outputroot [:pngname $d]]
    # 12-3-2014 if file exists, but is very small (2k?), then probably something went wrong previous time so create again.
    if {([:incr $dargv]) && [file exists $pngname] && ([file size $pngname] > 2000)} {
      # 14-11-2013 bugfix: use outputroot, not dir.
      log debug "File already exists, incr: return: [file join $outputroot [:pngname $d]]"
      return {}
    }
    my write "\nprint.log(concat('Making graph: ', '[:pngname $d]'))"
    if {[:query $d] != ""} {
      my query [:query $d] 
    }
    if {[:melt $d] != ""} {
      my melt [:melt $d] 
    }
    foreach cmd $stacked_cmds {
      puts $fcmd $cmd ; # replace quotes already done where needed (not with query!)
    }
    set stacked_cmds {}
    return $d
  }

  # stuff to to before qplot (or ggplot?) is called
  # @pre df does not contain an R-Date field (does contain date, with sql date, so R string).
  # @post df does contain an R-Date field (if x-axis has dates or times that is).
  method preprocess {} {
    my variable fcmd d
    if {[:legend.avgtype $d] != ""} {
      # add average of values to legend, add to df here using library(sqldf)
      # my write "dft = sqldf('select [:colour $d], avg([:yvar $d]) avrg from df group by 1')"
      if {[:facet $d] != ""} {
        # xvar is op date_Date gezet, en bestaat hier nog niet, dus gebruik :x, staat (gewoon) op date.
        # my write "dfnvalues = data.frame(nxvalues = length(levels(as.factor(df\$[:xvar $d]))), nfacets=length(levels(as.factor(df\$[:facet $d]))))"
        my write "dfnvalues = data.frame(nxvalues = length(levels(as.factor(df\$[:x $d]))), nfacets=length(levels(as.factor(df\$[:facet $d]))))"
      } else {
        # my write "dfnvalues = data.frame(nxvalues = length(levels(as.factor(df\$[:xvar $d]))), nfacets=1)"
        my write "dfnvalues = data.frame(nxvalues = length(levels(as.factor(df\$[:x $d]))), nfacets=1)"
      }
      
      # my write "dft = sqldf('select [:colour $d], 1.0*sum([:yvar $d])/nxvalues avrg, avg([:yvar $d]) avg2, count([:yvar $d]) nr from df, dfnvalues group by 1')"
      # my write "dft = sqldf('select [:colour $d], 1.0*sum([:yvar $d])/(nxvalues*nfacets) avrg, avg([:yvar $d]) avg2, count([:yvar $d]) nr from df, dfnvalues group by 1')"
      if {[:maxcolours $d] == 0} {
        my write "dft = sqldf('select [:colour $d], 1.0*sum([:yvar $d])/(nxvalues*nfacets) avg_sum, avg([:yvar $d]) avg_avg, count([:yvar $d]) nr from df, dfnvalues group by 1')"
      } else {
        my write "dft = sqldf('select [:colour $d], 1.0*sum([:yvar $d])/(nxvalues*nfacets) avg_sum, avg([:yvar $d]) avg_avg, count([:yvar $d]) nr from df, dfnvalues group by 1 order by 2 desc limit [:maxcolours $d]')"
      }
      # @todo bepaal of 8 goede waarde is, door ceiling(log10(m)), waarbij m = max(dft$avrg)
      # my write "dft\$avrg_f = sprintf('\[%8.[:legend.avg $d]f\] ', dft\$avrg)"
      my write "fmt.string = det.fmt.string(dft\$avg_[:legend.avgtype $d], [:legend.avgdec $d])"
      my write "dft\$avrg_f = sprintf(fmt.string, dft\$avg_[:legend.avgtype $d])"
      
      my write_df dft
      # my write not possible below, single quotes should stay single quotes.
      # 2-3-2014 df.avail staat hier nog, niet goed. Orig: select df.*, '\[' etc 
      # df is result query, dus je weet velden eigenlijk niet goed. Dan toch date_Date nog niet toevoegen zodat je weer * kunt doen en later toevoegen.
      # was new, but does not work: puts $fcmd "df.plot = sqldf(\"select df.scriptname, df.date, df.avail, '\['||round(dft.avrg,[:legend.avg $d])||'\] ' || df.[:colour $d] label_avg from df join dft on df.[:colour $d]=dft.[:colour $d]\")"
      # puts $fcmd "df.plot = sqldf(\"select df.*, '\['||printf('%.[:legend.avg $d]f', dft.avrg)||'\] ' || df.[:colour $d] label_avg from df join dft on df.[:colour $d]=dft.[:colour $d]\")"
      # puts $fcmd "df.plot = df.add.dt(sqldf(\"select df.*, '\['||round(dft.avrg, [:legend.avg $d])||'\] ' || df.[:colour $d] label_avg from df join dft on df.[:colour $d]=dft.[:colour $d]\"))"
      # puts $fcmd "df.plot = df.add.dt(sqldf(\"select df.*, dft.avrg_f || df.[:colour $d] label_avg from df join dft on df.[:colour $d]=dft.[:colour $d]\"))"
      # puts $fcmd "df.plot = df.add.dt(sqldf(\"select df.*, dft.avrg_f || substr(df.[:colour $d],1,100) label_avg from df join dft on df.[:colour $d]=dft.[:colour $d]\"))"
      puts $fcmd "df.plot = df.add.dt(sqldf(\"select df.*, dft.avrg_f || substr(df.[:colour $d],1,[:legend.maxchars $d]) label_avg from df join dft on df.[:colour $d]=dft.[:colour $d]\"))"
      # printf("%.2f", floatField) => kent 'ie niet, ook niet vanaf R. En vanaf tcl zelfs ook niet, alleen hier wel zelf toe te voegen natuurlijk.
      
      my write_df df.plot
      dict set d colour "label_avg"
      # dict set d colour2 "label_avg"
    } else {
      my write "df.plot = df.add.dt(df)"
      my write_df df.plot
      # dict set d colour2 [:colour $d]
    }
  }

  method write_df {df_name} {
    my write [my cmds_write_df $df_name]
  }
  
  method cmds_write_df {df_name} {
    #my write "print.log('Summary of data frame: $df_name')"
    #my write "print(head($df_name))"
    #my write "print(tail($df_name))"
    #my write "print(summary($df_name))"
    return [join [list "print.log('Summary of data frame: $df_name')" \
                       "print(head($df_name))" \
                       "print(tail($df_name))" \
                       "print(summary($df_name))"] "\n"]
  }
  
  method write_scales {colour} {
    my variable d
    # @note scale_colour should be put before scale_shape, in order for guides(ncol) to work.
    #       doesn't matter if guides is put first.    
    if {[:maxcolours $d] > 0} {
      set colourlabel "[:colourlabel $d] (top [:maxcolours $d])"
    } else {
      set colourlabel [:colourlabel $d]
    }
    if {$colour != ""} {
      # my write2 "scale_colour_discrete(name='[:colourlabel $d]') +"
      my write2 "scale_colour_discrete(name='$colourlabel') +"
    }
    if {([:geom $d] == "point") || ([:geom2 $d] == "point")} {
      # my write2 "scale_shape_manual(name='[:colourlabel $d]', values=rep(1:25,10)) +"
      my write2 "scale_shape_manual(name='$colourlabel', values=rep(1:25,10)) +"
    }
    if {([:ymin $d] != "") && ([:ymax $d] != "")} {
      my write2 "scale_y_continuous(limits=c([:ymin $d], [:ymax $d])) +"
    }
    if {[regexp {^dt/} [:xdatatype $d]]} {
      set options {}
      if {[:x.breaks $d] != ""} {
        lappend options "minor_breaks = date_breaks('[:x.breaks $d]')" 
      }
      lappend options "labels = date_format('[my det_date_format [:xdatatype $d]]')"
      if {[:xdatatype $d] == "dt/date"} {
        my write2 "scale_x_date([join $options ", "]) +"
      } else {
        my write2 "scale_x_datetime([join $options ", "]) +"
      }
    }
    # also possible: breaks instead of minor_breaks, and labels:
    # last_plot() + scale_x_datetime(breaks = date_breaks("10 days"), labels = date_format("%d/%m"))
  }
  
  method det_date_format {datatype} {
    # @todo maybe add a \n for ts format.
    # old, for test: dt/date {str "%Y-%m-%d\n%H:%M"}
    switch $datatype {
      dt/date {str "%Y-%m-%d"}
      dt/time {str "%H:%M:%S"}
      dt/ts {str "%Y-%m-%d\n%H:%M:%S"}
    }
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
    if 0 {
      if {[:maxcolours $d] != 0} {
        my write2 "theme(legend.title='[:colour $d] (top [:maxcolours $d])') +"
      } else {
        my write2 "theme(legend.title='[:colour $d]') +"
      }
    }
    my write-if-filled :legend.position "theme(legend.position='[:legend.position $d]') +"
    my write-if-filled :legend.direction "theme(legend.direction='[:legend.direction $d]') +"
    
    #legend.key.size 	size of legend keys (unit; inherits from legend.key.size)
    #legend.key.height 	key background height (unit; inherits from legend.key.size) 
    # my write "theme(legend.key.height=unit(1.0, 'char')) +"
    my write-if-filled :legend.keyheight "theme(legend.key.height=unit([:legend.keyheight $d], 'char')) +"
    
    # 24-1-2014 tests to solve long labels in legends -> failed.
    # my write "theme(legend.title.align = 1) + "
    # my write "theme(legend.justification = 1) + "
    my write-if-filled :legend.ncol "guides(col = guide_legend(ncol = [:legend.ncol $d])) +"
    my write-if-filled :legend.nrow "guides(col = guide_legend(nrow = [:legend.nrow $d])) +"
  }

  method write_labs {} {  
    my variable d
    my write2 "labs(title = '[:title $d]', x='[:xlab $d]', y='[:ylab $d]')"
  }

  method write_extra {} {
    my variable d
    my write-if-filled :extra "[:extra $d] +"
  }
  
  method write_hline {} {
    my variable d
    my write-if-filled :hline "geom_hline(yintercept=[:hline $d]) +"
  }
  
  method write_ggsave {} {
    my variable d outputroot outformats
    # @note 7-3-2014 with nested dict's, both height and height.min can exists, so check on height.min
    if {([:height.fixed $d] != "") && ([:height.fixed $d] > 0)} {
      set height [:height.fixed $d]
      my write "height = $height"
    } else {
      set facets [ifp [= [:facet $d] ""] "NA" "df.plot\$[:facet $d]"]
      set colours [ifp [= [:colour $d] ""] "NA" "df.plot\$[:colour $d]"]
      my write "height = det.height(height.min=[:height.min $d], height.max=[:height.max $d], height.base=[:height.base $d], height.perfacet=[:height.perfacet $d], height.percolour=[:height.percolour $d], facets=$facets, colours=$colours, legend.position='[:legend.position $d]')"
    }
 
    my write "print.log(concat('height: ', height))"
    foreach outformat $outformats {
      # outprocname: :0name
      set outprocname ":${outformat}name"
      my write "# outprocname: $outprocname"
      set outname [$outprocname $d]
      my write "# outname: $outname"
      # my write "ggsave('[file join $outputroot $outname]', dpi=100, width=[:width $d], height=[:height $d], plot=p)"
      my write "ggsave('[file join $outputroot $outname]', dpi=100, width=[:width $d], height=height, plot=p)"
      my write "print.log(concat('Made graph: ', '$outname'))"
    }
    
  }
  
  method write-if-filled {key expr} {
    my variable d
    if {[$key $d] != ""} {
      my write2 $expr 
    }
  }

  method det_plot_dct {dct} {
    log debug "det_plot_dct: start, dct=$dct"
    if {[dict? [:height $dct]]} {
      # dynamic calculation of height
      my dset dct height.fixed -1
    } else {
      # fixed height
      my dset dct height.fixed [:height $dct]
    }
    set dct [dict_flatten $dct "."] ; # so height {min 5 max 7} can be used.
    if {[:x $dct] == "date"} {
      # my dset dct xvar "date_psx"
      my dset dct xvar "date.Date"
      my dset dct xdatatype "dt/date"
    } elseif {[:x $dct] == "ts"} {
      my dset dct xvar "ts.psx"
      my dset dct xdatatype "dt/ts"
    } elseif {[:x $dct] == "time"} {
      my dset dct xvar "time.psx"
      my dset dct xdatatype "dt/time"
    } else {
      my dset dct xvar [:x $dct]
      my dset dct xdatatype "other/other"
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
    
    # 19-11-2013 vooral met facets is min/max niet zo handig, dan geen free-y meer.
    if {[:facet $dct] == ""} {
      my dset dct ymin "min(df\$[:yvar $dct], na.rm=TRUE)"
      my dset dct ymax "max(df\$[:yvar $dct], na.rm=TRUE)"
    } else {
      if {[:ymin $dct] == ""} {
        if {[:ymax $dct] == ""} {
          # no min/max set, leave as is
        } else {
          # only max is set, set min to min of values
          my dset dct ymin "min(df\$[:yvar $dct], na.rm=TRUE)"
        }
      } else {
        # ymin is set.
        if {[:ymax $dct] == ""} {
          # only min is set, set max to max of values
          my dset dct ymax "max(df\$[:yvar $dct], na.rm=TRUE)"
        } else {
          # both ymin and ymax are set, leave as is.
        }
      }
    }
    my dset dct title "No title"
    my dset dct pngname "[my sanitise [:title $dct]].png"
    my dset dct svgname "[my sanitise [:title $dct]].svg"
    
    # label to display above (as title) of the legend.
    my dset dct colourlabel [:colour $dct]
    
    # height of graph, 2 options: 1) fixed height 2) based on #facets.
    my dset dct height.min 5
    my dset dct height.max 20
    my dset dct height.base 3.4
    # @note default for height.perfacet/colour are 0, graphs might have just one of those items. If 0 don't check the df column.
    my dset dct height.perfacet 0
    my dset dct height.percolour 0
    my dset dct maxcolours 0
    
    # @note avg can be calculated in 2 ways: 1) with sum/total possible values or 2) just average of existing values.
    # 1) is used to show relative impact of items: if an item has a high value, but occurs only once, this way of calculating doesn't put it at the top. Other items
    #    with a lower average but occuring always will be put higher.
    # default/deprecated: legend.avg 3 -> legend.avgtype sum legend.avgdec 3
    if {[:legend.avg $dct] != ""} {
      my dset dct legend.avgtype sum
      my dset dct legend.avgdec [:legend.avg $dct]
    }
    my dset dct legend.keyheight 1.0
    my dset dct legend.maxchars 120
    
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
    my variable fcmd cmdfilename dir dargv Routput Rlatest
    my write [my pprint "\n# Finished\ndb.close(db)
              print.log('R finished')
              sink()
              sink(type = 'message')"]
    close $fcmd
    if {[:keepcmd $dargv]} {
      file copy -force [file join $dir $cmdfilename] [file join $dir $Rlatest]
    } else {
      file rename -force [file join $dir $cmdfilename] [file join $dir $Rlatest]
    }
    set rbinary [my det_rbinary]
    set script [file normalize [file join $dir $Rlatest]] 
    
    set exec_limit [CExecLimit #auto]
    # $exec_limit set_saveproc_filename "saveproc.txt"
    
    try_eval {
      log info "Exec R: $rbinary $script"
      if {[:execlimit $dargv] != ""} {
        set execlimit [:execlimit $dargv]
      } else {
        set execlimit 600 ; # 10 minutes is better for the CN graphs, take about 7 minutes.
      }
      set exit_code [$exec_limit exec_limit "$rbinary $script" $execlimit result res_stderr]
      log info "Exec R finished, exitcode = $exit_code, len(result)=[string length $result], len(stderr) = [string length $res_stderr]"
      # my log_last_lines [file normalize [file join $dir "R-output.txt"]] 
      my log_last_lines [file normalize [file join $dir $Routput]] 
    } {
      log_error "Error while executing R"
      log error "Error while executing R"
      # continue?
    }
  }

  method log_last_lines {filename} {
    set f [open $filename r]
    set text [read $f]
    set lines [split $text "\n"]
    set nlines 5
    set last_lines [lrange $lines end-$nlines end]
    log info "last $nlines from $filename:\n[join $last_lines "\n"]"
    close $f
  }
  
  method det_rbinary {} {
    global tcl_platform
    # @todo find R binary for windows in a better way.
    # windows {return "c:/develop/R/R-2.15.3/bin/i386/Rscript.exe"}
    switch $tcl_platform(platform) {
      unix {return "/usr/bin/Rscript"}
      windows {
		return [my find_file Rscript.exe "c:/develop/R/R-2.15.3/bin/x64" {C:\PCC\Util\R\R-3.1.1\bin\x64}]
	  }
      default {error "Don't know how to find R binary for platform: $tcl_platform(platform)"} 
    }
  }
  
  # TODO: - something similar already somewhere else...
  method find_file {name args} {
	foreach dir $args {
	  if {[file exists [file join $dir $name]]} {
		 return [file join $dir $name]
	  }
	}
	error "$name not found in: $args"
  }
  
  method cleanup {} {
    # maybe todo: remove commands file. 
  }

  # Helper methods
  method now {} {
    clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S" 
  }
  
  # replace ' with " before writing.
  method write {cmd} {
    my variable fcmd
    # regsub -all {\'} $cmd "\42" cmd2
    # puts $fcmd $cmd2
    # puts $fcmd [my indent [my replace_quotes $cmd]]
    puts $fcmd [my replace_quotes $cmd]
  }
  
  method write2 {cmd} {
    my write "  $cmd" 
  }
  
  # replace single quotes by double quotes.
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
  
  # format now so it can be used in filename (no ':')
  method format_now_filename {} {
    clock format [clock seconds] -format "%Y-%m-%d--%H-%M-%S"
  }
  
}

