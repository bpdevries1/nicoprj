directTrain(forbach,saarbruecken).
directTrain(freyming,forbach).
directTrain(fahlquemont,stAvold).
directTrain(stAvold,forbach).
directTrain(saarbruecken,dudweiler).
directTrain(metz,fahlquemont).
directTrain(nancy,metz).

%% travelBetween(nancy,saarbruecken). -> true

%% deze is niet eindig:
%% travelBoth(X,Y) :- directTrain(X,Y).
%% travelBoth(X,Y) :- directTrain(Y,X).

%% travelBetween(X,Y) :- travelBoth(X,Y).
%% travelBetween(X,Y) :- travelBoth(X,Z), travelBetween(Z,Y).

travelBetween(X,Y) :- directTrain(X,Y).
travelBetween(X,Y) :- directTrain(Y,X).

travelBetween(X,Y) :- directTrain(X,Z), travelBetween(Z,Y).
travelBetween(X,Y) :- directTrain(Z,X), travelBetween(Z,Y).

