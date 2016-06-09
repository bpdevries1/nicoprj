#source("C:/PCC/Nico/nicoprj/R/lib/ndvlib.R")
#source("C:\\PCC\\Nico\\nicoprj\\R\\RABO\\perflib.R")
#source("C:\\PCC\\Nico\\nicoprj\\R\\lib\\HTMLlib.R")

source("C:/PCC/Nico/nicoprj/perftools/graph/R/lib/ndvlib.R")
#source("C:/PCC/Nico/nicoprj/perftools/graph/R/current/perflib.R")
#source("C:/PCC/Nico/nicoprj/perftools/graph/R/lib/HTMLlib.R")

load.def.libs()

main = function() {
  # dir = "C:\\PCC\\Nico\\Projecten-no-sync\\Scrittura\\DT-reports\\2016-01-28-week-deel"
  dir = "C:/PCC/Nico/Projecten/Scrittura/Troubleshoot-2016/analysis/20160606-1500" 
  # filename = "purepaths.db"
  filename = "analysis.db"
  
#  make.graphs(dir, filename)
  make.graphs("C:/PCC/Nico/Projecten/Scrittura/Troubleshoot-2016/analysis/20160606-1500", "analysis.db")
  make.graphs("C:/PCC/Nico/Projecten/Scrittura/Troubleshoot-2016/analysis/20160606-1600", "20160606-1600.db")
}

make.graphs = function(dir, filename) {
  setwd(dir)
  db = db.open(filename)
  query = "select Start_Time ts_start, End_Time ts_end, wait_type, Client_IP, Thread_Name
           from report"
  df = db.query.dt(db, query)

  graph.conc(df, "ts_start.psx", "ts_end.psx", "#conc pure paths", "Purepaths-concurrent.png")
  
  graph.gantt(df, "ts_start.psx", "ts_end.psx", "Thread_Name", "wait_type", "purepaths-waittype.png")
  graph.gantt(df, "ts_start.psx", "ts_end.psx", "Thread_Name", "Client_IP", "purepaths-clientip.png")  
  graph.gantt(df, "ts_start.psx", "ts_end.psx", "Client_IP", "wait_type", "purepaths-clientip-waittype.png")  
  graph.gantt.facet(df, "ts_start.psx", "ts_end.psx", "Thread_Name", "wait_type", "Client_IP", "purepaths-waittype-ip")  
  
  db.close(db)
}



main()


