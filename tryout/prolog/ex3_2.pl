%% greater_than(X,Y) == true als X groter dan Y, alles in succ termen.
	
greater_than(succ(X), 0).
%% onderstaande werkt wel, maar geeft dubbele, dus niet ideaal.
greater_than(succ(0), 0).
greater_than(succ(X), succ(Y)) :-	greater_than(X, Y).
greater_than(succ(X), Y) :-	greater_than(X, Y).

%% onderstaande is van eerste poging, dus met greater_than(succ(X), 0). 
%% ?- greater_than(succ(succ(0)),X).
%% X = 0 ;
%% X = succ(0) ;
%% X = 0 ;

%% of wat simpeler, ook goed. En deze geen dubbele.
%% greater_than(succ(X), X).
%% greater_than(succ(X), Y) :-	greater_than(X, Y).
