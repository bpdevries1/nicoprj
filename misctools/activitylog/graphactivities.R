init = function(db_name) {
  library(ggplot2)
  library(RSQLite)
  
  # db_name = "model.db"
  db = dbConnect(dbDriver("SQLite"), db_name)
  db
}

plot.timegroups = function(db, timegroup_id, graph_basename, tg_date) {
  query = paste("select i.group_name groupname, e.ts_start ts_start, e.ts_end ts_end from event e, eventinfo i where i.event_id = e.id and i.timegroup_id = ", timegroup_id, " order by i.group_name", sep="")
  df = dbGetQuery(db, query)
  df$psx_start = as.POSIXct(df$ts_start, format ="%Y-%m-%d %H:%M:%S")
  df$psx_end   = as.POSIXct(df$ts_end, format ="%Y-%m-%d %H:%M:%S")
  qplot(data=df, x=psx_start, y=groupname,  xend = psx_end, yend = groupname, 
    geom="segment", xlab = "Time", ylab = "Title group")  +
    opts(legend.position=c(0.95, 0.95), legend.justification=c(1,1)) +
    scale_x_datetime(major="1 hour", minor="15 min", format="%H:%M")
  graph_filename = paste(graph_basename, tg_date, "-", timegroup_id, ".png", sep="")
  # wil een inch per uur in de breedte, soms 24 uur grafiek, niet te lezen dan.
  # ggsave(graph_filename, width = 7, height = 4, dpi=100)
  # 18-2-2012 voor nu even flink breed.
  ggsave(graph_filename, width = 20, height = 4, dpi=100)
}

main = function() {
  print(commandArgs())
  idx = 1; # first index of user parameter, using TRUE in commandArgs
  db_name = commandArgs(TRUE)[idx];                 idx=idx+1; 
  graph_basename = commandArgs(TRUE)[idx];                 idx=idx+1;
  # graph_basename = "titlegroup-" 
  # db_name = "activ-2011-12-22.db"
  db = init(db_name)
  dftg = dbGetQuery(db, "select id, strftime('%Y-%m-%d', ts_start) tg_date from timegroup order by id")
  for (tg_id in dftg$id) {
    plot.timegroups(db, tg_id, graph_basename, dftg$tg_date[1])
  }
}

main()
