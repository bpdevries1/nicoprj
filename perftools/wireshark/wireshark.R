library(ggplot2)
library(RSQLite)

plot.network = function(db_name, ipsrc = "10.16.16.205") {
  db = dbConnect(dbDriver("SQLite"), db_name)
  df = dbGetQuery(db, paste("select tcpstream, first, last, ipdst||':'||portdst dest from tcpstream where ipsrc = '", ipsrc, "'", sep = ""))
  dfr = dbGetQuery(db, "select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2 where r.req_num = p1.packetnum and r.resp_num = p2.packetnum")
  ggplot(x=time, y=segment) + 
    # geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest))) +
    geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = dest)) +
    geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm"))) +
    opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
    scale_x_datetime(format="%H:%M:%S", name="Time", major = "30 sec", minor = "10 sec")
  ggsave(paste(db_name, ".png", sep=""), width = 10, height = 8, dpi=100)
  dbDisconnect(db)
}

# starttime en endtime are floats, seconds since epoch.
# 15-2-2012 NdV join arrows and stripes in one graph.
plot.network.trans.startend = function(db_name, ipsrc = "10.16.16.205", transfile='', starttime=0, endtime=0, outbasename=db_name) {
  db = dbConnect(dbDriver("SQLite"), db_name)
  if (endtime == 0) {
    endtime = 9328869727 ; # voorlopig groot genoeg?
  }
  print(1)
  df = dbGetQuery(db, paste("select tcpstream, first, last, ipdst||':'||portdst dest from tcpstream s where s.ipsrc = '", 
    ipsrc, "' and s.first < ", endtime, " and s.last > ", starttime, " and tcpstream > 0 ", sep = ""))
  if (length(df$tcpstream) == 0) {
    print("WARN: df dataframe is emtpy") 
  }
  print(2)
  dfp = dbGetQuery(db, paste("select p.packetnum, p.timestamp, p.ipsrc, s.ipdst||':'||s.portdst dest, p.tcpstream from packet p, tcpstream s where s.tcpstream = p.tcpstream ",
                             "and s.ipsrc = '", ipsrc, "' and s.first < ", endtime, " and s.last > ", starttime, " and s.tcpstream > 0 ", sep = ""))
  dfp2 = ddply(dfp, .(packetnum, timestamp, dest, tcpstream), function(df) {
    value = df$tcpstream + ifelse(df$ipsrc == ipsrc, 0.3, -0.3)
    c(stream.offset = value)
  })
  
  dfr = dbGetQuery(db, paste("select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2, tcpstream s where r.req_num = p1.packetnum ", 
     "and r.resp_num = p2.packetnum and s.tcpstream=r.stream and p1.timestamp < ", endtime, " and p2.timestamp > ", starttime, sep = ""))
  if (length(dfr$stream) == 0) {
    print("WARN: dfr dataframe is emtpy") 
  }
  print(3)
  #max.stream = max(df$tcpstream)
  #print(max.stream)
  print(4)
  if (transfile != '') {
    dfs = read.csv(transfile)
  # dfs$maxs = maxs
    print(5)
    dfs$maxs = max(df$tcpstream)
    dfs$mins = min(df$tcpstream)
  }
  print(6)
  p = ggplot(x=time, y=segment) + 
    geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = dest)) +
    geom_segment(data=dfp2, aes(x=timestamp, y=tcpstream, xend = timestamp, yend = stream.offset, colour = dest)) +
    opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
    scale_x_datetime(format="%H:%M:%S", name="Time", major = "30 sec", minor = "10 sec") +
    # scale_y_continuous(limits=range(df$tcpstream))
    scale_y_continuous(limits= c(min(df$tcpstream)-1, max(df$tcpstream) + 1))
  if (transfile != '') {
    p = p + geom_rect(data=dfs, aes(xmin=start, ymin = mins-1, xmax=stop, ymax=maxs+1), colour="white", alpha=I(.1)) +
    geom_text(data=dfs, aes(x=start, y=maxs+1, label=transaction, hjust=0, vjust=0))
  }
  # 16-2-2012 nu even zonder pijltjes:
  if (length(dfr$stream) > 0) {    
    # niet altijd roundtrip in de periode, toch rest wel plotten.
    # p = p + geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm")))    
  }
  if (starttime > 0) {
    # coord_cartesian(xlim = c(starttime - 30, endtime + 30), ylim = c(min(df$tcpstream)-1, max(df$tcpstream) + 5)) +
    p = p + coord_cartesian(xlim = c(starttime - 30, endtime + 30))  
  }
  print(p)
  print(7)
  ggsave(paste(outbasename, ".png", sep=""), width = 10, height = 8, dpi=100)
  ggsave(paste(outbasename, "-big.png", sep=""), width = 100, height = 8, dpi=100)
  print(8)
  dbDisconnect(db)
  print(99)
}

plot.network.trans.startend.old = function(db_name, ipsrc = "10.16.16.205", transfile, starttime, endtime, outbasename=db_name) {
  db = dbConnect(dbDriver("SQLite"), db_name)
  print(1)
  df = dbGetQuery(db, paste("select tcpstream, first, last, ipdst||':'||portdst dest from tcpstream s where s.ipsrc = '", 
    ipsrc, "' and s.first < ", endtime, " and s.last > ", starttime, " and tcpstream > 0 ", sep = ""))
  if (length(df$tcpstream) == 0) {
    print("WARN: df dataframe is emtpy") 
  }
  print(2)
  dfp = dbGetQuery(db, paste("select p.packetnum, p.timestamp, p.ipsrc, s.ipdst||':'||s.portdst dest, p.tcpstream from packet p, tcpstream s where s.tcpstream = p.tcpstream ",
                             "and s.ipsrc = '", ipsrc, "' and s.first < ", endtime, " and s.last > ", starttime, " and s.tcpstream > 0 ", sep = ""))
  dfp2 = ddply(dfp, .(packetnum, timestamp, dest, tcpstream), function(df) {
    value = df$tcpstream + ifelse(df$ipsrc == ipsrc, 0.3, -0.3)
    c(stream.offset = value)
  })
  
  #dfr = dbGetQuery(db, paste("select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2, tcpstream s where r.req_num = p1.packetnum ", 
  #   "and r.resp_num = p2.packetnum and s.tcpstream=r.stream and p1.timestamp < ", endtime, " and p2.timestamp > ", starttime, sep = ""))
  #if (length(dfr$stream) == 0) {
  #  print("WARN: dfr dataframe is emtpy") 
  #}
  print(3)
  #max.stream = max(df$tcpstream)
  #print(max.stream)
  print(4)
  dfs = read.csv(transfile)
  # dfs$maxs = maxs
  print(5)
  dfs$maxs = max(df$tcpstream)
  dfs$mins = min(df$tcpstream)
  print(6)
  p = ggplot(x=time, y=segment) + 
    geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = dest)) +
    geom_segment(data=dfp2, aes(x=timestamp, y=tcpstream, xend = timestamp, yend = stream.offset, colour = dest)) +
    geom_rect(data=dfs, aes(xmin=start, ymin = mins-1, xmax=stop, ymax=maxs+1), colour="white", alpha=I(.1)) +
    geom_text(data=dfs, aes(x=start, y=maxs+1, label=transaction, hjust=0, vjust=0)) +
    opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
    # bij y-as 5 erbij om labels te tonen.
    # coord_cartesian(xlim = c(starttime - 30, endtime + 30), ylim = c(min(df$tcpstream)-1, max(df$tcpstream) + 5)) +
    coord_cartesian(xlim = c(starttime - 30, endtime + 30)) +
    scale_x_datetime(format="%H:%M:%S", name="Time", major = "30 sec", minor = "10 sec") +
    # scale_y_continuous(limits=range(df$tcpstream))
    scale_y_continuous(limits= c(min(df$tcpstream)-1, max(df$tcpstream) + 1))
  #if (length(dfr$stream) > 0) {    
  #  # niet altijd roundtrip in de periode, toch rest wel plotten.
  #  p = p + geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm")))    
  #}
  print(p)
  print(7)
  ggsave(paste(outbasename, ".png", sep=""), width = 10, height = 8, dpi=100)
  ggsave(paste(outbasename, "-big.png", sep=""), width = 100, height = 8, dpi=100)
  print(8)
  dbDisconnect(db)
  print(99)
}

# starttime en endtime are floats, seconds since epoch.
plot.network.trans.startend.http = function(db_name, ipsrc = "10.16.16.205", transfile, starttime, endtime, outbasename=db_name) {
  db = dbConnect(dbDriver("SQLite"), db_name)
  print(1)
  df = dbGetQuery(db, paste("select tcpstream, first, last, ipdst||':'||portdst dest from tcpstream s where s.ipsrc = '", 
    ipsrc, "' and s.first < ", endtime, " and s.last > ", starttime, " and tcpstream >= 0 ", sep = ""))
  if (length(df$tcpstream) == 0) {
    print("WARN: df dataframe is emtpy") 
  }
  print(2)
  dfr = dbGetQuery(db, paste("select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2, tcpstream s where r.req_num = p1.packetnum ", 
     "and r.resp_num = p2.packetnum and s.tcpstream=r.stream and p1.timestamp < ", endtime, " and p2.timestamp > ", starttime, sep = ""))
  if (length(dfr$stream) == 0) {
    print("WARN: dfr dataframe is emtpy") 
  }
  print(3)
  #max.stream = max(df$tcpstream)
  #print(max.stream)
  print(4)
  dfs = read.csv(transfile)
  # dfs$maxs = maxs
  print(5)
  dfs$maxs = max(df$tcpstream)
  print(6)
  p = ggplot(x=time, y=segment) + 
    # geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest))) +
    geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = dest)) +
    geom_rect(data=dfs, aes(xmin=start, ymin = 0, xmax=stop, ymax=maxs), colour="white", alpha=I(.1)) +
    geom_text(data=dfs, aes(x=start, y=maxs, label=transaction, hjust=0, vjust=0)) +
    opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
    # xlim(starttime - 30, endtime + 30) +
    # xlim(starttime, endtime) + 14-2-2012 werkt in nieuwe versie, mss nog niet in de mijne.
    coord_cartesian(xlim = c(starttime - 30, endtime + 30)) +
    scale_x_datetime(format="%H:%M:%S", name="Time", major = "30 sec", minor = "10 sec") +
    scale_y_continuous(limits=range(df$tcpstream))
  if (length(dfr$stream) > 0) {    
    # niet altijd roundtrip in de periode, toch rest wel plotten.
    p = p + geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm")))    
  }
  print(p)
  print(7)
  ggsave(paste(outbasename, ".png", sep=""), width = 10, height = 8, dpi=100)
  ggsave(paste(outbasename, "-big.png", sep=""), width = 100, height = 8, dpi=100)
  print(8)
  dbDisconnect(db)
  print(99)
}

plot.network.trans = function(db_name, ipsrc = "10.16.16.205", transfile) {
  db = dbConnect(dbDriver("SQLite"), db_name)
  df = dbGetQuery(db, paste("select tcpstream, first, last, ipdst||':'||portdst dest from tcpstream where ipsrc = '", ipsrc, "'", sep = ""))
  dfr = dbGetQuery(db, "select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2 where r.req_num = p1.packetnum and r.resp_num = p2.packetnum")
  
  #max.stream = max(df$tcpstream)
  #print(max.stream)
  dfs = read.csv(transfile)
  # dfs$maxs = maxs
  dfs$maxs = max(df$tcpstream)
  
  p = ggplot(x=time, y=segment) + 
    # geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest))) +
    geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = dest)) +
    geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm"))) +
    geom_rect(data=dfs, aes(xmin=start, ymin = 0, xmax=stop, ymax=maxs), alpha=I(.1)) +
    geom_text(data=dfs, aes(x=start, y=maxs, label=transaction, hjust=0, vjust=0)) +
    opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
    scale_x_datetime(format="%H:%M:%S", name="Time", major = "30 sec", minor = "10 sec")
  print(p)
  
  ggsave(paste(db_name, ".png", sep=""), width = 10, height = 8, dpi=100)
  dbDisconnect(db)
}

plot.network.trans.old = function(db_name, ipsrc = "10.16.16.205", transfile) {
  db = dbConnect(dbDriver("SQLite"), db_name)
  df = dbGetQuery(db, paste("select tcpstream, first, last, ipdst||':'||portdst dest from tcpstream where ipsrc = '", ipsrc, "'", sep = ""))
  dfr = dbGetQuery(db, "select r.stream stream, p1.timestamp req, p2.timestamp resp from roundtrip r, packet p1, packet p2 where r.req_num = p1.packetnum and r.resp_num = p2.packetnum")
  
  #max.stream = max(df$tcpstream)
  #print(max.stream)
  dfs = read.csv(transfile)
  # dfs$maxs = maxs
  dfs$maxs = max(df$tcpstream)
  
  ggplot(x=time, y=segment) + 
    # geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = as.factor(dest))) +
    geom_segment(data=df, aes(x=first, y=tcpstream, xend = last, yend = tcpstream, colour = dest)) +
    geom_segment(data=dfr, aes(x=req, y=stream, xend = resp, yend = stream), arrow=arrow(length=unit(0.1,"cm"))) +
    geom_rect(data=dfs, aes(xmin=start, ymin = 0, xmax=stop, ymax=maxs), alpha=I(.1)) +
    geom_text(data=dfs, aes(x=start, y=maxs, label=transaction, hjust=0, vjust=0)) +
    opts(legend.position=c(0.05, 0.95), legend.justification=c(0,1)) +
    scale_x_datetime(format="%H:%M:%S", name="Time", major = "30 sec", minor = "10 sec")

  ggsave(paste(db_name, ".png", sep=""), width = 10, height = 8, dpi=100)
  dbDisconnect(db)
}

show.ips = function(db_name) {
  db = dbConnect(dbDriver("SQLite"), db_name)
  print(dbGetQuery(db, "select count(*), ipsrc from packet group by 2 order by 1 desc limit 5"))
  dbDisconnect(db)
}

