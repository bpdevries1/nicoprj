male(nico).
male(willem).
male(anthony).
male(antonio).
male(meije).
male(sjoerd).

%% is dit een comment?
%% female zou niet nodig moeten zijn, meer iets als not male. Of andersom.
female(X) :- not(male(X)).
	
%% female(linda).
%% female(fenny).
%% female(ashley).

parent_of(willem,nico).
parent_of(willem,linda).
parent_of(fenny,nico).
parent_of(fenny,linda).
parent_of(antonio,anthony).
parent_of(antonio,ashley).
parent_of(linda,anthony).
parent_of(linda,ashley).
parent_of(meije,sjoerd).

%% couple: nu couple, of ooit geweest.
couple(X,Y) :- parent_of(X,Z), parent_of(Y,Z), not(X=Y).
%% geen kinderen samen, wel een couple
couple(linda,meije).

%% andersom def van couple.
couple2(X,Y) :- couple(X,Y).
couple2(X,Y) :- couple(Y,X).
	
father(X,Y) :- male(X), parent_of(X,Y).
mother(X,Y) :- male(X), parent_of(X,Y).
son(X,Y) :- male(X), parent_of(Y,X).
daughter(X,Y) :- female(X), parent_of(Y,X).
grandfather(X,Y) :- father(X,Z), parent_of(Z,Y).

sibling(X,Y) :- parent_of(Z1, X), parent_of(Z1, Y), parent_of(Z2, X), parent_of(Z2, Y), not(X=Y), not(Z1=Z2).
sister(X,Y) :- sibling(X,Y), female(X).
brother(X,Y) :- sibling(X,Y), male(X).
aunt(X,Y) :- sister(X, Z), parent_of(Z, Y).
uncle(X,Y) :- brother(X, Z), parent_of(Z, Y).
ancestor(X,Y) :- parent_of(X,Y).
ancestor(X,Y) :- parent_of(X,Z), ancestor(Z,Y).

