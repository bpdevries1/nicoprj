listcopy([],[]).
listcopy([H | A], [H | B]) :- listcopy(A, B).

%% simpeler
listcopy2(A,A).
	
