%% met onderstaande is het recursieve probleem al duidelijk, hier geen eindige oplossingen.
%% antwoord zit mogelijk in het herkennen van cycli.

edge(a,b).
edge(b,a). 
edge(b,c).
edge(b,d).
edge(d,c).
edge(d,a).
edge(c,a).

route(X,Y) :- edge(X,Y).
%% route(X,Y) :- edge(X, Z), route(Z, Y).
%% even heel simpel: als X en Y gelijk, dan geen route.
%% route(X,Y) :- edge(X, Z), route(Z, Y), X \= Y, X \= Z, Y \= Z.

%% ook volgorde binnen een clause!
%% route(X,Y) :- X \= Y, X \= Z, Y \= Z, edge(X, Z), route(Z, Y).
%% route(X,Y) :- X \= Y, edge(X, Z), route(Z, Y).
route(X,Y) :- edge(X, Z), route(Z, Y), X \= Y.

%% cycle concept gebruiken?
route(X,Y) :- edge(X,Y).
route(X,Y) :- edge(X, Z), route(Z, Y).
cycle(X) : route(X,X).
containsCycle(X,Y) :- route(X,Y), cycle(X).
%% => dit is het toch niet, mogelijk de route zelf bewaren, met chain-functie als in problem2.pl

chain(X,Y,[]) :- edge(X,Y).
chain(X,Y,[H|Tail]) :- chain(H,Y,Tail), edge(X,H).

nonmember(X, List) :- \+ member(X,List).

chainfull(X,Y,[X,Y]) :- edge(X,Y).
%% chainfull(X,Y,[H|Tail]) :- chainfull(H,Y,Tail), edge(X,H).
%% chainfull(X,Y,[X|Tail]) :- edge(X,H), chainfull(H,Y,Tail), not(member(X,Tail)).
%% chainfull(X,_,[X|Tail]) :- member(X,Tail), !, fail.
%% chainfull(X,Y,[X|Tail]) :- edge(X,H), chainfull(H,Y,Tail), \+ member(X,Tail).
%% chainfull(X,Y,[X|Tail]) :- edge(X,H), \+ member(X,Tail), chainfull(H,Y,Tail).
%% chainfull(X,Y,[X|Tail]) :- \+ member(X,Tail), edge(X,H), chainfull(H,Y,Tail).


%% idee: 2 regels, eentje goed, eentje fail?
%% 2e regel: \+ nodig?
%% als ik bij eerste de ! toevoeg, gaat ie committen, dan lukt het niet.
%% chainfull(X,Y,[X|Tail]) :- edge(X,H), chainfull(H,Y,Tail), \+ member(X,Tail).	
%% chainfull(X,Y,[X|Tail]) :- edge(X,H), chainfull(H,Y,Tail), nonmember(X,Tail).	
%% chainfull(X,Y,[X|Tail]) :- edge(X,H), chainfull(H,Y,Tail), member(X,Tail), fail.

%% nu: fail, kies andere oplossing: via achterkant wordt stiekem toch weer dezelfde gekozen.

chainfull(X,Y,[X|Tail]) :- edge(X,H), chainfull(H,Y,Tail).

%% oplossen met nonmember functie? ofwel isnew, of add maakt hem groter.

%% negation as failure. en cuts.

%% probleem: enerzijds moet je soms stoppen, als er cycle is, anderzijds moet je wel alternatieve edges proberen.

%% heel andere werkwijze: verzamel edge predicaten, sorteer ze op bepaalde manier en dan alsnog proberen. Dan mogelijk
%% wel goede oplossingen, maar hierna nog steeds stack overflow.
%% vervolg hierop: als edge gebruikt is, mag deze niet nogeens worden gebruikt.
%% dit is dan wel beter met hele graph als var te doen.
%% sorteren zou iets zijn van: eerste alle edges(X,y) waarbij X<Y, dan de andere edges. toch maar zeer de vraag of dat
%% gaat werken.

%% nog andere werkwijze: misschien is de representatie niet goed, voor alternatieven zie https://prof.ti.bfh.ch/hew1/informatik3/prolog/p-99/
%% hiermee dan een hele graph in een var.

%% of een oplossing waarbij ik accumulator of difference lists gebruik?

%% wat proberen met accumulator, eerst zonder cycles.
%% def: chainacc(X,Y,Acc,Result)
%% acc is eerst leeg, op einde wordt res=acc gezet.
%% einde is hier dan als je het eindpunt hebt bereikt.
%% als ie voorlopig net verkeerd om is, doe ik later wel een reverse.

accReverse([H|Tail],A,Rev) :- accReverse(Tail, [H|A], Rev).
accReverse([],A,A).
reverse(L, Rev) :- accReverse(L, [], Rev).



chainacc(X, X, Acc, [X|Acc]). %% stop-ding
%% nu eerst non-member vragen, dan recursion. Idee is dat dit werkt, omdat zowel H als Acc hier bekend zijn!
%% => en het werkt!
%% chain2(X,Y,Path) werkt ook, vindt alle paden met begin en eindpunten!
chainacc(X, Y, Acc, Res) :- edge(X,H), \+ member(H, Acc), chainacc(H,Y,[X|Acc], Res).
chain2(X, Y, Path) :- chainacc(X, Y, [], PathRev), reverse(PathRev, Path).


%% fail: deze gaat niet lukken, ga maar backtracken.
%% wil dus eigenlijk wel fail, maar niet ! gebruiken.
	
	
