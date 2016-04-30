source("C:/PCC/Nico/nicoprj/R/lib/ndvlib.R")
source("C:\\PCC\\Nico\\nicoprj\\R\\RABO\\perflib.R")
# source("C:\\PCC\\Nico\\nicoprj\\R\\lib\\HTMLlib.R")
load.def.libs()

main = function() {
  dir = "C:\\PCC\\Nico\\projecten-no-sync\\scrittura\\LST-20160401\\csv"
  filename = "csv.db"
  
  make.graphs(dir, filename)
}

make.graphs = function(dir, filename) {
  setwd(dir)
  db = db.open(filename)
  
  query = "select ts_cet ts, queue, cnt
           from scritconf
           where queue not in ('Delivery Failure')
           and queue in (
              select queue
              from scritconf
              group by 1
              having max(cnt) > min(cnt)
           )"
  df = db.query.dt(db, query)
  qplot.dt(x=ts_psx, y=cnt, colour = queue, shape=queue, data=df, 
        geom="point", xlab = NULL, ylab=NULL,
        main = "Queue sizes", filename="queue-sizes.png", facets = queue ~ .)

  query = "select count(*) cnt, strftime('%Y-%m-%d %H:%M', ts_cet) || ':00' ts, STP || '-' || Channel || '-' || MM type
from mqput p
join template t on t.template = p.template
group by 2,3
order by 2,3"
  df = db.query.dt(db, query)
  qplot.dt(x=ts_psx, y=cnt, colour = type, shape=type, data=df, 
           geom="point", xlab = NULL, ylab=NULL,
           main = "MQ put", filename="mqput.png")
  
  query = "select count(*) cnt, strftime('%Y-%m-%d %H:%M', ts_cet) || ':00' ts, 'mail' type
from mqput p
join template t on t.template = p.template
where channel like '%Mail%'
group by 2,3
order by 2,3"
  
  qplot.dt(x=ts_psx, y=cnt, colour = type, shape=type, data=db.query.dt(db, query), 
           geom="point", xlab = NULL, ylab=NULL,
           main = "MQ put (mail)", filename="mqput-mail.png")
  
  query = "select count(*) cnt, strftime('%Y-%m-%d %H:%M', ts_cet) || ':00' ts, status
  from mqget p
  where ts_cet > '2016-04-01 10:45'
  group by 2,3
  order by 2,3"
  df = db.query.dt(db, query)
  qplot.dt(x=ts_psx, y=cnt, colour = status, shape=status, data=df, 
           geom="point", xlab = NULL, ylab=NULL,
           main = "MQ get", filename="mqget.png")
  
  query = "select count(*) cnt, strftime('%Y-%m-%d %H:%M', ts_cet) || ':00' ts, 'docgen' gen
  from docgen
  where ts_cet > '2016-04-01 10:45'
  group by 2
  union
  select count(*) cnt, strftime('%Y-%m-%d %H:%M', ts_cet) || ':00' ts, 'pdfgen' gen
  from pdfgenok
  where ts_cet > '2016-04-01 10:45'
  group by 2
  order by 2"

  qplot.dt(x=ts_psx, y=cnt, colour = gen, shape=gen, data=db.query.dt(db, query), 
           geom="point", xlab = NULL, ylab=NULL,
           main = "Doc/PDF gen", filename="docpdfgen.png")

  query = "select count(*) cnt, strftime('%Y-%m-%d %H:%M', ts_cet) || ':00' ts, 'outlrepl' type
from outlrepl
group by 2,3
order by 2,3"
  
  qplot.dt(x=ts_psx, y=cnt, colour = type, shape=type, data=db.query.dt(db, query), 
           geom="point", xlab = NULL, ylab=NULL,
           main = "Outlook reply", filename="outlrepl.png")
  
  query = "select count(*) cnt, strftime('%Y-%m-%d %H:%M', ts_cet) || ':00' ts, 'exchconn' type
from exchconn
group by 2,3
order by 2,3"
  
  qplot.dt(x=ts_psx, y=cnt, colour = type, shape=type, data=db.query.dt(db, query), 
           geom="point", xlab = NULL, ylab=NULL,
           main = "Exchange connector", filename="exchconn.png")
  
  query = "select count(*) cnt, strftime('%Y-%m-%d %H:%M', ts_cet) || ':00' ts, 'msgid' type
from connfw
where msgid <> '<none>'
and ts_cet > '2016-04-01 10:45'
group by 2,3
union
select count(*) cnt, strftime('%Y-%m-%d %H:%M', ts_cet) || ':00' ts, 'none' type
from connfw
where msgid = '<none>'
and ts_cet > '2016-04-01 10:45'
group by 2,3
order by 2,3"
  
  qplot.dt(x=ts_psx, y=cnt, colour = type, shape=type, data=db.query.dt(db, query), 
           geom="point", xlab = NULL, ylab=NULL,
           main = "Connector framework", filename="connfw.png")
  
  query = "select count(*) cnt, strftime('%Y-%m-%d %H:%M', ts_cet) || ':00' ts, 'xml-fw' type
from xmlfw
where ts_cet > '2016-04-01 10:45'
group by 2,3
order by 2,3"
  
  qplot.dt(x=ts_psx, y=cnt, colour = type, shape=type, data=db.query.dt(db, query), 
           geom="point", xlab = NULL, ylab=NULL,
           main = "Dropbox XML forwarder", filename="xmlfw.png")
  
  # cumulative, prepare in DB by queries
  query = "select ts_cet ts, type, cnt
from allmsg"
  
  qplot.dt(x=ts_psx, y=cnt, colour = type, shape=type, data=db.query.dt(db, query), 
           geom="point", xlab = NULL, ylab=NULL,
           main = "Cumulative #msg (all)", filename="cumu-all.png")
  
  query = "select ts_cet ts, type, cnt
from mailmsg"
  
  qplot.dt(x=ts_psx, y=cnt, colour = type, shape=type, data=db.query.dt(db, query), 
           geom="point", xlab = NULL, ylab=NULL,
           main = "Cumulative #msg (mail)", filename="cumu-mail.png")
  
  db.close(db)
}


main()


