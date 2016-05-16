# R Percentile graph

Niet direct met google
Met quantile functie iets te doen, ook percentile functie?

tabulating and geom_hstep ()

ggplot2::geom_step      geom\_step
ggplot2::stairstep      Calculate stairsteps

     # Simple quantiles/ECDF from examples(plot)
     x <- sort(rnorm(47))
     qplot(seq_along(x), x, geom="step")

=> qua vorm goed, niet naar 100%
     
     # Steps go horizontally, then vertically (default)
     qplot(seq_along(x), x, geom="step", direction = "hv")
     plot(x, type = "s")
     # Steps go vertically, then horizontally
     qplot(seq_along(x), x, geom="step", direction = "vh")
     plot(x, type = "S")
     
     # Also works with other aesthetics
     df <- data.frame(
       x = sort(rnorm(50)),
       trt = sample(c("a", "b"), 50, rep = T)
     )
     qplot(seq_along(x), x, data = df, geom="step", colour = trt)
     ## End(Not run)

geldt voor allemaal, sorteren is key.

# Zie blz 63 vh boek Peter Dalgaard.

n = length(df$x)
plot(sort(df$x), (1:n)/n, type = "s", ylim=c(0,1))

# andersom
plot((1:n)/n, sort(df$x), type = "s", xlim=c(0,1))
plot((1:n)/n, sort(df$x), type = "l", xlim=c(0,1))

# met ggplot
qplot((1:n)/n, sort(df$x), geom="line") + scale_x_continuous(formatter="percent")
=> werkt wel.

# vermoeden dat a'dam lagere tijden laat zien, vooral als het goed gaat. Idee is om beide percentile graphs te tonen naast elkaar, kan niet met ymonitor.

df = data.frame(y = (1:100), sent = c(rep(1, 30), rep(2, 70)))

# eerst loskoppelen of niet.
# of 2 losse aes()

df = data.frame(y = (1:100), sent = c(rep('a', 30), rep('b', 70)))

d.f <- arrange(df,sent)
d.f.ecdf <- ddply(d.f, .(sent), transform, ecdf=ecdf(y)(y) )

ggplot( d.f.ecdf, aes(y, ecdf, colour = sent) ) +
  geom_step()
niet goed

d.f.ecdf = ddply(d.f, .(sent), transform, ecdf=ecdf(y)(y) )
# ecdf returns a function, dus dubbele (y) is dan wel weer begrijpelijk.

qplot(ecdf, y, data = d.f.ecdf, geom="line", colour = sent) +
 scale_x_continuous(formatter="percent")
 
# Ok

# in verschillende plots met facet

p <- ggplot( d.f.ecdf, aes(val, ecdf, colour = grp) )
p + geom_step() + facet_wrap( ~grp2 )

qplot(ecdf, y, data = d.f.ecdf, geom="line", colour = sent) +
 scale_x_continuous(formatter="percent") +
 facet_wrap( ~sent )

# werkt ook prima, misschien meer om data van hele maand in raster te zetten.


write.table(times, "times.tsv", sep="\t")
nu nog quotes erin, wil niet.

write.table(times, "times.tsv", sep="\t", quote=FALSE)

nu row-numbers nog wel, want titels en data kloppen zo niet.

write.table(times, "times.tsv", sep="\t", quote=FALSE, row.names = FALSE)
=> Ok!
  
# kolmogorov-smirnov test om te bepalen of 2 ecdf's gelijk zijn.
ks.test(x, y, ...,
             alternative = c("two.sided", "less", "greater"),
             exact = NULL)
     
v1 = c(1:100)
v2 = c(2:101)
ks.test(v1, v2)
niet zo helder, warning

ks.test(v1, v2, alternative="less")



