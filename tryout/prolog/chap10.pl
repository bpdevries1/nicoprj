s(X,Y) :- q(X,Y).
s(0,0).
 
q(X,Y) :- i(X),!,j(Y).
q(4,4). %% deze wordt nu nooit gekozen, want altijd al gebind met vorige.

i(1).
i(2).
j(1).
j(2).
j(3).
