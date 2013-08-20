source("~/nicoprj/R/lib/ndvlib.R")

main = function () {
  load.def.libs()
  # deze setwd werkt ook in Windows, staat dan onder c:/nico/Ymor/Philips/Keynote.
  # @note onderstaande werkte niet op Windows in RStudio, ~ verwijst dan naar C:/Users/310118637/Documents.
  # @note maar wel als je RStudio vanuit cygwin bash start, dan is ~ goed gezet.
  # setwd("c:/projecten/Philips/KNDL")
  setwd("c:/projecten/Philips/KN-Analysis")
  # in principe 1 DB met 1 script, alleen mobile is anders, daar losse functie voor.
  scriptname = "MyPhilips-CN-test"
  scriptname = "MyPhilips-DE-test"
  graph.main("MyPhilips-CN")
  graph.main("MyPhilips-DE-test")
  setwd("c:/projecten/Philips/KN-Analysis")
  graph.mobile("Mobile-landing-CN")
  graph.mobile("Mobile-landing-CN-20130813", ishwap=FALSE, max.date='2013-08-13')
  graph.mobile("Mobile-CN-search", ishwap=FALSE)
  graph.mobile("Mobile-CN-compare", ishwap=FALSE)
  
  graph.network("Mobile-landing-CN")
}

# goals:
# graphs of all (6 or more) weeks and of last week
# graphs of 1) al points (scatter), avg per day (as dashboard, incl numbers, avg of pages), distr per day
# also availabilty and response time graphs, first only response times.
# also maybe report total time as well as time to interactive and other values.
# this function is not for Mobile, because it has 3 scripts in the database.
graph.main = function(scriptname) {
  setwd(scriptname)
  db = db.open("keynotelogs.db")

  # first the dashboard graph (with numbers)
  # @todo determine number of pages in this script.
  # @todo what runs have errors, and which don't. Maybe need to check at page level or even page item.
  query = "select strftime('%Y-%m-%d', ts_cet) date, 0.001*avg(delta_msec) / 3 pageloadtime, 0.001*avg(trans_level_comp_msec) / 3 trans_level, 0.001*avg(delta_user_msec) / 3 delta_user
           from scriptrun
           where ts_cet >= '2013-07-27'
           group by 1
           order by 1"
  df = db.query(db, query)
  df = add.psxtime(df, "date", "psx_date")
  
  max.size = max(df$pageloadtime)
  #max.size = max(df$delta_user)
  # @todo don't put font size = 10 in the legend.
  # @todo how to set colour to green or blue (colour = 1, colour = 1000, colour = "blue" do strange things)
  qplot(psx_date, pageloadtime, data=df, geom="line") +
    labs(title = concat("Average page load time per day for: ", scriptname), x="Date", y="Page load time (sec)") +
    scale_y_continuous(limits=c(0, max.size)) +
    geom_text(aes(psx_date, pageloadtime, label=sprintf("%.1f", pageloadtime)), hjust = 0, vjust = 0,
              colour="blue", data=df)
  
  #qplot(psx_date, delta_user, data=df, geom="line") +
  #  labs(title = concat("Average page load time per day for: ", scriptname), x="Date", y="Page load time (sec)") +
  #  scale_y_continuous(limits=c(0, max.size)) +
  #  geom_text(aes(psx_date, delta_user, label=sprintf("%.1f", delta_user), group=NULL),data=df)
  
  ggsave(concat(scriptname, "-avg-pageload-per-day.png"), dpi=100, width = 9, height=7)
  db.close(db)
  setwd("..")
}

add.psxtime = function(df, from, to, format="%Y-%m-%d") {
  df[,to] = as.POSIXct(strptime(df[,from], format=format))
  df
}

graph.mobile = function(scriptname="Mobile-landing", ishwap=TRUE, max.date='2015-12-31') {
  setwd(scriptname)
  db = db.open("keynotelogs.db")

  if (ishwap) {
    graph.mobile.ishwap(scriptname, db)
  }
  graph.mobile.dashboard(scriptname, db, max.date)
  
  db.close(db)
  setwd("..")
}

graph.mobile.ishwap = function(scriptname, db) {
  query = "select strftime('%Y-%m-%d', ts_cet) date, 0.001*avg(delta_msec) pageloadtime
             from run_res
             where task_succeed = 1
             group by 1
             order by 1"
  df = db.query(db, query)
  df.all = add.psxtime(df, "date", "psx_date")
  
  query2 = "select strftime('%Y-%m-%d', ts_cet) date, 0.001*avg(delta_msec) pageloadtime
             from run_res
             where task_succeed = 1
             and ishwap = 0
             group by 1
             order by 1"
  df2 = db.query(db, query2)
  df.ok = add.psxtime(df2, "date", "psx_date")
  
  max.size = max(df.all$pageloadtime)
  qplot(psx_date, pageloadtime, data=df.all, geom="line") +
    labs(title = concat("Average page load time per day for: ", scriptname), x="Date", y="Page load time (sec)") +
    scale_y_continuous(limits=c(0, max.size)) +
    geom_line(aes(psx_date, pageloadtime), colour="blue", data=df.ok)
  ggsave(concat(scriptname, "-avg-pageload-per-day-ishwap.png"), dpi=100, width = 9, height=7)
  
  query = "select strftime('%Y-%m-%d', ts_cet) date, count(*) number
             from run_res
             where task_succeed = 1
             and ishwap = 1
             group by 1
             order by 1"
  df = db.query(db, query)
  df = add.psxtime(df, "date", "psx_date")
  max.size = max(df$number)
  qplot(psx_date, number, data=df, geom="point") +
    labs(title = concat("Count of ishwap measurements giving ok per day for: ", scriptname), x="Date", y="Count") +
    scale_y_continuous(limits=c(0, max.size))
  ggsave(concat(scriptname, "-count-ishwap-per-day.png"), dpi=100, width = 9, height=5)
  
  # plot count vs hour of day
  query = "select strftime('%H', ts_cet) hour, count(*) number
             from run_res
             where task_succeed = 1
             and ishwap = 1
             group by 1
             order by 1"
  plot.point(db, query, indep="hour", dep="number", title = "Count of ishwap measurements giving ok per hour")
}

plot.date = function(db, query, indep="date", dep="number", title, width=9, height=7) {
  df = db.query(db, query)
  df = add.psxtime(df, indep, "psx_date")
  # max.size = max(df$number)
  df$dep = df[,dep]
  max.size = max(df$dep)
  qplot(psx_date, dep, data=df, geom="point") +
    labs(title = title, x=indep, y=dep) +
    scale_y_continuous(limits=c(0, max.size))
  ggsave(concat(title, ".png"), dpi=100, width = width, height=height)
}

plot.point = function(db, query, indep, dep="number", title, width=9, height=7) {
  df = db.query(db, query)
  # df = add.psxtime(df, indep, "psx_date")
  # max.size = max(df$number)
  df$indep = df[,indep]
  df$dep = df[,dep]
  max.size = max(df$dep)
  qplot(indep, dep, data=df, geom="point") +
    labs(title = title, x=indep, y=dep) +
    scale_y_continuous(limits=c(0, max.size))
  ggsave(concat(title, ".png"), dpi=100, width = width, height=height)
}

graph.mobile.dashboard = function(scriptname, db, max.date) {
  # don't include current day, as it is not finished yet, and avg may still change
  query = "select scriptname, strftime('%Y-%m-%d', ts_cet) date, 0.001*avg(delta_msec) pageloadtime
             from scriptrun
             where task_succeed = 1
             and ts_cet > '2013-07-10'
             and ts_cet < '2013-08-13'
             group by 1,2
             order by 1,2"
  df = db.query(db, query)
  df.all = add.psxtime(df, "date", "psx_date")
  # and ts_cet < strftime('%Y-%m-%d', 'now')
  max.size = max(df.all$pageloadtime)
  qplot(psx_date, pageloadtime, data=df.all, geom="line") +
    labs(title = concat("Average page load time per day for: ", scriptname), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_text(aes(psx_date, pageloadtime, label=sprintf("%.1f", pageloadtime)), hjust = 0, vjust = 0,
              colour="blue", data=df.all) +
    geom_hline(yintercept=8, linetype="solid", colour = "red") +
    facet_grid(scriptname ~ ., scales="free_y")
  
  ggsave(concat(scriptname, "-avg-pageload-per-day.png"), dpi=100, width = 11, height=9)
}

graph.network = function(scriptname="Mobile-landing-CN-20130813") {
  setwd(scriptname)
  db = db.open("keynotelogs.db")
  
  graph.network.scatter(db, "element_delta")
  graph.network.scatter(db, "dns_delta")
  graph.network.scatter(db, "connect_delta")
  graph.network.scatter(db, "first_packet_delta")
  graph.network.scatter(db, "remain_packets_delta")
  graph.network.scatter(db, "request_delta")
  
  # graph.mobile.dashboard(scriptname, db)
  graph.network.distr.domains(db)
  graph.network.distr.items(db)
  
  db.close(db)
  setwd("..")
}

# note see correlation only with datepoints having too high page load time.
graph.network.scatter = function(db, yfield="element_delta") {
  query = concat("select  i.domain, r.id, 0.001*r.delta_msec pageloadtime, 0.001 * sum(i.", yfield, ") yvalue
                 from scriptrun r, pageitem i, run_res rr
                 where r.id = rr.scriptrun_id
                 and r.id = i.scriptrun_id
                 and r.task_succeed = 1
                 and rr.ishwap = 0
                 and r.ts_cet > '2013-08-01'
                 and r.scriptname = 'Mobile_CN'
                 and i.domain != 'philips.112.2o7.net'
                 and 0.001*r.delta_msec > 8.0
                 group by 1,2,3")
  df = db.query(db, query)  
  # f.keys 
  max.x = max(df$pageloadtime)
  max.y = max(df$yvalue)

  # Calculate correlation for each group
  cors <- ddply(df, .(domain), summarise, cor = round(cor(pageloadtime, yvalue), 2))
  # cors don't go together with log-scale: Error in lm.wfit(x, y, w, offset = offset, singular.ok = singular.ok,  : NA/NaN/Inf in 'y'
  ggplot(df, aes(x = pageloadtime, y = yvalue)) + 
    geom_smooth(method = "lm")  + 
    geom_point() +
    scale_x_continuous(limits=c(0, max.x)) +
    scale_y_continuous(limits=c(0, max.y)) +
    facet_grid(domain ~ ., scales="free_y") +
    geom_text(data=cors, aes(label=concat("r=", cor)), x=15, y=10) +
    labs(title = concat("Correlation of page load time versus sum of ", yfield), x="Page load time (sec)", y=concat("Sum of ", yfield, " (sec)"))
  ggsave(concat("Corr-pageload-", yfield, "-CN-2013-08.png"), dpi=100, width = 9, height=7) 
  

}

# facet: page element url
# x: load time, in bins.
# y: aantal gevallen of percentage
graph.network.distr.domains = function(db, ishwap=FALSE, req.time = 8, max.time = 20) {
  if (ishwap) {
    query = "select 0.001 * r.delta_msec pageloadtime, r.scriptname
           from scriptrun r, run_res rr
           where r.id = rr.scriptrun_id
           and r.task_succeed = 1
           and rr.ishwap = 0
           and r.ts_cet > '2013-08-01'"
  } else {
    query = "select 0.001 * r.delta_msec pageloadtime, r.scriptname
           from scriptrun r
           where r.task_succeed = 1
           and r.ts_cet > '2013-08-01'"
  }
  df = db.query(db, query)  
  ggplot(df, aes(x = pageloadtime)) +
    geom_density() +
    facet_grid(scriptname ~ ., scales="free_y") +
    # vertical line at 8 seconds.
    geom_vline(xintercept=c(req.time), linetype="solid", colour = "red") +
    scale_x_continuous(limits=c(0, max.time)) +
    labs(title = "Distribution of page load times", x="Page load time (sec)", y="density")
  ggsave("Distr-pageload.png", dpi=100, width = 7, height=5)
  
  # wil ook cumulatief
  qplot(pageloadtime, data=df, stat = "ecdf", geom = "step") +
    facet_grid(scriptname ~ ., scales="free_y") +
    geom_vline(xintercept=c(req.time), linetype="solid", colour = "red") +
    scale_x_continuous(limits=c(0, max.time)) +
    labs(title = "Cumulative distribution of page load times", x="Page load time (sec)", y="density")
  ggsave("Distr-pageload-cumulative.png", dpi=100, width = 7, height=5)
}

# @pre task_succeed is set to 0 for scriptruns containing ishwap.com.
# @pre urlsize table is available (use table_copy.tcl)
graph.network.distr.items = function(db, req.time = 8, max.time = 20) {
  query = "select r.scriptname, i.url, 0.001 * i.element_delta loadtime, 0.001 * i.first_packet_delta ttfb
           from scriptrun r, pageitem i
           where 1*r.task_succeed = 1
           and r.ts_cet > '2013-08-09'
           and r.scriptname = 'Mobile_CN'
           and i.scriptrun_id = r.id
           and i.domain <> 'philips.112.2o7.net'"
  df = db.query(db, query)  

  max.time = 3
  ggplot(df, aes(x = loadtime)) +
    geom_density() +
    facet_grid(url ~ ., scales="free_y", labeller="url.labeller") +
    scale_x_continuous(limits=c(0, max.time)) +
    labs(title = "Distribution of item load times", x="Item load time (sec)", y="density") +
    geom_text(aes(0, 0.7, label=url), size = 2, hjust = 0, vjust = 0,
              colour="blue", data=df)
  ggsave("Distr-pageitems-size.png", dpi=200, width = 7, height=30)
  
  df$label = url.labeller2(1, df$url)
  ggplot(df, aes(x = loadtime)) +
    geom_density() +
    facet_wrap(~ label, scales="free", ncol=2) +
    scale_x_continuous(limits=c(0, max.time)) +
    labs(title = "Distribution of item load times", x="Item load time (sec)", y="density") +
    geom_text(aes(0, 0.7, label=url), size = 2, hjust = 0, vjust = 0,
              colour="blue", data=df)
  ggsave("Distr-pageitems-size-facetwrap.png", dpi=200, width = 10, height=12)

  ggplot(df, aes(x = ttfb)) +
    geom_density() +
    facet_wrap(~ label, scales="free", ncol=2) +
    scale_x_continuous(limits=c(0, max.time)) +
    labs(title = "Distribution of item TTFB times", x="Item TTFB time (sec)", y="density") +
    geom_text(aes(0, 0.7, label=url), size = 2, hjust = 0, vjust = 0,
              colour="blue", data=df)
  ggsave("Distr-pageitems-ttfb-facetwrap.png", dpi=200, width = 10, height=12)
  
  qplot(loadtime, data=df, stat = "ecdf", geom = "step") +
    facet_grid(url ~ ., scales="free_y", labeller="url.labeller") +
    scale_x_continuous(limits=c(0, max.time)) +
    labs(title = "Cumulative distribution of item load times", x="Page load time (sec)", y="density") +
    geom_text(aes(0, 0.7, label=url), size = 2, hjust = 0, vjust = 0,
          colour="blue", data=df)
  ggsave("Distr-pageitems-cumulative-size.png", dpi=200, width = 7, height=30)
  
  #qplot(size, loadtime, data=df, geom="point", color = domain, shape=extension) +
  #  labs(title = "Loadtime vs item size", x="Page size (bytes)", y="Loadtime (sec)")
  #ggsave("Loadtime-vs-size-all.png", dpi=100, width = 9, height=8)
  
  query = "select avg(0.001 * i.element_delta) loadtime, i.url,  1*s.size size, i.domain, i.extension
           from scriptrun r, pageitem i, urlsize s
           where 1*r.task_succeed = 1
           and s.url = i.url
           and r.ts_cet > '2013-08-09'
           and r.scriptname = 'Mobile_CN'
           and i.scriptrun_id = r.id
           and i.domain <> 'philips.112.2o7.net'
           group by 2,3,4,5"
  df = db.query(db, query)
  qplot(size, loadtime, data=df, geom="point", color = domain, shape=extension) +
    labs(title = "Avg Loadtime vs item size", x="Item size (bytes)", y="Avg Loadtime (sec)")
  ggsave("Loadtime-vs-size-avg.png", dpi=100, width = 9, height=8)
}

url.labeller = function(var, value) {
  str_sub(str_extract(value, "[^/]+$"), 1, 10)
}

url.labeller2 = function(var, value) {
  str_sub(str_extract(value, "[^/]+$"), 1, 30)
}

main()
