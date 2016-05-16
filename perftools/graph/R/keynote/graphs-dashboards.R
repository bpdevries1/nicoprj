source("~/nicoprj/R/lib/ndvlib.R")

main = function () {
  load.def.libs()
  setwd("c:/projecten/Philips/Dashboards-DL")
  # make.dashboard.graphs.all()
  make.dashboard.graphs()
}

make.dashboard.graphs.all = function (max.time=3.5, min.avail=0.98) {
  setwd("c:/projecten/Philips/Dashboards-DL")
  db = db.open("dashboards.db")
  query = "select date, country || '-' || scriptname script, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source = 'dashboard'"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="line") +
    labs(title = concat("Average page load time per day"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_text(aes(psx_date, value, label=sprintf("%.1f", value)), hjust = 0, vjust = 0, size = 3,
              colour="blue", data=df) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ script, scales="free", ncol=2)
  ggsave("Dashboard-resp.png", dpi=100, width = 14, height=9)
  
  query = "select date, country || '-' || scriptname script, value from stat where respavail = 'avail' and country in ('CN','DE','FR','RU','UK','US') and source = 'dashboard' order by date"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="line") +
    labs(title = concat("Availability per day"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ script, scales="fixed", ncol=2)
  ggsave("Dashboard-avail.png", dpi=100, width = 14, height=9)
  
  # resp in one graph, one line per script, no text.
  query = "select date, country || '-' || scriptname script, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source = 'dashboard'"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="line",colour=script) +
    labs(title = concat("Average page load time per day"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red")
  ggsave("Dashboard-resp2.png", dpi=100, width = 11, height=8)
  
  # tests to see if dashboard data is the same as keynote API data
  query = "select date, source, country || '-' || scriptname script, value from stat where respavail = 'avail' and country in ('CN','DE','FR','RU','UK','US') and source in ('API', 'dashboard') order by date"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="point", colour=source) +
    labs(title = concat("Availability per day"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ script, scales="fixed", ncol=2)
  ggsave("Dashboard-avail-check-same.png", dpi=100, width = 14, height=9)
  
  # avg van delta_msec
  query = "select date, source, country || '-' || scriptname script, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source in ('API', 'dashboard')"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="point", colour = source) +
    labs(title = concat("Average page load time per day"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ script, scales="free_y", ncol=2)
  ggsave("Dashboard-resp-check-same.png", dpi=100, width = 14, height=9)
  
  # avg van delta_user_msec
  query = "select date, source, country || '-' || scriptname script, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source in ('APIuser', 'dashboard')"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="point", colour = source) +
    labs(title = concat("Average page load time per day"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ script, scales="free_y", ncol=2)
  ggsave("Dashboard-resp-check-same-user.png", dpi=100, width = 14, height=9)
  
  # 21-8-2013 result of adding checks, pageitem details are available from 26-6-2013 10PM onwards, so start from 27-6-2013.
  query = "select date, source, country || '-' || scriptname script, value from stat where respavail = 'avail' and country in ('CN','DE','FR','RU','UK','US') and source in ('dashboard', 'check') and date > '2013-06-27' order by date"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, value, data=df, geom="point", colour=source) +
    labs(title = concat("Availability per day"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ script, scales="fixed", ncol=2)
  ggsave("Dashboard-avail-check-ok-point.png", plot=p, dpi=100, width = 14, height=9)
  p = qplot(psx_date, value, data=df, geom="line", colour=source) +
    labs(title = concat("Availability per day"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ script, scales="fixed", ncol=2)
  ggsave("Dashboard-avail-check-ok-line.png", plot=p, dpi=100, width = 14, height=9)
  
  # avg van delta_user_msec
  query = "select date, source, country || '-' || scriptname script, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source in ('check', 'dashboard') and date > '2013-06-27' "
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, value, data=df, geom="point", colour = source) +
    labs(title = concat("Average page load time per day"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ script, scales="free_y", ncol=2)
  ggsave("Dashboard-resp-check-ok-point.png", plot=p, dpi=100, width = 14, height=9)
  p = qplot(psx_date, value, data=df, geom="line", colour = source) +
    labs(title = concat("Average page load time per day"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ script, scales="free_y", ncol=2)
  ggsave("Dashboard-resp-check-ok-line.png", plot=p, dpi=100, width = 14, height=9)
  
  db.close(db)
}

make.dashboard.graphs = function (max.time=3.5, min.avail=0.98, start.date="2013-01-01", end.date="2013") {
  setwd("c:/projecten/Philips/Dashboards-DL")
  db = db.open("dashboards.db")
  
  # 21-8-2013 result of adding checks, pageitem details are available from 26-6-2013 10PM onwards, so start from 27-6-2013.
  query = "select date, source, country || '-' || scriptname script, value from stat where respavail = 'avail' and source in ('API', 'check') and date > '2013-06-27' order by date"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, value, data=df, geom="point", colour=source, shape=source) +
    labs(title = concat("Availability per day"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "green") +
    facet_wrap(~ script, scales="fixed", ncol=2)
  ggsave("Dashboard-avail-check-ok-point.png", plot=p, dpi=100, width = 14, height=27)
  p = qplot(psx_date, value, data=df, geom="line", colour=source) +
    labs(title = concat("Availability per day"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "green") +
    facet_wrap(~ script, scales="fixed", ncol=2)
  ggsave("Dashboard-avail-check-ok-line.png", plot=p, dpi=100, width = 14, height=27)
  
  # avg van delta_user_msec
  query = "select date, source, country || '-' || scriptname script, value from stat where respavail = 'resp' and source in ('API', 'check') and date > '2013-06-27' "
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, value, data=df, geom="point", colour = source, shape=source) +
    labs(title = concat("Average page load time per day"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "green") +
    facet_wrap(~ script, scales="free_y", ncol=2)
  ggsave("Dashboard-resp-check-ok-point.png", plot=p, dpi=100, width = 14, height=27)
  p = qplot(psx_date, value, data=df, geom="line", colour = source) +
    labs(title = concat("Average page load time per day"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "green") +
    facet_wrap(~ script, scales="free_y", ncol=2)
  ggsave("Dashboard-resp-check-ok-line.png", plot=p, dpi=100, width = 14, height=27)
  
  # ter controle aantal measurements tonen.
  query = "select date, source, country || '-' || scriptname script, nmeas from stat where respavail = 'avail' and source in ('API', 'check') and date > '2013-06-27' "
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, nmeas, data=df, geom="point", colour = source, shape=source) +
    labs(title = concat("#measurements per day"), x="Date", y="#measurements") +
    facet_wrap(~ script, scales="free_y", ncol=2)
  ggsave("Dashboard-nmeas-point.png", plot=p, dpi=100, width = 14, height=27)
  p = qplot(psx_date, nmeas, data=df, geom="line", colour = source) +
    labs(title = concat("#measurements per day"), x="Date", y="#measurements") +
    facet_wrap(~ script, scales="free_y", ncol=2)
  ggsave("Dashboard-nmeas-line.png", plot=p, dpi=100, width = 14, height=27)
  
  db.close(db)
}

main()