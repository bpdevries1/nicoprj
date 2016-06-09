# ndvlib.R - general R functions to use
# note: make it a package sometime, but first just source the thing.

load.def.libs.old.see.ndvlib = function() {
  library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
  # print("Loaded RSQLITe quietly")
  library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
  library(gsubfn, quietly=TRUE)
  library(proto, quietly=TRUE)
  library(RSQLite.extfuns, quietly=TRUE)
  library(plyr, quietly=TRUE)
  library(stringr, quietly=TRUE)
  library(reshape2, quietly=TRUE)
  library(grid, quietly=TRUE) # for unit, met legends.
  library(scales, quietly=TRUE) # for ticks per hour.
  library(sqldf, quietly=TRUE) # for query-ing dataframes.
  library(RODBC, quietly=TRUE)
  library(tcltk, quietly=TRUE)
}

concat = paste0

det.connstring = function(server, db) {
  concat("Driver=SQL Server;Server=", server, ";Database=", db, ";Trusted_Connection=yes;")
}

det.connstring.PT = function(testnr) {
  concat("Driver=SQL Server;Server=AXZTSTW001;Database=PerfTestResultsT", testnr, ";Trusted_Connection=yes;")
}

det.connstring.LT = function(testnr, fase = "") {
  if (is.na(fase) || (fase == "")) {
    testnr.fase = testnr
  } else {
    testnr.fase = concat(testnr, "-", fase)    
  }
  concat("Driver=SQL Server;Server=AXZTSTW001;Database=LoadTest2010T", testnr.fase, ";Trusted_Connection=yes;")
}

det.outdir = function(testnr) {
  concat("G:\\Testware\\_Results\\Test ", testnr, "\\Analyse")  
}

make.logger = function(filename) {
  fo = file(filename, "w")
  fn = function(...) {
    # logstr = paste0(list(...))
    logstr = paste0(...)
    if (length(logstr) == 0) {
      writeLines("Closing logfile", fo)
      close(fo) 
    } else {
      writeLines(logstr, fo)
      flush(fo)
    }
  }
  fn  
}

calc.df.aggr = function(df, xcol, ycol, nsegments, extracols = c(), aggr.fn=mean) {
  df$cut_x = cut(df[,xcol], nsegments,labels=FALSE)
  df.ply = ddply(df, as.quoted(c("cut_x", extracols)), 
                 function(df) {c(cut_x2 = min(df[,xcol]), calc_y=aggr.fn(df[,ycol]))})
  df.ply[,xcol] = df.ply$cut_x2
  df.ply[,ycol] = df.ply$calc_y
  df.ply[,c(extracols, xcol, ycol)]
}

calc.df.aggr.ts = function(df, xcol, ycol, nsegments, extracols = c(), aggr.fn=mean) {
  s = seq(min(df[,xcol]), max(df[,xcol]), length.out = nsegments)
  df$cut_x = cut(df[,xcol], s)
  df$ts_cut = as.POSIXct(strptime(df$cut_x, format="%Y-%m-%d %H:%M:%S"))
  df.ply = ddply(df, as.quoted(c("cut_x", extracols)), 
                 function(df) {c(calc_y=aggr.fn(df[,ycol]))})
  
  df.ply[,xcol] = as.POSIXct(strptime(df.ply$cut_x, format="%Y-%m-%d %H:%M:%S"))
  df.ply[,ycol] = df.ply$calc_y
  df.ply[,c(extracols, xcol, ycol)]
}

det.interval.sec = function(df, cols = c("DatabaseName", "ChannelName")) {
  dfa = ddply(df, as.quoted(cols),
              function(dft) {
                c(dtime = as.numeric(max(dft$ts_psx) - min(dft$ts_psx), units="secs") / (length(dft$ts_psx)-1))
              })
  mean(dfa$dtime)  
}

segment.secs = function(test.start, seg.start, seg.end) {
  test.start.psx = as.POSIXct(strptime(test.start, format="%Y-%m-%d %H:%M:%S"))
  seg.start.psx = as.POSIXct(strptime(seg.start, format="%Y-%m-%d %H:%M:%S"))
  seg.end.psx = as.POSIXct(strptime(seg.end, format="%Y-%m-%d %H:%M:%S"))
  seg.start.sec = as.double(seg.start.psx - test.start.psx, units="secs")
  seg.end.sec = as.double(seg.end.psx - test.start.psx, units="secs")
  c(seg.start.sec, seg.end.sec)  
}

write.tsv = function(ftsv, part, name, value) {
  writeLines(paste(part, name, value, sep="\t"), ftsv)
}

query.with.log = function(con, query, log) {
  log(query)  
  df = sqlQuery(con, query)
  log.df(log, df, "query executed")
  df
}

log.df = function(log, df, msg = NULL) {
  if (is.null(msg)) {
    log("df summary:")
  } else {
    log(msg)
  }
  log("column names:")
  log(names(df))
  log(summary(df))
  log("head:")
  log(head(df))
  log("tail:")
  log(tail(df))
  log("end of summary/head/tail")
}

det.height = function(height.min=5, height.max=30, height.base=3.4, height.perfacet=1.7, facets=NULL, height.percolour=0.24, colours=NULL, legend.cols = 2, legend.position = "bottom", log) {
  # base height should include height for 1 facet.
  height = height.base
  if (height.perfacet > 0) {
    nfacets = length(levels(as.factor(facets)))
    # only change hight if minimal 2 facets.
    if (nfacets >= 2) {
      height = height + (nfacets-1) * height.perfacet
    }
  }
  if (height.percolour > 0) {
    ncolours = length(levels(as.factor(colours)))
    if (legend.position == "right") {
      height.colours = (1.0 * ncolours / legend.cols) * height.percolour
      if (height.colours > height) {
        height = height.colours
      }
    } else {
      height = height + (1.0 * ncolours / legend.cols) * height.percolour
    }
  }
  if (height > height.max) {
    height.max
  } else {
    if (height < height.min) {
      height.min
    } else {
      height
    }
  }
}

det.height.log = function(height.min=5, height.max=20, height.base=3.4, height.perfacet=1.7, facets=NULL, height.percolour=0.24, colours=NULL, legend.cols = 2, legend.position = "bottom", log) {
  # base height should include height for 1 facet.
  height = height.base
  if (height.perfacet > 0) {
    nfacets = length(levels(droplevels(as.factor(facets))))
    log(concat("#facets: ", nfacets))
    # only change hight if minimal 2 facets.
    if (nfacets >= 2) {
      height = height + (nfacets-1) * height.perfacet
    }
  }
  log(concat("Height before colours: ", height))
  if (height.percolour > 0) {
    ncolours = length(levels(droplevels(as.factor(colours))))
    if (legend.position == "right") {
      height.colours = (1.0 * ncolours / legend.cols) * height.percolour
      if (height.colours > height) {
        height = height.colours
      }
    } else {
      height = height + (1.0 * ncolours / legend.cols) * height.percolour
    }
  }
  log(concat("Height after colours: ", height))
  if (height > height.max) {
    height.max
  } else {
    if (height < height.min) {
      height.min
    } else {
      height
    }
  }
}

qplot.dt = function(x, y, data, colour=NULL, facets=NULL, filename, ...) {
  print("qplot.dt: start")
  a=1
  mf <- match.call()
  mf[[1]] <- as.name("qplot")
  print(x=(a=a+1))
  if (missing(colour)) {
    print("colour missing")
    colour = NULL
    has.colour = FALSE
  } else {
    colourname = deparse(substitute(colour))
    has.colour = TRUE
    mf$shape = mf$colour
  }
  print(x=(a=a+1))
  p <- eval(mf, parent.frame())
  print(x=(a=a+1))
  p = p +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M")) +
    # always a time axis in this function, so don't show the axis name:
    xlab(NULL) + 
    scale_y_continuous(labels = comma)
  print(x=(a=a+1))
  if (has.colour) {    
    g = guide_legend(colourname, ncol = 2)
    p = p + scale_colour_discrete(name=colourname) +
      scale_shape_manual(name=colourname, values=rep(1:25,10)) +
      guides(colour = g, shape = g) +
      theme(legend.position="bottom") +
      theme(legend.direction="horizontal")
  }
  print(x=(a=a+1))
  facetvars <- all.vars(facets)
  facetvars <- facetvars[facetvars != "."]
  if (!is.na(facetvars[1])) {
    p = p + facet_grid(facets, scales='free_y', labeller=label_wrap_gen3(width=25))
  }
  print(x=(a=a+1))
  height = det.height(colours = data[[colourname]], facets = data[[facetvars[1]]])
  print(x=(a=a+1))
  filename = eval(mf$filename, parent.frame())
  print(x=(a=a+1))
  print("before ggsave")
  print(filename)
  print(height)
  ggsave(filename, plot=p, width=12, height=height, dpi=100)
  print("after ggsave")
  # don't return p, to supress warnings.
  # p 
}

# TODO deze samenvoegen met vorige, of wrapper functie.
# TODO al eerder een versie gemaakt waarbij je title opgeeft wat meteen ook filename wordt?
# generic version of qplot.dt, with x-axis not a date/time value.
# vb facets: facets=transname~.
qplot.gen = function(x, y, data, colour=NULL, facets=NULL, filename, ...) {
  print("qplot.dt: start")
  a=1
  mf <- match.call()
  mf[[1]] <- as.name("qplot")
  print(x=(a=a+1))
  if (missing(colour)) {
    print("colour missing")
    colour = NULL
    has.colour = FALSE
  } else {
    colourname = deparse(substitute(colour))
    has.colour = TRUE
    mf$shape = mf$colour
  }
  print(x=(a=a+1))
  p <- eval(mf, parent.frame())
  print(x=(a=a+1))
  p = p +
    # scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M")) +
    # always a time axis in this function, so don't show the axis name:
    # xlab(NULL) + 
    scale_x_continuous(labels = comma)
    scale_y_continuous(labels = comma)
  # TODO title zo overnemen werkt niet, moet nog eval overheen.
  #p = p +
  #  labs(title=mf$title)
  print(x=(a=a+1))
  if (has.colour) {    
    g = guide_legend(colourname, ncol = 2)
    p = p + scale_colour_discrete(name=colourname) +
      scale_shape_manual(name=colourname, values=rep(1:25,10)) +
      guides(colour = g, shape = g) +
      theme(legend.position="bottom") +
      theme(legend.direction="horizontal")
  }
  print(x=(a=a+1))
  facetvars <- all.vars(facets)
  facetvars <- facetvars[facetvars != "."]
  if (!is.na(facetvars[1])) {
    p = p + facet_grid(facets, scales='free_y', labeller=label_wrap_gen3(width=25))
  }
  print(x=(a=a+1))
  height = det.height(colours = data[[colourname]], facets = data[[facetvars[1]]])
  print(x=(a=a+1))
  filename = eval(mf$filename, parent.frame())
  print(x=(a=a+1))
  print("before ggsave")
  print(filename)
  print(height)
  ggsave(filename, plot=p, width=12, height=height, dpi=100)
  print("after ggsave")
  # don't return p, to supress warnings.
  # p 
}



if (FALSE) {
  qplot.dt.ff(ts_cut,nelts,data=dfaggr,colour=ChannelName, ylab="#messages", file.facets = "DatabaseName",
              filename.prefix=det.graphname.ff(outdir, runid, part, "channels-nmessages-ff-db"))
  data = dfaggr
  file.facets = "DatabaseName"
  filename.prefix=det.graphname.ff(outdir, runid, part, "channels-nmessages-ff-db-")
  
  lfn = daply(data, file.facets, function(dft) {
    # @todo replace DatabaseName
    filename = paste0(filename.prefix, dft$DatabaseName[1], ".png")
    qplot.dt(ts_cut, nelts, data=dft, colour=ChannelName, ylab="#messages", filename=filename)
    filename
  })
  
}

# 17-6-2015 wat doet deze in vgl met qplot.dt? Mogelijk ff=file.facets.
# vb: file.facets = "DatabaseName",
qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.dt")
  ddply(data, file.facets, function(dft) {
    mf$data = dft
    mf$filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    mf$filename.prefix = NULL
    mf$file.facets = NULL
    eval(mf, parent.frame())
    data.frame(filename=mf$filename)
  })
}

# vb: file.facets = "transname", filename.prefix="avg-"
qplot.gen.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.gen")
  ddply(data, file.facets, function(dft) {
    mf$data = dft
    mf$filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    mf$filename.prefix = NULL
    mf$file.facets = NULL
    eval(mf, parent.frame())
    data.frame(filename=mf$filename)
  })
}


# TODO ook splitsen op camel-Case.
label_wrap_gen3 <- function(width = 100) {
  function(variable, value) {
    value = sub("InvalidMessage", "Inv", value)
    value = sub("Channel", "", value)
    value = sub("Queue", "Q", value)
    inter <- lapply(strwrap(as.character(value), width=width, simplify=FALSE), 
                    paste, collapse="\n")
    inter <- gsub(paste0("(.{",width,"})"), "\\1\n",inter)
  }
}

