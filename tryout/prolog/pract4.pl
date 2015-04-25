%% consult(append)
%% concat is voor string concatenatie.

%% ?- combine1([a,b,c],[1,2,3],X).
%% X = [a,1,b,2,c,3]

combine1([],[],[]).
combine1([H1|Tail1],[H2|Tail2],[H1,H2|Tail12]) :- combine1(Tail1, Tail2, Tail12).

%% ?- combine2([a,b,c],[1,2,3],X).
%% X = [[a,1],[b,2],[c,3]]

combine2([],[],[]).
combine2([H1|Tail1],[H2|Tail2],[[H1,H2]|Tail12]) :- combine2(Tail1, Tail2, Tail12).

%% ?- combine3([a,b,c],[1,2,3],X).
%% X = [join(a,1),join(b,2),join(c,3)]

combine3([],[],[]).
combine3([H1|Tail1],[H2|Tail2],[join(H1,H2)|Tail12]) :- combine3(Tail1, Tail2, Tail12).

%%    1.      Write a predicate mysubset/2 that takes two lists (of constants) as arguments and checks, whether the first list is a subset of the second.
%%   2.       Write a predicate mysuperset/2 that takes two lists as arguments and checks, whether the first list is a superset of the second.

member(X, [X|_]).
member(X, [_|Tail]) :- member(X, Tail).

mysublist(A,A).
mysublist(A, [_|B]) :- mysublist(A, B).
%% mysublist(A, C) :- append(B,_,C), mysublist(A,B).
%% of toch per element: 
mysublist(A, C) :- append(B,[_],C), mysublist(A,B).

%% andere def is verzameling def, dat elk element in de set zit.	
mysubset([],_).
mysubset([E],S) :- member(E,S).
mysubset([H|Tail], S) :- member(H,S), mysubset(Tail, S).
	
%% reverse van 2 kanten benaderen, zonder append te gebruiken?
%% heb ik accumulator nodig, eerst concept leren.
	
