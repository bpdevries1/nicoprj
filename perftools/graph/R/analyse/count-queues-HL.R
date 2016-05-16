setwd("G:\\Testware\\Scripts\\Analyse-R")
source("TSLlib.R")
load.def.libs()

main = function() {
  # testnr = "449"
  testnr = commandArgs()[6]
  while (TRUE) {
    print("measure.queues")
    measure.queues(testnr) 
    print("sleep")
    Sys.sleep(300)
  }
}  
  
measure.queues = function(testnr) {
  connstring.huur = det.connstring("ATBSQLW000", "Huur")
  connstring.kot = det.connstring("ATBSQLW000", "KinderOpvang")
  connstring.pt = det.connstring.PT(testnr)
  outdir = det.outdir(testnr)
  con.huur = odbcDriverConnect(connection=connstring.huur)
  con.kot = odbcDriverConnect(connection=connstring.kot)
  con.pt = odbcDriverConnect(connection=connstring.pt)
  
  q.huur = "WITH ct (cur_ts, queue) as (select CURRENT_TIMESTAMP, 'HerberekenenBepalenHuurLastenQueue')
            SELECT ct.cur_ts, ct.queue, [CEventID], count(*) aantal
            FROM [Huur].[dbo].[HerberekenenBepalenHuurlastenQueue] WITH(NOLOCK), ct
            group by ct.cur_ts, ct.queue, ceventid"
  df.huur = sqlQuery(con.huur, q.huur)
 
  #sqlSave(con.pt, df.huur, "queuecount")
  #sqlSave(con.pt, df.huur, "queuecount", rownames=FALSE, append=TRUE, test=TRUE)
  sqlSave(con.pt, df.huur, "queuecount", rownames=FALSE, append=TRUE)

  q.kot  = "WITH ct (cur_ts, queue) as (select CURRENT_TIMESTAMP, 'HerberekenenBepalenKinderopvanglastenQueue')
            SELECT ct.cur_ts, ct.queue, [CEventID], count(*) aantal
            FROM [KinderOpvang].[dbo].[HerberekenenBepalenKinderopvanglastenQueue] WITH(NOLOCK), ct
            group by ct.cur_ts, ct.queue, ceventid"
  df.kot = sqlQuery(con.kot, q.kot)
  
  sqlSave(con.pt, df.kot, "queuecount", rownames=FALSE, append=TRUE)
  
  odbcClose(con.huur)
  odbcClose(con.kot)
  odbcClose(con.pt)
  
}

main()
