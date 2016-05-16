Voorbeeld op http://stackoverflow.com/questions/2082553/using-ggplot2-and-rpanel-together

library(ggplot2)
library(rpanel)

poisson.draw = function(panel) {
  with(panel, {
     x = seq(0,n, by = 1)
     y = dpois(x, lambda)
     d = data.frame(cbind(x,y))
     p1 = ggplot(d, aes(x,y)) + geom_point()
     print(p1)
  })
  panel
}
panel <- rp.control("Poisson distribution", n = 30, lambda = 3, 
  ylim = 0.5)
rp.slider(panel, lambda, 1, 30, poisson.draw)

=> doet het wel, niet ideaal:
* slider is erg traag
* slider in een ander scherm als de graph-window
* kan dit vanuit een batch/shell worden gestart?
  => usecase: heb een script met functies, deze uitvoeren, mag best in interactive mode zijn.
* wel een handleiding met alle functies en dus een klein voorbeeld zoals hierboven, maar geen tutorial?
* met x11 een window te forcen in non-interactive? Met tcltk ook een mogelijkheid om R niet te eindigen nadat script klaar is.

Ander voorbeeld, zonder ggplot:

library(rpanel)
x11(width=4,height=4)
qq.draw <- function(panel) {
   z <- bc.fn(panel$y, panel$lambda)
   qqnorm(z, main = paste("lambda =",
     round(panel$lambda, 2)))
   panel
   }
panel <- rp.control(y = exp(rnorm(50)), lambda = 1)
rp.slider(panel, lambda, -2, 2, qq.draw,
  showvalue = TRUE)

Andere packages genoemd:
Relationship with wider ("widgety") gui packages
- Rgtk2
- gWidgets
- playwith
- rwxwidgets
- JGR
- rtcltk

In 'tutorial' PDF wel controls en de graph in hetzelfde window.
website: www.stats.gla.ac.uk/~adrian/rpanel

voorbeeld met graph in panel:

rpplot <- rp.control(title = "Demonstration of rp.tkrplot", h= 1)
redraw <- function(panel) {
  rp.tkrreplot(panel, tkrp)
  panel
}
draw <- function(panel) {
  plot(1:20, (1:20)^panel$h)
  panel
}
rp.tkrplot(rpplot, tkrp, draw)
rp.slider(rpplot, h, action = redraw, from = 0.05, to = 2.00,
resolution = 0.05)

=> tkrplot is er nog niet, install?
=> package is er wel, maar compileert niet goed, /usr/bin/ld: cannot find -lXss
=> komt me bekend voor, eerst laten zitten.

Algemeen: update.packages() helpt nog wel eens bij problemen, nu (9-10-2011) nieuwe versies van ggplot, rsqlite etc, blijkbaar niet via ubuntu-update...
Melding:  'lib = "/usr/local/lib/R/site-library"' is not writable
Heb idd niet met sudo uitgevoerd, kan verklaring zijn.

Nogmaals met sudo, R dus herstarten:
Allemaal goed, behalve RMySQL, nu niet zo spannend.

Tips:
      export PKG_CPPFLAGS="-I<MySQL-include-dir>"
      export PKG_LIBS="-L<MySQL-lib-dir> -lmysqlclient"

tkrplot nog eens onder sudo:

Melding:
gcc -I/usr/share/R/include -I/usr/include/tcl8.5 -I/usr/include/tcl8.5     -fpic  -std=gnu99 -O3 -pipe  -g -c tcltkimg.c -o tcltkimg.o
gcc -shared -o tkrplot.so tcltkimg.o -L/usr/lib -ltcl8.5 -L/usr/lib -ltk8.5 -lX11 -lXss -lXext -L/usr/lib/R/lib -lR
/usr/bin/ld: cannot find -lXss

-lXss even verwijderd uit de cmdline, en dan doet ie het gewoon.
maar dit zegt niet alles: als ik alle libs verwijder, doet 'ie het ook.
zou dus in /usr/lib moeten staan, net als tk8.5 en X11 en Xext

heb wel libtk8.5.a
libtk8.5.so

en libX11.a
libX11.so

en heb:
libXss.so.1
libXss.so.1.0.0

wordt wel met symlinks gewerkt.

lrwxrwxrwx  1 root root       15 2008-04-12 18:37 libXss.so.1 -> libXss.so.1.0.0
-rw-r--r--  1 root root     7472 2007-04-27 17:55 libXss.so.1.0.0

even een symlink maken, geen .a variant bij deze:
sudo ln -s  libXss.so.1 libXss.so

hiermee gaat het linken goed.

rename: 
mv tkrplot zztkrplot.zz

Opnieuw install.package vanuit R:
Lijkt gelukt

R uit en opnieuw zonder sudo en dan package laden:

> library(tkrplot)
Loading required package: tcltk
Loading Tcl/Tk interface ... done

yesyes!

Nogmaals voorbeeld met graph in panel:

rpplot <- rp.control(title = "Demonstration of rp.tkrplot", h= 1)
redraw <- function(panel) {
  rp.tkrreplot(panel, tkrp)
  panel
}
draw <- function(panel) {
  plot(1:20, (1:20)^panel$h)
  panel
}
rp.tkrplot(rpplot, tkrp, draw)
rp.slider(rpplot, h, action = redraw, from = 0.05, to = 2.00,
resolution = 0.05)

toch foutmeldingen bij gebruik slider:
Error in .rptkrreplot(.geval(panelname, "$", id)) : 
  could not find function ".my.tkdev"
Error in .rptkrreplot(.geval(panelname, "$", id)) : 
  could not find function ".my.tkdev"

En op windows dezelfde melding! Is voorbeeld fout, of wat anders aan de hand?
Zelfde gedrag: panel met zowel graph als slider wordt wel getekend, maar bij bewegen slider gaat iets mis in de callback functie.
  
Ander voorbeeld:
   smooth.panel <- rp.control("Nonparametric regression", size = c(600, 450),
                  x = x, y = y, xlab = "Covariate", ylab = "Response",
                  h = diff(range(x)) / 8)
   rp.doublebutton(smooth.panel, h, h.delta, pos = c(25, 25, 100, 30),
                  range = c(diff(range(smooth.panel$x)) / 50, NA),
                  title = "Bandwidth", action = replot.smooth)
   rp.radiogroup(smooth.panel, model, pos = c(25, 75, 100, 100),
                  c("none", "no effect", "linear"),
                  title = "Reference", action = replot.smooth)
   rp.tkrplot(smooth.panel, plot, plot.smooth, pos = c(150, 0, 500, 450))

   replot.smooth <- function(panel) {
       rp.tkrreplot(panel, plot)
       panel
       }

Melding op x en y, even zelf maken:
x= 1:20
y= 5:25

plot.smooth niet gevonden

  could not find function ".my.tkdev"

Onderstaande is groot, maar doet het wel, geen rpanel:

TkBuildDist <- function(  x=seq(min+(max-min)/nbin/2,
                                max-(max-min)/nbin/2,
                                length.out=nbin),
                          min=0, max=10, nbin=10, logspline=TRUE,
                          intervals=FALSE) {

    if(logspline) logspline <- require(logspline)
    require(tkrplot)

    xxx <- x

    brks <- seq(min, max, length.out=nbin+1)
    nx <- seq( min(brks), max(brks), length.out=250 )

    lx <- ux <- 0
    first <- TRUE

    replot <- if(logspline) {
        if(intervals) {
            function() {
                hist(xxx, breaks=brks, probability=TRUE,xlab='', main='')
                xx <- cut(xxx, brks, labels=FALSE)
                fit <- oldlogspline( interval = cbind(brks[xx], brks[xx+1]) )
                lines( nx, doldlogspline(nx,fit), lwd=3 )
                if(first) {
                    first <<- FALSE
                    lx <<- grconvertX(min, to='ndc')
                    ux <<- grconvertX(max, to='ndc')
                }
            }
        } else {
            function() {
                hist(xxx, breaks=brks, probability=TRUE,xlab='', main='')
                fit <- logspline( xxx )
                lines( nx, dlogspline(nx,fit), lwd=3 )
                if(first) {
                    first <<- FALSE
                    lx <<- grconvertX(min, to='ndc')
                    ux <<- grconvertX(max, to='ndc')
                }
            }
        }
    } else {
        function() {
            hist(xxx, breaks=brks, probability=TRUE,xlab='',main='')
            if(first) {
                first <<- FALSE
                lx <<- grconvertX(min, to='ndc')
                ux <<- grconvertX(max, to='ndc')
            }
        }
    }

    tt <- tktoplevel()
    tkwm.title(tt, "Distribution Builder")

    img <- tkrplot(tt, replot, vscale=1.5, hscale=1.5)
    tkpack(img, side='top')

    tkpack( tkbutton(tt, text='Quit', command=function() tkdestroy(tt)),
           side='right')

    iw <- as.numeric(tcl('image','width',tkcget(img,'-image')))

    mouse1.down <- function(x,y) {
        tx <- (as.numeric(x)-1)/iw
        ux <- (tx-lx)/(ux-lx)*(max-min)+min
        xxx <<- c(xxx,ux)
        tkrreplot(img)
    }

    mouse2.down <- function(x,y) {
        if(length(xxx)) {
            tx <- (as.numeric(x)-1)/iw
            ux <- (tx-lx)/(ux-lx)*(max-min)+min
            w <- which.min( abs(xxx-ux) )
            xxx <<- xxx[-w]
            tkrreplot(img)
        }
    }

    tkbind(img, '<ButtonPress-1>', mouse1.down)
    tkbind(img, '<ButtonPress-2>', mouse2.down)
    tkbind(img, '<ButtonPress-3>', mouse2.down)

    tkwait.window(tt)

    out <- list(x=xxx)
    if(logspline) {
        if( intervals ) {
            xx <- cut(xxx, brks, labels=FALSE)
            out$logspline <- oldlogspline( interval = cbind(brks[xx], brks[xx+1]) )
        } else {
            out$logspline <- logspline(xxx)
        }
    }

    if(intervals) {
        out$intervals <- table(cut(xxx, brks))
    }

    out$breaks <- brks

    return(out)
}

rpanel nog eens install zonder sudo?

install.packages deed het gewoon, geen melding dat 'ie er al was.

Nogmaals: nog steeds geen melding, dus zegt niet zoveel

update.packages() nogmaals, niet onder sudo.

Opties:
* .my.tkdev in de source opzoeken, ziet eruit als een tk widget naam
* Andere rpanel functies testen, zelfde fout? Want slider wil ik toch eigenlijk niet gebruiken.
* verder met andere tool.

In source van tkrplot een def gevonden van de functie:
if (Sys.info()["sysname"] == "Windows") {
    .my.tkdev <- function(hscale=1, vscale=1)
        win.metafile(width=4*hscale,height=4*vscale, restoreConsole=FALSE)
} else if (exists("X11", env=.GlobalEnv)) {
    .my.tkdev <- function(hscale=1, vscale=1)
        X11("XImage", 480*hscale, 480*vscale)
} else stop("tkrplot only supports Windows and X11")

kan ik uitvoeren, krijgt een waarde.
nogmaals het voorbeeld:

rpplot <- rp.control(title = "Demonstration of rp.tkrplot", h= 1)
redraw <- function(panel) {
  rp.tkrreplot(panel, tkrp)
  panel
}
draw <- function(panel) {
  plot(1:20, (1:20)^panel$h)
  panel
}
rp.tkrplot(rpplot, tkrp, draw)
rp.slider(rpplot, h, action = redraw, from = 0.05, to = 2.00,
resolution = 0.05)

=> Zowaar, het werkt!

In windows:
Werkt nu ook!

Compleet:
library(rpanel)
library(tkrplot)

if (Sys.info()["sysname"] == "Windows") {
    .my.tkdev <- function(hscale=1, vscale=1)
        win.metafile(width=4*hscale,height=4*vscale, restoreConsole=FALSE)
} else if (exists("X11", env=.GlobalEnv)) {
    .my.tkdev <- function(hscale=1, vscale=1)
        X11("XImage", 480*hscale, 480*vscale)
} else stop("tkrplot only supports Windows and X11")

rpplot <- rp.control(title = "Demonstration of rp.tkrplot", h= 1)
redraw <- function(panel) {
  rp.tkrreplot(panel, tkrp)
  panel
}
draw <- function(panel) {
  plot(1:20, (1:20)^panel$h)
  panel
}
rp.tkrplot(rpplot, tkrp, draw)
rp.slider(rpplot, h, action = redraw, from = 0.05, to = 2.00,
resolution = 0.05)

=> gaat goed!

werkt dit ook met ggplot? evt trager.
Kan best een keuze zijn met exploratieve acties met standaard plot te werken ipv ggplot, omdat de standaard veel sneller is.

even soort batch testen.

laatste regel van test-rpanel2.R om te zorgen dat R niet stopt:
rp.block(rpplot)

cat test-rpanel2.R | R --vanilla

panel is dus niet de goede naam.

vraag is hoe deze dan wel heet: rpplot!

R --vanilla <test-rpanel2.R
werkt ook.

Dan met ggplot, plot vervangen door qplot.

library(rpanel)
library(tkrplot)

# van tkrplot:
if (Sys.info()["sysname"] == "Windows") {
    .my.tkdev <- function(hscale=1, vscale=1)
        win.metafile(width=4*hscale,height=4*vscale, restoreConsole=FALSE)
} else if (exists("X11", env=.GlobalEnv)) {
    .my.tkdev <- function(hscale=1, vscale=1)
        X11("XImage", 480*hscale, 480*vscale)
} else stop("tkrplot only supports Windows and X11")

rpplot <- rp.control(title = "Demonstration of rp.tkrplot", h= 1)
redraw <- function(panel) {
  rp.tkrreplot(panel, tkrp)
  panel
}
draw <- function(panel) {
  qplot(1:20, (1:20)^panel$h)
  panel
}
rp.tkrplot(rpplot, tkrp, draw)
rp.slider(rpplot, h, action = redraw, from = 0.05, to = 2.00,
resolution = 0.05)

=> geen foutmelding, maar geen goede plot, wel iets van interactie, maar het lijkt er niet op.

In windows:
Ook niet, dan ook helemaal geen ruimte voor de graph.

dus combi rpanel/tkrplot/ggplot2 lijkt niet goed, zowel ubuntu als windows.

ggsave-tk?

Opties:
* in ggplot een optie om output naar tk te doen? Nee, zit niet in de lijst van ggsave.
* of in ggplot eerst save naar een file, en dan reload in tk/panel.
* in tkrplot opties kijken: rp.image(): tkrplot werkt wel met plot() cmd. Iets met X11() functie te maken?
* rp.tkrplot functie bekijken, en rp.image() en tkrreplot, roepen tkrplot aan, zonder rp.
* coordinaten van plot opvragen (of zetten), en tk deel hieronder neerzetten. en beide op de voorgrond.


Idee (als het allemaal werkt):
* Grafiek tonen, bij andere start/end tijd deze waarden in een listbox/dropdown zetten, zodat je ze weer kan selecteren.
* Ook optie om weer alles te tonen.
* Inzoomen ofwel door tijden in voeren, ofwel door een zoom-actie op de grafiek.

containing a Tk image of type Rplot.  For now the size is
     hard-wired.  The plot is created by calling ‘fun’ with a special
     device used create the image.

# voorbeeld van het begin werkt wel, maar slider/ggplot combi is niet handig.     
     
poisson.draw = function(panel) {
  with(panel, {
     x = seq(0,n, by = 1)
     y = dpois(x, lambda)
     d = data.frame(cbind(x,y))
     p1 = ggplot(d, aes(x,y)) + geom_point()
     print(p1)
  })
  panel
}
panel <- rp.control("Poisson distribution", n = 30, lambda = 3, 
  ylim = 0.5)
rp.slider(panel, lambda, 1, 30, poisson.draw)
     
Wil gewoon waarde invoeren en op go-knop drukken. of gewoon enter in het veld.
Nog wel string terug naar getal?  

rp.textentry(panel, lambda, poisson.draw, "lambda")

ook meerdere vars te doen blijkbaar.

rp.do(panel, plotf)

Voorbeeld:
     if (interactive()) {
        plotf <- function(panel) {
           with(panel, {
                      pars   <- as.numeric(pars)
              xgrid <- seq(0.1, max(c(pars[3], 5), na.rm = TRUE), length = 50)
              dgrid <- df(xgrid, pars[1], pars[2])
              plot(xgrid, dgrid, type = "l", col = "blue", lwd = 3)
              if (!is.na(pars[3])) {
                 lines(rep(pars[3], 2), c(0, 0.95 * max(dgrid)), lty = 2, col = "red")
                 text(pars[3], max(dgrid), as.character(pars[3]), col = "red")
                 }
              })
           panel
           }
     
        panel <- rp.control(pars = c(5, 10, NA))
        rp.textentry(panel, pars, plotf, labels = c("df1", "df2", "observed"),
               initval = c(10, 5, 3))
        rp.do(panel, plotf)
        }


# eigen testje:
poisson.draw = function(panel) {
  print("poisson draw called")
  print(panel)
  print("===")
  print(panel$lambda)
  with(panel, {
    lambda = as.numeric(lambda) 
    x = seq(0,n, by = 1)
     y = dpois(x, lambda)
     d = data.frame(cbind(x,y))
     p1 = ggplot(d, aes(x,y)) + geom_point()
     print(p1)
  })
  panel
}
panel <- rp.control("Poisson distribution", n = 30, lambda = 3,  ylim = 0.5)
rp.textentry(panel, lambda, poisson.draw, "lambda")
rp.button(panel, poisson.draw, "Go")
rp.do(panel, poisson.draw)

werkt wel, alleen op de goede enter drukken, in het midden, niet helemaal rechts. En raar, bij klikken op button wordt niet laatste val van textentry gelezen.
blijkbaar alleen met enter hierop wel.

even de vraag of je rpanel nog wilt, of dat je net zo goed tcltk direct kunt gebruiken.

> dev.cur()
X11cairo 
       2 

X11(): width, height: in inches, xpos, ypos: integer topleft in pixels


panel heeft hier niets mee te maken.
maar de graph zelf komt hier wel in, dus hoopgevend.

rp.control maakt het windowtje al en zet hem linksboven neer.
opties hiervan?
 size = c(100, 100) in pixels

size dus wel, maar lokatie niet.

in tcltk zelf?
ls("package:tcltk")

panel <- rp.control("Poisson distribution", n = 30, lambda = 3,  ylim = 0.5, aschar=TRUE)

> panel <- rp.control("Poisson distribution", n = 30, lambda = 3,  ylim = 0.5, aschar=TRUE)
> panel
[1] ".rpanel54792916"

# eerst even met standaard tk-window, los van rpanel:

# Load the tcltk package
require(tcltk)

# Create a new toplevel window
tt <- tktoplevel()
# meteen op scherm gezet.

# Create a button whose function (command) is to destroy the window
OK.but <- tkbutton(tt,text="OK",command=function()tkdestroy(tt))

# Place the button on the window, using the grid manager.
tkgrid(OK.but)

# Now, bring the window to the focus, using tkfocus.  (This will not work
# if the code is run from RGui, because the focus will automatically
# return to RGui, but it will work if the code is copied and pasted into
# a script file and run using
# Rterm < scriptfile.R > scriptfile.Rout
tkfocus(tt)

in Tcl zelf:
% wm geometry .
28x29+704+362
% wm geometry .
347x175+704+362

aanpassen:

wm geometry . 347x175+104+362 
dat werkt, wordt verplaatst.

> tkwm.geometry(".")
<Tcl> 1x1+0+0 

doet wel iets, maar lijkt niet goed.

> tkwm.geometry(tt)
<Tcl> 181x29+0+25 

tkwm.geometry(tt, "181x29+400+25" )
=> werkt!

panel <- rp.control("Poisson distribution", n = 30, lambda = 3,  ylim = 0.5)


tkwm.geometry(panel)


> tkwm.geometry(panel)
Error in structure(.External("dotTclObjv", objv, PACKAGE = "tcltk"), class = "tclObj") : 
  [tcl] bad window path name ".rpanel42758907".

Er is er wel een, vraag hoe erbij te komen.

winfo rootx window
winfo toplevel window

Alle functies:
> ls("package:tcltk")
  [1] "addTclPath"             "as.tclObj"              "getTkProgressBar"      
  [4] "is.tclObj"              "is.tkwin"               "setTkProgressBar"      
  [7] "tcl"                    "tclArray"               "tclclose"              
 [10] "tclfile.dir"            "tclfile.tail"           "tclObj"                
 [13] "tclObj<-"               "tclObj<-.tclVar"        "tclopen"               
 [16] "tclputs"                "tclread"                "tclRequire"            
 [19] "tclServiceMode"         "tclvalue"               "tclvalue<-"            
 [22] "tclvalue<-.default"     "tclvalue<-.tclVar"      "tclvar"                
 [25] "tclVar"                 "tkactivate"             "tkadd"                 
 [28] "tkaddtag"               "tkbbox"                 "tkbell"                
 [31] "tkbind"                 "tkbindtags"             "tkbutton"              
 [34] "tkcanvas"               "tkcanvasx"              "tkcanvasy"             
 [37] "tkcget"                 "tkcheckbutton"          "tk_choose.dir"         
 [40] "tkchooseDirectory"      "tk_choose.files"        "tkclipboard.append"    
 [43] "tkclipboard.clear"      "tkclose"                "tkcmd"                 
 [46] "tkcompare"              "tkconfigure"            "tkcoords"              
 [49] "tkcreate"               "tkcurselection"         "tkdchars"              
 [52] "tkdebug"                "tkdelete"               "tkdelta"               
 [55] "tkdeselect"             "tkdestroy"              "tkdialog"              
 [58] "tkdlineinfo"            "tkdtag"                 "tkdump"                
 [61] "tkentry"                "tkentrycget"            "tkentryconfigure"      
 [64] "tkevent.add"            "tkevent.delete"         "tkevent.generate"      
 [67] "tkevent.info"           "tkfile.dir"             "tkfile.tail"           
 [70] "tkfind"                 "tkflash"                "tkfocus"               
 [73] "tkfont.actual"          "tkfont.configure"       "tkfont.create"         
 [76] "tkfont.delete"          "tkfont.families"        "tkfont.measure"        
 [79] "tkfont.metrics"         "tkfont.names"           "tkfraction"            
 [82] "tkframe"                "tkget"                  "tkgetOpenFile"         
 [85] "tkgetSaveFile"          "tkgettags"              "tkgrab"                
 [88] "tkgrab.current"         "tkgrab.release"         "tkgrab.set"            
 [91] "tkgrab.status"          "tkgrid"                 "tkgrid.bbox"           
 [94] "tkgrid.columnconfigure" "tkgrid.configure"       "tkgrid.forget"         
 [97] "tkgrid.info"            "tkgrid.location"        "tkgrid.propagate"      
[100] "tkgrid.remove"          "tkgrid.rowconfigure"    "tkgrid.size"           
[103] "tkgrid.slaves"          "tkicursor"              "tkidentify"            
[106] "tkimage.cget"           "tkimage.configure"      "tkimage.create"        
[109] "tkimage.names"          "tkindex"                "tkinsert"              
[112] "tkinvoke"               "tkitembind"             "tkitemcget"            
[115] "tkitemconfigure"        "tkitemfocus"            "tkitemlower"           
[118] "tkitemraise"            "tkitemscale"            "tklabel"               
[121] "tklistbox"              "tklower"                "tkmark.gravity"        
[124] "tkmark.names"           "tkmark.next"            "tkmark.previous"       
[127] "tkmark.set"             "tkmark.unset"           "tkmenu"                
[130] "tkmenubutton"           "tkmessage"              "tkmessageBox"          
[133] "tk_messageBox"          "tkmove"                 "tknearest"             
[136] "tkopen"                 "tkpack"                 "tkpack.configure"      
[139] "tkpack.forget"          "tkpack.info"            "tkpack.propagate"      
[142] "tkpack.slaves"          "tkpager"                "tkplace"               
[145] "tkplace.configure"      "tkplace.forget"         "tkplace.info"          
[148] "tkplace.slaves"         "tkpopup"                "tkpost"                
[151] "tkpostcascade"          "tkpostscript"           "tkProgressBar"         
[154] "tkputs"                 "tkradiobutton"          "tkraise"               
[157] "tkread"                 "tkscale"                "tkscan.dragto"         
[160] "tkscan.mark"            "tkscrollbar"            "tksearch"              
[163] "tksee"                  "tkselect"               "tkselection.adjust"    
[166] "tkselection.anchor"     "tkselection.clear"      "tkselection.from"      
[169] "tkselection.includes"   "tkselection.present"    "tkselection.range"     
[172] "tkselection.set"        "tkselection.to"         "tk_select.list"        
[175] "tkset"                  "tksize"                 "tkStartGUI"            
[178] "tktag.add"              "tktag.bind"             "tktag.cget"            
[181] "tktag.configure"        "tktag.delete"           "tktag.lower"           
[184] "tktag.names"            "tktag.nextrange"        "tktag.prevrange"       
[187] "tktag.raise"            "tktag.ranges"           "tktag.remove"          
[190] "tktext"                 "tktitle"                "tktitle<-"             
[193] "tktoggle"               "tktoplevel"             "tktype"                
[196] "tkunpost"               "tkwait.variable"        "tkwait.visibility"     
[199] "tkwait.window"          "tkwidget"               "tkwindow.cget"         
[202] "tkwindow.configure"     "tkwindow.create"        "tkwindow.names"        
[205] "tkwinfo"                "tkwm.aspect"            "tkwm.client"           
[208] "tkwm.colormapwindows"   "tkwm.command"           "tkwm.deiconify"        
[211] "tkwm.focusmodel"        "tkwm.frame"             "tkwm.geometry"         
[214] "tkwm.grid"              "tkwm.group"             "tkwm.iconbitmap"       
[217] "tkwm.iconify"           "tkwm.iconmask"          "tkwm.iconname"         
[220] "tkwm.iconposition"      "tkwm.iconwindow"        "tkwm.maxsize"          
[223] "tkwm.minsize"           "tkwm.overrideredirect"  "tkwm.positionfrom"     
[226] "tkwm.protocol"          "tkwm.resizable"         "tkwm.sizefrom"         
[229] "tkwm.state"             "tkwm.title"             "tkwm.transient"        
[232] "tkwm.withdraw"          "tkXselection.clear"     "tkXselection.get"      
[235] "tkXselection.handle"    "tkXselection.own"       "tkxview"               
[238] "tkxview.moveto"         "tkxview.scroll"         "tkyposition"           
[241] "tkyview"                "tkyview.moveto"         "tkyview.scroll"        
[244] "ttkbutton"              "ttkcheckbutton"         "ttkcombobox"           
[247] "ttkentry"               "ttkframe"               "ttkimage"              
[250] "ttklabel"               "ttklabelframe"          "ttkmenubutton"         
[253] "ttknotebook"            "ttkpanedwindow"         "ttkprogressbar"        
[256] "ttkradiobutton"         "ttkscrollbar"           "ttkseparator"          
[259] "ttksizegrip"            "ttktreeview"          

wel tkwinfo

rp.control():
panelname: the name of the panel at .rpenv. If this is not assigned,
          then realname is taken.
          
          
met rp.control de source van deze functie.
        wm <- tktoplevel()
    panel$window <- wm

panel <- rp.control("Poisson distribution", n = 30, lambda = 3,  ylim = 0.5)
    
dan alleen panelname terug.

rp.button(panel, poisson.draw, "Go")

deze kan dus met de panel-naam de window weer vinden om de button erbij te zetten.

source van rp.button:

> rp.button
function (panel, action, title = deparse(substitute(action)), 
    id = "", parent = window, repeatdelay = 0, repeatinterval = 0, 
    quitbutton = FALSE, pos = NULL, ...) 
{
    ischar <- is.character(panel)
    if (ischar) {
        panelname <- panel
        panel <- .geval(panel)
    }
    else {
        panelname <- panel$intname
        panelreturn <- deparse(substitute(panel))
        .gassign(panel, panelname)
    }
    pos = .newpos(pos, ...)
    f <- function(...) {
        panel <- action(.geval(panelname))
        if (!is.null(panel$intname)) {
            .gassign(panel, panelname)
        }
        else {
            stop("The panel was not passed back from the action function.")
        }
        if (quitbutton) {
            .geval("try(tkdestroy(", panelname, "$window))")
        }
    }
    if (.checklayout(pos)) {
        if ((!is.list(pos)) || (is.null(pos$row))) {
            newbutton <- tkbutton(panel$window, text = title, 
                command = f, repeatdelay = repeatdelay, repeatinterval = repeatinterval)
            .rp.layout(newbutton, pos)
        }
        else {
            if (is.null(pos$grid)) {
                gd = panel$window
            }
            else {
                gd = .geval(panelname, "$", pos$grid)
            }
            if ((is.null(pos$width)) && (is.null(pos$height))) {
                newbutton <- tkbutton(panel$window, text = title, 
                  command = f, repeatdelay = repeatdelay, repeatinterval = repeatinterval)
            }
            else {
                newbutton <- tkbutton(panel$window, text = title, 
                  command = f, repeatdelay = repeatdelay, repeatinterval = repeatinterval, 
                  width = pos$width, height = pos$height)
            }
            if (is.null(pos$sticky)) {
                pos$sticky <- "w"
            }
            if (is.null(pos$rowspan)) {
                pos$rowspan = 1
            }
            if (is.null(pos$columnspan)) {
                pos$columnspan = 1
            }
            tkgrid(newbutton, row = pos$row, column = pos$column, 
                sticky = pos$sticky, `in` = gd, rowspan = pos$rowspan, 
                columnspan = pos$columnspan)
        }
    }
    if (ischar) 
        invisible(panelname)
    else assign(panelreturn, .geval(panelname), envir = parent.frame())
}
<environment: namespace:rpanel>


panel <- .geval(panel) is wel boeiend.

.geval niet gevonden...

panel <- rp.control("Poisson distribution", n = 30, lambda = 3,  ylim = 0.5, ischar=FALSE)

ischar lijkt geen invloed te hebben.

 parent.frame()
<environment: R_GlobalEnv>

  x: a variable name (given as a character string).
get(x, envir=..)

> rp.control
function (title = "", size = c(100, 100), panelname, realname, 
    aschar = TRUE, ...) 
{

panel <- rp.control("Poisson distribution", panelname="rpanel", n = 30, lambda = 3,  ylim = 0.5, ischar=FALSE)

> panel
[1] "rpanel"

in rp.button
    ischar <- is.character(panel)
    if (ischar) {
        panelname <- panel
        panel <- .geval(panel)
    }

aanroep:    
rp.button(panel, poisson.draw, "Go")

> is.character(panel)
[1] TRUE

> panel <- .geval(panel)
Error: could not find function ".geval"

misschien functies met punten niet ge-exporteerd, in andere namespace? dit is wel de reden dat ik 'em niet vind, en de functie wel.

Vraag is of ik RPanel zo goed kan gebruiken, als ggplot hierin toch niet wil, en ik 2 aparte windows wil houden. Dan net zo goed met tcltk direct, en hierin heb ik het wel gevonden.

Puur een (intellectuele?) uitdaging nog om de missing link te vinden...

source van rpanel te vinden?

ja, in ~/aaa/rpanel gezet

in rpanel.r is de functie .geval te vinden, doet zoiets:
invisible(eval(parse(text = expression), envir = .rpenv))

> get(panel, envir = .rpenv)
$n
[1] 30

$lambda
[1] 3

$ylim
[1] 0.5

$ischar
[1] FALSE

$window
$ID
[1] ".16"

$env
<environment: 0x955f538>

attr(,"class")
[1] "tkwin"

$intname
[1] "rpanel"


> get(panel, envir = .rpenv)$window
$ID
[1] ".16"

$env
<environment: 0x955f538>

attr(,"class")
[1] "tkwin"
> get(panel, envir = .rpenv)$window$ID
[1] ".16"
> 

dan terug naar rtcltk om window te verplaatsen:

> tt
$ID
[1] ".12"

$env
<environment: 0x857398c>

attr(,"class")
[1] "tkwin"

ziet er best hetzelfde uit, dus waarschijnlijk op $window niveau nodig.
get(panel, envir = .rpenv)$window

oude voor rtcltk:
tkwm.geometry(tt, "181x29+400+25" )


panel <- rp.control("Poisson distribution", panelname="rpanel", n = 30, lambda = 3,  ylim = 0.5, ischar=FALSE)
tkwm.geometry(get(panel, envir = .rpenv)$window, "181x29+400+25" )

=> en alweer: yesyes, dit is 'em!

dan heb ik t aardig door nu. Kan met geometry zowel lezen als zetten. De std R window igg zetten, dus ook ok.

