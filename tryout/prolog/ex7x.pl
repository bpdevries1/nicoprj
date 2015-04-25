s --> foo,bar,wiggle.
foo --> [choo].
foo --> foo,foo.
bar --> mar,zar.
mar --> me,my.
me --> [i].
my --> [am].
zar --> blar,car.
blar --> [a].
car --> [train].
wiggle --> [toot].
wiggle --> wiggle,wiggle.


s2 --> l,r.
s2 --> l,s2,r.
 
l --> [a].
r --> [b].

s3 --> [].
s3 --> l3,s3,r3.
 
l3 --> [a].
r3 --> [b,b].

%% aEven
se --> [].
se --> items, se.
items --> [a,a].


