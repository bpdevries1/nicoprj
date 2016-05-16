library(RMySQL)
library(ggplot2)

testrun_id = commandArgs()[6] # geeft de eerste, via rterm.exe etc.
testrun_name = commandArgs()[7]
output_file = commandArgs()[8]
machine = commandArgs()[9]
title = commandArgs()[10]
graph_start = commandArgs()[11]
graph_end = commandArgs()[12]
dbname = commandArgs()[13]
dbuser = commandArgs()[14]
dbpassword = commandArgs()[15]

print(commandArgs())

theme_set(theme_bw())  

# con = dbConnect(MySQL(), user="perftest", password="perftest", dbname="indmeetmod", host="localhost")
# con = dbConnect(MySQL(), user="perftest", password="perftest", dbname="testmeetmod", host="localhost")
# @todo gaat dbname=dbname werken?
con = dbConnect(MySQL(), user=dbuser, password=dbpassword, dbname=dbname, host="localhost")

is.filled = function(x) {
  if (is.na(x)) {
    FALSE 
  } else {
    x != "" 
  }
}

det_subwhere_start_end = function() {
  if (is.filled(graph_start)) {
    paste(" and r.dt >= '", graph_start, "' and r.dt <= '", graph_end, "' ", sep = "")
  } else {
    " " 
  }
}

query = paste("SELECT r.dt, r.dec_dt, t.label resource, r.value / t.fct value
FROM resusage r, logfile l, tempgraph t
where r.logfile_id = l.id
and t.resname_id = r.resname_id
and r.machine = '", machine,
"' and l.testrun_id = ", testrun_id, det_subwhere_start_end(),
" order by r.dt, t.label", sep="")

print(query)

df=dbGetQuery(con, query)

det_scale_x_datetime = function () {
  if (is.filled(graph_start)) {
    scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S", minor="5 min", limits=c(as.POSIXct(graph_start), as.POSIXct(graph_end)))
  } else {
    scale_x_datetime(format = "%d-%m-%Y\n%H:%M:%S", minor="5 min")
  }
}

# standaard scale_shape heeft max 6 waarden, bij sar 14 nodig, dus 30 moet genoeg zijn.
qplot(as.POSIXct(dt), value, data=df, geom="point", colour=resource, shape=resource, main=title, xlab="Time", ylab="Usage") +
  opts(legend.position=c(0.06, 0.96), legend.justification = c(0, 1)) + 
  det_scale_x_datetime() +
  scale_shape_manual(value=0:25)

ggsave(filename=output_file, width=11, height=9, dpi=100)

# print("finished")



