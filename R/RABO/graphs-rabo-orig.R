# source("~/nicoprj/R/lib/ndvlib.R")

source("C:/PCC/Nico/nicoprj/R/lib/ndvlib.R")

load.def.libs()

main = function () {
  load.def.libs()
  make.load.graphs("C:/PCC/Nico/Projecten/RCC - Cash Balances/run206", "2015-06-10 09:00", "2015-06-10 12:30")
  make.load.graphs("C:/PCC/Nico/Projecten/RCC - Cash Balances/run208", "2015-06-10 09:00", "2015-06-10 19:30")
}

make.load.graphs = function(dir, mintime, maxtime) {
  setwd(dir)
  db = db.open("vuserlog.db")

  make.load.graphs.part(db, "2015-01-01","2020-01-01", "all")
  make.load.graphs.part(db, mintime, maxtime, "sel")
  
  db.close(db)
}

make.load.graphs.part = function(db, mintime, maxtime, tp) {
  query = paste0("select ts_cet ts, 1*naccts naccts, 1.0*resptime resptime
         from request
         where ts_cet between '", mintime, "' and '", maxtime, "'")
  df = db.query.dt(db, query)
  p = qplot(ts_psx, resptime, data=df)
  ggsave(paste0("resptime-in-time-", tp, ".png"), dpi=100, width = 9, height=7, plot=p)
  p = qplot(naccts, resptime, data=df)
  ggsave(paste0("resptime-per-naccts-", tp, ".png"), dpi=100, width = 9, height=7, plot=p)
  
  query = paste0("select 1*naccts naccts, avg(1.0*resptime) avg_resptime
         from request
         where ts_cet between '", mintime, "' and '", maxtime, "'
         group by 1")
  df = db.query.dt(db, query)
  p = qplot(naccts, avg_resptime, data=df)
  ggsave(paste0("resptime-avg-per-naccts-", tp, ".png"), dpi=100, width = 9, height=7, plot=p)
}

main()
