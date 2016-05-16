open.libs = function() {
  library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
  library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
  library(plyr, quietly=TRUE)
}

open.db = function(db_name) {
  db = dbConnect(dbDriver("SQLite"), db_name)  
  db
}

open.query = function(db, query) {
  df = dbGetQuery(db, query)
  df$tspsx = strptime(df$ts, format="%Y-%m-%d %H:%M:%S")
  df$tsct = as.POSIXct(df$tspsx)
  df$tslt = as.POSIXlt(df$tspsx)
  df
}

plot.multi = function(db, query, title="", filename=paste(title, ".png", sep=""), dpi=100, width=11, height=9) {
  df = open.query(db, query)
  qpl = qplot(tspsx, value, data=df) +
    facet_grid(name ~ ., scales = "free_y") +
    xlab("Timestamp") +
    opts(title = title)
  print(qpl)
  height = adjust.height(df, 10, height)
  ggsave(filename, dpi=dpi, width=width, height=height)
  qpl
}

plot.multi.play = function(db, query, title="", filename=paste(title, ".png", sep=""), dpi=100, width=11, height=9) {
  df = open.query(db, query)
  playwith(qplot(tspsx, value, data=df) +
    facet_grid(name ~ ., scales = "free_y") +
    xlab("Timestamp") +
    opts(title = title))
}

adjust.height = function(df, MAX_NGR, height) {
  names = unique(df$name)
  ngr = length(names)
  maxchar = max(nchar(names))
  if (ngr > MAX_NGR) {
    height.per.graph = max(12, maxchar)
    ngr * (height / MAX_NGR) * (height.per.graph / 12)
  } else {
    height
  }
}

plot.single = function(db, query, title="", filename=paste(title, ".png", sep=""), dpi=100, width=11, height=9) {
  df = open.query(db, query)
  qpl = qplot(tspsx, value, data=df) +
    xlab("Timestamp")
  print(qpl)
  ggsave(filename, dpi=dpi, width=width, height=height)
  qpl
}

plot.single.tsgrp = function(db, query, title="", filename=paste(title, ".png", sep=""), dpi=100, width=11, height=9, nmins=1) {
  df = openquery(db, query)
  
  ts.seq = seq(from=min(df$tspsx, na.rm=TRUE), to=max(df$tspsx, na.rm=TRUE), by = as.difftime(nmins, units="mins"))
  df$tscut=cut(df$tspsx, ts.seq)
  df2 = ddply(df, .(tscut), function(df) {
    data.frame(aantal = sum(df$aantal))
  })
  df2$tspsx = strptime(df2$tscut, format="%Y-%m-%d %H:%M:%S")
  qpl = qplot(tspsx, aantal, data=df2) +
    xlab("Timestamp")
  print(qpl)
  ggsave(filename, dpi=dpi, width=width, height=height)
  qpl
}
