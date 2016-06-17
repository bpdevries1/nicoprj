library(ggplot2)
library(scales)

setwd("C:/PCC/Nico/nicoprj/perftools/graph/R/csvexample")
df = read.csv("data.csv")

# convert Time to Posix for plotting
df$time.psx = as.POSIXct(strptime(df$Time, format="%Y-%m-%d %H:%M:%OS"))

# basic plot
qplot(x=time.psx, y=Duration, data=df)
  
# with some extensions
qplot(x=time.psx, y=0.001*Duration, data=df,
      main = "Durations (sec)") +
  ylab("Duration (sec)") +
  xlab("Date/Time") +
  scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M:%OS"))
  
ggsave(filename="Duration.png", width=10, height=8, dpi=100)
