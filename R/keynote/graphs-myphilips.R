source("~/nicoprj/R/lib/ndvlib.R")

main = function () {
  load.def.libs()
  # deze setwd werkt ook in Windows, staat dan onder c:/nico/Ymor/Philips/Keynote.
  # @note onderstaande werkte niet op Windows in RStudio, ~ verwijst dan naar C:/Users/310118637/Documents.
  # @note maar wel als je RStudio vanuit cygwin bash start, dan is ~ goed gezet.
  # setwd("c:/projecten/Philips/KNDL")
  setwd("c:/projecten/Philips/KN-Analysis")
  make.graphs("MyPhilips-CN")
  make.graphs("MyPhilips-DE")
  make.graphs("MyPhilips-FR")
  make.graphs("MyPhilips-RU")
  make.graphs("MyPhilips-UK")
  make.graphs("MyPhilips-US")
  
  setwd("c:/projecten/Philips/Dashboards")
  make.dashboard.graphs()
}

# scriptname = "MyPhilips-CN"
make.graphs = function(scriptname) {
  setwd(scriptname)
  db = db.open("keynotelogs.db")
  graph.mobile.dashboard(scriptname, db)
  graph.mobile.dashboard2(scriptname, db)
  db.close(db)
  setwd("..")  
}

graph.mobile.dashboard = function(scriptname, db, max.time = 3.5) {
  # don't include current day, as it is not finished yet, and avg may still change
  query = "select r.scriptname, strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq, 0.001*avg(p.delta_msec) pageloadtime
             from scriptrun r, page p
             where p.scriptrun_id = r.id
             and r.ts_cet > '2013-06-20'
             and r.ts_cet < (select strftime('%Y-%m-%d', max(r1.ts_cet)) from scriptrun r1)
             group by 1,2,3
             order by 1,2,3"
  df = db.query(db, query)
  df.all = add.psxtime(df, "date", "psx_date")
  # and ts_cet < strftime('%Y-%m-%d', 'now')
  max.size = max(df.all$pageloadtime)
  qplot(psx_date, pageloadtime, data=df.all, geom="line") +
    labs(title = concat("Average page load time per day for: ", scriptname), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_text(aes(psx_date, pageloadtime, label=sprintf("%.1f", pageloadtime)), hjust = 0, vjust = 0, size = 3,
              colour="blue", data=df.all) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_grid(page_seq ~ ., scales="free_y")
  
  ggsave(concat(scriptname, "-dashboard.png"), dpi=100, width = 11, height=9)
}

graph.mobile.dashboard2 = function(scriptname, db, max.time = 3.5) {
  # don't include current day, as it is not finished yet, and avg may still change
  query = "select r.scriptname, strftime('%Y-%m-%d', r.ts_cet) date, 0.001*avg(p.delta_msec) pageloadtime
             from scriptrun r, page p
             where p.scriptrun_id = r.id
             and r.ts_cet > '2013-06-20'
             and r.ts_cet < (select strftime('%Y-%m-%d', max(r1.ts_cet)) from scriptrun r1)
             group by 1,2
             order by 1,2"
  df = db.query(db, query)
  df.all = add.psxtime(df, "date", "psx_date")
  # and ts_cet < strftime('%Y-%m-%d', 'now')
  max.size = max(df.all$pageloadtime)
  qplot(psx_date, pageloadtime, data=df.all, geom="line") +
    labs(title = concat("Average page load time per day for: ", scriptname), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_text(aes(psx_date, pageloadtime, label=sprintf("%.1f", pageloadtime)), hjust = 0, vjust = 0, size = 3,
              colour="blue", data=df.all) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red")
  ggsave(concat(scriptname, "-dashboard2.png"), dpi=100, width = 11, height=9)
}

make.dashboard.graphs = function (max.time=3.5, min.avail=0.98) {
  db = db.open("dashboards.db")
  query = "select date, country, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US')"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="line") +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_text(aes(psx_date, value, label=sprintf("%.1f", value)), hjust = 0, vjust = 0, size = 3,
              colour="blue", data=df) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="free", ncol=2)
  ggsave("MyPhilips-Dashboard-resp.png", dpi=100, width = 14, height=9)
  
  query = "select date, country, value from stat where respavail = 'avail' and country in ('CN','DE','FR','RU','UK','US') order by date"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="line") +
    labs(title = concat("Availability per day for MyPhilips"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="fixed", ncol=2)
  ggsave("MyPhilips-Dashboard-avail.png", dpi=100, width = 14, height=9)
  
  # resp in one graph, one line per country, no text.
  query = "select date, country, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US')"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="line",colour=country) +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red")
    
  ggsave("MyPhilips-Dashboard-resp2.png", dpi=100, width = 11, height=8)
  
  # tests to see if dashboard data is the same as keynote API data
  query = "select date, source, country, value from stat where respavail = 'avail' and country in ('CN','DE','FR','RU','UK','US') order by date"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="point", colour=source) +
    labs(title = concat("Availability per day for MyPhilips"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="fixed", ncol=2)
  ggsave("MyPhilips-Dashboard-avail-check.png", dpi=100, width = 14, height=9)
  
  # avg van delta_msec
  query = "select date, source, country, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source in ('API', 'dashboard')"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="point", colour = source) +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="free_y", ncol=2)
  ggsave("MyPhilips-Dashboard-resp-check1.png", dpi=100, width = 14, height=9)

  # avg van delta_user_msec
  query = "select date, source, country, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source in ('API', 'dashboard')"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="point", colour = source) +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="free_y", ncol=2)
  ggsave("MyPhilips-Dashboard-resp-check1.png", dpi=100, width = 14, height=9)
  
  db.close(db)
}

main()