source("C:/PCC/Nico/nicoprj/R/lib/ndvlib.R")
source("C:\\PCC\\Nico\\nicoprj\\R\\RABO\\perflib.R")
source("C:\\PCC\\Nico\\nicoprj\\R\\lib\\HTMLlib.R")
load.def.libs()

main = function() {
  # dir = "C:\\PCC\\Nico\\Projecten\\Scrittura\\Troubleshoot-dec-2015\\purepaths"
  # dir = "C:\\PCC\\Nico\\Projecten-no-sync\\Scrittura\\DT-exports\\2016-01-25-week"
  dir = "C:\\PCC\\Nico\\Projecten-no-sync\\Scrittura\\DT-reports\\2016-01-28-week-deel"
  
  # filename = "purepaths.db"
  filename = "2016-01-28-week-deel.db"
  
  make.graphs(dir, filename)
}

make.graphs = function(dir, filename) {
  setwd(dir)
  db = db.open(filename)
  
  query = "select rp.id period_id, r.*
           from report r join req_period rp on rp._id = r._id
           "
  df = db.query.dt(db, query)
  df$ts.start.psx = as.POSIXct(strptime(df$Start_Time, format="%Y-%m-%d %H:%M:%OS"))
  df$ts.end.psx  = as.POSIXct(strptime(df$End_Time,  format="%Y-%m-%d %H:%M:%OS"))
  
  d_ply(df, .(period_id), function(dft) {
    # testje of yend=y werkt -> niet dus.
    if (det.height(dft) > 2.2) {
      # minimaal 2 threads.
      qplot(x=ts.start.psx, xend=ts.end.psx, y=Thread_Name, yend=Thread_Name, colour = wait_type, lwd=10, data=dft, 
            geom="segment", xlab = NULL, ylab=NULL,
            main = sprintf("Requests in period: %d",
                           dft$period_id[1])) +
        scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M:%OS")) +
        scale_y_discrete(limits = rev(levels(as.factor(dft$Thread_Name)))) + 
        guides(lwd=FALSE) +
        theme(legend.position="bottom")
      
      fn.graph = sprintf("period-requests-%04d.png", dft$period_id[1])
      ggsave(filename=fn.graph, width=12, height=det.height(dft), dpi=100)
    }
  })
  
  db.close(db)
}

det.height = function(df) {
  nq = length(ddply(df, .(Thread_Name), function(dft) {c(n=1)})$Thread_Name)
  2 + 0.20 * nq
  #9
}

main()


