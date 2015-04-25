edge(a,e).
edge(b,d).
edge(b,c).
edge(c,a).
edge(e,b).
edge(a,b).

edge(X,Y) :- tedge(X,Y).

tedge(Node1,Node2) :-
      edge(Node1,SomeNode),
      edge(SomeNode,Node2).

