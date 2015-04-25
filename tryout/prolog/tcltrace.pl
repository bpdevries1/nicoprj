%% tcl trace defs in prolog

start(genanres).
start(isxml).
aanroep(genanres,clientres).
aanroep(genanres,serverres).
aanroep(serverres,nmonres).
aanroep(nmonres,nmongraph).
aanroep(foo,bar).

ancestor(Caller, Callee) :- aanroep(Caller, Callee).
ancestor(Caller, Callee) :- aanroep(Caller, X), ancestor(X, Callee).

used(X) :- start(X).
used(X) :- start(Y), ancestor(Y,X).

unused(X) :- not(used(X)).

