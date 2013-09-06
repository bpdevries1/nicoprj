source("~/nicoprj/R/lib/ndvlib.R")

main = function () {
  load.def.libs()
  # setwd("c:/projecten/Philips/KN-Analysis/Mobile")
  # make.dashboard.graphs.all()
  # make.mobile.graphs()
  setwd("c:/projecten/Philips/KN-Analysis/Mobile-landing")
  make.mobile.weight.graphs()
}

make.mobile.graphs = function() {
  db = db.open("keynotelogs.db")
  query = "select ts_cet, 0.001*delta_msec pageload, scriptname from scriptrun where ts_cet > '2013-08-22'"
  df = add.psxtime(db.query(db, query), "ts_cet", "psx_date",format="%Y-%m-%d %H:%M:%S")
  
  p=qplot(psx_date, pageload, data=df, geom="point") +
    labs(title = concat("Page load times"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    facet_wrap(~ scriptname, scales="free", ncol=1)
  ggsave("Loadtimes-point.png", dpi=100, width = 10, height=9, plot=p)

  p=qplot(psx_date, pageload, data=df, geom="line") +
    labs(title = concat("Page load times"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    facet_wrap(~ scriptname, scales="free", ncol=1)
  ggsave("Loadtimes-line.png", dpi=100, width = 10, height=9, plot=p)

  # sum of times per domain, ignore ishwap etc.
  query = "select r.ts_cet, sum(0.001*i.element_delta) loadtime, r.scriptname, i.domain 
           from scriptrun r, pageitem i
           where r.id = i.scriptrun_id
           and r.ts_cet > '2013-08-22'
           and not i.domain = 'philips.112.2o7.net'
           and i.domain like '%philips%'
           group by 1,3,4"
  df = add.psxtime(db.query(db, query), "ts_cet", "psx_date",format="%Y-%m-%d %H:%M:%S")
  
  p=qplot(psx_date, loadtime, data=df, geom="line", colour=domain) +
    labs(title = concat("Sum of domain load times"), x="Date", y="Sum domain load time (sec)") +
    facet_wrap(~ scriptname, scales="free", ncol=1)
  ggsave("Domain-Loadtimes-line.png", dpi=100, width = 10, height=9, plot=p)
  
  # sum of network-parts-time
  query = "select r.ts_cet, r.scriptname, i.domain,
              sum(0.001*i.element_delta) loadtime,
              sum(0.001*i.dns_delta) dnstime,
              sum(0.001*i.connect_delta) connecttime,
              sum(0.001*i.request_delta) reqtime,
              sum(0.001*i.first_packet_delta) firstpackettime,
              sum(0.001*i.remain_packets_delta) remainpacketstime
           from scriptrun r, pageitem i
           where r.id = i.scriptrun_id
           and r.ts_cet > '2013-08-22'
           and not i.domain = 'philips.112.2o7.net'
           and i.domain like '%philips%'
           and r.scriptname = 'Mobile_CN'
           group by 1,2,3"
  df = add.psxtime(db.query(db, query), "ts_cet", "psx_date",format="%Y-%m-%d %H:%M:%S")
  # dfm = melt(df, measure.vars=c("loadtime","dnstime","connecttime","reqtime","firstpackettime","remainpacketstime"))
  dfm = melt(df, id.vars=c("ts_cet","psx_date","scriptname","domain"))
  p=qplot(psx_date, value, data=dfm, geom="line", colour=variable) +
    labs(title = concat("Sum of network times"), x="Date", y="Sum network times (sec)") +
    facet_wrap(~ domain, scales="free", ncol=1)
  p=qplot(psx_date, value, data=dfm, geom="line") +
    labs(title = concat("Sum of network times"), x="Date", y="Sum network times (sec)") +
    facet_grid(variable ~ domain, scales="free")
  ggsave("Network-times-line2.png", dpi=100, width = 10, height=9, plot=p)
  
  # #elements and bytes
  query = "select r.ts_cet, r.scriptname, 1*p.page_bytes bytes, 1*p.element_count elt_count
           from scriptrun r, page p
           where p.scriptrun_id = r.id
           and r.ts_cet > '2013-08-22'"
  df = add.psxtime(db.query(db, query), "ts_cet", "psx_date",format="%Y-%m-%d %H:%M:%S")
  dfm = melt(df, id.vars=c("ts_cet","psx_date","scriptname"))
  p=qplot(psx_date, value, data=dfm, geom="line", colour=variable) +
    labs(title = concat("#elements and #bytes"), x="Date", y="#elements and #bytes") +
    facet_grid(variable ~ scriptname, scales="free")
  ggsave("Numbers-content-line.png", dpi=100, width = 9, height=7, plot=p)
  
  # network and signal_strength
  # network as facet/colour, signal_strength as number.
  query = "select r.ts_cet, r.scriptname, 1*r.signal_strength signal_strength, r.network
           from scriptrun r
           where r.ts_cet > '2013-08-22'"
  df = add.psxtime(db.query(db, query), "ts_cet", "psx_date",format="%Y-%m-%d %H:%M:%S")
  p = qplot(psx_date, signal_strength, data=df, geom = "line", colour=network) +
    labs(title = concat("Network/signal strength"), x="Date", y="Signal strength") +
    facet_grid(scriptname ~ ., scales="free")
  ggsave("Network-signal-strength-line.png", dpi=100, width = 9, height=9, plot=p)

  p = qplot(psx_date, signal_strength, data=df, geom = "point", colour=network, shape=network) +
    labs(title = concat("Network/signal strength"), x="Date", y="Signal strength") +
    facet_grid(scriptname ~ ., scales="free")
  ggsave("Network-signal-strength-line2.png", dpi=100, width = 9, height=9, plot=p)
  
  p = qplot(psx_date, signal_strength, data=df, geom = "point") +
    labs(title = concat("Network/signal strength"), x="Date", y="Signal strength") +
    facet_grid(scriptname ~ network, scales="free")
  ggsave("Network-signal-strength-line2.png", dpi=100, width = 12, height=9, plot=p)
  
}

make.mobile.weight.graphs = function() {
  setwd("c:/projecten/Philips/KN-Analysis/Mobile-landing")
  db = db.open("keynotelogs.db")
  scriptname = "Mobile_CN"
  # #elements and #bytes per page: does this increase?
  # elements
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, avg(1*p.element_count) element_count, avg(1*page_bytes) page_bytes, avg(0.001*p.delta_msec) loadtime
           from scriptrun r join page p on p.scriptrun_id = r.id
           where r.scriptname = 'Mobile_CN'
           and r.ts_cet > '2013-08-01'
           and task_succeed = 1
           group by 1,2
           order by 1,2"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, element_count, data=df, geom="line", colour=pagenr) +
    labs(title = concat("Average element count per page and day for: ", scriptname), x="Date", y="Element count")
  ggsave(concat(scriptname, "-elt-count.png"), dpi=100, width = 11, height=7, plot=p)
  
  # bytes
  p = qplot(psx_date, page_bytes, data=df, geom="line", colour=pagenr) +
    labs(title = concat("Average page bytes per page and day for: ", scriptname), x="Date", y="Page bytes")
  ggsave(concat(scriptname, "-page-bytes.png"), dpi=100, width = 11, height=7, plot=p)
  
  # loadtime
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=pagenr) +
    labs(title = concat("Average load time (sec) per page and day for: ", scriptname), x="Date", y="Load time (sec)")
  ggsave(concat(scriptname, "-loadtime.png"), dpi=100, width = 11, height=7, plot=p)
  
  
  db.close(db)
}

main()
