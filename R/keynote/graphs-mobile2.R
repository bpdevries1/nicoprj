source("~/nicoprj/R/lib/ndvlib.R")

main = function () {
  load.def.libs()
  setwd("c:/projecten/Philips/KN-AN-Mobile")
  
  dirnames = Sys.glob("*")
  for (dirname in dirnames) {
    make.graphs(dirname)
  }
  
  #setwd("c:/projecten/Philips/Dashboards")
  #make.dashboard.graphs()
}

# scriptname = "MyPhilips-CN"
# scriptname = "CBF-CN-AC4076"
make.graphs = function(scriptname="MyPhilips-CN") {
  setwd(scriptname)
  db = db.open("keynotelogs.db")
  #graph.mobile.dashboard(scriptname, db)
  #graph.mobile.dashboard2(scriptname, db)
  # graph.checks(scriptname, db)
  graph.pageload.pages.domains(scriptname, db)
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

# just report on succeeded scriptruns.
# @pre checkrun is available, use keynotetools/postproclogs.tcl to create.
graph.pageload.pages.domains = function(scriptname, db) {
  # first fill tables
  
  # 10-9-2013 those queries now done from Tcl script, along with other queries.
  # fill.helper.tables(db, scriptname)
  
  # scriptname = "MyPhilips-DE"
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
  # query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.domain, sum(0.001*i.element_delta) loadtime
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.domain, avg(0.001*i.element_delta) loadtime
           from scriptrun r, checkrun c, page p, pageitem i
           where c.scriptrun_id = r.id
           and c.real_succeed = 1
           and p.scriptrun_id = r.id
           and i.page_id = p.id
           and not i.domain = 'philips.112.2o7.net'
           group by 1,2,3
           order by 1,2,3"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=domain) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=domain)) +
    # scale_shape(solid=FALSE) +
    # scale_shape_manual(values=1:30) +
    scale_shape_manual(values=rep(1:25,2)) +
    labs(title = concat("Average load times per page, domain and day for: ", scriptname), x="Date", y="Avg load time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y")
  ggsave(concat(scriptname, "-pageload-domain-avg.png"), dpi=100, width = 11, height=7, plot=p)
  
  query = "select scriptname, strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.domain, sum(0.001*i.element_delta)/rc.number loadtime
         from scriptrun r, checkrun c, page p, pageitem i, runcount rc
         where c.scriptrun_id = r.id
         and c.real_succeed = 1
         and p.scriptrun_id = r.id
         and i.page_id = p.id
         and rc.date = strftime('%Y-%m-%d', r.ts_cet)
         and not i.domain = 'philips.112.2o7.net'
         and r.ts_cet > '2013-08-01'
         group by 1,2,3,4
         order by 1,2,3,4"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=domain) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=domain)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,2)) +
    labs(title = concat("Sum of item load times per page, domain and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(scriptname ~ ., scales="free_y")
  ggsave(concat(scriptname, "-pageload-domain-runtotal.png"), dpi=100, width = 11, height=7, plot=p)
  
  # max 60 seconds
  query = "select scriptname, strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.domain, sum(0.001*i.element_delta)/rc.number loadtime
         from scriptrun r, checkrun c, page p, pageitem i, runcount rc
         where c.scriptrun_id = r.id
         and c.real_succeed = 1
         and p.scriptrun_id = r.id
         and i.page_id = p.id
         and rc.date = strftime('%Y-%m-%d', r.ts_cet)
         and not i.domain = 'philips.112.2o7.net'
         and r.ts_cet > '2013-08-01'
         and 0.001*r.delta_user_msec < 60
         group by 1,2,3,4
         order by 1,2,3,4"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=domain) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=domain)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,2)) +
    labs(title = concat("Sum of item load times per page, domain and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(scriptname ~ ., scales="free_y")
  ggsave(concat(scriptname, "-pageload-domain-runtotal-max60s.png"), dpi=100, width = 11, height=7, plot=p)
  
  
  # per extension
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.extension, avg(0.001*i.element_delta) loadtime
           from scriptrun r, checkrun c, page p, pageitem i
           where c.scriptrun_id = r.id
           and c.real_succeed = 1
           and p.scriptrun_id = r.id
           and i.page_id = p.id
           and not i.domain = 'philips.112.2o7.net'
           group by 1,2,3
           order by 1,2,3"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=extension) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=extension)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,2)) +
    labs(title = concat("Average load times per page, extension and day for: ", scriptname), x="Date", y="Avg load time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y")
  ggsave(concat(scriptname, "-pageload-extension-avg.png"), dpi=100, width = 11, height=7, plot=p)
  
  query = "select scriptname, strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.extension, sum(0.001*i.element_delta)/rc.number loadtime
            from scriptrun r, checkrun c, page p, pageitem i, runcount rc
            where c.scriptrun_id = r.id
            and c.real_succeed = 1
            and p.scriptrun_id = r.id
            and i.page_id = p.id
            and rc.date = strftime('%Y-%m-%d', r.ts_cet)
            and not i.domain = 'philips.112.2o7.net'
            and r.ts_cet > '2013-08-01'
            group by 1,2,3,4
            order by 1,2,3,4"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=extension) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=extension)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,2)) +
    labs(title = concat("Sum of item load times per page, extension and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(scriptname ~ ., scales="free_y")
  ggsave(concat(scriptname, "-pageload-extension-runtotal.png"), dpi=100, width = 11, height=7, plot=p)

  # also here max 60 seconds.
  query = "select scriptname, strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.extension, sum(0.001*i.element_delta)/rc.number loadtime
            from scriptrun r, checkrun c, page p, pageitem i, runcount rc
            where c.scriptrun_id = r.id
            and c.real_succeed = 1
            and p.scriptrun_id = r.id
            and i.page_id = p.id
            and rc.date = strftime('%Y-%m-%d', r.ts_cet)
            and not i.domain = 'philips.112.2o7.net'
            and r.ts_cet > '2013-08-01'
            and 0.001*r.delta_user_msec < 60
            group by 1,2,3,4
            order by 1,2,3,4"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=extension) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=extension)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,2)) +
    labs(title = concat("Sum of item load times per page, extension and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(scriptname ~ ., scales="free_y")
  ggsave(concat(scriptname, "-pageload-extension-runtotal-max60s.png"), dpi=100, width = 11, height=7, plot=p)
  
  # only top 20 page items, use helper tables (already filled here)
  query = "select r.scriptname scriptname, strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.urlnoparams url, sum(0.001*i.element_delta)/rc.number loadtime
    from scriptrun r, checkrun c, page p, pageitem i, runcount rc, maxitem m
    where c.scriptrun_id = r.id
    and c.real_succeed = 1
    and p.scriptrun_id = r.id
    and i.page_id = p.id
    and i.urlnoparams = m.url
    and p.page_seq = m.page_seq
    and rc.date = strftime('%Y-%m-%d', r.ts_cet)
    and not i.domain = 'philips.112.2o7.net'
    and r.ts_cet > '2013-08-01'
    group by 1,2,3,4
    order by 1,2,3,4"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=url) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=url)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,2)) +
    labs(title = concat("Sum of item load times per page, url and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(scriptname ~ ., scales="free_y") +
    theme(legend.position="bottom") +
    theme(legend.direction="vertical") +
    theme(legend.key.height=unit(10, "points"))
  ggsave(concat(scriptname, "-pageload-url-runtotal.png"), dpi=100, width = 11, height=11, plot=p)
  
  # ook als average, kijken of er dan hetzelfde uitkomt.
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.urlnoparams url, avg(0.001*i.element_delta) loadtime
    from scriptrun r, checkrun c, page p, pageitem i, maxitem m
    where c.scriptrun_id = r.id
    and c.real_succeed = 1
    and p.scriptrun_id = r.id
    and i.page_id = p.id
    and i.urlnoparams = m.url
    and p.page_seq = m.page_seq
    and not i.domain = 'philips.112.2o7.net'
    and r.ts_cet > '2013-08-01'
    group by 1,2,3
    order by 1,2,3"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=url) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=url)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,2)) +
    labs(title = concat("Average item load times per page, url and day for: ", scriptname), x="Date", y="Avg load time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y") +
    theme(legend.position="bottom") +
    theme(legend.direction="vertical") +
    theme(legend.key.height=unit(10, "points"))
  ggsave(concat(scriptname, "-pageload-url-avg.png"), dpi=100, width = 11, height=11, plot=p)

  # #elements and #bytes per page: does this increase?
  # elements
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, avg(1*p.element_count) element_count, avg(0.001*page_bytes) page_kbytes
           from scriptrun r, checkrun c, page p
           where c.scriptrun_id = r.id
           and c.real_succeed = 1
           and p.scriptrun_id = r.id
           and r.ts_cet > '2013-08-01'
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
    and r.ts_cet > '2013-08-01'
    group by 1,2,3
    order by 1,2,3"     
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, content_bytes, data=df, geom="line", colour=url) +
    geom_point(data=df, aes(x=psx_date, y=content_bytes, shape=url)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=rep(1:25,2)) +
    labs(title = concat("Average content bytes per page, url and day for: ", scriptname), x="Date", y="Avg content bytes") +
    facet_grid(pagenr ~ ., scales="free_y") +
    theme(legend.position="bottom") +
    theme(legend.direction="vertical") +
    theme(legend.key.height=unit(10, "points"))
  ggsave(concat(scriptname, "-content-bytes-url-avg.png"), dpi=100, width = 11, height=11, plot=p)
  
  
}

fill.helper.tables.old = function(db, scriptname="MyPhilips-DE") {
  dbSendQuery(db, "drop table if exists runcount")
  dbSendQuery(db, "create table runcount as
    select strftime('%Y-%m-%d', r.ts_cet) date, count(*) number
    from scriptrun r, checkrun c
    where r.id = c.scriptrun_id
    and c.real_succeed = 1
    group by 1")

  # helpers to show top 20 URL's (page items)
  dbSendQuery(db, "drop table if exists maxitem")
  
  dbSendQuery(db, "CREATE TABLE maxitem (id integer primary key autoincrement, 
                  url, page_seq, loadtime)")
  
  dbSendQuery(db, "update pageitem
                    set urlnoparams = url
                    where not url like '%?%'
                    and urlnoparams is null")
  
  # instr is not included in R SQLite lib, so exec (in Tcl from cmdline)
  # after updating from 0.11.2->0.11.4 (6-9-2013) instr is available!
  # print("Shell exec not working yet, run Tcl script before: c:/nico/nicoprj/R/keynote/fill_url.tcl")
  # shell(concat("tclsh c:/nico/nicoprj/R/keynote/fill_url.tcl c:/projecten/Philips/KN-Analysis/", scriptname, "/keynotelogs.db"), translate=TRUE)
  # shell.exec, system, shell commands.
  
  # 6-9-2013 shell also works:
  #> tclsh = "c:/develop/tcl86/bin/tclsh86.exe"
  #> tclscr = "c:/aaa/test.tcl"
  #> shell(concat(tclscr, " a b c"), tclsh, flag=NULL)
  #Testing calling tcl from R. args=a b c
  #> shell(paste(tclscr, 1, 2, 3), tclsh, flag=NULL)
  #Testing calling tcl from R. args=1 2 3
  
  dbSendQuery(db, "update pageitem
                    set urlnoparams = substr(url, 1, instr(url, '?'))
                    where url like '%?%'
                    and urlnoparams is null")
  
  dbSendQuery(db, "insert into maxitem (url, page_seq, loadtime)
                    select i.urlnoparams, p.page_seq, avg(0.001*i.element_delta) loadtime
                    from scriptrun r, page p, pageitem i, checkrun c
                    where c.scriptrun_id = r.id
                    and p.scriptrun_id = r.id
                    and i.page_id = p.id
                    and c.real_succeed = 1
                    and r.ts_cet > '2013-08-26'
                    group by 1,2
                    order by 3 desc
                    limit 20")
}

test.legend = function() {
  qplot(psx_date, loadtime, data=df, geom="line", colour=url) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=url)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=1:25) +
    labs(title = concat("Sum of item load times per page, url and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y") +
    theme(legend.position="bottom") +
    theme(legend.direction="vertical") +
    theme(legend.key.height=unit(10, "points"))
}

old.ext = function() {
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, p.page_seq pagenr, i.extension, sum(0.001*i.element_delta) loadtime
           from scriptrun r, checkrun c, page p, pageitem i
           where c.scriptrun_id = r.id
           and c.real_succeed = 1
           and p.scriptrun_id = r.id
           and i.page_id = p.id
           and not i.domain = 'philips.112.2o7.net'
           group by 1,2,3
           order by 1,2,3"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=extension) +
    labs(title = concat("Sum of item load times per page, extension and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y")
  ggsave(concat(scriptname, "-pageload-extension.png"), dpi=100, width = 11, height=7, plot=p)
  
  
}

test = function() {
  library(ggplot2)
  library(data.table)
  d=data.table(x=seq(0, 100, by=0.1), y=seq(0,1000))
  ggplot(d, aes(x=x, y=y))+geom_line()
  #Change the length parameter for fewer or more points
  thinned <- floor(seq(from=1,to=dim(d)[1],length=70))
  ggplot(d, aes(x=x, y=y))+geom_line()+geom_point(data=d[thinned,],aes(x=x,y=y))  
  
  # voor df
  thinned <- floor(seq(from=1,to=dim(df)[1],length=70))
  p = qplot(psx_date, loadtime, data=df, geom="line", colour=domain) +
    geom_point(data=df, aes(x=psx_date, y=loadtime, shape=domain)) +
    # geom_point(data=df[thinned,], aes(x=psx_date, y=loadtime, shape=domain)) +
    # scale_shape(solid=FALSE) +
    scale_shape_manual(values=1:25) +
    labs(title = concat("Sum of item load times per page, domain and day for: ", scriptname), x="Date", y="Sum load time (sec)") +
    facet_grid(pagenr ~ ., scales="free_y")

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
  
}

graph.ggobi = function() {
  setwd("c:/projecten/Philips/KN-Analysis")
  setwd("MyPhilips-CN")
  
  db = db.open("keynotelogs.db")
  #graph.mobile.dashboard(scriptname, db)
  #graph.mobile.dashboard2(scriptname, db)
  query = "select r.scriptname, strftime('%Y-%m-%d', r.ts_cet) date, 
    1*resp_bytes resp_bytes, 1*element_count element_count, 1*domain_count domain_count, 
    1*content_errors content_errors, 1*connection_count connection_count,
    1*delta_msec delta_msec, 1*delta_user_msec delta_user_msec
    from scriptrun r
    where task_succeed = 1
    and r.ts_cet between '2013-08-09' and '2013-09-16'"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  dfm = melt(df, measure.vars=c("resp_bytes", "element_count", "domain_count", "content_errors", "connection_count"))

  Sys.setenv(PATH=paste(Sys.getenv("PATH"), 
                        "C:\\Program Files (x86)\\ggobi",
                        "C:\\GTK\\bin",
                        sep=";"))
  library(rggobi)
  ggobi(df)
  
  # per page
  query = "select strftime('%Y-%m-%d', r.ts_cet) date, 
    1*p.page_bytes page_bytes, 1*p.element_count element_count, 1*p.domain_count domain_count, 
    1*p.content_errors content_errors, 1*p.connection_count connection_count,
    1*p.delta_user_msec delta_user_msec
    from scriptrun r, page p
    where r.task_succeed = 1
    and p.scriptrun_id = r.id
    and 1*p.page_seq = 3
    and r.ts_cet between '2013-08-09' and '2013-09-16'"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  
  
  db.close(db)
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

# prereqs before calling this function: dashboard-myphilips.txt (in same dir)
make.dashboard.graphs = function (max.time=3.5, min.avail=0.98) {
  setwd("c:/projecten/Philips/Dashboards")
  db = db.open("dashboards.db")
  query = "select date, country, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source = 'dashboard'"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="line") +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    geom_text(aes(psx_date, value, label=sprintf("%.1f", value)), hjust = 0, vjust = 0, size = 3,
              colour="blue", data=df) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="free", ncol=2)
  ggsave("MyPhilips-Dashboard-resp.png", dpi=100, width = 14, height=9)
  
  query = "select date, country, value from stat where respavail = 'avail' and country in ('CN','DE','FR','RU','UK','US') and source = 'dashboard' order by date"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="line") +
    labs(title = concat("Availability per day for MyPhilips"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="fixed", ncol=2)
  ggsave("MyPhilips-Dashboard-avail.png", dpi=100, width = 14, height=9)
  
  # resp in one graph, one line per country, no text.
  query = "select date, country, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source = 'dashboard'"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="line",colour=country) +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red")
  ggsave("MyPhilips-Dashboard-resp2.png", dpi=100, width = 11, height=8)
  
  # tests to see if dashboard data is the same as keynote API data
  query = "select date, source, country, value from stat where respavail = 'avail' and country in ('CN','DE','FR','RU','UK','US') and source in ('API', 'dashboard') order by date"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="point", colour=source) +
    labs(title = concat("Availability per day for MyPhilips"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="fixed", ncol=2)
  ggsave("MyPhilips-Dashboard-avail-check-same.png", dpi=100, width = 14, height=9)
  
  # avg van delta_msec
  query = "select date, source, country, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source in ('API', 'dashboard')"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="point", colour = source) +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="free_y", ncol=2)
  ggsave("MyPhilips-Dashboard-resp-check-same.png", dpi=100, width = 14, height=9)

  # avg van delta_user_msec
  query = "select date, source, country, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source in ('APIuser', 'dashboard')"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  qplot(psx_date, value, data=df, geom="point", colour = source) +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="free_y", ncol=2)
  ggsave("MyPhilips-Dashboard-resp-check-same-user.png", dpi=100, width = 14, height=9)
  
  # 21-8-2013 result of adding checks, pageitem details are available from 26-6-2013 10PM onwards, so start from 27-6-2013.
  query = "select date, source, country, value from stat where respavail = 'avail' and country in ('CN','DE','FR','RU','UK','US') and source in ('dashboard', 'check') and date > '2013-06-27' order by date"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, value, data=df, geom="point", colour=source) +
    labs(title = concat("Availability per day for MyPhilips"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="fixed", ncol=2)
  ggsave("MyPhilips-Dashboard-avail-check-ok-point.png", plot=p, dpi=100, width = 14, height=9)
  p = qplot(psx_date, value, data=df, geom="line", colour=source) +
    labs(title = concat("Availability per day for MyPhilips"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="fixed", ncol=2)
  ggsave("MyPhilips-Dashboard-avail-check-ok-line.png", plot=p, dpi=100, width = 14, height=9)
  
  # avg van delta_user_msec
  query = "select date, source, country, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source in ('check', 'dashboard') and date > '2013-06-27' "
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, value, data=df, geom="point", colour = source) +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="free_y", ncol=2)
  ggsave("MyPhilips-Dashboard-resp-check-ok-point.png", plot=p, dpi=100, width = 14, height=9)
  p = qplot(psx_date, value, data=df, geom="line", colour = source) +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="free_y", ncol=2)
  ggsave("MyPhilips-Dashboard-resp-check-ok-line.png", plot=p, dpi=100, width = 14, height=9)
  
  # 2-9-2013 just check API (should be same as dashboard) with check (actual situation)
  query = "select date, source, country, value from stat where respavail = 'avail' and country in ('CN','DE','FR','RU','UK','US') and source in ('API', 'check') and date > '2013-06-27' order by date"
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, value, data=df, geom="point", colour=source) +
    labs(title = concat("Availability per day for MyPhilips"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="fixed", ncol=2)
  ggsave("MyPhilips-Dashboard-avail-check-api-ok-point.png", plot=p, dpi=100, width = 14, height=9)
  p = qplot(psx_date, value, data=df, geom="line", colour=source) +
    labs(title = concat("Availability per day for MyPhilips"), x="Date", y="Availability") +
    geom_hline(yintercept=min.avail, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="fixed", ncol=2)
  ggsave("MyPhilips-Dashboard-avail-check-api-ok-line.png", plot=p, dpi=100, width = 14, height=9)
  
  # avg van delta_user_msec
  query = "select date, source, country, value from stat where respavail = 'resp' and country in ('CN','DE','FR','RU','UK','US') and source in ('API', 'check') and date > '2013-06-27' "
  df = add.psxtime(db.query(db, query), "date", "psx_date")
  p = qplot(psx_date, value, data=df, geom="point", colour = source) +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="free_y", ncol=2)
  ggsave("MyPhilips-Dashboard-resp-check-api-ok-point.png", plot=p, dpi=100, width = 14, height=9)
  p = qplot(psx_date, value, data=df, geom="line", colour = source) +
    labs(title = concat("Average page load time per day for MyPhilips"), x="Date", y="Page load time (sec)") +
    # scale_y_continuous(limits=c(0, max.size)) +
    geom_hline(yintercept=max.time, linetype="solid", colour = "red") +
    facet_wrap(~ country, scales="free_y", ncol=2)
  ggsave("MyPhilips-Dashboard-resp-check-api-ok-line.png", plot=p, dpi=100, width = 14, height=9)
  
  db.close(db)
}

main()
