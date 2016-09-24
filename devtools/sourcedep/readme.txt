sourcedep - yet another [2016-09-14 21:55] 

* Ruby version is too complicated, with OO bloat. This should be minimal version for Tcl and Vugen scripts, possibly clojure. Only file includes and function calls. First put in Sqlite DB, maybe some heuristics to determine namespaces.
* (still) make graphs with graphviz/dot, embed in HTML, specific config files (tcl) to determine scope (eg include libndv).
* Use logdb framework (with coroutines) to read logfiles
* First pass determines als proc/function definitions, second pass determines where they are used, where a call is done. This should be doable with just a string search, no full parsing needed.
* Parser combinator is out of scope here, could be a good (first?) project for Racket.

Data structuur:
* Sourcefile: language (tcl), path, name.
* Project: bv buildtool, ndvlib, report, perftools. Hier kun je dan sourcefiles aanhangen, evt n:m. -> eerst niet, eerst in losse DB's
* proc - procedure definition. Statements within proc. Default proc in sourcefile.
* Statement: source of source_once: verwijzing naar sourcefile, linenr_start, linenr_end, lines. Kan voorkomen dat het multiline is. Dus kijk met info complete.
  - evt generiek onder statement, heeft ook verw naar sourcefile en linenr dingen. Dan type toevoegen.
  - bij procdef: name, namespace, ook class (bij ITcl, TclOO, XoTcl), proctype dan ook: proc, oo-method, Itcl-method, etc.
  - onderscheid tussen definities en calls? Def is alleen proc, class, method. Call is source of proc-aanroep.
* Ref: van statement naar ander statement (call) of een sourcefile (bij source, include).
* Mooi als het ook voor vugen gebruikt kan worden. En ook Clojure? Waarsch lastiger.

Source files:
* sourcedep.tcl - main
* sourcedepdb.tcl - alleen db defs
* use liblogreader - met coroutines. Deze later evt hernoemen, verplaatsen.
* tclreader + vugenreader - source readers, gebruiken coroutines.
* libsourcedep.tcl - diverse functies, te gebruiken in andere sources.

Eerst tcl, dan meteen ook op eigen tool toe te passen.
Of toch eerst C/vugen, is gemakkelijker, minder flexibel, meer rigide.

Notes:
* Ook wel op ndvlib alleen toe te passen, onderlinge afhankelijkheden. En dan ook op vugenlibs in repo/lib.
* Naast procs mss ook globals (vars) bekijken, waar ze worden gebruikt.


