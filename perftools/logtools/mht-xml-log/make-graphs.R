# make mht graphs.
# first use the statement in here interactively, later maybe a complete cmdline script.

library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.

db = dbConnect(dbDriver("SQLite"), "mht.db") # alleen nog data van 30-8, en niet perf queries.
data = dbGetQuery(db, "select u.id, u.duration, u.nqdb, sum(q.duration) sum from quser u, qdb q where u.id = q.quser_id group by u.id")

axis.breaks <- as.vector(c(1, 2, 5) %o% 10^(-2:2))

size.labels = c(1, 2, 5, 10, 20, 50, 100)
size.breaks = log10(size.labels)


qplot(duration / 1000, sum / 1000, data=data, size=log10(nqdb), xlab = "Responstijd (sec)", ylab = "Som van queries (sec)") +
  scale_x_log10(breaks = axis.breaks, labels = axis.breaks, limits=c(0.01,100)) +  
  scale_y_log10(breaks = axis.breaks, labels = axis.breaks, limits=c(0.01,50)) +
  scale_size(name = "#queries", breaks=size.breaks, labels=size.labels)

ggsave(filename="QR-vs-R.png", width=8, height=5, dpi=100)

# ook:x = nq, y = R totaal
qplot(nqdb, duration / 1000, data=data, xlab = "#queries", ylab = "Responstijd (sec)") +
  scale_x_log10(breaks = axis.breaks, labels = axis.breaks, limits=c(1,600)) +  
  scale_y_log10(breaks = axis.breaks, labels = axis.breaks, limits=c(0.01,70))

ggsave(filename="R-vs-nq.png", width=8, height=5, dpi=100)
  
data10 = dbGetQuery(db, "select urlmain, start, duration, nqdb from quser order by duration desc limit 10")
write.table(data10, "expen-reqs.tsv", sep="\t", quote=FALSE, row.names = FALSE)
