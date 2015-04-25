%% Write a two-place predicate termtype(+Term,?Type) that takes a term and gives back the type(s) of that term (atom, number, constant, variable etc.). 
%% The types should be given back in the order of their generality. The predicate should, e.g., behave in the following way.
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

groundterm(X) :- atomic(X), nonvar(X).
groundterm(X) :- complexterm(X), X =.. [_|ArgsX], groundtermList(ArgsX). 

groundtermList([]).
groundtermList([H|Tail]) :- groundterm(H), groundtermList(Tail).

%% onderstaande mag ik hier niet doen, is redefinition.
%% maar met :- ervoor mag het wel.
:- op(300, xfx, [are, is_a]).
:- op(300, fx, likes).
:- op(200, xfy, and).
:- op(100, fy, famous).

is_a(_,_).
are(_,_).
likes(_).
and(_,_).
famous(_).

