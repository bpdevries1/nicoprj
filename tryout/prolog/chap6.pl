append([],L,L).
append([H|T],L2,[H|L3]) :- append(T,L2,L3).

prefix(P,L) :- append(P,_,L).
suffix(S,L) :- append(_,S,L).
sublist(SubL,L) :- suffix(S,L),prefix(SubL,S).


naiverev([],[]).
naiverev([H|T],R) :- naiverev(T,RevT),append(RevT,[H],R).

accRev([H|T],A,R) :- accRev(T,[H|A],R).
accRev([],A,A).
rev(L,R) :- accRev(L,[],R).

%% exercises - 1
doubled(L) :- append(A, B, L), A = B.

%% exercises - 2
palindrome(L) :- rev(L, LRev), L = LRev.

%% exercises - 3
%% second(X,List)

second(X, [_,X|_]).

%% Write a predicate swap12(List1,List2) which checks whether List1 is identical to List2, except that the first two elements are exchanged.

swap12([A,B|Tail],[B,A|Tail]).

%% Write a predicate final(X,List) which checks whether X is the last element of List.
final(X,L) :- rev(L,[X|_]).

%% toptail(InList,Outlist)
toptail([_|Tail],Out) :- final(F,Tail), append(Out,[F],Tail).
	
%% swapfl(List1,List2)
%% swapfl([H1|Tail1],[H2|Tail2]) :- final(H2,Tail1), final(H1,Tail2), append(X,[H2],Tail1), append(X, [H1], Tail2).
	
%% swapfl([H1|Tail1],[H2|Tail2]) :- append(X,[H2],Tail1), append(X, [H1], Tail2).	
%% swapfl([_|Tail1],[H2|_]) :- append(X,[H2],Tail1).

swapfl([H1|Tail1],[H2|Tail2]) :- toptail([H1|Tail1], X), toptail([H2|Tail2], X), final(H1,Tail2), final(H2,Tail1).

	
	
%% swapfl([A,B],[B,A]).

%% puzzle:
%%       The Englishman lives in the red house.
%%       The jaguar is the pet of the Spanish family.
%%       The Japanese lives to the right of the snail keeper.
%%       The snail keeper lives to the left of the blue house.

%% predicates: color(1,red): first house (leftmost) is red.
%% color(N,red),lang(N,eng) :- 1 <= N <= 3.

pet(P) :- member(P, [jag,snail,zebra]).
lang(L) :- member(L, [eng,spa,jap]).

%% pet(jag).
%% pet(snail).
%% pet(zebra).
%% lang(eng).
%% lang(spa).
%% lang(jap).
poss_pet_lang(P, L) :- pet(P), lang(L).

pet_lang(jag, spa, 1).
pet_lang(snail, jap, 0).

pet_lang(P,L2,0) :- poss_pet_lang(P,L2), pet_lang(P,L1,1), L2 \= L1.
pet_lang(P,L1,1) :- poss_pet_lang(P,L1), pet_lang(P, L2, 0), pet_lang(P, L3, 0), L1 \= L2, L1 \= L3, L2 \= L3.

pet_lang(P2,L,0) :- poss_pet_lang(P2,L), pet_lang(P1,L,1), P2 \= P1.
pet_lang(P1,L,1) :- poss_pet_lang(P1,L), pet_lang(P2, L, 0), pet_lang(P3, L, 0), P1 \= P2, P1 \= P3, P2 \= P3.

%% ook poss_pet_lang: alleen als pet 1 van de 3 en lang ook.
%% pet_lang(P,L1) :- pet_lang(P, L1, 1), pet_lang(P, L2, 0), pet_lang(P, L3, 0), L1 \= L2, L1 \= L3, L2 \= L3.
%% pet_lang(P,L,1) :- pet_lang(P,L).

pet_lang_decided(P,L) :- pet_lang(P,L,1).
pet_lang_decided(P,L) :- pet_lang(P,L,0).

poss_list_pets([P1,P2,P3]) :- pet(P1),pet(P2),pet(P3),P1\=P2,P1\=P3,P2\=P3.
poss_list_langs([L1,L2,L3]) :- lang(L1),lang(L2),lang(L3),L1\=L2,L1\=L3,L2\=L3.
%% poss_solution(ListPets,ListLangs) :- poss_list_pets(ListPets), poss_list_langs(ListLangs).
%% kan 1 lijst wel vastzetten.
poss_solution([jag,snail,zebra],ListLangs) :- poss_list_langs(ListLangs).


pet_lang(P,L) :- pet_lang(P,L,1).
zebra(X) :- pet_lang(zebra,X).

%% practicum
%%member(X, [X|_]).
%%member(X, [_|Tail]) :- member(X, Tail).

%% member functie met 1 regel, using append. Werkte alleen positief, als het een member is. Maar nu omgedraaid, werkt helemaal goed.
member1(X, L) :- append(PreX, _, L), append(_,[X], PreX).

%%    set([2,2,foo,1,foo, [],[]],X).  

set([],[]).
set([H|Tail], Res) :- set(Tail,Res),member(H,Res).
%% bovenstaande wordt eerst geprobeerd, als niet lukt, dan onderstaande.
%% not wel nodig, anders ook [a,b,a],[a,b,a] is goed.
%% volgorde wel anders dan bij opdracht, komt omdat ik achteraan begin, zonder accumulator. 
set([H|Tail], [H|Res]) :- set(Tail,Res), not(member(H,Res)).

%%flatten    [a,b,[c,d],[[1,2]],foo]
%%    [a,b,c,d,1,2,foo]

%%    [a,b,[[[[[[[c,d]]]]]]],[[1,2]],foo,[]]
%% =>  [a,b,c,d,1,2,foo].

%% append is niet nodig.
%% je kan atom gebruiken.
flatten([],[]).
flatten([[]|Tail], TailRes) :- flatten(Tail,TailRes).
flatten([H|Tail], [H|TailRes]) :- atom(H), H \= [], flatten(Tail,TailRes).
flatten([H|Tail], [H|TailRes]) :- number(H), flatten(Tail,TailRes).
%% flatten([H|Tail], [H|TailRes]) :- atom(H), flatten(Tail,TailRes).
%% flatten([A],A).
%% flatten([[H|T1]|T2], [H|[T1Result|T2Result]]) :- flatten(T2, T2Result), flatten(T1, T1Result).
flatten([[H|T1]|T2], [H|T3Result]) :- flatten(T2, T2Result), flatten(T1, T1Result),append(T1Result,T2Result,T3Result).
	
%% geen append: hint voor gebruik accumulators, net als bij reverse?

accFlatten([[]|Tail],A,Res) :- accFlatten(Tail,A,Res).
accFlatten([[H1|Tail1]|Tail],A,Res) :- accFlatten([H1, Tail1 | Tail],A,Res).
%% bovenstaande wel nodig, met deze stack overflow, met komma ipv |. accFlatten([[H1|Tail1]|Tail],A,Res) :- accFlatten([H1, Tail1 , Tail],A,Res).
accFlatten([H|Tail],A,Res) :- atom(H), H \= [], accFlatten(Tail,[H|A],Res).
accFlatten([H|Tail],A,Res) :- number(H), accFlatten(Tail,[H|A],Res).
%% accFlatten([H|Tail],A,Res) :- accFlatten(Tail,[H|A],Res).
%% als het geen atom is, en niet de lege lijst, is het een lijst met minimaal 1 item.
%% accFlatten([H|Tail],A,Res) :- H = [H1|Tail1], accFlatten([H1, Tail1 | Tail],A,Res).
accFlatten([],A,A).

%% met deze dus gelukt! kan mogelijk nog beter door een andere die geen reverse nodig heeft.
flatten2(L, LF) :- accFlatten(L, [], LFR), rev(LFR,LF).


