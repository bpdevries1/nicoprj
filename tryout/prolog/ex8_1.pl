s(SingPlur) --> np(SingPlur),vp(SingPlur).

np(SingPlur) --> det(SingPlur),n(SingPlur).
 
vp(SingPlur) --> v(SingPlur),np(_).
vp(SingPlur) --> v(SingPlur).
 
det(_) --> [the].
det(singular) --> [a].
 
n(singular) --> [woman].
n(singular) --> [man].
n(plural) --> [men].

v(singular) --> [shoots].
v(plural) --> [shoot].

%% 8.2:
kanga(V,R,Q) --> roo(V,R),jumps(Q,Q),{marsupial(V,R,Q)}.
	
