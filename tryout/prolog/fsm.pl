start(s).
final(f1).
final(f2).
delta(s,a,q1).
delta(s,b,q2).
delta(q1,b,s).
delta(q1,a,f1).
delta(q2,a,s).
delta(q2,b,f2).

accept(S) :- start(Q), accept2(Q,S).             %%% This looks strange!!!?
accept2(Q,[X|XS]) :- delta(Q,X,Q1),              %%% Does this make sense that
                         accept2(Q1,XS).         %%% the number of parameters to
accept2(F,[]) :- final(F).                       %%% accept changes?

