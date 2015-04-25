
%% de enige echte hieronder.
reverse([],[]).
reverse([H|Tail],X) :- reverse(Tail, TailRev), append(TailRev,[H],X).

%% mem(X,[X]).
mem(X,[X|_Tail]).
mem(X,[_H|Tail]) :- mem(X,Tail).
