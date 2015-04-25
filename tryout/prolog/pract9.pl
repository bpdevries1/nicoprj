%% pptree(s(np(det(a),n(man)),vp(v(shoots),np(det(a),n(woman))))),
%% consult[ex9_3]. die werkt dus blijkbaar niet zo, dus eerst copy/paste:
termtype(X,atom) :- atom(X).
termtype(X,number) :- number(X).
termtype(X,constant) :- atomic(X).
termtype(X,variable) :- var(X).
termtype(X,simple_term) :- termtype(X,constant).
termtype(X,simple_term) :- termtype(X,variable).
termtype(X,complex_term) :- complexterm(X).
termtype(_,term).

complexterm(X) :-
        nonvar(X),
        functor(X,_,A),
        A > 0.

pptree(X) :- pptreerec(X,0).

%% pptreerec(s(NP, VP), Indent) :- tab(Indent), write(s), write('('), nl, Indentp2 is Indent + 2, 
%%		pptreerec(NP, Indentp2),nl,pptreerec(VP,Indentp2),write(')').

%% pptreerec(X, Indent) :- tab(Indent), write(X).

pptreerec(X, _) :- atomic(X), write(X).

pptreerec(X, Indent) :- complexterm(X), X =.. [H,Arg], atomic(Arg), tab(Indent), write(H), write('('), 
												pptreerec(Arg, Indent), write(')').

pptreerec(X, Indent) :- complexterm(X), X =.. [H|ArgsX], tab(Indent), write(H), write('('),  
												Indentp2 is Indent + 2, pptreereclist(ArgsX, Indentp2), write(')').
														
pptreereclist([], _).
pptreereclist([H|Tail], Indent) :- nl, pptreerec(H, Indent), pptreereclist(Tail, Indent).


