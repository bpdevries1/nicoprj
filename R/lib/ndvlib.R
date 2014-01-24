# ndvlib.R - general R functions to use
# note: make it a package sometime, but first just source the thing.

load.def.libs = function() {
  library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
  library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
  library(plyr)
  library(stringr)
  library(reshape2)
  library(grid) # for unit, met legends.
  library(scales) # for ticks per hour.
  library(sqldf) # for query-ing dataframes.
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

# always forget about paste, so use concat as an alias.
concat = function(...) {
  paste0(...)
}

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

add.psxtime = function(df, from, to, format="%Y-%m-%d") {
  df[,to] = as.POSIXct(strptime(df[,from], format=format))
  df
}

# df = add.psxtime(db.query(db, query), "ts_cet", "psx_date", format="%Y-%m-%d %H:%M:%S")

# add ts_psx if ts is present as a field in result of query
# add date_psx if date is present as a field in result of query
# first try is add fields blindly, possibly with null values
# second try is to check which fields are available,
# or add a try-catch.

# [2013-10-25 14:09:15] stond er dubbel in, geen idee waarom...
# db.query.dt = function(db, query) {
#   df = db.query(db, query)
#   if (match("ts", colnames(df)) > 0) {
#     df$ts_psx = as.POSIXct(strptime(df$ts, format="%Y-%m-%d %H:%M:%S"))
#   }
#   if (match("date", colnames(df)) > 0) {
#     df$date_psx = as.POSIXct(strptime(df$date, format="%Y-%m-%d"))
#   }
#   df
# }

db.query.dt = function(db, query) {
  df = db.query(db, query)
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

det.height = function(height.min, height.max, height.base, height.perfacet, facets, height.percolour, colours, legend.position = "") {
  # base height should include height for 1 facet.
  height = height.base
  if (height.perfacet > 0) {
    nfacets = length(levels(as.factor(facets)))
    height = height + (nfacets-1) * height.perfacet
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
