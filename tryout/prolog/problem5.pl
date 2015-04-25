%% reverse([],[]).
%% reverse([H|Tail],X) :- reverse(Tail, TailRev), append(TailRev,[H],X).

palindrome([]).
palindrome([_A]).
%%kan niet: palindrome(append([X],A,[X])) :- palindrome(A).

%% oplossing 1:
%%palindrome([H|Tail]) :- reverse(Tail, [H|TailRev]), palindrome(TailRev).

%% oplossing 2:
palindrome(X) :- append([H|Mid], [H], X), palindrome(Mid).
