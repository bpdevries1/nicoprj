%% oefening: soort left, maar stoppen bij char -1.	
%% deze tillMin1 werkt zo:
tillMin1([-1],[]).
%% tillMin1([-1|_Rest],[]). Deze niet zo nodig, na -1 komt niets meer.
tillMin1([H|Tail], [H|TailResult]) :- tillMin1(Tail, TailResult).

%% libary function: read_file_to_codes('abc.txt', Result, [eof_action(eof_code)]).

file(X,Y) :-
        open(X,read,In,[eof_action(eof_code)]),
        readAll(In, Y).

%% todo parse-tree uitschrijven voor onderstaande en ook foute progs, volgens manier in 2e tutorial.
					
					
%% Onderstaande werkt zowaar. Aandachtspunten: volgorde tussen kommas is belangrijk: eerst character lezen, dan de rest, anders wordt get0 nooit aangeroepen.
%% Ook: wanneer -1 wordt teruggegeven, faalt de eerste regel. De tweede regel wordt dan gedaan, die nogmaals leest, nogmaals -1, en dan de lege lijst teruggeeft.
%%readAll(In, [H|TailResult]) :- get0(In,H), legal(H), readAll(In, TailResult). 
%% deze erbij voor illegals, maar gaat niet goed.
%%readAll(In, TailResult) :- get0(In,H), illegal(H), readAll(In, TailResult). 
%%readAll(In, []) :- get0(In,C), eof_char(C), close(In).

%% nu oplossing met maar 1 keer gebruik van get0.

%% readAll/2 hoofdfunctie.
%% readAll/4 met buffer en finished, hierin get0 doen.

%% evt nog een param 'finished' opnemen.
%% werkt allemaal nog niet.
readAll(In, Result) :- readAll(In, Result, [], finished).
readAll(In, Result, [C], unfinished) :- get0(In, C), readAll(In, Result, [], unfinished).
readAll(In, [C | Result], [], unfinished) :- legal(C), readAll(In, Result, [C], unfinished).
%% readAll(In, Result, [], unfinished) :- illegal(C), readAll(In, Result, [C], unfinished).

%% readAll(In, Result, [], finished) :- eof_char(C), readAll(In, Result, [C], unfinished), close(In).
readAll(In, [], [], finished) :- eof_char(C), readAll(In, [], [C], unfinished), close(In).




%% TODOs
%% vraag of close zo goed gaat, close mag pas als file gelezen is.					
%% eof handlen
%% characters toevoegen aan lijst.

%% eerste def.	
%% readAll(In,C) :- get0(In,C).

%% niet goed, kunnen ook foute chars midden in de file zitten.
eof_char(-1).
%% legal(C) :- C >= 32, C =< 127.
legal(C) :- C >= 0.
%% legal(C) :- C = 66.
legal(10).
illegal(C) :- not(legal(C)), C >= 0.

%% begin je voor of achteraan met definitie?
%% start of einde conditie.
%% readAll(In, []) :- get0(In,C), eof_char(C), close(In).
%% readAll(In, L) :- readAll(In, L), get0(In,C), eof_char(C), close(In).

%% readAll(In, append(L,[C])) :- readAll(In, L), get0(In,C), legal(C).
%% readAll(In, [C|L]) :- readAll(In, L), get0(In,C), legal(C).


fileN(X,N,Y) :-
        open(X,read,In,[eof_action(eof_code)]),
        readN(In, N, Y, 0).
readN(In, N, [], 0).
readN(In, N-1, [C|Rest],NRead+1) :- readN(In, N, Rest, NRead), get0(In, C).


%% methode met laatste character bewaren?

%% of stel methode die vast aantal chars inleest, evt meegeven. Evt later een die max aantal inleest, of stopt bij eof.

%% readAll(In, L) :- readAll(In, L), get0(In,C), eof_char(C).
%% bij readAll nog de close erachter zetten.
%% evt een readchar maken.

%%readAll(In, L) :- readAll(In, L), get0(In,C), illegal(C).

%% close_file(In) :- get0(In,eof_char(C)). straks nog even.


%% opties: isOpen clause, readChar (=get0?) clause.
%%isOpen(In) :- ???

%%readchar(In, C) :- get0(In,C).

%% de lengte van een lijst
listLen([],0).
listLen([H|Tail],Nplus1) :- listLen(Tail, N), succ(N,Nplus1).

%% charAt(L, I, Result), I begint bij 1
charAt([], I, null).
charAt([H|Tail],1,H).
charAt([H|Tail],Iplus1,C) :- charAt(Tail, I, C), succ(I, Iplus1).
	
%% copyListN: resultaat bevat eerste N tekens van param.
%%copyLeft(L,0,[]).
%%copyLeft([H|Tail], N, [H|Rest]) :- copyLeft(Tail, N-1, Rest).

%% copyLeft is zo nog niet goed.
copyLeft(L,N,L) :- listLen(L,N).
copyLeft(L2, N, Left) :- copyLeft(List, N, Left), append(L, C, L2).



