edge(a,b).
edge(a,f).
edge(f,g).
edge(g,c).
edge(b,c).
edge(f,c).
edge(f,e).
edge(c,e).
edge(c,d).
edge(e,d).

twoedge(A,B) :- edge(A,X), edge(X,B).
threedge1(A,B) :- edge(A,X), edge(X,Y), edge(Y,B).
threedge2(A,B) :- twoedge(A,X), edge(X,B).

edge(X,Y) :- twoedge(X,Y).

