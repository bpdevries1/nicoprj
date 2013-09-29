source("~/nicoprj/R/lib/ndvlib.R")

main = function () {
  load.def.libs()
  # deze setwd werkt ook in Windows, staat dan onder c:/nico/Ymor/Philips/Keynote.
  # @note onderstaande werkte niet op Windows in RStudio, ~ verwijst dan naar C:/Users/310118637/Documents.
  # @note maar wel als je RStudio vanuit cygwin bash start, dan is ~ goed gezet.
  # setwd("c:/projecten/Philips/KNDL")
  setwd("c:/projecten/Philips/KN-AN-CN")
  
  dirnames = Sys.glob("*")
  for (dirname in dirnames) {
    make.graphs(dirname)
  }
  
  make.graphs.allflows()
  make.graphs.allflows.perc()
}

main.cn = function () {
  load.def.libs()
  # setwd("c:/projecten/Philips/KN-Analysis")
  setwd("c:/projecten/Philips/KN-AN-CN")
  make.graphs("CBF-CN-AC4076")
}

make.graphs = function(scriptname="MyPhilips-CN") {
  setwd(scriptname)
  db = db.open("keynotelogs.db")
  #graph.mobile.dashboard(scriptname, db)
  #graph.mobile.dashboard2(scriptname, db)
  # graph.checks(scriptname, db)
  graph.avail(scriptname, db)
  db.close(db)
  setwd("..")  
}

graph.avail = function(scriptname, db) {
  query = "select strftime('%Y-%m-%d', ts_cet) date, task_succeed, err_page_seq, count(*) number
           from run_avail
           group by 1,2,3
           order by 1,2,3"
  df = db.query.dt(db, query)
  p = qplot(date_psx, number, data=df, geom="line", colour=as.factor(err_page_seq)) +
    labs(title = concat("Availability and errors per page and day for: ", scriptname), x="Date", y="Number")
  ggsave(concat(scriptname, "-avail-errors-per-page.png"), dpi=100, width = 11, height=7, plot=p)
  
  query = "select strftime('%Y-%m-%d', ts_cet) date, task_succeed, elt_topdomain topdomain, count(*) number
           from run_avail
           where task_succeed = 0
           group by 1,2,3
           order by 1,2,3"
  df = db.query.dt(db, query)
  p = qplot(date_psx, number, data=df, geom="line", colour=topdomain) +
    labs(title = concat("Availability and errors per topdomain and day for: ", scriptname), x="Date", y="Number")
  ggsave(concat(scriptname, "-avail-errors-per-topdomain.png"), dpi=100, width = 11, height=7, plot=p)
  
  query = "select strftime('%Y-%m-%d', ts_cet) date, task_succeed, pg_err_code, count(*) number
           from run_avail
           where task_succeed = 0
           group by 1,2,3
           order by 1,2,3"
  df = db.query.dt(db, query)
  p = qplot(date_psx, number, data=df, geom="line", colour=pg_err_code) +
    labs(title = concat("Availability and errors per pg_err_code and day for: ", scriptname), x="Date", y="Number")
  ggsave(concat(scriptname, "-avail-errors-per-pg_err_code.png"), dpi=100, width = 11, height=7, plot=p)

  query = "select strftime('%Y-%m-%d', ts_cet) date, task_succeed, elt_topdomain topdomain, elt_error_code error_code, count(*) number
           from run_avail
           where task_succeed = 0
           group by 1,2,3,4
           order by 1,2,3,4"
  df = db.query.dt(db, query)
  p = qplot(date_psx, number, data=df, geom="line", colour=error_code) +
    labs(title = concat("Availability and errors per topdomain/errorcode and day for: ", scriptname), x="Date", y="Number") +
    facet_grid(topdomain ~ ., scales="free_y")
  ggsave(concat(scriptname, "-avail-errors-per-topdomain-errorcode.png"), dpi=100, width = 11, height=15, plot=p)
  
}

make.graphs.allflows = function () {
  setwd("c:/projecten/Philips/Dashboards-CN")
  db = db.open("dashboards.db")

  query = "select strftime('%Y-%m-%d', ts_cet) date, task_succeed, err_page_seq, scriptname, count(*) number
           from run_avail
           where task_succeed = 0
           group by 1,2,3,4
           order by 1,2,3"
  df = db.query.dt(db, query)
  p = qplot(date_psx, number, data=df, geom="line", colour=as.factor(err_page_seq)) +
    labs(title = concat("Availability and errors per page and day for CN scripts"), x="Date", y="Number") +
    facet_wrap(~ scriptname, scales="free", ncol=2)
  ggsave(concat("avail-errors-per-page.png"), dpi=100, width = 11, height=9, plot=p)
  
  query = "select strftime('%Y-%m-%d', ts_cet) date, task_succeed, elt_topdomain topdomain, scriptname, count(*) number
            from run_avail
            where task_succeed = 0
            group by 1,2,3,4
            order by 1,2,3,4"
  df = db.query.dt(db, query)
  p = qplot(date_psx, number, data=df, geom="line", colour=topdomain) +
    labs(title = concat("Availability and errors per topdomain and day for CN script"), x="Date", y="Number") +
    facet_wrap(~ scriptname, scales="free", ncol=2)
  ggsave(concat("avail-errors-per-topdomain.png"), dpi=100, width = 11, height=9, plot=p)
  
  query = "select strftime('%Y-%m-%d', ts_cet) date, task_succeed, elt_topdomain topdomain, scriptname, count(*) number
            from run_avail
            where task_succeed = 0
            group by 1,2,3,4
            order by 1,2,3,4"
  df = db.query.dt(db, query)
  p = qplot(date_psx, number, data=df, geom="line", colour=scriptname) +
    labs(title = concat("Availability and errors per topdomain and day for CN script"), x="Date", y="Number") +
    facet_wrap(~ topdomain, scales="free_y", ncol=2)
  ggsave(concat("avail-errors-per-topdomain-script.png"), dpi=100, width = 11, height=9, plot=p)
  
  # gesommeerd over alle scripts
  query = "select strftime('%Y-%m-%d', ts_cet) date, task_succeed, elt_topdomain topdomain, count(*) number
            from run_avail
            where task_succeed = 0
            group by 1,2,3
            order by 1,2,3"
  df = db.query.dt(db, query)
  p = qplot(date_psx, number, data=df, geom="line", colour=topdomain) +
    labs(title = concat("Availability and errors per topdomain and day for CN scripts"), x="Date", y="Number")
  ggsave(concat("avail-errors-per-topdomain-script-1.png"), dpi=100, width = 11, height=9, plot=p)
  
  # met script-pages erbij voor soorten pages
  query = "select strftime('%Y-%m-%d', ts_cet) date, task_succeed, page_type, scriptname, count(*) number           
           from run_avail ra join script_pages sp on ra.scriptname = sp.scriptname and ra.err_page_seq = sp.page_seq
           where task_succeed = 0
           group by 1,2,3,4
           order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=number, fill=page_type)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and errors per pagetype and day for CN scripts (stacked)"), x="Date", y="Number") +
    facet_wrap(~ scriptname, scales="free", ncol=2) +
    theme(legend.position="bottom")
  
  ggsave("errors-per-pagetype-stacked.png", dpi=100, width = 17, height=9, plot=p)
  

  db.close(db)  
}

make.graphs.allflows.perc = function () {
  
  setwd("c:/projecten/Philips/Dashboards-CN")
  db = db.open("dashboards.db")
  
  # bovenstaande al ok, nog even onderstaande met available erbij.
  # deze gaat goed, alles totaal op 100%, maar wel verwarrend. Mss kleurstelling aanpassen, eerst bovenstaande houden.
  # ook avail als eerste, is nu opvulling tot 100%.
  # @todo check met known errors of totaal nog steeds 100% is.
  query = "select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, page_type page_error_type, ra.scriptname scriptname, count(*) number, 100.0 * count(*)/s.nmeas perc
              from run_avail ra 
              join script_pages sp on ra.scriptname = sp.scriptname and ra.err_page_seq = sp.page_seq
              join stat s on s.scriptname = ra.scriptname and s.date = strftime('%Y-%m-%d', ra.ts_cet)
              where task_succeed = 0
              and s.respavail = 'avail'
              and s.source = 'API'
              and ra.known_error = 0
              group by 1,2,3,4
              union all
              select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, ra.known_error_type page_error_type, ra.scriptname scriptname, count(*) number, 100.0 * count(*)/s.nmeas perc
              from run_avail ra 
              join stat s on s.scriptname = ra.scriptname and s.date = strftime('%Y-%m-%d', ra.ts_cet)
              where task_succeed = 0
              and s.respavail = 'avail'
              and s.source = 'API'
              and ra.known_error = 1
              group by 1,2,3,4
              union all
              select s.date, 1, '0-available' page_error_type, s.scriptname, s.nmeas number, 100.0 * s.value perc
              from stat s
              where s.respavail = 'avail'
              and s.source = 'API'
              order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=perc, fill=page_error_type)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and error-percentage per pagetype and day for CN scripts (perc)"), x="Date", y="Percentage") +
    # facet_wrap(~ scriptname, scales="free", ncol=2) +
    facet_wrap(~ scriptname, ncol=2) +
    theme(legend.position="bottom")
  
  ggsave("avail-errors-per-pagetype-perc2.png", dpi=100, width = 17, height=9, plot=p)

  # 1. naar percentages
  query = "select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, page_type page_error_type, ra.scriptname, count(*) number, 100.0 * count(*)/s.nmeas perc
            from run_avail ra 
            join script_pages sp on ra.scriptname = sp.scriptname and ra.err_page_seq = sp.page_seq
            join stat s on s.scriptname = ra.scriptname and s.date = strftime('%Y-%m-%d', ra.ts_cet)
            where task_succeed = 0
            and s.respavail = 'avail'
            and s.source = 'API'
            and ra.known_error = 0
            group by 1,2,3,4
            union all
            select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, ra.known_error_type page_error_type, ra.scriptname scriptname, count(*) number, 100.0 * count(*)/s.nmeas perc
            from run_avail ra 
            join stat s on s.scriptname = ra.scriptname and s.date = strftime('%Y-%m-%d', ra.ts_cet)
            where task_succeed = 0
            and s.respavail = 'avail'
            and s.source = 'API'
            and ra.known_error = 1
            group by 1,2,3,4
            order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=perc, fill=page_type)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and error-percentage per pagetype and day for CN scripts (perc)"), x="Date", y="Percentage") +
    # facet_wrap(~ scriptname, scales="free", ncol=2) +
    facet_wrap(~ scriptname, ncol=2) +
    theme(legend.position="bottom")
  
  ggsave("avail-errors-per-pagetype-perc.png", dpi=100, width = 17, height=9, plot=p)
  
  # Errors-per-topdomain-perc.png
  query = "select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, elt_topdomain topdomain, ra.scriptname, count(*) number, 100.0 * count(*)/s.nmeas perc
            from run_avail ra 
            join stat s on s.scriptname = ra.scriptname and s.date = strftime('%Y-%m-%d', ra.ts_cet)
            where task_succeed = 0
            and s.respavail = 'avail'
            and s.source = 'API'
            and ra.known_error = 0
            group by 1,2,3,4
            union all
            select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, ra.known_error_type page_error_type, ra.scriptname scriptname, count(*) number, 100.0 * count(*)/s.nmeas perc
            from run_avail ra 
            join stat s on s.scriptname = ra.scriptname and s.date = strftime('%Y-%m-%d', ra.ts_cet)
            where task_succeed = 0
            and s.respavail = 'avail'
            and s.source = 'API'
            and ra.known_error = 1
            group by 1,2,3,4
            order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=perc, fill=topdomain)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and error-percentage per topdomain and day for CN scripts (perc)"), x="Date", y="Percentage") +
    # facet_wrap(~ scriptname, scales="free", ncol=2) +
    facet_wrap(~ scriptname, ncol=2) +
    theme(legend.position="bottom")
  
  ggsave("Errors-per-topdomain-perc.png", dpi=100, width = 17, height=9, plot=p)
  
  # Errors-per-topdomain-perc-1.png - all scripts summed up
  query = "select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, elt_topdomain topdomain, count(*) number, s.tot_nmeas, 100.0 * count(*)/s.tot_nmeas perc
            from run_avail ra 
            join (select date, sum(nmeas) tot_nmeas
              from stat
              where respavail = 'avail'
              and source = 'API'
              group by 1) s on s.date = strftime('%Y-%m-%d', ra.ts_cet)
            where task_succeed = 0
            and ra.known_error = 0
            union all
            select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, known_error_type topdomain, count(*) number, s.tot_nmeas, 100.0 * count(*)/s.tot_nmeas perc
            from run_avail ra 
            join (select date, sum(nmeas) tot_nmeas
              from stat
              where respavail = 'avail'
              and source = 'API'
              group by 1) s on s.date = strftime('%Y-%m-%d', ra.ts_cet)
            where task_succeed = 0
            and ra.known_error = 1
            group by 1,2,3
            order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=perc, fill=topdomain)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and error-percentage per topdomain and day for CN scripts (perc)"), x="Date", y="Percentage") +
    theme(legend.position="bottom")
  
  ggsave("Errors-per-topdomain-perc-1.png", dpi=100, width = 17, height=9, plot=p)
  
  # then also graphs with just the unknown errors, one per pagetype and one per domain.
  # 1. naar percentages
  query = "select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, page_type page_error_type, ra.scriptname, count(*) number, 100.0 * count(*)/s.nmeas perc
            from run_avail ra 
            join script_pages sp on ra.scriptname = sp.scriptname and ra.err_page_seq = sp.page_seq
            join stat s on s.scriptname = ra.scriptname and s.date = strftime('%Y-%m-%d', ra.ts_cet)
            where task_succeed = 0
            and s.respavail = 'avail'
            and s.source = 'API'
            and ra.known_error = 0
            group by 1,2,3,4
            order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=perc, fill=page_type)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and error-percentage per pagetype and day for CN scripts (perc)"), x="Date", y="Percentage") +
    # facet_wrap(~ scriptname, scales="free", ncol=2) +
    facet_wrap(~ scriptname, ncol=2) +
    theme(legend.position="bottom")
  
  ggsave("avail-errors-per-pagetype-perc-unknown.png", dpi=100, width = 17, height=9, plot=p)
  
  # Errors-per-topdomain-perc.png
  query = "select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, elt_topdomain topdomain, ra.scriptname, count(*) number, 100.0 * count(*)/s.nmeas perc
            from run_avail ra 
            join stat s on s.scriptname = ra.scriptname and s.date = strftime('%Y-%m-%d', ra.ts_cet)
            where task_succeed = 0
            and s.respavail = 'avail'
            and s.source = 'API'
            and ra.known_error = 0
            group by 1,2,3,4
            order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=perc, fill=topdomain)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and error-percentage per topdomain and day for CN scripts (perc)"), x="Date", y="Percentage") +
    # facet_wrap(~ scriptname, scales="free", ncol=2) +
    facet_wrap(~ scriptname, ncol=2) +
    theme(legend.position="bottom")
  
  ggsave("Errors-per-topdomain-perc-unknown.png", dpi=100, width = 17, height=9, plot=p)
  
  # Errors-per-topdomain-perc-1.png - all scripts summed up
  query = "select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, elt_topdomain topdomain, count(*) number, s.tot_nmeas, 100.0 * count(*)/s.tot_nmeas perc
            from run_avail ra 
            join (select date, sum(nmeas) tot_nmeas
              from stat
              where respavail = 'avail'
              and source = 'API'
              group by 1) s on s.date = strftime('%Y-%m-%d', ra.ts_cet)
            where task_succeed = 0
            and ra.known_error = 0
            order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=perc, fill=topdomain)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and error-percentage per topdomain and day for CN scripts (perc)"), x="Date", y="Percentage") +
    theme(legend.position="bottom")
  
  ggsave("Errors-per-topdomain-perc-1-unknown.png", dpi=100, width = 17, height=9, plot=p)
  
  db.close(db)
}

make.graphs.allflows.perc.old = function () {
  
  setwd("c:/projecten/Philips/Dashboards-CN")
  db = db.open("dashboards.db")
  
  # @todo naar percentages omzetten en available erbij (mss met union)
  # 1. naar percentages
  
  query = "select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, page_type, ra.scriptname, count(*) number, 100.0 * count(*)/s.nmeas perc
  from run_avail ra 
  join script_pages sp on ra.scriptname = sp.scriptname and ra.err_page_seq = sp.page_seq
  join stat s on s.scriptname = ra.scriptname and s.date = strftime('%Y-%m-%d', ra.ts_cet)
  where task_succeed = 0
  and s.respavail = 'avail'
  and s.source = 'API'
  group by 1,2,3,4
  order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=perc, fill=page_type)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and error-percentage per pagetype and day for CN scripts (perc)"), x="Date", y="Percentage") +
    # facet_wrap(~ scriptname, scales="free", ncol=2) +
    facet_wrap(~ scriptname, ncol=2) +
    theme(legend.position="bottom")
  
  ggsave("avail-errors-per-pagetype-perc.png", dpi=100, width = 17, height=9, plot=p)
  
  # bovenstaande al ok, nog even onderstaande met available erbij.
  # deze gaat goed, alles totaal op 100%, maar wel verwarrend. Mss kleurstelling aanpassen, eerst bovenstaande houden.
  # ook avail als eerste, is nu opvulling tot 100%.
  query = "select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, page_type, ra.scriptname scriptname, count(*) number, 100.0 * count(*)/s.nmeas perc
  from run_avail ra 
  join script_pages sp on ra.scriptname = sp.scriptname and ra.err_page_seq = sp.page_seq
  join stat s on s.scriptname = ra.scriptname and s.date = strftime('%Y-%m-%d', ra.ts_cet)
  where task_succeed = 0
  and s.respavail = 'avail'
  and s.source = 'API'
  group by 1,2,3,4
  union
  select s.date, 1, '0-available', s.scriptname, s.nmeas number, 100.0 * s.value perc
  from stat s
  where s.respavail = 'avail'
  and s.source = 'API'
  order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=perc, fill=page_type)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and error-percentage per pagetype and day for CN scripts (perc)"), x="Date", y="Percentage") +
    # facet_wrap(~ scriptname, scales="free", ncol=2) +
    facet_wrap(~ scriptname, ncol=2) +
    theme(legend.position="bottom")
  
  ggsave("avail-errors-per-pagetype-perc2.png", dpi=100, width = 17, height=9, plot=p)
  
  # Errors-per-topdomain-perc.png
  query = "select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, elt_topdomain topdomain, ra.scriptname, count(*) number, 100.0 * count(*)/s.nmeas perc
  from run_avail ra 
  join stat s on s.scriptname = ra.scriptname and s.date = strftime('%Y-%m-%d', ra.ts_cet)
  where task_succeed = 0
  and s.respavail = 'avail'
  and s.source = 'API'
  group by 1,2,3,4
  order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=perc, fill=topdomain)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and error-percentage per topdomain and day for CN scripts (perc)"), x="Date", y="Percentage") +
    # facet_wrap(~ scriptname, scales="free", ncol=2) +
    facet_wrap(~ scriptname, ncol=2) +
    theme(legend.position="bottom")
  
  ggsave("Errors-per-topdomain-perc.png", dpi=100, width = 17, height=9, plot=p)
  
  # Errors-per-topdomain-perc-1.png - all scripts summed up
  query = "select strftime('%Y-%m-%d', ra.ts_cet) date, task_succeed, elt_topdomain topdomain, count(*) number, s.tot_nmeas, 100.0 * count(*)/s.tot_nmeas perc
  from run_avail ra 
  join (select date, sum(nmeas) tot_nmeas
  from stat
  where respavail = 'avail'
  and source = 'API'
  group by 1) s on s.date = strftime('%Y-%m-%d', ra.ts_cet)
  where task_succeed = 0
  group by 1,2,3
  order by 1,2,3"
  df = db.query.dt(db, query)
  
  # in ggplot2 geen textures/fill patterns mogelijk (Hadley, 25-5-2010)
  p = ggplot(df, aes(x=date_psx, y=perc, fill=topdomain)) + 
    geom_bar(stat = "identity") +
    labs(title = concat("Availability and error-percentage per topdomain and day for CN scripts (perc)"), x="Date", y="Percentage") +
    theme(legend.position="bottom")
  
  ggsave("Errors-per-topdomain-perc-1.png", dpi=100, width = 17, height=9, plot=p)
  
  db.close(db)  
}
