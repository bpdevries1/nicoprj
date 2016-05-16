Tcltk package door Peter Dalgaard gemaakt, schrijver van Intro to R dat ik heb.

> t = .Tcl("expr 2+3")
> t
<Tcl> 5 
> t + 2
Error in t + 2 : non-numeric argument to binary operator
> paste(t, "abc")
[1] "5 abc"
> as.numeric(t)
[1] 5

root <- tktoplevel()
button <- tkbutton(root, text="hello")
tkpack(button)

txt <- tktext(tt) # tt niet gevonden.
scr <- tkscrollbar(tt, command=function(...) tkyview(txt, ...))
tkconfigure(txt, yscrollcommand=function(...) tkset(scr, ...))

check <- tkcheckbutton(root, variable="foo")
tkpack(check)
tclvar$foo <- 1
tclvar$foo <- 0

> tclvar$foo <- 1
Error: '$<-.tclvar' is defunct.
Use 'tclVar and tclvalue<-' instead.
See help("Defunct")

werken nog niet zo.

In tcl/wish zelf:

label .lvan -text "Van:"
label .ltot -text "Tot:"

# text .tvan -variable tsvan
# geen text, is multiline window
entry .evan
entry .etot
# .e get om de string te krijgen

button .refresh -label Refresh -command tsrefresh
pack .lvan .evan .ltot .etot .refresh

proc tsrefresh {args} {
  global tsvan tstot
  puts $args
  puts "tsvan: [.evan get], tstot: [.etot get]"
}

Dit gaat goed, alle widgets nu onder elkaar met std pack.

Hetzelfde binnen R:

library(tcltk)

root <- tktoplevel()
lvan <- tklabel(root, text="Van:")
ltot <- tklabel(root, text="Tot:")

.Tcl("proc tsrefresh {args} {
  global tsvan tstot;
  puts $args;
  puts "tsvan: [.evan get], tstot: [.etot get]"
}")
# werkt niet

evan = tktext(root)
etot = tktext(root)


brefresh = tkbutton(root, text="Refresh", command="tsrefresh")

tkpack(lvan, evan, ltot, etot, brefresh)

# gebeurt wel wat: window gemaakt, maar veel te grote widgets, resizen gaat ook niet goed.
# en bij klikken button uiteraard fout melding dat proc niet gevonden is.

.Tcl("proc tsrefresh {args} {puts $args}")

> .Tcl("tsrefresh abc")
abc
<Tcl>  

# dus gaat goed, klikken op button geeft nu lege regel.

PressedOK <- function()
{
    # tkmessageBox(message="You pressed OK!")
    print("You pressed Ok")
}

tt <- tktoplevel()
OK.but <- tkbutton(tt,text="OK",command=PressedOK)
tkgrid(OK.but)
tkfocus(tt)

tkconfigure(brefresh, command=PressedOK)
# dat werkt, nu alleen nog inhoud van text meegegeven, resizing goed en koppelen aan graph window.

# voorbeeld
tt <- tktoplevel()
labelText <- tclVar("This is a text label")
label1 <- tklabel(tt,text=tclvalue(labelText))
tkconfigure(label1,textvariable=labelText)
tkgrid(label1)
ChangeText <- function() tclvalue(labelText) <- "This text label has changed!"
ChangeText.but <- tkbutton(tt,text="Change text label",command=ChangeText)
tkgrid(ChangeText.but)
# werkt

# vertalen naar mijn probleem
vanText = tclVar("")
totText = tclVar("")
tkconfigure(evan, textvariable=vanText)
tkconfigure(etot, textvariable=totText)

tt <- tktoplevel()
evan <- tkentry(tt,text=tclvalue(vanText))
etot <- tkentry(tt,text=tclvalue(totText))

tkconfigure(evan,textvariable=vanText)
tkconfigure(etot,textvariable=totText)
# nu doet 'ie het wel.

refreshPressed <- function() {
  print("button pressed3")
  #vt = tclvalue(vanText)
  #print(vt)
  print(paste("van: ", tclvalue(vanText)))
  print(paste("tot: ", tclvalue(totText)))
}

tkconfigure(btRefresh, command=refreshPressed)

lvan <- tklabel(tt, text="Van:")
ltot <- tklabel(tt, text="Tot:")

btRefresh = tkbutton(tt, text="Refresh", command=refreshPressed)

tkgrid(lvan, evan, ltot, etot, btRefresh)

# dit werkt allemaal, dus nu in de praktijk: zie test-dataframe-apply-by.R

moet nu wel de hele timestamp incl seconden intypen, niet zo handig. Iets als een default tijd
defstart = "2010-01-01 00:00:00"
defend = "2020-01-01 00:00:00"

en dan de ingevulde timestamp aanvullen met chars uit start en end.

start = "2011-08-29 14"

start1 = paste(start, substr(defstart, nchar(start) + 1, nchar(defstart)), sep="")

Rcmdr: The Commander GUI is launched only in interactive sessions
heb dus in .R file alleen library(Rcmdr) gezet en met Rscript uitgevoerd. Maar dan geen window geopend, en
R stopt meteen weer.

ook zoiets in activitylog, dat je ofwel periodiek de evenqueue uitleest, ofwel zorgt dat je in wacht mode gaat.
evt nadat alles gedaan is een Tcl script uitvoeren die in een lus blijft wachten met after.

* installing *source* package ‘tkrplot’ ...
configure: creating ./config.status
config.status: creating src/Makevars
** libs
gcc -I/usr/share/R/include -I/usr/include/tcl8.5 -I/usr/include/tcl8.5     -fpic  -std=gnu99 -O3 -pipe  -g -c tcltkimg.c -o tcltkimg.o
gcc -shared -o tkrplot.so tcltkimg.o -L/usr/lib -ltcl8.5 -L/usr/lib -ltk8.5 -lX11 -lXss -lXext -L/usr/lib/R/lib -lR
/usr/bin/ld: cannot find -lXss
collect2: ld returned 1 exit status
make: *** [tkrplot.so] Error 1
ERROR: compilation failed for package ‘tkrplot’
* removing ‘/home/nico/R/i486-pc-linux-gnu-library/2.13/tkrplot’

The downloaded packages are in
	‘/tmp/Rtmpe8Pasr/downloaded_packages’
Warning message:
In install.packages("tkrplot") :
  installation of package 'tkrplot' had non-zero exit status
> 

Idee was om te kijken of tkrplot het doet, en evt ook in combi met ggplot. Met symlinks nog wel de tcl includes
en libs goedgezet, maar onduidelijk (ook na google) wat Xss lib is. en ook of deze echt nodig is. ERgens iets
van X screen saver gevonden, lijkt niet zo nuttig.

Alternatief is dat R functie een nieuwe .png schrijft, en dat ik deze kan inlezen in een Tk window. Als .png
niet lukt, dan ook wel andere formaten. SVG lijkt dan bv ook leuk.


