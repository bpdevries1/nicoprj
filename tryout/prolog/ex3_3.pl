%% leaf(X).

%% tree(X) :- leaf(X).	
%% tree(leaf(X)).

%% tree(tree(X), tree(Y)) :- tree(X), tree(Y).


%% swap(tree(tree(leaf(1), leaf(2)), leaf(4)),T).
%% tree(tree(leaf(1), leaf(2)), leaf(4))

%% swap(tree(A, B)) :- tree(B,A).
%% swap(A, B) :- tree(X,Y), tree(Y,X)
%% swap(tree(X,Y), tree(Y,X)). 

%% onderstaande werkt wel met def in vraagstelling.	
%% swap(leaf(X), leaf(X)).
%% swap(tree(Left, Right), tree(RightSwapped, LeftSwapped)) :- swap(Left, LeftSwapped), swap(Right, RightSwapped).
	
%%leaf(X) :- X>0.
%% leaf(X) :- number(X).
%% eigenlijk controle dat X singular is. atom?
%% leaf(X).
%% tree(X,Y) :- leaf(X), leaf(Y).
%% tree(X) :- leaf(X).
%% tree(tree(X)) :- tree(X). 
%% tree(X,Y) :- tree(X), tree(Y).

%% met branch-def?

%% andere manier van definieren. Eigenlijk zijn leaf en branch attributen/waarheden over een var. tree is echt de constuctie methode.
%% bij eerste manier was leaf ook een constructie methode.
leaf(X) :- number(X).
branch(X) :- leaf(X).
branch(tree(_X,_Y)).
tree(X,Y) :- branch(X), branch(Y).

%% en dan andere swap.
swap(X, X) :- leaf(X).
swap(tree(Left, Right), tree(RightSwapped, LeftSwapped)) :- swap(Left, LeftSwapped), swap(Right, RightSwapped).



