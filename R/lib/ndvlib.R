# ndvlib.R - general R functions to use
# note: make it a package sometime, but first just source the thing.

load.def.libs = function() {
  library(RSQLite, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
  library(ggplot2, quietly=TRUE) ; # quietly: so we have no warnings, and no error output reported by Tcl.
  library(plyr)
}

db.open = function(db.name) {
  dbConnect(dbDriver("SQLite"), db.name)
}

db.close = function(db) {
  dbDisconnect(db)
}

db.query = function(db, query) {
  dbGetQuery(db, query)
}

