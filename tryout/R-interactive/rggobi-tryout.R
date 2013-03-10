sudo apt-get install ggobi
sudo apt-get install r-cran-rggobi

Dus niet met install.packages("rggobi") in R, deze nog steeds foutmeldingen.

R
library(rggobi)
df = ..
ggobi(df)

Lukt wel, maar time series (nog) niet goed.

