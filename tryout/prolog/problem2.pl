edge(a,b).
edge(a,f).
edge(f,g).
edge(g,c).
edge(b,c).
edge(f,c).
edge(f,e).
edge(c,e).
edge(c,d).
edge(e,d).

path(A,A).
path(A,B) :- edge(A,B).
path(A,B) :- edge(A,X), path(X,B).


%% chain: lijst van start naar eindpunt.
%% chain(X,Y,Z): X is start, Y is eind, Z is lijst/chain.
%% chain bevat niet de eindpunten, want die weet ik al.
%% voorbeeld1: chain(a,b,[])
%% vb2: chain(a,c,[b])
%% vb3: chain(a,e,[f,g,c]), want chain(f,e,[g,c]),edge(a,f) 

%% chain(X,X,[]). Deze weg, want kan niet van X naar X.
chain(X,Y,[]) :- edge(X,Y).
chain(X,Y,[H|Tail]) :- chain(H,Y,Tail), edge(X,H).


%% keten(X,Y,[X,chain(X,Y,Result),Y] 

%% of in de chain zitten wel start en eindpunt.
%% chain(X,X,[X]).
%% chain(X,Y,[H|Tail]) :- 

%% voorbeeld1: chain(a,b,[a,b])
%% fout: vb2: chain(a,c,[a,b,c]), want chain(a,b,[a,b]),edge(b,c)
%% vb2: chain(a,c,[a,b,c]), want chain(b,c,[b,c]),edge(a,b)

%% vb3: chain(a,e,[f,g,c]), want chain(f,e,[g,c]),edge(a,f) 
%% chain(X,Y,[X,Y]) :- edge(X,Y).
%% chain(X,Y,[H|Tail]) :- chain(H,Y,Tail), edge(X,H).

%% de enige echte hieronder.
reverse([],[]).
reverse([H|Tail],X) :- reverse(Tail, TailRev), append(TailRev,[H],X).

%% lessen: links behalve de head|tail constructie geen 'functie' aanroepen.
%% let goed op wat lijst is, en wat element, H is dus element, en moet in append dus met [] omvat worden.

%% en hier nog veel probeersels.
%% reverse([a,b,c],[c,b,a]), reverse([a],[a])
%% reverse([X],[X]).
%% reverse(X,[H|Tail]) :- append(reverse(Tail),[H], X).
%% plak([H|Tail],X,[H|NewTail]) :- plak(Tail,X,NewTail).

%% reverse([H|Tail],X) :- append(reverse(Tail), [H], X).
%% reverse([H1|Tail1],append(Tail2,H2,X)) :- reverse(Tail1, Tail2), X = [H1|Tail1].

%% reverse([H1|Tail1],append(Tail2,H2,[H1|Tail1])) :- reverse(Tail1, Tail2).
%% reverse([H1|Tail1],append(Tail2,H1,[H1|Tail1])) :- reverse(Tail1, Tail2).
%% reverse([H1|Tail1],append(Tail2,H1,[H1|Tail1])) :- reverse(Tail1, Tail2), X=.

%% reverse([H1|Tail1],X) :- reverse(Tail1, Tail2), X = append(Tail2,H2,[H1|Tail1]).

%% reverse([H|Tail],append(reverse(Tail),[H]).

	

