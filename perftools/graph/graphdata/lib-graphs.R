# codes:
# 0: geen metingen, hier begint het mee
# 1: goed
# 2: ontbrekende meetwaarden, verwacht er 7, zijn er bv 6.
# 3: code 2 of 3 in brondata, echte fail of timeout.

library(reshape, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(plyr,    quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

graph.errors = function(graphdata, name.title,
                        group.by = "sentinel",
                        datetime_format = "%Y-%m-%d %H:%M:%S",
                        ylab = "Result (0: no measurements, 1: ok, 2: missing data, 3: errors)", 
                        graphname.suffix = "-errors-all.png", 
                        ts.seq.by = "15 min", # normal ymonitor frequency
                        xsize = 11, 
                        outputdir = ".",
                        interactive = FALSE, ...) {
  
  graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
  ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), by=ts.seq.by)
  graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")
  
  group.by.levels = levels(as.factor(graphdata[[group.by]]))
  
  needed = dlply(graphdata, c(group.by), function (df) {
    length(levels(as.factor(df$trans)))
  })
  
  errors = ddply(graphdata, c('tscut', group.by), function (df) {
    code = ifelse(max(df$status) > 1, 3,
             ifelse(length(df$status) >= needed[[ df[[group.by]][1] ]], 1, 2))
    offset = ((length(group.by.levels) - match(df[[group.by]][1], group.by.levels)) * 0.1) 
    c(code = code + offset)          
  })

  if (xsize > 50) {
    print("xsize>50")
    qplot(tscut, code, data=errors, geom="point", colour=errors[[group.by]], shape=errors[[group.by]], main=paste("Errors (", name.title, ")", sep=""), xlab="Time", ylab=ylab) +
            opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
            scale_y_continuous(limits=c(0, 3.5)) +
            labs(colour = group.by, shape = group.by) +
            scale_x_datetime(major="6 hour",
                       minor="1 hour",
                       format="%d/%m/%Y\n%H:%M") +
            scale_shape_manual(value=0:25)                       
  } else {
    print("xsize<50")
      qplot(tscut, code, data=errors, geom="point", colour=errors[[group.by]], shape=errors[[group.by]], main=paste("Errors (", name.title, ")", sep=""), xlab="Time", ylab=ylab) +
        opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
        scale_y_continuous(limits=c(0, 3.5)) +
        labs(colour = group.by, shape = group.by) +
        scale_shape_manual(value=0:25)
  }
  
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=11, height=9, dpi=100)
  ggsave(filename=paste(outputdir,"/",name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100)  
  if (interactive) {
    print("Interactive mode")
    qp = qplot(tscut, code, data=errors, geom="point", colour=errors[[group.by]], shape=errors[[group.by]], main=paste("Errors (", name.title, ")", sep=""), xlab="Time", ylab=ylab) +
        opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
        scale_y_continuous(limits=c(0, 3.5)) +
        labs(colour = group.by, shape = group.by)
    show.interactive(qp)
    print("show.interactive returned")
  }
}

graph.errors.facet = function(graphdata, name.title,
                        group.by = "sentinel",
                        datetime_format = "%Y-%m-%d %H:%M:%S",
                        ylab = "Resultaat (0: geen metingen, 1: ok, 2: missende data, 3: errors)", 
                        graphname.suffix = "-errors-all.png", 
                        ts.seq.by = "15 min", # normal ymonitor frequency
                        facet = NULL, ncol = 7,
                        xsize = 11, ysize = 9,
                        outputdir = ".",
                        interactive = FALSE, ...) {
  print("Making error facet graph")
  
  graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
  ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), by=ts.seq.by)
  graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")
  graphdata$facet = graphdata[[facet]]
  
  print(summary(graphdata))
  
  group.by.levels = levels(as.factor(graphdata[[group.by]]))
  
  needed = dlply(graphdata, c(group.by), function (df) {
    length(levels(as.factor(df$trans)))
  })
  
  errors = ddply(graphdata, c('tscut', group.by, "facet"), function (df) {
    code = ifelse(max(df$status) > 1, 3,
             ifelse(length(df$status) >= needed[[ df[[group.by]][1] ]], 1, 2))
    offset = ((length(group.by.levels) - match(df[[group.by]][1], group.by.levels)) * 0.1) 
    c(code = code + offset)          
  })

  print(summary(errors))
  
  qplot(tscut, code, data=errors, geom="point", colour=errors[[group.by]], shape=errors[[group.by]], main=paste("Errors (", name.title, ")", sep=""), xlab="Time", ylab=ylab) +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
    scale_x_datetime(major="6 hour",
           minor="1 hour",
           format="%d/%m/%Y\n%H:%M") +
    scale_y_continuous(limits=c(0, 3.5)) +
    labs(colour = group.by, shape = group.by) +
    scale_shape_manual(value=0:25) +
    facet_wrap(~facet, ncol = ncol)  
  
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=11, height=9, dpi=100)
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=xsize, height=ysize, dpi=100)  
  ggsave(filename=paste(outputdir,"/",name.title, graphname.suffix, sep=""), width=xsize, height=ysize, dpi=100)
}

# @todo deze functie ook met ddply etc doen.
graph.times = function(graphdata, name.title,
                        group.by = "sentinel",
                        datetime_format = "%Y-%m-%d %H:%M:%S",
                        ylab = "Responsetime (sec)", 
                        graphname.suffix = "-times-all.png", 
                        ts.seq.by = "15 min", # normal ymonitor frequency.
                        outputdir = ".",
                        xsize = 11, ...) {
  
  graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
  ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), by=ts.seq.by)

  # errors = tapply(graphdata$status, list(cut(graphdata$psx_timestamp, ts.seq), graphdata[[group.by]]), det.error)
  times = tapply(graphdata$resptime, list(cut(graphdata$psx_timestamp, ts.seq), graphdata[[group.by]]), max) # det.time nodig?
  
  # keuze: overal waar geen meetwaarden zijn, def ik verder niets.
  
  times.melt = melt(times)
  colnames(times.melt) = c("ts", group.by, "maxtime")
  times.melt$ts.psx = as.POSIXct(strptime(times.melt$ts, format="%Y-%m-%d %H:%M:%S"))
  
  breaks <- as.vector(c(1, 2, 5) %o% 10^(-1:2))
  
  if (xsize > 50) {
    scale_x = scale_x_datetime(major="6 hour",
                        minor="1 hour",
                        format="%d/%m/%Y\n%H:%M")
    qplot(ts.psx, maxtime, data=times.melt, geom="point", colour=times.melt[[group.by]], shape=times.melt[[group.by]], main=paste("Max times (", name.title, ")", sep=""), xlab="Time", ylab=ylab) +
      opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
      # scale_y_continuous(limits=c(0, 3.5)) + # misschien later deze er weer bij.
      # coord_trans(y = "log") +
      scale_y_log10(breaks = breaks, labels = comma(breaks, digits = 1), limits=c(2,200)) +
      # scale_y_continuous(major = 10, minor = 1) +
      labs(colour = group.by, shape = group.by) +
      scale_x +
      scale_shape_manual(value=0:25)
  } else {
    qplot(ts.psx, maxtime, data=times.melt, geom="point", colour=times.melt[[group.by]], shape=times.melt[[group.by]], main=paste("Max times (", name.title, ")", sep=""), xlab="Time", ylab=ylab) +
      opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
      # scale_y_continuous(limits=c(0, 3.5)) + # misschien later deze er weer bij.
      # coord_trans(y = "log") +
      scale_y_log10(breaks = breaks, labels = comma(breaks, digits = 1), limits=c(2,200)) +
      # scale_y_continuous(major = 10, minor = 1) +
      labs(colour = group.by, shape = group.by) +
      scale_shape_manual(value=0:25)
  }
  
  ggsave(filename=paste(outputdir,"/",name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100)  
  
}

if (FALSE) {
  # graphdata = graphdata, 
  name.title = "test"
  group.by = "sentinel"
  datetime_format = "%Y-%m-%d %H:%M:%S"
  datetime_format = "%H:%M:%S"
  ylab = "Responstime"
  graphname.suffix = "-times-all.png" 
  ts.seq.by = "15 min"
  facet = "monthday" 
  ncol = 4
  xsize = 11
  ysize = 9  
}

graph.times.facet = function(graphdata, name.title,
                        group.by = "sentinel",
                        datetime_format = "%Y-%m-%d %H:%M:%S",
                        ylab = "Responsetime (sec)", 
                        graphname.suffix = "-times-all.png", 
                        ts.seq.by = "15 min", # normal ymonitor frequency.
                        facet = NULL, ncol = 4,
                        outputdir = ".",
                        xsize = 11, ysize = 9,  ...) {
  print("Making times facet graph...")                          
  
  graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
  print(summary(graphdata))
  ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), by=ts.seq.by)
  # bij de as.POSIXct altijd volledige datetime format meegeven.
  graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")
  graphdata$facet = graphdata[[facet]]
  # graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format=datetime_format)

  times = ddply(graphdata, c('tscut', group.by, "facet"), function (df) {
    c(maxtime = max(df$resptime))
  })
  
  breaks <- as.vector(c(1, 2, 5) %o% 10^(-1:2))
  
  qplot(tscut, maxtime, data=times, geom="point", colour=times[[group.by]], shape=times[[group.by]], main=paste("Max times (", name.title, ")", sep=""), xlab="Date/time", ylab=ylab) +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
    # scale_y_continuous(limits=c(0, 3.5)) + # misschien later deze er weer bij.
    # coord_trans(y = "log") +
    scale_x_datetime(major="6 hour",
           minor="1 hour",
           format="%d/%m/%Y\n%H:%M") +
    scale_y_log10(breaks = breaks, labels = comma(breaks, digits = 1), limits=c(2,200)) +
    # scale_y_continuous(major = 10, minor = 1) +
    labs(colour = group.by, shape = group.by) +
    scale_shape_manual(value=0:25) +
    facet_wrap(~facet, ncol = ncol) 
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=xsize, height=ysize, dpi=100)  
  ggsave(filename=paste(outputdir,"/",name.title, graphname.suffix, sep=""), width=xsize, height=ysize, dpi=100)
}

# @todo y-as hier ook logaritmisch?
graph.times.perc = function(graphdata, name.title,
                        group.by = "sentinel",
                        datetime_format = "%Y-%m-%d %H:%M:%S",
                        ylab = "Responstime (sec)",
                        xlab = "Percentiel",
                        graphname.suffix = "-times-perc.png", 
                        ts.seq.by = "15 min", # normal ymonitor frequency.
                        outputdir = ".",
                        xsize = 11, ...) {

  print("Making percentile graph...")                          
                          
  graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
  ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), by=ts.seq.by)
  graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")
  
  times = tapply(graphdata$resptime, list(cut(graphdata$psx_timestamp, ts.seq), graphdata[[group.by]]), max) # det.time nodig?
  
  # keuze: overal waar geen meetwaarden zijn, def ik verder niets.
  
  times.melt = melt(times)
  colnames(times.melt) = c("ts", group.by, "maxtime")
  times.melt$ts.psx = as.POSIXct(strptime(times.melt$ts, format="%Y-%m-%d %H:%M:%S"))
  

  maxtimes = ddply(graphdata, c('tscut', group.by), function (df) {
    c(maxtime = max(df$resptime))
  })

  maxtimes.ecdf = ddply(maxtimes, c(group.by), transform, ecdf=ecdf(maxtime)(maxtime) )
  breaks <- as.vector(c(1, 2, 5) %o% 10^(-1:2))
  qplot(ecdf, maxtime, data = maxtimes.ecdf, geom="line", colour = maxtimes.ecdf[[group.by]], 
    main=paste("Percentiles (", name.title, ")", sep=""), xlab=xlab, ylab=ylab) +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
    scale_x_continuous(formatter="percent") +
    scale_y_log10(breaks = breaks, labels = comma(breaks, digits = 1), limits=c(2,200)) +
    labs(colour = group.by, shape = group.by)    
    
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=11, height=9, dpi=100)
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100)
  ggsave(filename=paste(outputdir,"/",name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100)  
}

if (FALSE) {
  name.title = "test"
  group.by = "day"
  datetime_format = "%Y-%m-%d %H:%M:%S"
  ylab = "Responsetime (sec)"
  xlab = "Day"
  graphname.suffix = "-times-overdag-stats.png" 
  ts.seq.by = "15 min"
  xsize = 11
  
}

# stats per day, all transactions
graph.times.stats = function(graphdata, name.title,
                        group.by = "sentinel",
                        datetime_format = "%Y-%m-%d %H:%M:%S",
                        ylab = "Responsetime (sec)",
                        xlab = "Day",
                        graphname.suffix = "-times-stats.png", 
                        ts.seq.by = "15 min", # normal ymonitor frequency.
                        outputdir = ".",
                        xsize = 11, ...) {

  print("Making times stat graph...")                          
  graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
  ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), by=ts.seq.by)
  graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")
  
  times.stat = ddply(graphdata, c(group.by), function (df) {
    data.frame(stat = c("min", "avg", "p90", "max"),
               value = c(min(df$resptime), mean(df$resptime), quantile(df$resptime, .9), max(df$resptime)))
  })

  times.stat$day.psx = as.POSIXct(times.stat$day, format="%Y-%m-%d")
  
  breaks <- as.vector(c(1, 2, 5) %o% 10^(-1:2))
  
  print("before plot")
  qplot(day.psx, value, data = times.stat, geom="line", colour = stat, 
    main=paste("Daily statistics (", name.title, ")", sep=""), xlab=xlab, ylab=ylab) +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
    scale_y_log10(breaks = breaks, labels = comma(breaks, digits = 1), limits=c(0.2, 200)) +
    labs(colour = "stat")    
  
  print("before ggsave")
    
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=11, height=9, dpi=100)
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100)  
  ggsave(filename=paste(outputdir,"/",name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100)  
}

# stats per day, 90 percentile for every transaction
graph.times.p90 = function(graphdata, name.title,
                        group.by = "sentinel",
                        datetime_format = "%Y-%m-%d %H:%M:%S",
                        ylab = "Responsetime 90th percentile (sec)",
                        xlab = "Day",
                        graphname.suffix = "-times-p90.png", 
                        ts.seq.by = "15 min", # normal ymonitor frequency.
                        outputdir = ".",
                        xsize = 11, ...) {

  print("Making times p90 stat graph...")                          
  graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
  ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), by=ts.seq.by)
  graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")
  
  # genereer per group meer dan 1 row: data.frame(), maar 1 row: c()
  times.stat = ddply(graphdata, c("day", group.by), function (df) {
    # c(p90 = quantile(df$resptime, .9)) ; # this one didn't work, column was named 'p90.90%'
    data.frame(perc90 = quantile(df$resptime, .9))
  })

  times.stat$day.psx = as.POSIXct(times.stat$day, format="%Y-%m-%d")
  
  breaks <- as.vector(c(1, 2, 5) %o% 10^(-1:2))
  
  print(summary(times.stat))
  
  print("before plot")
  qplot(day.psx, perc90, data = times.stat, geom="line", colour = times.stat[[group.by]], # shape = times.stat[[group.by]],
    main=paste("Daily statistics (", name.title, ")", sep=""), xlab=xlab, ylab=ylab) +
    # opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
    # scale_y_log10(breaks = breaks, labels = comma(breaks, digits = 1), limits=c(0.2, 50)) +
    labs(colour = group.by)    
  
  print("before ggsave")
    
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=11, height=9, dpi=100)
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100) 
  ggsave(filename=paste(outputdir,"/",name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100)
}

# stats per day, 90 percentile for every transaction, facet for each sentinel
graph.times.p90.facet = function(graphdata, name.title,
                        group.by = "sentinel",
                        datetime_format = "%Y-%m-%d %H:%M:%S",
                        ylab = "Responsetime 90th percentile (sec)",
                        xlab = "Day",
                        graphname.suffix = "-times-p90.png", 
                        ts.seq.by = "15 min", # normal ymonitor frequency.
                        outputdir = ".",
                        facet = NULL, ncol = 1,
                        xsize = 11, ...) {

  print("Making times p90 stat facet graph...")                          
  graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
  ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), by=ts.seq.by)
  graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")
  graphdata$facet = graphdata[[facet]]
  
  # genereer per group meer dan 1 row: data.frame(), maar 1 row: c()
  times.stat = ddply(graphdata, c("day", group.by, "facet"), function (df) {
    # c(p90 = quantile(df$resptime, .9)) ; # this one didn't work, column was named 'p90.90%'
    data.frame(perc90 = quantile(df$resptime, .9))
  })

  times.stat$day.psx = as.POSIXct(times.stat$day, format="%Y-%m-%d")
  
  breaks <- as.vector(c(1, 2, 5) %o% 10^(-1:2))
  
  print(summary(times.stat))
  
  print("before plot")
  qplot(day.psx, perc90, data = times.stat, geom="line", colour = times.stat[[group.by]], # shape = times.stat[[group.by]],
    main=paste("Daily statistics (", name.title, ")", sep=""), xlab=xlab, ylab=ylab) +
    # opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
    labs(colour = group.by) +
    scale_y_log10(breaks = breaks, labels = comma(breaks, digits = 1), limits=c(0.2, 100)) +
    facet_wrap(~facet, ncol = ncol)    
  
  print("before ggsave")
    
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=11, height=9, dpi=100)
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100) 
  ggsave(filename=paste(outputdir,"/",name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100)
}

# stats per day, all transactions
graph.error.stats = function(graphdata, name.title,
                        group.by = "sentinel",
                        datetime_format = "%Y-%m-%d %H:%M:%S",
                        ylab = "Errors",
                        xlab = "Day",
                        graphname.suffix = "-error-stats.png", 
                        ts.seq.by = "15 min", # normal ymonitor frequency.
                        outputdir = ".",
                        xsize = 11, ...) {

  print("Making error stat graph...")                          
  graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
  ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), by=ts.seq.by)
  graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")
  
  error.stat = ddply(graphdata, c(group.by), function (df) {
    # c(mintime = min(df$resptime), avgtime = mean(df$resptime), p90time = quantile($df$resptime, .9), maxtime = max(df$resptime))
    # als dataframe
    data.frame(stat = c("failure", "timeout"),
               value = c(length(df$status[df$status == 2]), length(df$status[df$status == 3])))
  })

  error.stat$day.psx = as.POSIXct(error.stat$day, format="%Y-%m-%d")
  
  breaks <- as.vector(c(1, 2, 5) %o% 10^(-1:2))
  
  print("before plot")
  qplot(day.psx, value, data = error.stat, geom="line", colour = stat, 
    main=paste("Daily statistics (", name.title, ")", sep=""), xlab=xlab, ylab=ylab) +
    opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) +
    # scale_y_log10(breaks = breaks, labels = comma(breaks, digits = 1), limits=c(0.2, 200)) +
    labs(colour = "stat")    
  
  print("before ggsave")
    
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=11, height=9, dpi=100)
  # ggsave(filename=paste(name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100)  
  ggsave(filename=paste(outputdir,"/",name.title, graphname.suffix, sep=""), width=xsize, height=9, dpi=100)
}

# stats per day, all transactions
tsv.times.stats = function(graphdata, name.title,
                        group.by = "trans",
                        datetime_format = "%Y-%m-%d %H:%M:%S",
                        ylab = "Responsetime (sec)",
                        xlab = "Day",
                        graphname.suffix = "-times-stats.png", 
                        ts.seq.by = "15 min", # normal ymonitor frequency.
                        outputdir = ".",
                        xsize = 11, ...) {

  print("Making times stat tsv...")                          
  graphdata$psx_timestamp = strptime(graphdata$meas_time, format=datetime_format)
  ts.seq = seq(from=min(graphdata$psx_timestamp, na.rm=TRUE), to=max(graphdata$psx_timestamp, na.rm=TRUE), by=ts.seq.by)
  graphdata$tscut = as.POSIXct(cut(graphdata$psx_timestamp, ts.seq), format="%Y-%m-%d %H:%M:%S")
  
  times.stat = ddply(graphdata, c(group.by), function (df) {
    c(min = min(df$resptime), avg = mean(df$resptime), p90 = quantile(df$resptime, .9), max = max(df$resptime))
  })

  write.table(times.stat, "times-stats.tsv", sep="\t", quote=FALSE, row.names = FALSE)

}



show.interactive = function (qp) {
  library(tcltk,   quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
  
  refreshPressed <- function() {
    print("button pressed")
    print(paste("van: ", tclvalue(vanText)))
    print(paste("tot: ", tclvalue(totText)))
    tsfmt = "%Y-%m-%d %H:%M:%S"
    defstart = "2010-01-01 00:00:00"
    defend = "2020-01-01 00:00:00"
    tsstr1 = paste(tclvalue(vanText), substr(defstart, nchar(tclvalue(vanText)) + 1, nchar(defstart)), sep="")
    tsstr2 = paste(tclvalue(totText), substr(defend, nchar(tclvalue(totText)) + 1, nchar(defend)), sep="")
    ts1 = as.POSIXct(strptime(tsstr1, format=tsfmt))
    ts2 = as.POSIXct(strptime(tsstr2, format=tsfmt))
    print(qp + scale_x_datetime(limits=c(ts1, ts2)))
  }
  
  tt <- tktoplevel()
  tkwm.title(tt,"Change start and end timestamps for graph.")
  vanText = tclVar("")
  totText = tclVar("")
  evan <- tkentry(tt,text=tclvalue(vanText))
  etot <- tkentry(tt,text=tclvalue(totText))
  tkconfigure(evan, textvariable=vanText)
  tkconfigure(etot, textvariable=totText)
  lvan <- tklabel(tt, text="Van:")
  ltot <- tklabel(tt, text="Tot:")
  btRefresh = tkbutton(tt, text="Refresh", command=refreshPressed)
  tkgrid(lvan, evan, ltot, etot, btRefresh)
  tkfocus(tt)
  
  # hier nu een wacht lus nodig? of blijft 'ie automatisch wachten.
  print("vwait forever: start")
  .Tcl("vwait forever")
  print("vwait forever: finished")
  
}


