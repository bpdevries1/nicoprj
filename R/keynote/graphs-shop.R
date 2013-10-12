source("~/nicoprj/R/lib/ndvlib.R")

main = function () {
  load.def.libs()
  # deze setwd werkt ook in Windows, staat dan onder c:/nico/Ymor/Philips/Keynote.
  # @note onderstaande werkte niet op Windows in RStudio, ~ verwijst dan naar C:/Users/310118637/Documents.
  # @note maar wel als je RStudio vanuit cygwin bash start, dan is ~ goed gezet.
  # setwd("c:/projecten/Philips/KNDL")
  # setwd("c:/projecten/Philips/KN-Analysis")
  # setwd("c:/projecten/Philips/KN-AN-Mobile")
  setwd("c:/projecten/Philips/KN-AN-Shop")
  
  dirnames = Sys.glob("*")
  make.graphs("Shop-Browsing-Flow-UK-RQ1275")
  for (dirname in dirnames) {
    make.graphs(dirname)
  }

# Lines below for testing.
#   make.graphs("MyPhilips-BR")
#   make.graphs("MyPhilips-CN")
#   make.graphs("MyPhilips-DE")
#   make.graphs("MyPhilips-FR")
#   make.graphs("MyPhilips-RU")
#   make.graphs("MyPhilips-UK")
#   make.graphs("MyPhilips-US")
  
  #setwd("c:/projecten/Philips/Dashboards")
  #make.dashboard.graphs()
}


# scriptname = "MyPhilips-CN"
# scriptname = "CBF-CN-AC4076"
make.graphs = function(scriptname="MyPhilips-CN") {
  print(concat("Making graphs for: ", scriptname))
  setwd(scriptname)
  db = db.open("keynotelogs.db")
  #graph.mobile.dashboard(scriptname, db)
  #graph.mobile.dashboard2(scriptname, db)
  # graph.checks(scriptname, db)
  graph.pageload.pages.domains(scriptname, db)
  if (has.cloudfront(scriptname, db)) {
    graph.cloudfront(scriptname, db)
  }
  if ((scriptname == "MyPhilips-CN") || (scriptname == "MyPhilips-BR")) {
    graph.cloudfront.locations(scriptname, db)
  }
  if (scriptname == "MyPhilips-CN") {
    graph.cloudfront.locations.hongkong(scriptname, db)
  }
  db.close(db)
  setwd("..")  
}

has.cloudfront = function(scriptname, db) {
  grepl("MyPhilips", scriptname)
}

# just report on succeeded scriptruns.
# @pre checkrun is available, use keynotetools/postproclogs.tcl to create.
graph.pageload.pages.domains = function(scriptname, db) {
  # first fill tables
  
  # 10-9-2013 those queries now done from Tcl script, along with other queries.
  # fill.helper.tables(db, scriptname)
  
  # scriptname = "MyPhilips-DE"
  # scriptname = "MyPhilips-CN"
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, avg(0.001*p.delta_user_msec) pageload
           from scriptrun r, checkrun c, page p
           where c.scriptrun_id = r.id
           and c.real_succeed = 1
           and p.scriptrun_id = r.id
           group by 1,2
           order by 1,2"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  # 3-9-2013 plotten van avg.pageload time hierbij is lastig, nu foutmelding op. Nu niet echt nodig.
  p = qplot(psx_date, pageload, data=df, geom="line", colour=pagenr) +
    labs(title = concat("Average page load time per page and day for: ", scriptname), x="Date", y="Page load time (sec)")
    # geom_line(aes(psx_date, pageload, data=df2))
  ggsave(concat(scriptname, "-pageload.png"), dpi=100, width = 11, height=7, plot=p)
  
  # pageload times ook als facet, want varieert nogal wild.
  p = qplot(psx_date, pageload, data=df, geom="line") +
    labs(title = concat("Average page load time per page and day for: ", scriptname), x="Date", y="Page load time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y")
  # geom_line(aes(psx_date, pageload, data=df2))
  ggsave(concat(scriptname, "-pageload-fct.png"), dpi=100, width = 11, height=10, plot=p)
  
  # per domain: sum of element load times (not exactly, as things are loaded in parallel, but should give a good indication)
  # cloudfront may prove difficult because of the subdomain, but maybe specific subdomains give problems. So first check.
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.domain, sum(0.001*i.element_delta)/rc.number loadtime
         from scriptrun r, checkrun c, page p, pageitem i, runcount rc
         where c.scriptrun_id = r.id
         and c.real_succeed = 1
         and p.scriptrun_id = r.id
         and i.page_id = p.id
         and rc.date = strftime('%Y-%m-%d', r.ts_cet)
         and not i.domain = 'philips.112.2o7.net'
         group by 1,2,3
         order by 1,2,3"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=domain) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=domain)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,5)) +
    labs(title = concat("Sum of item load times per page, domain and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y")
  ggsave(concat(scriptname, "-pageload-domain-runtotal.png"), dpi=100, width = 11, height=7, plot=p)

  # per topdomain: sum of element load times (not exactly, as things are loaded in parallel, but should give a good indication)
  # cloudfront may prove difficult because of the subdomain, but maybe specific subdomains give problems. So first check.
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.topdomain, sum(0.001*i.element_delta)/rc.number loadtime
         from scriptrun r, checkrun c, page p, pageitem i, runcount rc
         where c.scriptrun_id = r.id
         and c.real_succeed = 1
         and p.scriptrun_id = r.id
         and i.page_id = p.id
         and rc.date = strftime('%Y-%m-%d', r.ts_cet)
         and not i.domain = 'philips.112.2o7.net'
         group by 1,2,3
         order by 1,2,3"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=topdomain) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=topdomain)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,5)) +
    labs(title = concat("Sum of item load times per page, topdomain and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y")
  ggsave(concat(scriptname, "-pageload-topdomain-runtotal.png"), dpi=100, width = 11, height=7, plot=p)
  
  # per extension
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.extension, sum(0.001*i.element_delta)/rc.number loadtime
            from scriptrun r, checkrun c, page p, pageitem i, runcount rc
            where c.scriptrun_id = r.id
            and c.real_succeed = 1
            and p.scriptrun_id = r.id
            and i.page_id = p.id
            and rc.date = strftime('%Y-%m-%d', r.ts_cet)
            and not i.domain = 'philips.112.2o7.net'
            group by 1,2,3
            order by 1,2,3"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=extension) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=extension)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,5)) +
    labs(title = concat("Sum of item load times per page, extension and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y")
  ggsave(concat(scriptname, "-pageload-extension-runtotal.png"), dpi=100, width = 11, height=7, plot=p)
    
  # only top 20 page items, use helper tables (already filled here)
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.urlnoparams url, sum(0.001*i.element_delta)/rc.number loadtime
    from scriptrun r, checkrun c, page p, pageitem i, runcount rc, maxitem m
    where c.scriptrun_id = r.id
    and c.real_succeed = 1
    and p.scriptrun_id = r.id
    and i.page_id = p.id
    and i.urlnoparams = m.url
    and p.page_seq = m.page_seq
    and rc.date = strftime('%Y-%m-%d', r.ts_cet)
    and not i.domain = 'philips.112.2o7.net'
    group by 1,2,3
    order by 1,2,3"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=url) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=url)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,5)) +
    labs(title = concat("Sum of item load times per page, url and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y") +
    theme(legend.position="bottom") +
    theme(legend.direction="vertical") +
    theme(legend.key.height=unit(10, "points"))
  ggsave(concat(scriptname, "-pageload-url-runtotal.png"), dpi=100, width = 11, height=11, plot=p)

  # #elements and #bytes per page: does this increase?
  # elements
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, avg(1*p.element_count) element_count, avg(0.001*page_bytes) page_kbytes
           from scriptrun r, checkrun c, page p
           where c.scriptrun_id = r.id
           and c.real_succeed = 1
           and p.scriptrun_id = r.id
           group by 1,2
           order by 1,2"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, element_count, data=df, geom="line", colour=pagenr) +
    labs(title = concat("Average element count per page and day for: ", scriptname), x="Date", y="Element count")
  ggsave(concat(scriptname, "-elt-count.png"), dpi=100, width = 11, height=7, plot=p)
  
  # bytes
  p = qplot(psx_date, page_kbytes, data=df, geom="line", colour=pagenr) +
    labs(title = concat("Average page kilobytes per page and day for: ", scriptname), x="Date", y="Page kilobytes")
  ggsave(concat(scriptname, "-page-bytes.png"), dpi=100, width = 11, height=7, plot=p)
  
  # bytes for the 2 problematic URL's:
  # https://secure.philips.de/services/services/JanrainAuthenticationWebService/login?
  # https://philips.janraincapture.com/widget/traditional_signin.jsonp
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.urlnoparams url, avg(1*i.content_bytes) content_bytes
    from scriptrun r, checkrun c, page p, pageitem i, maxitem m
    where c.scriptrun_id = r.id
    and c.real_succeed = 1
    and p.scriptrun_id = r.id
    and i.page_id = p.id
    and i.urlnoparams = m.url
    and p.page_seq = m.page_seq
    and not i.domain = 'philips.112.2o7.net'
    group by 1,2,3
    order by 1,2,3"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, content_bytes, data=df, geom="line", colour=url) +
    geom_point(data=df, aes(x=psx_date, y=content_bytes, shape=url)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,5)) +
    labs(title = concat("Average content bytes per page, url and day for: ", scriptname), x="Date", y="Avg content bytes") +
    facet_grid(pagenr ~ ., scales="free_y") +
    theme(legend.position="bottom") +
    theme(legend.direction="vertical") +
    theme(legend.key.height=unit(10, "points"))
  ggsave(concat(scriptname, "-content-bytes-url-avg.png"), dpi=100, width = 11, height=11, plot=p)
}

graph.cloudfront = function(scriptname, db) {
  query = "select i.date_cet date, i.page_seq pagenr, i.topdomain topdomain, 
          sum(0.001*i.element_delta)/rc.number loadtime,
          sum(0.001*i.dns_delta)/rc.number dnstime,
          sum(0.001*i.connect_delta)/rc.number connecttime,
          sum(0.001*i.ssl_handshake_delta)/rc.number ssltime,
          sum(0.001*i.request_delta)/rc.number reqtime,
          sum(0.001*i.first_packet_delta)/rc.number firstpackettime,
          sum(0.001*i.remain_packets_delta)/rc.number remainpacketstime,
          sum(0.001*system_delta)/rc.number clienttime
          from checkrun c, pageitem i, runcount rc
          where c.scriptrun_id = i.scriptrun_id
          and c.real_succeed = 1
          and rc.date = i.date_cet
          and i.topdomain = 'cloudfront.net'
          group by 1,2,3
          order by 1,2,3"    
  df = db.query.dt(db, query)

  # dfm = melt(df, measure.vars=c("loadtime","dnstime","connecttime","reqtime","firstpackettime","remainpacketstime"))
  dfm = melt(df, id.vars=c("date", "date_psx","pagenr", "topdomain"))
  p=qplot(date_psx, value, data=dfm, geom="line", colour=variable, shape=variable) +
    geom_point(data=dfm, aes(x=date_psx, y=value, shape=variable)) +
    labs(title = "Sum of network times for Cloudfront", x="Date", y="Sum network times (sec)") +
    scale_shape_manual(values=rep(1:25,5)) +
    facet_grid(pagenr ~ ., scales="free")
  ggsave("Network-times-cloudfront.png", dpi=100, width = 11, height=9, plot=p)
  

}

graph.cloudfront.locations = function(scriptname, db) {
  # @todo surround with try-except: only location tables for CN and BR.
  # c.real_succeed = 1 and   
  query = "select i.date_cet date, l.location location, count(*) number, avg(0.001*i.element_delta) loadtime, avg(0.001*(i.element_delta-i.system_delta)) loadtime_nc
            from pageitem i 
              join checkrun c on c.scriptrun_id = i.scriptrun_id
              left join location l on l.ip_address = i.ip_address
            where i.topdomain = 'cloudfront.net'
            and i.ts_cet < (select max(date_cet) from scriptrun)
            and 1*i.page_seq = 1
            group by 1, 2"
  df = db.query.dt(db, query)
  
  # both with and without in one graph, facet is type.
  dfm = melt(df, id.vars = c("date", "location", "number", "date_psx"))
  p=qplot(date_psx, value, data=dfm, geom="line", colour=location) +
    geom_point(data=dfm, aes(x=date_psx, y=value, shape=location)) +
    labs(title = "Average loadtime for Cloudfront elements per location", x="Date", y="Average load time (sec)") +
    scale_shape_manual(values=rep(1:25,5)) +
    facet_grid(. ~ variable) +
    theme(legend.position="bottom")
    #theme(legend.direction="vertical") +
    #theme(legend.key.height=unit(10, "points"))
  
  ggsave("Loadtimes-type-cloudfront-location.png", dpi=100, width = 11, height=4, plot=p)
  
  # @todo both plots in one, use melt and facet.
  p=qplot(date_psx, loadtime, data=df, geom="line", colour=location) +
    geom_point(data=df, aes(x=date_psx, y=loadtime, shape=location)) +
    labs(title = "Average loadtime for Cloudfront elements per location", x="Date", y="Average load time (sec)") +
    scale_shape_manual(values=rep(1:25,5))
  ggsave("Loadtimes-cloudfront-location.png", dpi=100, width = 11, height=6, plot=p)
  p=qplot(date_psx, loadtime_nc, data=df, geom="line", colour=location) +
    geom_point(data=df, aes(x=date_psx, y=loadtime_nc, shape=location)) +
    labs(title = "Average loadtime (excl client time) for Cloudfront elements per location", x="Date", y="Average load time (sec)") +
    scale_shape_manual(values=rep(1:25,5))
  ggsave("Loadtimes-nc-cloudfront-location.png", dpi=100, width = 11, height=6, plot=p)
  p=qplot(date_psx, number, data=df, geom="line", colour=location) +
    geom_point(data=df, aes(x=date_psx, y=number, shape=location)) +
    labs(title = "Daily #items for Cloudfront elements per location", x="Date", y="Daily #items") +
    scale_shape_manual(values=rep(1:25,5))
  ggsave("Loadtimes-cloudfront-location-nitems.png", dpi=100, width = 11, height=6, plot=p)
  
  # just total counts
  query = "select i.date_cet date, count(*) number, 'real' result
          from pageitem i 
          join checkrun c on c.scriptrun_id = i.scriptrun_id
          where c.real_succeed = 1
          and i.topdomain = 'cloudfront.net'
          and i.ts_cet < (select max(date_cet) from scriptrun)
          and 1*i.page_seq = 1
          group by 1,3
union all
          select i.date_cet date, count(*) number, 'task' result
          from pageitem i 
          join checkrun c on c.scriptrun_id = i.scriptrun_id
          where i.topdomain = 'cloudfront.net'
          and c.task_succeed = 1
          and i.ts_cet < (select max(date_cet) from scriptrun)
          and 1*i.page_seq = 1
          group by 1,3
union all
          select i.date_cet date, count(*) number, 'total' result
          from pageitem i 
          where i.topdomain = 'cloudfront.net'
          and i.ts_cet < (select max(date_cet) from scriptrun)
          and 1*i.page_seq = 1
          group by 1,3"

  df = db.query.dt(db, query)
  # @todo both plots in one, use melt and facet.
  p=qplot(date_psx, number, data=df, geom="line", colour=result) +
    geom_point(data=df, aes(x=date_psx, y=number, shape=result)) +
    scale_shape_manual(values=rep(1:25,5)) +
    labs(title = "Daily #items for Cloudfront elements", x="Date", y="Daily #items")
  ggsave("cloudfront-numbers.png", dpi=100, width = 11, height=6, plot=p)
    
  # SSL time per location wrt ticket #11823. Uses all runs, also failed ones.
  # scriptname = "MyPhilips-BR" ; db = get.db(scriptname)
  # scriptname = "MyPhilips-CN" ; db = get.db(scriptname)
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, l.location location, sum(0.001*i.ssl_handshake_delta)/rc.number ssltime
         from scriptrun r, page p, pageitem i, runcount rc, location l
         where p.scriptrun_id = r.id
         and i.page_id = p.id
         and i.topdomain = 'cloudfront.net'
         and rc.date = strftime('%Y-%m-%d', r.ts_cet)
         and i.ip_address = l.ip_address
         group by 1,2,3
         order by 1,2,3"     
  # df = add.psxtime(db.query(db, query), "date", "psx_date")
  df = db.query.dt(db, query)
  p = qplot(date_psx, ssltime, data=df, geom="line", colour=location) +
    geom_point(data=df, aes(x=date_psx, y=ssltime, shape=location)) +
    scale_shape_manual(values=rep(1:25,5)) +
    labs(title = concat("Sum of SSL times per page, location and day for: ", scriptname), x="Date", y="Sum SSL time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y")
  ggsave(concat(scriptname, "-ssl-location-runtotal.png"), dpi=100, width = 11, height=7, plot=p)

  # After September 15th (very high times for Hong Kong before)
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, l.location location, sum(0.001*i.ssl_handshake_delta)/rc.number ssltime
         from scriptrun r, page p, pageitem i, runcount rc, location l
         where p.scriptrun_id = r.id
         and i.page_id = p.id
         and i.topdomain = 'cloudfront.net'
         and rc.date = strftime('%Y-%m-%d', r.ts_cet)
         and rc.date > '2013-09-15'
         and i.ip_address = l.ip_address
         group by 1,2,3
         order by 1,2,3"     
  df = db.query.dt(db, query)
  p = qplot(date_psx, ssltime, data=df, geom="line", colour=location) +
    geom_point(data=df, aes(x=date_psx, y=ssltime, shape=location)) +
    scale_shape_manual(values=rep(1:25,5)) +
    labs(title = concat("Sum of SSL times per page, location and day for: ", scriptname), x="Date", y="Sum SSL time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y")
  ggsave(concat(scriptname, "-ssl-location-runtotal-after-20130915.png"), dpi=100, width = 11, height=7, plot=p)
  
  
}

get.db = function(scriptname) {
  setwd("c:/projecten/Philips/KN-AN-MyPhilips")
  setwd(scriptname)
  db = db.open("keynotelogs.db")
  db
}

graph.cloudfront.locations.hongkong = function(scriptname, db) {
  # No Hong Kong, loadtimes very high in comparison.
  query = "select i.date_cet date, l.location location, count(*) number, avg(0.001*i.element_delta) loadtime, avg(0.001*(i.element_delta-i.system_delta)) loadtime_nc
            from pageitem i 
              join checkrun c on c.scriptrun_id = i.scriptrun_id
              left join location l on l.ip_address = i.ip_address
            where i.topdomain = 'cloudfront.net'
            and i.ts_cet < (select max(date_cet) from scriptrun)
            and l.location != 'Hong Kong'
            and 1*i.page_seq = 1
            group by 1, 2"
  df = db.query.dt(db, query)
  
  p=qplot(date_psx, loadtime, data=df, geom="line", colour=location) +
    geom_point(data=df, aes(x=date_psx, y=loadtime, shape=location)) +
    labs(title = "Average loadtime for Cloudfront elements per location", x="Date", y="Average load time (sec)") +
    scale_shape_manual(values=rep(1:25,5))
  ggsave("Loadtimes-cloudfront-location-no-hongkong.png", dpi=100, width = 11, height=6, plot=p)

  # Page 1 loading times vs number/% of Hong Kong items
  # first # and time, later %.
  # Loadtimes-cloudfront-location-nitems.png
  # MyPhilips-CN-pageload.png
  query = "select 'pageload' valtype, strftime('%Y-%m-%d', r.ts_cet) date, avg(0.001*p.delta_user_msec) value
           from scriptrun r, checkrun c, page p
           where c.scriptrun_id = r.id
           and c.real_succeed = 1
           and p.scriptrun_id = r.id
           and 1*p.page_seq = 1
           group by 1,2
           union all
            select 'perc' valtype, i.date_cet date, 100.0 * count(*) / n.number value
            from pageitem i 
            join ncloudfront n on n.date = i.date_cet
            left join location l on l.ip_address = i.ip_address
            where i.topdomain = 'cloudfront.net'
            and l.location = 'Hong Kong'
            and i.ts_cet < (select max(date_cet) from scriptrun)
            and 1*i.page_seq = 1
            group by 1, 2  "
  df = db.query.dt(db, query)
  p=qplot(date_psx, value, data=df, geom="line") +
    labs(title = "Average page loadtime (sec) and % of Cloudfront Hong Kong items per day", x="Date", y="Value") +
    facet_grid(valtype ~ ., scales = "free")
  ggsave("Loadtimes-cloudfront-hongkong.png", dpi=100, width = 11, height=6, plot=p)

  # en tegen elkaar uitzetten:
  query = "select v1.date, v1.value pageload, v2.value perc
            from vcf v1 join vcf v2 on v1.date = v2.date
            where v1.valtype = 'pageload'
            and v2.valtype = 'perc'"
  df = db.query.dt(db, query)
  
  # ook scatter van perc vs loadtime
  p=qplot(perc, pageload, data=df, geom="point") +
    labs(title = "Average page loadtime versus % of Cloudfront Hong Kong items per day", x="Perc", y="Load time (sec)")
  ggsave("Loadtimes-cloudfront-hongkong-scatter.png", dpi=100, width = 8, height=6, plot=p)
}


# check whether #items etc is constant for 'good' measurements.
graph.checks = function(scriptname, db) {
  #setwd(scriptname)
  #db = db.open("keynotelogs.db")
  
  query = "select r.scriptname, strftime('%Y-%m-%d', r.ts_cet) date, 
    1*resp_bytes resp_bytes, 1*element_count element_count, 1*domain_count domain_count, 
    1*content_errors content_errors, 1*connection_count connection_count
    from scriptrun r
    where task_succeed = 1
    and r.ts_cet between '2013-08-09' and '2013-09-16'"
  
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  dfm = melt(df, measure.vars=c("resp_bytes", "element_count", "domain_count", "content_errors", "connection_count"))
  ggplot(dfm, aes(x = value)) +
    geom_density() +
    facet_grid(date ~ variable, scales="free") +
    labs(title = concat("Distribution of variables for ", scriptname), x="Variable", y="density")
  ggsave("Distr-variables.png", dpi=100, width = 12, height=12)

  # just element_count
  ggplot(df, aes(x = element_count)) +
    geom_density() +
    facet_grid(date ~ ., scales="fixed") +
    labs(title = concat("Distribution of element_count for ", scriptname), x="element count", y="density")
  ggsave("Distr-element-count.png", dpi=100, width = 7, height=9)
  
  # just resp_bytes
  ggplot(df, aes(x = resp_bytes)) +
    geom_density() +
    facet_grid(date ~ ., scales="fixed") +
    labs(title = concat("Distribution of resp_bytes for ", scriptname), x="resp_bytes", y="density")
  ggsave("Distr-resp-bytes.png", dpi=100, width = 7, height=9)
  
}

main()
