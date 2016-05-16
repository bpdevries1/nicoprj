# page weights

source("~/nicoprj/R/lib/ndvlib.R")

main = function () {
  load.def.libs()
  # deze setwd werkt ook in Windows, staat dan onder c:/nico/Ymor/Philips/Keynote.
  # @note onderstaande werkte niet op Windows in RStudio, ~ verwijst dan naar C:/Users/310118637/Documents.
  # @note maar wel als je RStudio vanuit cygwin bash start, dan is ~ goed gezet.
  setwd("~/Ymor/Philips/Keynote")
  setwd("c:/projecten/Philips/KN-Analysis/Mobile-landing-CN-20130813")
  # setwd("c:/nico/Ymor/Philips/Keynote")
  db = db.open("keynotelogs.db")
  
  # goal is distribution on x-axis, and country on y-axis. Like with MyPhilips
  
  # for now, only items without an error, so error_code < 400 (redirects are 'ok')
  query = "select r.scriptname, 1*strftime('%W', ts_utc) weeknr, 1*p.page_bytes pageweight, 1*element_count element_count, 1*p.delta_msec resptime from scriptrun r, page p where r.id = p.scriptrun_id and p.error_code < 400"
  df = db.query(db, query)

  make.distr(df, indep="scriptname", dep="pageweight", title = "Page weight distribution (bytes) per country", pngname="page-weights.png", width=9, height=3)
  make.distr(df, indep="scriptname", dep="element_count", title = "Page #elements distribution per country", pngname="page-elt-count.png", width=9, height=3)
  make.distr(df, indep="scriptname", dep="resptime", title = "Response time distribution per country", pngname="page-resptime.png", width=9, height=3)
  
  make.distr.period(df, indep="weeknr", dep="pageweight", title = "Page weight distribution (bytes) per country per week", pngname="page-weights-week.png", width=9, height=9)
  make.distr.period(df, indep="weeknr", dep="element_count", title = "Page #elements per country per week", pngname="page-elt-count-week.png", width=9, height=9)
  make.distr.period(df, indep="weeknr", dep="resptime", title = "Response time distribution per country per week", pngname="page-resptime-week.png", width=9, height=9)
  
  make.percbelow.period(df, indep="weeknr", dep="resptime", title = "Response time fraction below 8 seconds per country per week", pngname="page-frac8sec-week.png", width=9, height=9)
  
  # 22-7-2013 voor laatste week, mobile change live gegaan 18-7-2013
  query = "select r.scriptname, 1*strftime('%d', ts_cet) daynr, 1*p.page_bytes pageweight, 1*p.element_count element_count, 1*p.delta_msec resptime 
    from scriptrun r, page p where r.id = p.scriptrun_id and 1*p.error_code < 400
  and r.task_succeed = 1  
  and r.ts_cet between '2013-08-09' and '2013-08-12'"
  df = db.query(db, query)
  make.distr.period(df, indep="daynr", dep="pageweight", title = "Page weight distribution (bytes) per country per day", pngname="page-weights-day.png", width=9, height=6)
  make.distr.period(df, indep="daynr", dep="element_count", title = "Page #elements per country per day", pngname="page-elt-count-day.png", width=9, height=6)
  make.distr.period(df, indep="daynr", dep="resptime", title = "Response time distribution per country per day", pngname="page-resptime-day.png", width=9, height=6, req.line=8000)
  make.percbelow.period(df, indep="daynr", dep="resptime", title = "Response time fraction below 8 seconds per country per day", pngname="page-frac8sec-day.png", width=9, height=9)
  
  graph.agent.deps(db)
  graph.dashboard.values(db)
  
  graph.googlemaps(db)
  
  dbDisconnect(db)
}

make.percbelow.period = function(df, indep="weeknr", dep="pageweight", pngname, title, dpi=100, ...) {
  df2 = ddply(df, c("scriptname", indep), function(dfp) {
    s = subset(dfp, resptime <= 8000, select = c(resptime))
    data.frame(
      ntotal = length(dfp[, dep]),
      nsmaller8sec = length(s[, dep]),
      fracsmaller8sec = 1.0 * length(s[, dep]) / length(dfp[, dep]))})
  # qplot(daynr, fracsmaller8sec, data=df2) +
  qplot(df2[,indep], fracsmaller8sec, data=df2) +
    labs(title = title, x=indep, y="Fraction smaller than 8 seconds") +
    facet_grid(scriptname ~ ., scales="free", space="free")
  ggsave(pngname, dpi=dpi, ...) 
}
# make.percbelow.period(df, indep="daynr", dep="resptime", title = "Response time fraction below 8 seconds per country per day", pngname="page-frac8sec-day.png", width=9, height=9)



graph.agent.deps = function(db) {
  # resp time dependent on agent_id, agent_inst, profile_id or network?
  # first for whole 6w period.
  query = "select r.scriptname, 1*strftime('%W', ts_utc) weeknr, 1*p.page_bytes pageweight, 1*element_count element_count, 
     1*p.delta_msec resptime, r.provider, r.agent_id, r.agent_inst, r.profile_id, r.network, 1*r.signal_strength signal_strength, 1*no_of_resources nresources 
     from scriptrun r, page p where r.id = p.scriptrun_id and p.error_code < 400
     and r.ts_utc >= '2013-07-19'"
  df = dbGetQuery(db, query)
  # dfpngname = "page-weights.png"
  # make.distr.period(df, indep="signal_strength", dep="resptime", title = "Response time distribution (bytes) per country by signal strength", pngname="resptimes-week-signal-strength.png", width=9, height=20)

  make.boxplot(df, indep="signal_strength", dep="resptime", title="Response time distribution (msec) per country by signal strength", pngname="resptimes-signal-strength-boxplot.png")
  make.scatterplot(df, indep="signal_strength", dep="resptime", title="Response time distribution (msec) per country by signal strength", pngname="resptimes-signal-strength-scatter.png")
  
  make.boxplot(df, indep="agent_id", dep="resptime", title="Response time distribution (msec) per country by agent_id", pngname="resptimes-agentid-boxplot.png")
  make.boxplot(df, indep="agent_inst", dep="resptime", title="Response time distribution (msec) per country by agent_inst", pngname="resptimes-agentinst-boxplot.png")
  make.boxplot(df, indep="profile_id", dep="resptime", title="Response time distribution (msec) per country by profile_id", pngname="resptimes-profileid-boxplot.png")
  make.boxplot(df, indep="network", dep="resptime", title="Response time distribution (msec) per country by network", pngname="resptimes-network-boxplot.png")
  make.boxplot(df, indep="provider", dep="resptime", title="Response time distribution (msec) per country by provider", pngname="resptimes-provider-boxplot.png")
  make.boxplot(df, indep="nresources", dep="resptime", title="Response time distribution (msec) per country by #resources", pngname="resptimes-nresources-boxplot.png")
  
  make.boxplot(df, indep="agent_id", dep="signal_strength", title="signal_strength distribution per country by agent_id", pngname="signalstrength-agentid-boxplot.png")
  make.boxplot(df, indep="agent_inst", dep="signal_strength", title="signal_strength distribution per country by agent_inst", pngname="signalstrength-agentinst-boxplot.png")
  make.boxplot(df, indep="profile_id", dep="signal_strength", title="signal_strength distribution per country by profile_id", pngname="signalstrength-profileid-boxplot.png")
  make.boxplot(df, indep="network", dep="signal_strength", title="signal_strength distribution per country by network", pngname="signalstrength-network-boxplot.png")
  make.boxplot(df, indep="provider", dep="signal_strength", title="signal_strength distribution per country by provider", pngname="signalstrength-provider-boxplot.png")
  
}

# graph avg response time and availability as shown in daily dashboard. Use ts_cet to determine the date.
graph.dashboard.values = function(db) {
  query = "select strftime('%Y-%m-%d', ts_cet) date, scriptname, avg(delta_msec) resptime_avg
    from scriptrun r
    where r.error_code < 400
    group by 1,2"
  df = dbGetQuery(db, query)
  df$ts_psx = as.POSIXct(strptime(df$date, format="%Y-%m-%d"))
  qplot(ts_psx, resptime_avg, data=df, geom="line") +
    scale_y_continuous(limits=c(0, max(df$resptime_avg))) +
    labs(title = "Average response time per day (msec)", x="Date", y="Average response time (msec)") +
    facet_grid(scriptname ~ ., scales="free", space="free")
  ggsave("Avg-resptime-day.png", dpi=100, width=9, height=9) 
  
  # availability was lastiger, net zo doen als resptime < 8 sec.
  query = "select strftime('%Y-%m-%d', ts_cet) date, scriptname, 1*error_code error_code, delta_msec resptime
    from scriptrun r"
  df = dbGetQuery(db, query)
  df2 = ddply(df, .(scriptname, date), function(dfp) {
    s = subset(dfp, error_code < 400, select = c(resptime))
    data.frame(
      ntotal = length(dfp$error_code),
      navail = length(s$resptime),
      fracavail = 1.0 * length(s$resptime) / length(dfp$error_code))})
  df2$ts_psx = as.POSIXct(strptime(df2$date, format="%Y-%m-%d"))
  qplot(ts_psx, fracavail, data=df2, geom="line") +
    scale_y_continuous(limits=c(0, max(df2$fracavail))) +
    labs(title = "Availability per day", x="Date", y="Availability") +
    facet_grid(scriptname ~ ., scales="free", space="free")
  ggsave("Availability-day.png", dpi=100, width=9, height=9) 
}

graph.googlemaps = function(db) {
  query = "select r.scriptname, i.domain, 1*i.element_delta loadtime
           from scriptrun r, page p, pageitem i
           where r.id = p.scriptrun_id
           and p.id = i.page_id
           and r.ts_utc > '2013-07-20'"
  df = db.query(db, query)
  make.distr.facet(df, facet="scriptname", indep="domain", dep="loadtime", title = "Load time distribution per domain per country after July 20th", pngname="domain-loadtime-after-july20.png", width=9, height=7)

  # just google
  query = "select r.scriptname, i.domain, 1*i.element_delta loadtime
           from scriptrun r, page p, pageitem i
           where r.id = p.scriptrun_id
           and (domain like '%google%' or domain like '%gstatic%')
           and p.id = i.page_id"
  df = db.query(db, query)
  make.distr.facet(df, facet="scriptname", indep="domain", dep="loadtime", title = "Load time distribution per (google) domain per country", pngname="google-domain-loadtime.png", width=9, height=5)

  # number of items per domain, since 20-7-2013.
  # also total download time per domain.
  query = "select r.scriptname, i.domain, count(*) number, sum(element_delta) sum_loadtime
          from scriptrun r, page p, pageitem i
          where r.id = p.scriptrun_id
          and p.id = i.page_id
          and r.ts_utc > '2013-07-20'
          group by 1,2
          order by 1,2"
  df = db.query(db, query)
  make.barchart.facet(df, facet="scriptname", indep="domain", dep="number", title = "#items downloaded per domain per country", pngname="domain-nitems.png", width=9, height=7)
  make.barchart.facet(df, facet="scriptname", indep="domain", dep="sum_loadtime", title = "sum of loadtime of items downloaded per domain per country", pngname="domain-sumloadtime.png", width=9, height=7)
  
  # 1.2.3.* is maybe used by T-Mobile, find out the numbers per carrier.
  query = "select r.provider, i.domain, count(*) number, sum(element_delta) sum_loadtime
          from scriptrun r, page p, pageitem i
          where r.id = p.scriptrun_id
          and p.id = i.page_id
          and r.ts_utc > '2013-07-20'
          group by 1,2
          order by 1,2"
  df = db.query(db, query)
  make.barchart.facet(df, facet="provider", indep="domain", dep="number", title = "#items downloaded per domain per provider", pngname="provider-domain-nitems.png", width=9, height=7)
  
}

main()
