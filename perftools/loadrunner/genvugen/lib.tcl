# library functions, verplaatsen naar ndv-lib 

# subst uitvoeren zonder variabelen te vervangen, ofwel $ negeren
# subst met -novariables werkt niet (goed)
# vervang eerst $ door een \004
proc subst_no_variables {text} {
  if {[regexp "\004" $text]} {
    error "char(4) already exists in text: $text"
  }
  regsub -all {\$} $text "\004" text2
  set text3 [subst $text2]
  regsub -all "\004" $text3 "\$" text4
  return $text4
}

