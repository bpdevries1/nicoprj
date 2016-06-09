# ndvlib.R - general R functions to use
# note: make it a package sometime, but first just source the thing.

# TODO split into useful sub-files, as libndv.tcl.

# install.packages("gsubfn")
# sudo apt-get install tcl8.5-dev tk8.5-dev 
# NOT: install.packages("tcltk"), door apt-get hierboven komt het goed.
# install.packages("proto")
# install.packages("gsubfn")
# install.packages("chron")
# install.packages("sqldf")
# install.packages("digest")
# install.packages("ggplot2", dependencies=TRUE) -> werkt ook niet zo lekker
# install.packages("gtable")
# install.packages("plyr")
# install.packages("stringr")
# install.packages("reshape2")
# install.packages("colorspace")
# install.packages("munsell")
# install.packages("scales")
# install.packages("RColorBrewer")
# install.packages("Formula")
# install.packages("ggplot2", dependencies=TRUE)
# install.packages("Hmisc") -> laat maar even zitten, niet nodig nu.

# 28-6-2015 deze bestaat niet meer? Maar nog wel nodig?
# install.packages("RSQLite.extfuns")

load.def.libs = function() {
  library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
  library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
  library(plyr)
  library(stringr)
  library(reshape2)
  library(grid) # for unit, met legends.
  library(scales) # for ticks per hour.
  library(sqldf) # for query-ing dataframes.
  library(labeling) # for labels
  # blijkbaar ook RSQLite.extfuns nodig
  # library(RSQLite.extfuns)
}

db.open = function(db.name) {
  dbConnect(dbDriver("SQLite"), db.name)
}

db.close = function(db) {
  dbDisconnect(db)
}



db.query = function(db, query) {
  dbGetQuery(db, query)
}

db.exec = function(db, query) {
  res = dbSendQuery(db, query)
  dbClearResult(res)
}

# always forget about paste, so use concat as an alias.
# zou concat = paste0 ook kunnen? Idd!
concat = paste0
#concat = function(...) {
#  paste0(...)
#}

# check if R/RStudio are started from cygwin (in windows) so ~ is set to c:/nico
check.cygwin = function() {
  shell = Sys.getenv("SHELL") # should be something like /bin/bash.
  if (shell == "") {
    print("WARN: not started from (cygwin) bash, ~ is probably not set correctly!")    
    print("value of SHELL is empty")    
  } else {
    if (grep("bash", shell)) {
      print("Ok, started from (cygwin) bash") 
    } else {
      print("WARN: not started from (cygwin) bash, ~ is probably not set correctly!")    
      print(concat("value of SHELL is: ", shell))
    }
  }
}

check.cygwin()

#######################################################################################
# Some more specific functions, they look generic enough, see if they are reusable... #
#######################################################################################

# make a distribution graph from a data.frame df, with an indep(endent) and a dep(endent) column in the df.
# example call: make.distr(df, indep="scriptname", dep="pageweight", title = "Page weight distribution (bytes) per country", pngname="page-weights.png", width=9, height=3)
make.distr = function(df, indep="scriptname", dep="pageweight", pngname, title, dpi=100, ...) {
  df2 = ddply(df, c(indep), function(dfp) {
    data.frame(
                min = min(dfp[, dep]),
                max = max(dfp[, dep]),
                avg = mean(dfp[,dep]),
                q05 = quantile(dfp[, dep], 0.05),
                q25 = quantile(dfp[, dep], 0.25),
                q45 = quantile(dfp[, dep], 0.45),
                q55 = quantile(dfp[, dep], 0.55),
                q75 = quantile(dfp[, dep], 0.75),
                q95 = quantile(dfp[, dep], 0.95))})
  n.indep = length(df2[,indep])
  df2$nameAlt = 1:n.indep
  
  max.size = max(df2$q95)
  ggplot(df2, aes(ymin = nameAlt - 0.2,ymax = nameAlt + 0.2)) + 
    geom_rect(aes(xmin = q05,xmax = q95),fill = "white",colour = "black") + 
    geom_rect(aes(xmin = q25,xmax = q75),fill = 'lightblue',colour = "black") +
    geom_rect(aes(xmin = q45,xmax = q55),fill = 'blue',colour = "black") +
    geom_rect(aes(xmin = min, xmax = min), colour = "red") +
    geom_rect(aes(xmin = max, xmax = max), colour = "red") +
    geom_rect(aes(xmin = avg, xmax = avg), colour = "red") +
    scale_y_continuous(breaks = 1:n.indep, labels = df2[,indep]) +
    scale_x_continuous(limits=c(0, 1.1*max.size)) +
    labs(title = title, x=dep, y=indep)
  
  ggsave(pngname, dpi=dpi, ...) 
}

# make a distribution graph from a data.frame df, with an indep(endent) and a dep(endent) column in the df.
# also supply a facet field here.
# similar to make.distr
# example call: make.distr.period(df, indep="weeknr", dep="pageweight", title = "Page weight distribution (bytes) per country per week", pngname="page-weights-week.png", width=9, height=9)
make.distr.facet = function(df, facet="scriptname", indep="weeknr", dep="pageweight", pngname, title, dpi=100, req.line = -1, ...) {
  df2 = ddply(df, c(facet, indep), function(dfp) {
    data.frame(
      min = min(dfp[, dep]),
      max = max(dfp[, dep]),
      avg = mean(dfp[,dep]),
      q05 = quantile(dfp[, dep], 0.05),
      q25 = quantile(dfp[, dep], 0.25),
      q45 = quantile(dfp[, dep], 0.45),
      q55 = quantile(dfp[, dep], 0.55),
      q75 = quantile(dfp[, dep], 0.75),
      q95 = quantile(dfp[, dep], 0.95))})
  n.indep = length(df2[,indep])
  df2$nameAlt = 1:n.indep
  
  # max.size = max(df2$q95)
  max.size = max(df2$max)
  p = ggplot(df2, aes(ymin = nameAlt - 0.2,ymax = nameAlt + 0.2)) + 
    geom_rect(aes(xmin = q05,xmax = q95),fill = "white",colour = "black") + 
    geom_rect(aes(xmin = q25,xmax = q75),fill = 'lightblue',colour = "black") +
    geom_rect(aes(xmin = q45,xmax = q55),fill = 'blue',colour = "black") +
    geom_rect(aes(xmin = min, xmax = min), colour = "red") +
    geom_rect(aes(xmin = max, xmax = max), colour = "red") +
    geom_rect(aes(xmin = avg, xmax = avg), colour = "red") +
    scale_y_continuous(breaks = 1:n.indep,labels = df2[,indep]) +
    scale_x_continuous(limits=c(0, max.size)) +
    labs(title = title, x=dep, y=indep) +
    # facet_grid(scriptname ~ ., scales="free_y")
    facet_grid(concat(facet, " ~ ."), scales="free_y", space="free_y")
  if (req.line != -1) {
    p = p +
      geom_vline(xintercept=req.line, linetype="solid", colour = "red")
  }
  p
  
  ggsave(pngname, dpi=dpi, ...) 
}

# @deprecated (already), use make.distr.facet
make.distr.period = function(...) {
  make.distr.facet(...)
}

# make a distribution graph from a data.frame df, with an indep(endent) and a dep(endent) column in the df.
# also supply a facet field here.
# similar to make.distr
# example call: make.distr.period(df, indep="weeknr", dep="pageweight", title = "Page weight distribution (bytes) per country per week", pngname="page-weights-week.png", width=9, height=9)
make.barchart.facet = function(df, facet="scriptname", indep="weeknr", dep="pageweight", pngname, title, dpi=100, ...) {
  max.size = max(df[,dep])
  df$dep = df[,dep]
  fct.indep = factor(df[,indep])
  n.indep = length(fct.indep)
  df$nameAlt = 1:n.indep
  
  ggplot(df, aes(ymin = nameAlt - 0.2,ymax = nameAlt + 0.2)) + 
    geom_rect(aes(xmin = 0,xmax = dep),fill = 'blue',colour = "black") +
    scale_y_continuous(breaks = 1:n.indep,labels = df[,indep]) +
    scale_x_continuous(limits=c(0, max.size)) +
    labs(title = title, x=dep, y=indep) +
    facet_grid(concat(facet, " ~ ."), scales="free_y", space="free_y")
  ggsave(pngname, dpi=dpi, ...) 
}

# example: make.boxplot(df, indep="signal_strength", dep="resptime", title="Response time distribution (msec) per country by signal strength", pngname="resptimes-signal-strength-boxplot.png")
make.boxplot = function(df, indep, dep, title, pngname, width=12, height=9, ...) {
  df$fct = factor(df[, indep])
  ggplot(df, aes_string(x="fct", y=dep)) +
    geom_boxplot()  +
    labs(title = title, x=indep, y=dep) +
    facet_grid(scriptname ~ ., scales="free", space="free")
  ggsave(pngname, dpi=100, width=width, height=height, ...) 
}

# example: make.scatterplot(df, indep="signal_strength", dep="resptime", title="Response time distribution (msec) per country by signal strength", pngname="resptimes-signal-strength-scatter.png")
make.scatterplot = function(df, indep, dep, title, pngname, width=12, height=9, ...) {
  df$fct = factor(df[, indep])
  ggplot(df, aes(fct, resptime)) +
    geom_point()  +
    labs(title = title, x=indep, y=dep) +
    facet_grid(scriptname ~ ., scales="free", space="free")
  ggsave(pngname, dpi=100, width=width, height=height, ...) 
}

add.psxtime = function(df, from, to, format="%Y-%m-%d %H:%M:%OS") {
  df[,to] = as.POSIXct(strptime(df[,from], format=format))
  df
}

# add ts_psx if ts is present as a field in result of query
# add date_psx if date is present as a field in result of query
# first try is add fields blindly, possibly with null values
# second try is to check which fields are available,
# or add a try-catch.
# Used from R-wrapper.tcl
db.query.dt = function(db, query) {
  df = db.query(db, query)
  df.add.dt(df)
}

# als kolom met ts_ begint, dan .psx toevoegen.
# for met evt ook filter erbij.
df.add.dt = function(df) {
  for (colname in colnames(df)[grep("^ts", colnames(df))]) {
    df[,paste0(colname,".psx")] = as.POSIXct(strptime(df[,colname], format="%Y-%m-%d %H:%M:%S"))
  }
  if ("date" %in% colnames(df)) {
    # df$date_psx = as.POSIXct(strptime(df$date, format="%Y-%m-%d"))
    # df$date_date = as.Date(df$date, "%Y-%m-%d")
    # @todo rename field to date_parsed, and ts_parsed, cause format is not Posix always.
    df$date_Date = as.Date(df$date, "%Y-%m-%d")
    # df$date_psx = as.POSIXct(strptime(df$date, format="%Y-%m-%d", tz="UTC"))
    # df$date_psx = as.POSIXct(strptime(df$date, format="%Y-%m-%d", tz="GMT"))
  }
  if ("time" %in% colnames(df)) {
    df$time_psx = as.POSIXct(strptime(df$time, format="%H:%M:%S"))
  }
  df
}

df.add.dt.orig = function(df) {
  if ("ts" %in% colnames(df)) {
    df$ts_psx = as.POSIXct(strptime(df$ts, format="%Y-%m-%d %H:%M:%S"))
  }
  if ("date" %in% colnames(df)) {
    # df$date_psx = as.POSIXct(strptime(df$date, format="%Y-%m-%d"))
    # df$date_date = as.Date(df$date, "%Y-%m-%d")
    # @todo rename field to date_parsed, and ts_parsed, cause format is not Posix always.
    df$date_Date = as.Date(df$date, "%Y-%m-%d")
    # df$date_psx = as.POSIXct(strptime(df$date, format="%Y-%m-%d", tz="UTC"))
    # df$date_psx = as.POSIXct(strptime(df$date, format="%Y-%m-%d", tz="GMT"))
  }
  if ("time" %in% colnames(df)) {
    df$time_psx = as.POSIXct(strptime(df$time, format="%H:%M:%S"))
  }
  df
}

# determine sprintf format string based on values in vct (vector) and ndigits after decimal point.
# eg maxval = 123.456, ndigits = 3 => result = '[%6.3d] '. The 6 is the total number of digits
det.fmt.string = function(vct, ndigits) {
  # totaldigits includes the decimal point, so add 1.
  m = max(vct)
  if (m > 0) {
    totaldigits = ndigits + ceiling(log10(max(vct))) + 1
  } else {
    # eg no values, max=-Inf, return default format string.
    totaldigits = ndigits + 2;    
  }
  concat('[%', totaldigits, '.', ndigits, 'f] ')
}

# Used from R-wrapper.tcl
det.height = function(height.min, height.max, height.base, height.perfacet, facets, height.percolour, colours, legend.position = "") {
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
      height.colours = ncolours * height.percolour
      if (height.colours > height) {
        height = height.colours
      }
    } else {
      height = height + ncolours * height.percolour
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

print.log = function(str) {
  # print(concat(format(Sys.time(), "[%Y-%m-%d %H:%M:%S] "), str))
  cat(concat(format(Sys.time(), "[%Y-%m-%d %H:%M:%S] "), str, "\n"))
}

# return data.frame based on df with per timestamp number of active/concurrent
# actions based on startcol and endcol, which should be timestamps (posix),
# or other numeric values.
# cnt = det.nconc(df, "ts_cet_start.psx", "ts_cet_end.psx")
det.nconc = function(df, startcol, endcol) {
  df.step1 = ddply(df, c(startcol), function (df) {
    data.frame(ts=df[1,startcol], step=length(df[,startcol]))})
  df.step2 = ddply(df, c(endcol), function (df) {
    data.frame(ts=df[1,endcol], step=-length(df[,endcol]))})
  df.step = subset(rbind.fill(df.step1, df.step2), select=c(ts,step)) 
  
  # eerst samenvoegen, dan arrange
  df.steps = arrange(ddply(df.step, .(ts), function(df) {
    c(step=sum(df$step))}), ts)
  df.steps$count = cumsum(df.steps$step) # werkt omdat het sorted is.
  df.steps$ts_psx = df.steps$ts
  df.steps  
}

graph.conc = function(df, startcol, endcol, ylab, filename, width=12, height=7) {
  cnt = det.nconc(df, startcol, endcol)
  qplot(data=cnt, x=ts_psx, y=count, geom="step", xlab=NULL, ylab = ylab) +
    scale_y_continuous(limits=c(0, max(cnt$count))) +
    scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M:%OS"))
  ggsave(filename=filename, width=width, height=height, dpi=100)
  write.csv(cnt, file=paste0(filename,".csv"))
}

# TODO: hier een algemene facet van te maken, waarbij je aangeeft wat de single graph functie is?
graph.gantt.facet = function(df, startcol, endcol, ycol, colourcol, facetcol, filename.prefix, lwd=10, width=12) {
  print("graph.gantt.facet: start")
  d_ply(df, c(facetcol), function(dft) {
    if (det.height.ycol(dft, ycol) > 2.2) {
      filename = paste0(filename.prefix , dft[1,facetcol], ".png")
      graph.gantt(dft, startcol, endcol, ycol, colourcol, filename)   
    }
  })
  print("graph.gantt.facet: finished")
}

graph.gantt = function(df, startcol, endcol, ycol, colourcol, filename, lwd=10, width=12) {
  if (det.height.ycol(df, ycol) > 2.2) {
    # minimaal 2 threads.
    # [2016-06-07 15:58:15] guide_legend lijkt hier niet nodig.
    g = guide_legend(colourcol, ncol=6)
    qplot(x=df[,startcol], xend=df[,endcol], y=df[,ycol], yend=df[,ycol], colour = df[,colourcol], lwd=lwd, data=df, 
          geom="segment", xlab = NULL, 
          main = sprintf("Requests in period: %d",
                         df$period_id[1])) +
      ylab(ycol) +
      scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M:%OS")) +
      # scale_y_discrete(limits = rev(levels(as.factor(df$Thread_Name)))) + 
      scale_y_discrete(limits = rev(levels(as.factor(df[,ycol])))) + 
      scale_colour_discrete(name=colourcol) +
      scale_shape_manual(name=colourcol, values=rep(1:25,10)) +
      guides(colour = g, shape = g, lwd=FALSE) +
      # guides(lwd=FALSE) +
      theme(legend.position="bottom")
    
    ggsave(filename=filename, width=12, height=det.height.ycol(df, ycol), dpi=100, limitsize=FALSE)
  }
}

det.height.ycol = function(df, ycol) {
  df1 = ddply(df, c(ycol), function(dft) {c(n=1)})
  2 + 0.20 * nrow(df1)
}

