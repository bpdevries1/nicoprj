word(abalone,a,b,a,l,o,n,e).
word(abandon,a,b,a,n,d,o,n).
word(enhance,e,n,h,a,n,c,e).
word(anagram,a,n,a,g,r,a,m).
word(connect,c,o,n,n,e,c,t).
word(elegant,e,l,e,g,a,n,t).

%% crosswd/6

crosswd(V1, V2, V3, H1, H2, H3) :-
	word(V1, V1a, V1b, V1c, V1d, V1e, V1f, V1g),
	word(V2, V2a, V2b, V2c, V2d, V2e, V2f, V2g),
	word(V3, V3a, V3b, V3c, V3d, V3e, V3f, V3g),
	word(H1, H1a, H1b, H1c, H1d, H1e, H1f, H1g),
	word(H2, H2a, H2b, H2c, H2d, H2e, H2f, H2g),
	word(H3, H3a, H3b, H3c, H3d, H3e, H3f, H3g),
	V1b=H1b, V1d=H2b, V1f=H3b,
	V2b=H1d, V2d=H2d, V2f=H3d,
	V3b=H1f, V3d=H2f, V3f=H3f.
		
