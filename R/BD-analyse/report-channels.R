setwd("G:\\Testware\\Scripts\\Analyse-R")
source("TSLlib.R")
source("HTMLlib.R")

load.def.libs()

main = function() {
  testnr = commandArgs()[6]
  runid = commandArgs()[7]
  print(testnr)
  print(runid)
  connstring = det.connstring.PT(testnr)
  outdir = det.outdir(testnr)
  print(connstring)
  print(outdir)
  con = odbcDriverConnect(connection=connstring)
  # stats2csv(con, outdir, runid)
  make.report(con, outdir, runid)
  # graph.dc(con, outdir=outdir, channel.group, "2014-01-01 00:00", "2016-01-01 00:00")
  # graph.dc(con, outdir=outdir, channel.group, "2014-09-29 15:00", "2014-09-29 19:00")
}

test = function() {
  testnr = "449"
  runid = "3"
  connstring = det.connstring.PT(testnr)
  outdir = det.outdir(testnr)
  con = odbcDriverConnect(connection=connstring)

  
}

stats2csv = function(con, outdir, runid) {
  query = concat("select runid, servername, databasename, channelname, nelts_min, nelts_max, 
                  nelts_avg, nelts_start, nelts_end 
                  from dbo.aggr_tdc 
                  where runid = ", runid, "
                  order by runid, servername, databasename, channelname")
  df = sqlQuery(con, query)
  write.csv(df, file = concat(outdir, "\\", runid, "-aggr_tdc.csv"), row.names = FALSE, sep=";")
}

make.report = function(con, outdir, runid) {
  # make html with graphs included. For now only for channels where nelts_start != nelts_end
  query = concat("select runid, servername, databasename, channelname, nelts_min, nelts_max, 
                  nelts_avg, nelts_start, nelts_end 
                  from dbo.aggr_tdc 
                  where runid = ", runid, "
                  and nelts_start != nelts_end
                  order by runid, servername, databasename, channelname")
  df = sqlQuery(con, query)
  filename = concat(outdir, "\\", runid, "-report.html")
  fo = file(filename, "w")
  html.header(fo, concat("Channel report, runid = ", runid))
  # write.csv(df, file = fo, row.names = FALSE)

  df2 = ddply(df, .(channelname), function(dfp) {
    print("ddply: start")
    print(dfp)
    print(dfp$servername)
    print("ddply: end")
    dfp1 = dfp[1,]
    print(dfp1$servername)
    print(str(dfp1$servername))
    c(tr = html.table.row(dfp1$servername, dfp1$databasename, dfp1$channelname, dfp1$nelts_start, dfp1$nelts_end))
  })

  df$servername

  
  html.footer(fo)
  close(fo)
}

df2 = ddply(df, .(channelname), function(dfp) {
  concat(html.td(dfp$channelname), html.td(dfp$nelts_end))
})



df2 = ddply(df, .(channelname), function(dfp) {
  print(dfp)
  print(html.table.row(dfp$channelname[1,], dfp$nelts_end[1,]))
})




main()
