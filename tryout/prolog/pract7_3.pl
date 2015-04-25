%% [not, '(', p, implies, q, ')']

prop --> [p].
prop --> [q].
prop --> [r].
prop --> notsym, prop.
prop --> leftbrsym, prop, andsym, prop, rightbrsym.
prop --> leftbrsym, prop, orsym, prop, rightbrsym.
prop --> leftbrsym, prop, implsym, prop, rightbrsym.

leftbrsym --> ['('].
rightbrsym --> [')'].
notsym --> [not].
andsym --> [and].
orsym --> [or].
implsym --> [implies].

