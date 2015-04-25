%% twice([a,4,buggle],X).
%% ook andersom aan te roepen om dubbelen te verwijderen, werkt alleen als elk element precies 2x voorkomt, na elkaar.
twice([],[]).
twice([H|Tail], [H,H|Tail2]) :- twice(Tail,Tail2).

