# pslist-plot.R - make plots of pslist.db sqlite data.
# doel: x = tijd, y=pids van w3wp, lijnen zijn looptijden (segment), kleur is machine.

library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

db_name = "pslist.db"
db = dbConnect(dbDriver("SQLite"), db_name)

query = "select pid, pname, computer, dt_first, dt_last from ps_runtime where pname = 'w3wp' order by computer, pid, dt_first"
df = dbGetQuery(db, query)
df$ts_psx_first = strptime(df$dt_first, format="%Y-%m-%d %H:%M:%S")
df$ts_psx_last = strptime(df$dt_last, format="%Y-%m-%d %H:%M:%S")

qplot(geom="segment", data=df, x=ts_psx_first, xend=ts_psx_last, y=pid, yend=pid, colour=computer, size=5)
ggsave("pslist-w3wp.png", width=11, height=9, dpi=100)

# alleen 21, alle processen:
query = "select pid, pname, computer, dt_first, dt_last from ps_runtime where computer like '%21%' order by computer, pname, dt_first"
df = dbGetQuery(db, query)
df$ts_psx_first = strptime(df$dt_first, format="%Y-%m-%d %H:%M:%S")
df$ts_psx_last = strptime(df$dt_last, format="%Y-%m-%d %H:%M:%S")

qplot(geom="segment", data=df, x=ts_psx_first, xend=ts_psx_last, y=pname, yend=pname)

qplot(geom="segment", data=df, x=ts_psx_first, xend=psx2, y=pname, yend=pname)
ggsave("pslist-21.png", width=11, height=9, dpi=100)

# aantallen per tijdstip per soort process

query = "select count(*) aantal, pname, computer, datetime from pslist where computer like '%21%' group by 2,3,4 order by 4,1,2,3"
df = dbGetQuery(db, query)
df$ts_psx = strptime(df$datetime, format="%Y-%m-%d %H:%M:%S")
qplot(ts_psx, aantal, data=df) +
  facet_grid(pname ~ .)

# past niet op scherm, naar file opslaan:
ggsave("pslist-counts-21.png", width=11, height=40, dpi=100)
# lijkt niet heel zinvol.



