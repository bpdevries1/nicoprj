byCar(auckland,hamilton).
byCar(hamilton,raglan).
byCar(valmont,saarbruecken).
byCar(valmont,metz).
 
byTrain(metz,frankfurt).
byTrain(saarbruecken,frankfurt).
byTrain(metz,paris).
byTrain(saarbruecken,paris).
 
byPlane(frankfurt,bangkok).
byPlane(frankfurt,singapore).
byPlane(paris,losAngeles).
byPlane(bangkok,auckland).
byPlane(losAngeles,auckland).

byAll(X,Y) :- byCar(X,Y).
byAll(X,Y) :- byTrain(X,Y).
byAll(X,Y) :- byPlane(X,Y).
%% travel(A,B) :- byAll(A,B).
%% travel(A,B) :- byAll(A,C), travel(C,B).

%% part 3: determine route, go()
%% travel(valmont,paris,go(valmont,metz,go(metz,paris))) and X = go(valmont,metz,go(metz,paris,go(paris,losAngeles))) to the query travel(valmont,losAngeles,X).

%% chain(X,Y,[]) :- edge(X,Y).
%% chain(X,Y,[H|Tail]) :- chain(H,Y,Tail), edge(X,H).

travel(A,B,go(A,B)) :- byAll(A,B).
%% travel(A,B,go(A,C, Route)) :- travel(C,B, Route), byAll(A,C).
travel(A,B,go(A,C, Route)) :- byAll(A,C), travel(C,B, Route).

%% part 4: how.
byHow(A,B,car) :- byCar(A,B).
byHow(A,B,train) :- byTrain(A,B).
byHow(A,B,plane) :- byPlane(A,B).

travelHow(A,B,goHow(A,B,How)) :- byHow(A,B, How).
travelHow(A,B,goHow(A,C,How,Route)) :- byHow(A,C, How), travelHow(C,B,Route).

