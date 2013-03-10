# RGtk2 probeersel
library(playwith)
library(ggplot2)
library(RGtk2)

# Goals
# simple GUI thing
# ggplot inside GUI window (if fails, normal plot inside GUI window)
# 24-12-2012 these work, see below.
#
# General tutorial.
# Specific:
# * Zoom in on graph: only change axes, or also underlying query.
# * Select point: show info.
# * select subset of data: filter data in R, or change underlying query.

demo(appWindow)
# doet iets, lijkt goed.

demo(package="RGtk2") # to see the rest
demo(slide) # doet het niet.

# kon installeren met sudo R/install.packages("cairoDevice")
# To draw R graphics inside an RGtk2 GUI:
library(cairoDevice)

win = gtkWindow()
da = gtkDrawingArea()
win$add(da)
asCairoDevice(da)
plot(1:10)

#> asCairoDevice(da)
#Error: could not find function "asCairoDevice"
# mss nog iets installeren.
require("cairoDevice")

# dan proberen met ggplot
require(ggplot2)


win = gtkWindow()
da = gtkDrawingArea()
win$add(da)
asCairoDevice(da)
qplot(1:10)
# werkt ook.

# Voorbeelden uit v37i08 (RGtk2).pdf (dropbox)
window = gtkWindow("toplevel", show=FALSE)
names(GtkWindowType)
GtkWindowType["toplevel"]

button = gtkButton("Hello World")
window$add(button)
window$setDefaultSize(200, 200)

window["visible"]
window$show()

image = gdkPixbuf(filename = imagefile("rgtk-logo.gif"))[[1]]
window$set(icon = image, title = "Hello World 1.0")
window[["allocation"]]
gSignalConnect(button, "clicked", function(widget) print("Hello World!"))

help("GtkWindow")
?GtkWindow
?GtkContainer

box = gtkHBox(TRUE, 5)
button_a = gtkButton("Button A")
button_b = gtkButton("Button B")
box$packStart(button_a, fill=FALSE)
box$packStart(button_b, fill=FALSE)

main_application_window = NULL
dialog = gtkMessageDialog(main_application_window, "detroy-with-parent", "question", "yes-no", "Do you want to upgrade RGtk2?")

if (dialog$run() == GtkResponseType["yes"]) print("RGtk2 installing...")
# zie binnen RStudio nu geen modal dialog box.
# hij is er wel, met alt-tab wel naartoe te gaan.

res = dialog$run()

dialog$destroy()

# met checkbox erbij.
dialog = gtkMessageDialog(main_application_window, "detroy-with-parent", "question", "yes-no", "Do you want to upgrade RGtk2?")
check = gtkCheckButton("Upgrade GTK+ system library")
dialog[["vbox"]]$add(check)

# met radiobuttons
dialog = gtkMessageDialog(main_application_window, "detroy-with-parent", "question", "yes-no", "Do you want to upgrade RGtk2?")
choices = c("None", "Stable version", "Unstable version")
radio_buttons = NULL
vbox = gtkVBox(FALSE, 0)
for (choice in choices) {
  button = gtkRadioButton(radio_buttons, choice)
  vbox$add(button)
  radio_buttons = c(radio_buttons, button)
}

frame = gtkFrame("Install GTK+ system library")
frame$add(vbox)
dialog[["vbox"]]$add(frame)

# met combobox
dialog = gtkMessageDialog(main_application_window, "detroy-with-parent", "question", "yes-no", "Do you want to upgrade RGtk2?")
choices = c("None", "GTK+ 2.8.x", "GTK+ 2.10.x", "GTK+ 2.12.x")
combo = gtkComboBoxNewText()
combo$show()
for (choice in choices) combo$appendText(choice)
combo$setActive(0)
frame = gtkFrame("Install GTK+ system library")
frame$add(combo)
dialog[["vbox"]]$add(frame)

# GSignal?
# blz 32: identify point, 1 vd dingen die ik wil.

library(RGtk2)
library("rggobi")
attach(mtcars)
gg <- ggobi(mtcars)
model <- lm(mpg ~ hp)
plot(hp, mpg)
abline(model)
gSignalConnect(gg, "identify-point",
  function(gg, plot, id, dataset) {
    plot(hp, mpg)
    points(hp[id + 1], mpg[id + 1], pch = 19)
    abline(model)
  })

fn = function(gg, plot, id, dataset) {
    plot(hp, mpg)
    points(hp[id + 1], mpg[id + 1], pch = 19)
    abline(model)
  }
# werkt niet zo, onderstaande eens doen.  

win = gtkWindow()
da = gtkDrawingArea()
win$add(da)
asCairoDevice(da)
qplot(1:10)
  
gSignalConnect(win, "identify-point",
  function(gg, plot, id, dataset) {
    print("clicked!")
  })
# not

gSignalConnect(da, "identify-point",
  function(gg, plot, id, dataset) {
    print("clicked!")
  })

# ook niet.  
# demos:
drawingArea
rgtkplot
demo(appWindow)
# doet wel, niet zoveel aan nu.

demo(drawingArea)

> scribble.button.press.event <- function(widget, event, data)
+ {
+   if (is.null(pixmap))
+     return(FALSE) # paranoia check, in case we haven't gotten a configure event
+ 
+   if (event[["button"]] == 1) # left mouse button click
+     draw.brush(widget, event[["x"]], event[["y"]])
+ 
+   # We've handled the event, stop processing
+   return(TRUE)
+ }

> scribble.motion.notify.event <- function(widget, event, data)
+ {
+   if (is.null(pixmap))
+     return(FALSE) # paranoia check, in case we haven't gotten a configure event
+ 
+   # This call is very important it requests the next motion event.
+   # If you don't call gdkWindowGetPointer() you'll only get
+   # a single motion event. The reason is that we specified
+   # GDK_POINTER_MOTION_HINT_MASK to gtkWidgetSetEvents().
+   # If we hadn't specified that, we could just use event[["x"]], event[["y"]]
+   # as the pointer location. But we'd also get deluged in events.
+   # By requesting the next event as we handle the current one,
+   # we avoid getting a huge number of events faster than we
+   # can cope.
+   #
+ 
+   pointer <- gdkWindowGetPointer(event[["window"]])
+ 
+   # if button1 held down, draw
+   if (as.flag(pointer$mask) & GdkModifierType["button1-mask"])
+     draw.brush(widget, pointer$x, pointer$y)
+ 
+   # We've handled it, stop processing
+   return(TRUE)
+ }

gSignalConnect(da, "motion_notify_event", scribble.motion.notify.event)

> gSignalConnect(da, "button_press_event", scribble.button.press.event)

> # Ask to receive events the drawing area doesn't normally
> # subscribe to
> #
> # we have to do this numerically, because the function takes gint, not GdkEventMask
> da$setEvents(da$getEvents() + GdkEventMask["button-press-mask"] +
+     GdkEventMask["pointer-motion-mask"] + GdkEventMask["pointer-motion-hint-mask"])

# bovenstaande lijkt wel kritisch!

win = gtkWindow()
da = gtkDrawingArea()
win$add(da)
asCairoDevice(da)
qplot(1:10)
  
gSignalConnect(da, "button_press_event",
  function(widget, event, data=0) {
    print("clicked!")
    print(widget)
    print(event)
    print(data)
  })
  
da$setEvents(da$getEvents() + GdkEventMask["button-press-mask"] +
     GdkEventMask["pointer-motion-mask"] + GdkEventMask["pointer-motion-hint-mask"])  

# Deze werkt wel, dus hoopgevend!

# playwith

# in sudo R
install.packages("playwith")

# in R
library(ggplot2)
# source('~/nicoprj/tryout/R-interactive/playwith.R')
playwith(qplot(qsec, wt, data = mtcars) + stat_smooth())

# zie pbg-commands.R en pbg-lib.R
qpl = plot.multi(db, "select ts, name, value from tab20 where filename like '%garb/20' and length(value) < 20 and 1.0*value >= 0.001 and name not like '*%'", title="Garbage collection")
playwith(qpl)
# werkt niet.

plot.multi.play(db, "select ts, name, value from tab20 where filename like '%garb/20' and length(value) < 20 and 1.0*value >= 0.001 and name not like '*%'", title="Garbage collection")


playwith(qplot(tspsx, value, data=df) +
           facet_grid(name ~ ., scales = "free_y") +
           xlab("Timestamp") +
           opts(title = title))
# werkt niet

source('~/perftoolset/tools/graphdata/pbg-lib.R')
open.libs()
library(playwith)
setwd("~/Ymor/Parnassia/Resultaten")
db = open.db("log20.db")
df = open.query(db, "select ts, name, value from tab20 where filename like '%garb/20' and length(value) < 20 and 1.0*value >= 0.001 and name not like '*%'")
summary(df)
playwith(qplot(tspsx, value, data=df))

xyplot(Income ~ log(Population/Area), data = data.frame(state.x77), 
       groups = state.region, type = c("p", "smooth"), 
       span = 1, auto.key = TRUE, xlab = "Population density, 1974 (log scale)", 
       ylab = "Income per capita, 1974")

playwith(xyplot(value ~ ts, data=df))
xyplot(value ~ ts, data = df, type = c("p", "smooth"), span = 1, auto.key = TRUE)
qplot(tspsx, value, data=df)
xyplot(df$tspsx, df$value, data=df)

library(zoo)
playwith(xyplot(sunspots ~ yearmon(time(sunspots)),
                xlim = c(1900, 1930), type = "l"),
         time.mode = TRUE)

playwith(xyplot(value ~ tspsx, data=df, type = "l"), time.mode = TRUE)

playwith(qplot(tspsx, value, data=df), time.mode = TRUE)
class(df$tspsx)

## Time series plot (Lattice).
## Date-time range can be entered directly in "time mode"
## (supports numeric, Date, POSIXct, yearmon and yearqtr).
## Click and drag to zoom in, holding Shift to constrain;
## or use the scrollbar to move along the x-axis.
library(zoo)
playwith(xyplot(sunspots ~ yearmon(time(sunspots)),
                xlim = c(1900, 1930), type = "l"),
         time.mode = TRUE)

# ofwel support posixct, en heb nu posixlt: aanpassen.
head(df)

# eerst xyplot
playwith(xyplot(value ~ tsct, data=df, type = "p"), time.mode = TRUE)
# deze gaat nu wel goed, nu weer qplot.

playwith(qplot(tsct, value, data=df), time.mode = TRUE)
qplot(tsct, value, data=df)
# ok
playwith(qplot(tsct, value, data=df), time.mode = TRUE)
# niet goed, plot wordt wel gedaan, maar identify, navigate etc doen het niet, waarschijnlijk hier niet voor bedoeld.

## Interactive control of a parameter with a slider.
xx <- rnorm(50)
playwith(plot(density(xx, bw = bandwidth), panel.last = rug(xx)),
         parameters = list(bandwidth = seq(0.05, 1, by = 0.01)))
# ok

# Playwith laat wel duidelijk interactieve zien, alleen werkt (nu) niet voldoende met ggplot2.

# nu 2 mogelijke richtingen:
# * playwith qua idee spreekt me aan, voor std plots werkt het goed. Is het te doen de ggplot ondersteuning beter te maken?
# * gebruik voorbeeld code hierin om mijn eigen toolset te maken, specifiek voor mij, voor timeseries data.

# ggplot2 wordt op een grid geplaatst, wat commando's:
> grob = ggplotGrob(qp)
> fix(grob)
> showGrob()
> sceneListing <- grid.ls(viewports=T, print=FALSE)
> do.call("cbind", sceneListing)

current.vpTree(all=TRUE)
grid.ls(grobs=FALSE, viewports=TRUE)
grid.ls()

# zie boek in dropbox/bien/graphing: chapter5.pdf

library(grid)
vignette()

library(ggmap)

# in sudo R uitvoeren:
install.packages("ggmap")
# hierna werkt het meteen in nog draaiende Rstudio!

df <- data.frame(xvar = 1:10, yvar = 1:10)
qplot(xvar, yvar, data = df) + annotate(geom = 'point', x = 3, y = 6)
gglocator(4)

gglocator(1)
# dan 1 keer klikken en coordinates terugkrijgen, werkt. Best wel breakthrough dus!!

# ook even logaritmisch.
qplot(xvar, yvar, data = df, log="y") + annotate(geom = 'point', x = 3, y = 6)
# -> dat gaat niet goed: klik op 6, komt 8 uit.

# dat nog google dus: ggplot2 gglocator log scale.
# en ook dat je niet eerst hoeft te klikken, is met RGtk2/playwith al gedaan.

help(gglocator)

gglocator

####
ndvloc = function (object = last_plot(), message = FALSE, xexpand = c(0.05, 0), yexpand = c(0.05, 0)) {
  x <- grid.ls(print = message)[[1]]
  x <- x[grep("panel-", grid.ls(print = message)[[1]])]
  seekViewport(x)
  loc <- as.numeric(grid.locator("npc"))
  xrng <- with(object, range(data[, deparse(mapping$x)]))
  yrng <- with(object, range(data[, deparse(mapping$y)]))
  xrng <- scales::expand_range(range = xrng, mul = xexpand[1], 
                               add = xexpand[2])
  yrng <- scales::expand_range(range = yrng, mul = yexpand[1], 
                               add = yexpand[2])
  point <- data.frame(xrng[1] + loc[1] * diff(xrng), yrng[1] + 
                        loc[2] * diff(yrng))
  names(point) <- with(object, c(deparse(mapping$x), deparse(mapping$y)))
  point
}

qplot(xvar, yvar, data = df) + annotate(geom = 'point', x = 3, y = 6)

coord = ndvloc()
coord

# nog uitdaging: 
# nu dus 3.005, 5.997 te zien, wil terugvertalen naar 3, 6 point.

grid.locator()
# retourneert waarde tussen 0 en 1 zo te zien.
locator()
# werkt hier niet, mogelijk alleen met base plots.

# functie los, per regel, wat gebeurt er:
object = last_plot()
message = FALSE
xexpand = c(0.05, 0)
yexpand = c(0.05, 0)
x <- grid.ls(print = message)[[1]]
x <- x[grep("panel-", grid.ls(print = message)[[1]])]
seekViewport(x)
loc <- as.numeric(grid.locator("npc"))
# loc geeft 2 waarden tussen 0 en 1 van het grijze gebied
xrng <- with(object, range(data[, deparse(mapping$x)]))
yrng <- with(object, range(data[, deparse(mapping$y)]))
# xrng bevat data-range, hier 1..10.
# na expand wordt dit 0.55-10.45. mul=0.05, deze maal 9 (10-1) geeft 0.45. Met deze waarde uitbreiden.
# waarsch is dit default in ggplot.
xrng <- scales::expand_range(range = xrng, mul = xexpand[1], 
                             add = xexpand[2])
yrng <- scales::expand_range(range = yrng, mul = yexpand[1], 
                             add = yexpand[2])
point <- data.frame(xrng[1] + loc[1] * diff(xrng), yrng[1] + 
                      loc[2] * diff(yrng))
names(point) <- with(object, c(deparse(mapping$x), deparse(mapping$y)))
point

# resumerend:
# zoek het goede deel van de grafiek, de viewport.
# bepaal een punt hierin, waarde by x en y tussen 0 en 1
# bepaal van data de range, incl expand.
# vertaal waarde 0..1 naar de data range
# format als data.frame met goede titels.
# vraag hoe je binnen playwith de input-waarden krijgt: points of ook 0..1.

# terug naar playwith, met lineEqTool gespeeld, geeft fouten, blijft soms hangen, kan nu eerst simpeler.

library(playwith)
library(ggplot2)

## A tool to draw a line and label it with its equation.
## The annotations are persistent and may be redrawn in other contexts.
## The actions can be reversed with "Undo" menu item or <Ctrl>Z.

## This "callback" is run when the action is activated
## (from toolbar, menu, or keyboard shortcut).
identify_handler <- function(widget, playState) {
  print(widget)
  print(playState)
  # lnInfo <- playLineInput(playState)
  ptInfo <- playPointInput(playState, prompt =
                             paste("Click to identify point,",
                                   "Right-click to cancel."))
  if (is.null(ptInfo)) {
    print("Nothing clicked")
    return()
  }
  print("ptInfo:")
  print(ptInfo)
}

identifyTool <- list("MyIdentify", "gtk-indent", "MyIdentify",
                   callback = identify_handler)

playwith(plot(1:10), tools = list(identifyTool))


[1] "ptInfo:"
$coords
$coords$x
[1] 2.979356

$coords$y
[1] 2.949898


$space
[1] "plot"

$dc
$dc$x
[1] 168

$dc$y
[1] 299


$ndc
$ndc$x
[1] 0.333996

$ndc$y
[1] 0.35141


$modifiers
Error in get(class(x)[1]) : object 'flag' not found

# Hier info dus in alle mogelijke vormen: oorspronkelijke data, pixels, 0..1

# Ook doen voor qplot
playwith(qplot(1:10, 1:10), tools = list(identifyTool))
# meteen foutmelding, gaat wel door.

# na myIdentify en click op 3,3:
[1] "ptInfo:"
$coords
NULL

$space
[1] "page"

$dc
$dc$x
[1] 168

$dc$y
[1] 318


$ndc
$ndc$x
[1] 0.333996

$ndc$y
[1] 0.3101952


$modifiers
Error in get(class(x)[1]) : object 'flag' not found

# coords dus niet gevuld, rest wel.
# onderliggende data zou op te vragen moeten zijn.

qp = qplot(1:10, 1:10)
playwith(qp, tools = list(identifyTool))
# werkt dus niet.
qp$data

# mogelijk echt data.frame meegeven
df <- data.frame(xvar = 1:10, yvar = 1:10)
qplot(xvar, yvar, data = df) + annotate(geom = 'point', x = 3, y = 6)
ndvloc()
qp = qplot(xvar, yvar, data = df) + annotate(geom = 'point', x = 3, y = 6)
qp$data
# gaat dan wel goed.
# playwith source te bekijken hoe je van expr naar plot gaat. Want playwith wil de expr, niet de resulterende (q)plot.

# wil nu een functie die obv qplot object en npc coordinaten de data-coordinaten geeeft.
$ndc
$ndc$x
[1] 0.333996

$ndc$y
[1] 0.3101952

Wat is $ndc hier voor type/class?

playwith(qplot(1:10, 1:10), tools = list(identifyTool))

# global assign
a <- "old"
test <- function () {
  assign("a", "new", envir = .GlobalEnv)
}
test()
a  # display the new value
# hiermee de ptInfo buiten de functie-call te bekijken

identify_handler <- function(widget, playState) {
  print(widget)
  print(playState)
  # lnInfo <- playLineInput(playState)
  ptInfo <- playPointInput(playState, prompt =
                             paste("Click to identify point,",
                                   "Right-click to cancel."))
  assign("ptInfo", ptInfo, envir = .GlobalEnv)
  if (is.null(ptInfo)) {
    print("Nothing clicked")
    return()
  }
  print("ptInfo:")
  print(ptInfo)
}

identifyTool <- list("MyIdentify", "gtk-indent", "MyIdentify",
                     callback = identify_handler)

playwith(plot(1:10), tools = list(identifyTool))

> class(ptInfo$ndc)
[1] "list"
> ndc = ptInfo$ndc
> class(ndc)
[1] "list"
> ndc$x
[1] 0.4194831
> ndc$y
[1] 0.4186551

# mooi, in eigen functie dus zo'n list verwachten.

ggplot.locator = function(ggp, ndc) {
  # ggp is a ggplot object, with a data object
  
}

# ndc: list with $x and $y values, both between 0 and 1.
ggplot.locator = function (ndc, object = last_plot(), message = FALSE, xexpand = c(0.05, 0), yexpand = c(0.05, 0)) {
  xrng <- with(object, range(data[, deparse(mapping$x)]))
  yrng <- with(object, range(data[, deparse(mapping$y)]))
  xrng <- scales::expand_range(range = xrng, mul = xexpand[1], 
                               add = xexpand[2])
  yrng <- scales::expand_range(range = yrng, mul = yexpand[1], 
                               add = yexpand[2])
  point <- data.frame(xrng[1] + ndc$x * diff(xrng), yrng[1] + 
                        ndc$y * diff(yrng))
  names(point) <- with(object, c(deparse(mapping$x), deparse(mapping$y)))
  point
}


df <- data.frame(xvar = 1:10, yvar = 1:10)
ggp = qplot(xvar, yvar, data = df) + annotate(geom = 'point', x = 3, y = 6)
ggp$data
# gglocator(4)

ndc = list(x=0.5, y=0.5)
ndc$y

ggplot.locator(ndc, ggp)
ggplot.locator(list(x=0.0, y=1.0), ggp)
xvar  yvar
1 0.55 10.45
# ziet er goed uit.

identify_handler <- function(widget, playState) {
  print(widget)
  print(playState)
  assign("last.widget", widget, envir = .GlobalEnv)
  assign("last.playState", playState, envir = .GlobalEnv)
  # lnInfo <- playLineInput(playState)
  ptInfo <- playPointInput(playState, prompt =
                             paste("Click to identify point,",
                                   "Right-click to cancel."))
  assign("ptInfo", ptInfo, envir = .GlobalEnv)
  if (is.null(ptInfo)) {
    print("Nothing clicked")
    return()
  }
  # printen ptInfo gaat fout, dan knalt 'ie uit de functie.
  #print("ptInfo:")
  #print(ptInfo)
  
  
  # pre: ggp should be filled with the same ggplot-object
  data.point = ggplot.locator(ptInfo$ndc, ggp)
  assign("last.data.point", data.point, envir = .GlobalEnv)
  print("calculation data point:")
  print(data.point)
}

identifyTool <- list("MyIdentify", "gtk-indent", "MyIdentify",
                     callback = identify_handler)

ggp = qplot(xvar, yvar, data = df)
playwith(qplot(xvar, yvar, data = df), tools = list(identifyTool))

# doet het wel, maar waarden zijn toch niet goed.
# betekent waarsch dat de ptInfo niet goed is.
