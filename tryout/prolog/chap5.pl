add_3_and_double(X,Y) :- Y is (X+3)*2.
	
accLen([_|T],A,L) :-  Anew is A+1, accLen(T,Anew,L).
accLen([],A,A).

%% max zonder accumulator.
max([X], X).
max([H|Tail], M) :- max(Tail,M), H =< M.
max([H|Tail], H) :- max(Tail,M), H > M.

%% reverse met accumulator?

accMax([H|T],A,Max) :-
    H > A,
    accMax(T,H,Max).
 
accReverse([H|Tail],A,Rev) :- accReverse(Tail, [H|A], Rev).
accReverse([],A,A).
reverse(L, Rev) :- accReverse(L, [], Rev).

increment(X,Xplus1) :- Xplus1 is X + 1.
sum(X,Y,Sum) :- Sum is X + Y.

%% addone op een lijst, zonder en met accumulator:
addone([],[]).
addone([H|Tail],[Hp1|Tailp1]) :- Hp1 is H + 1, addone(Tail,Tailp1).


accAddOne([H|Tail],A,Res) :- Hp1 is H + 1, append(A, [Hp1], ANew), accAddOne(Tail,ANew,Res).
accAddOne([],A,A).

%% scalarMult(3,[2,7,4],Result). => Result = [6,21,12]

scalarMult(_,[],[]).
scalarMult(N, [H|Tail], [HkN|TailkN]) :- HkN is H * N, scalarMult(N,Tail,TailkN).

%%          dot([2,5,6],[3,4,1],Result).
%%          Result = 32

dot([],[],0).
dot([H1|T1],[H2|T2],R) :- dot(T1,T2,PrevRes), R is PrevRes + (H1*H2).

accDot([H1|T1], [H2|T2], A, Res) :- ANew is A + (H1 * H2), accDot(T1, T2, ANew, Res).
accDot([],[],A,A).

