d <- data.frame(xx = 1:10, yy = 11:20, zz=as.factor(21:30), ff=as.factor(rep(c(1,2), 5)))

idee qplot.dt met file.facet
vgl facet, maar maak een file aan per item.

nodig:
for-lus die langs elke gaat.
selectie uit data.frame met alleen de current item.

of is hiervoor ddply te gebruiken? of d_ply?

d_ply(d, .(ff), function(dft) {
  p = qplot(xx, yy, data=dft, colour=zz)
  filename = paste0("~/aaa/facet-file-", dft$ff[1], ".png")
  ggsave(filename, plot=p, width=12, height=8, dpi=100)
})

l1 = daply(d, .(ff), function(dft) {
  p = qplot(xx, yy, data=dft, colour=zz)
  filename = paste0("~/aaa/facet-file-", dft$ff[1], ".png")
  ggsave(filename, plot=p, width=12, height=8, dpi=100)
  filename
})

qplot.dt = function(x, y, data, colour=NULL, facets=NULL, filename, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot")
  if (missing(colour)) {
    colour = NULL
    has.colour = FALSE
  } else {
    colourname = deparse(substitute(colour))
    has.colour = TRUE
    mf$shape = mf$colour
  }
  p <- eval(mf, parent.frame())
  p = p +
    # scale_x_datetime(labels = date_format("%Y-%m-%d\n%H:%M")) +
    # always a time axis in this function, so don't show the axis name:
    xlab(NULL)
    # scale_y_continuous(labels = comma)
  if (has.colour) {    
    g = guide_legend(colourname, ncol = 2)
    p = p + scale_colour_discrete(name=colourname) +
      scale_shape_manual(name=colourname, values=rep(1:25,10)) +
      guides(colour = g, shape = g) +
      theme(legend.position="bottom") +
      theme(legend.direction="horizontal")
  }
  facetvars <- all.vars(facets)
  facetvars <- facetvars[facetvars != "."]
  if (!is.na(facetvars[1])) {
    p = p + facet_grid(facets, scales='free_y', labeller=label_wrap_gen3(width=25))
  }
  height = det.height(colours = data[[colourname]], facets = data[[facetvars[1]]])
  filename = eval(mf$filename, parent.frame())
  #print("before ggsave")
  ggsave(filename, plot=p, width=12, height=height, dpi=100)
  #print("after ggsave")
  # don't return p, to supress warnings.
  # p 
}  

l1 = daply(d, .(ff), function(dft) {
  filename = paste0("~/aaa/facet-file-", dft$ff[1], ".png")
  p = qplot.dt(xx, yy, data=dft, colour=zz, filename=filename)
  # ggsave(filename, plot=p, width=12, height=8, dpi=100)
  filename
})
# => deze werkt, met iets aangepaste qplot.dt ivm hier geen tijd x-var.

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  l1 = daply(d, .(ff), function(dft) {
    filename = paste0("~/aaa/facet-file-", dft$ff[1], ".png")
    p = qplot.dt(xx, yy, data=dft, colour=zz, filename=filename)
    # ggsave(filename, plot=p, width=12, height=8, dpi=100)
    filename
  })
  l1
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", 
                 filename.prefix = "~/aaa/facet-file-")
l1
# => deze werkt ook.

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  l1 = daply(d, .(ff), function(dft) {
    filename = paste0(filename.prefix, dft$ff[1], ".png")
    p = qplot.dt(xx, yy, data=dft, colour=zz, filename=filename)
    # ggsave(filename, plot=p, width=12, height=8, dpi=100)
    filename
  })
  l1
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", 
                 filename.prefix = "~/aaa/facet-file-")
l1
# ook goed

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  l1 = daply(d, .(ff), function(dft) {
    # filename = paste0(filename.prefix, dft$ff[1], ".png")
    filename = paste0(filename.prefix, dft[1,"ff"], ".png")
    p = qplot.dt(xx, yy, data=dft, colour=zz, filename=filename)
    filename
  })
  l1
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", 
                 filename.prefix = "~/aaa/facet-file-")
l1

# goed
qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  l1 = daply(d, .(ff), function(dft) {
    filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    p = qplot.dt(xx, yy, data=dft, colour=zz, filename=filename)
    filename
  })
  l1
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", 
                 filename.prefix = "~/aaa/facet-file-")
l1
# goed

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  l1 = daply(d, "ff", function(dft) {
    filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    p = qplot.dt(xx, yy, data=dft, colour=zz, filename=filename)
    filename
  })
  l1
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", 
                 filename.prefix = "~/aaa/facet-file-")
l1
# goed

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  l1 = daply(d, file.facets, function(dft) {
    filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    p = qplot.dt(xx, yy, data=dft, colour=zz, filename=filename)
    filename
  })
  l1
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", 
                 filename.prefix = "~/aaa/facet-file-")
l1
# goed nog steeds. Maar nu de d nog.

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  l1 = daply(data, file.facets, function(dft) {
    filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    p = qplot.dt(xx, yy, data=dft, colour=zz, filename=filename)
    filename
  })
  l1
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", 
                 filename.prefix = "~/aaa/facet-file-")
l1
# nog steeds goed.

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  l1 = daply(data, file.facets, function(dft) {
    filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    qplot.dt(xx, yy, data=dft, colour=zz, filename=filename)
    filename
  })
  l1
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", 
                 filename.prefix = "~/aaa/facet-file-")
l1
# ok
qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  daply(data, file.facets, function(dft) {
    filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    qplot.dt(xx, yy, data=dft, colour=zz, filename=filename)
    filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", 
                 filename.prefix = "~/aaa/facet-file-")
l1
# ok, maar gebruik nog xx, yy en zz in qplot.dt aanroep!!!

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  daply(data, file.facets, function(dft) {
    filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    qplot.dt(x, yy, data=dft, colour=zz, filename=filename)
    filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", 
                 filename.prefix = "~/aaa/facet-file-")
l1
# fout, object 'xx' niet gevonden, omdat x als xx wordt ge-eval-ed, en dus fout.

# dan call zoals ook in implementatie van qplot.dt

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.dt")
  # p <- eval(mf, parent.frame())
  daply(data, file.facets, function(dft) {
    filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    # qplot.dt(x, yy, data=dft, colour=zz, filename=filename)
    eval(mf, parent.frame())
    filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", 
                 filename.prefix = "~/aaa/facet-file-")
l1
# foutmelding:  Error: object '~/aaa/facet-file-' of mode 'function' was not found 
# nu even weg, later nog kijken.

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.dt")
  # p <- eval(mf, parent.frame())
  daply(data, file.facets, function(dft) {
    # filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    filename = paste0("~/aaa/facet-file-", dft[1,file.facets], ".png")
    # qplot.dt(x, yy, data=dft, colour=zz, filename=filename)
    eval(mf, parent.frame())
    filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff")
l1
# fout: non-character argument, mogelijk wordt filename niet meegegeven.
# deze in aanroep er even bij

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.dt")
  # p <- eval(mf, parent.frame())
  daply(data, file.facets, function(dft) {
    # filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    filename = paste0("~/aaa/facet-file-", dft[1,file.facets], ".png")
    # qplot.dt(x, yy, data=dft, colour=zz, filename=filename)
    mf$filename = filename
    eval(mf, parent.frame())
    filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff")
l1
# geen foutmelding, ook wel graphs, maar in beide staat alles, waarsch doordat hele data.frame wordt meegegeven

# params verwijderen, toevoegen is gemakkelijk.
l1 = list(a="abc", b="bcd")
l1
l1$c = "cde"
# toevoegen werkt
l1$a = NULL
# werkt, dan verwijderd.

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.dt")
  # p <- eval(mf, parent.frame())
  daply(data, file.facets, function(dft) {
    # filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    filename = paste0("~/aaa/facet-file-", dft[1,file.facets], ".png")
    # qplot.dt(x, yy, data=dft, colour=zz, filename=filename)
    print("mf$data:")
    print(mf$data)
    print(mode(mf$data))
    print(str(mf$data))
    mf$filename = filename
    eval(mf, parent.frame())
    filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff")
l1
# 'ok' extra info, nog wel fout.
quote(d1)

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.dt")
  # p <- eval(mf, parent.frame())
  daply(data, file.facets, function(dft) {
    # filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    filename = paste0("~/aaa/facet-file-", dft[1,file.facets], ".png")
    # qplot.dt(x, yy, data=dft, colour=zz, filename=filename)
    mf$data = quote(dft)
    print("mf$data:")
    print(mf$data)
    print(mode(mf$data))
    print(str(mf$data))
    mf$filename = filename
    eval(mf, parent.frame())
    filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff")
l1
# melding: object 'dft' not found.
# reden waarsch dat deze in parent-frame niet bestaat.
# klopt idd, als je dft=d doet, dan doet 'ie het wel sort-of, maar met alle data.

# dus even de vraag of je deze eval in het parent frame wilt uitvoeren, denk het niet.
# filename gaat wel goed, hier is de inhoud aan de param toegevoegd.
# ook proberen met dft:

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.dt")
  # p <- eval(mf, parent.frame())
  daply(data, file.facets, function(dft) {
    # filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    filename = paste0("~/aaa/facet-file-", dft[1,file.facets], ".png")
    # qplot.dt(x, yy, data=dft, colour=zz, filename=filename)
    mf$data = dft
    print("mf$data:")
    print(mf$data)
    print(mode(mf$data))
    print(str(mf$data))
    mf$filename = filename
    eval(mf, parent.frame())
    filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff")
l1
# lijkt zowaar goed, hier geen xx, yy of zz meer in de functie-def.

# eerst filename.prefix er weer in:
qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.dt")
  # p <- eval(mf, parent.frame())
  daply(data, file.facets, function(dft) {
    filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    # filename = paste0("~/aaa/facet-file-", dft[1,file.facets], ".png")
    # qplot.dt(x, yy, data=dft, colour=zz, filename=filename)
    mf$data = dft
    print("mf$data:")
    print(mf$data)
    print(mode(mf$data))
    print(str(mf$data))
    mf$filename = filename
    eval(mf, parent.frame())
    filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", filename.prefix="~/aaa/facet-file-")
l1
# ook goed. dft zo blijft wel wat vaag, nog alternatief?

# wil file.facets en filename.prefix niet doorgeven aan qplot.dt, deze weg:

qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.dt")
  # p <- eval(mf, parent.frame())
  daply(data, file.facets, function(dft) {
    filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    # filename = paste0("~/aaa/facet-file-", dft[1,file.facets], ".png")
    # qplot.dt(x, yy, data=dft, colour=zz, filename=filename)
    mf$data = dft
    print("mf$data:")
    print(mf$data)
    print(mode(mf$data))
    print(str(mf$data))
    mf$filename = filename
    mf$filename.prefix = NULL
    mf$file.facets = NULL
    eval(mf, parent.frame())
    filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", filename.prefix="~/aaa/facet-file-")
l1
# ook goed.

# alle zut weg:
qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.dt")
  daply(data, file.facets, function(dft) {
    filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    mf$data = dft
    mf$filename = filename
    mf$filename.prefix = NULL
    mf$file.facets = NULL
    eval(mf, parent.frame())
    filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", filename.prefix="~/aaa/facet-file-")
l1

# dan nog filename direct:
qplot.dt.ff = function(x, y, data, colour=NULL, facets=NULL, file.facets, filename.prefix, ...) {
  mf <- match.call()
  mf[[1]] <- as.name("qplot.dt")
  daply(data, file.facets, function(dft) {
    mf$data = dft
    mf$filename = paste0(filename.prefix, dft[1,file.facets], ".png")
    mf$filename.prefix = NULL
    mf$file.facets = NULL
    eval(mf, parent.frame())
    mf$filename
  })
}

l1 = qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", filename.prefix="~/aaa/facet-file-")
l1
# ook goed!

# optie om file.facet ook als formule mee te geven, vraag of het daar beter van wordt.

# experiment met eval en parent.frame()
l1 = eval(qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", filename.prefix="~/aaa/facet-file-"))
l1
# ook ok, dus hier niet in functie scope of zo.
l1 = eval(qplot.dt.ff(xx, yy, data=d, colour=zz, file.facets = "ff", filename.prefix="~/aaa/facet-file-"), envir=NULL)
# ook goed, met envir=NULL
# 't is tijd, dus df$data= quote(dft) zit er nu niet in.


TODO: as.name("dft") proberen, net als naam van de functie??
