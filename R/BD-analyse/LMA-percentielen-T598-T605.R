library(RODBC)
library(ggplot2)
library(sqldf)

con = odbcDriverConnect(connection="Driver=SQL Server;Server=AXZTSTW001;Database=PerfTestResultsT605;Trusted_Connection=yes;")
df = sqlQuery(con, "select * from LmaDoorlooptijdenMeldingenPercentielTabel")

con598 = odbcDriverConnect(connection="Driver=SQL Server;Server=AXZTSTW001;Database=PerfTestResultsT598;Trusted_Connection=yes;")
df598 = sqlQuery(con598, "select * from LmaDoorlooptijdenMeldingenPercentielTabel")

df2 = sqldf("select 'T602' testnr, Percentage, MaxDoorlooptijd from df
             union
             select 'T598' testnr, Percentage, MaxDoorlooptijd from df598
             union
             select 'req' testnr, Percentage, 30 MaxDoorlooptijd from df")

df85 = sqldf("select * from df2 where Percentage <= 85")

#qplot(Percentage, MaxDoorlooptijd, data=df2, colour=testnr) +
#  scale_y_log10()
  
qplot(Percentage, MaxDoorlooptijd, data=df85, colour=testnr, geom="line")
ggsave("LMA-percentielen-T598-T605.png", width = 8, height = 6, dpi=100 )

getwd()
