# in Splunk wat issues met verwerkings tijden, met name x-tijd-as.

source("C:/PCC/Nico/nicoprj/R/lib/ndvlib.R")
source("C:\\PCC\\Nico\\nicoprj\\R\\RABO\\perflib.R")
source("C:\\PCC\\Nico\\nicoprj\\R\\lib\\HTMLlib.R")
load.def.libs()

df = read.csv("c:/PCC/processing-times.csv")
# "2015-12-05--09-33-42.835"
df$time_sent = as.POSIXct(strptime(df$time_sent_str, format="%Y-%m-%d--%H-%M-%OS"))
head(df)  

df2 = read.csv("c:/PCC/proc-times2.csv")
df2$time_sent = as.POSIXct(strptime(df2$time_sent_str, format="%Y-%m-%d--%H-%M-%OS"))
summary(df2)

df3 = read.csv("c:/PCC/proc-times3.csv")
df3$time_sent = as.POSIXct(strptime(df3$time_sent_str, format="%Y-%m-%d--%H-%M-%OS"))
summary(df3)


qplot(time_sent, total_time, data=df)

# [2015-12-07 16:45:26] weinig mee gedaan verder; toch in Splunk kunnen doen.
library(reshape)
funstofun(min, max)(1:10)
