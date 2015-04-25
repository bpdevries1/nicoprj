plak([],List,List).
plak([H|Tail],X,[H|NewTail]) :- plak(Tail,X,NewTail).

