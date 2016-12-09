# find . -name "*.tcl" -exec etags --lang=none --regex='/proc[ \t]+\([^ \t]+\)/\1/' {} \;
# etags --lang=none --regex='/proc[ \t]+\([^ \t]+\)/\1/'

# etags overschrijf vorige. Dan 3 opties:
# - optie om te appenden.
# - input file waarin filenames staan, deze eerst vullen.
# - alle files op cmdline, paar dirs, moet kunnen.
rm TAGS
etags --lang=none --regex='/proc[ \t]+\([^ \t]+\)/\1/' *.tcl vugen/*.tcl ahk/*.tcl generic/*.tcl lib/*.tcl

# load tags: M-x visit-tags-table, staat in buildtool dir.
# M-. jump to def.
# M-* jump back.
# mss meerdere tag files te loaden, of verdere automatisering?


