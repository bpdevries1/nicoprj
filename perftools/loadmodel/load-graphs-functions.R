init = function() {
  library(ggplot2)
  library(RSQLite)
  
  db_name = "model.db"
  db = dbConnect(dbDriver("SQLite"), db_name)
  db
}

make.iter = function(df, looptijd, full = FALSE, time2show = ifelse(full, looptijd, min(looptijd, 2*max(df$secrampup))), random=TRUE) {
  vu.start = ddply(df, .(script, itersec, pacing), function(df) {
    data.frame(vu.nr = 1:df$vusers, start = sort(rep(seq(0, df$secrampup, df$rampevery), df$vusersper)))     
  })
  vu.start$vu.nra = row.names(vu.start)
  
  # time2show = ifelse(full, looptijd, min(looptijd, 2*max(df$secrampup)))  

  iter = ddply(vu.start, .(script, vu.nra, vu.nr), looptijd = time2show, function(df, looptijd=NULL) {
    # per vuser, eerste random value is 0
    if (random) {
      cumsum.rnd = c(0, cumsum(runif((looptijd - df$start) / df$pacing, -10, 10)))
      data.frame(start = seq(df$start, looptijd, df$pacing) + cumsum.rnd, end = sapply(seq(df$start + df$itersec, looptijd + df$itersec, df$pacing) + cumsum.rnd, function (val) {min(c(val, looptijd))}))
    } else {
      data.frame(start = seq(df$start, looptijd, df$pacing), end = sapply(seq(df$start + df$itersec, looptijd + df$itersec, df$pacing), function (val) {min(c(val, looptijd))}))
    }
  })
  iter
}

plot.iter = function(iter) {
  qplot(data=iter, x=start, y=as.integer(vu.nra),  xend = end, yend = as.integer(vu.nra), 
    geom="segment", colour = script, xlab = "Time", ylab = "(v)user")  +
   opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1))
}

make.count = function(iter) {
  df.step1 = ddply(iter, .(start), function (df) {data.frame(ts=df$start[1], step=length(df$start))})
  df.step2 = ddply(iter, .(end), function (df) {data.frame(ts=df$end[1], step=-length(df$end))})
  df.step = subset(rbind.fill(df.step1, df.step2), select=c(ts,step)) 
  
  # eerst samenvoegen, dan arrange
  df.steps = arrange(ddply(df.step, .(ts), function(df) {c(step=sum(df$step))}), ts)
  df.steps$count = cumsum(df.steps$step) # werkt omdat het sorted is.
  df.steps
}

plot.count = function(df.count) {
  qplot(data=df.count, x=ts, y=count, geom="step", xlab = "Time", ylab = "#vusers")
}


