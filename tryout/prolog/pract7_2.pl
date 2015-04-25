%% a^n, b^2m, c^2m, d^n
%% gespiegeld, dus vanuit midden beginnen.
s --> [].
s --> la,s,rd.
s --> s2.
s2 --> [].
s2 --> mb,s2,mc.
la --> [a].
rd --> [d].
mb --> [b,b].
mc --> [c,c].



