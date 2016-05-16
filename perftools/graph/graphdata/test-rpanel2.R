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

rp.block(rpplot)

