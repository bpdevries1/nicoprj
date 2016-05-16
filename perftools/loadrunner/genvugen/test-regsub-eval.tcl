proc main {} {
  set str "tekst ervoor
    \"&paramname=paramvalue\"
    tekst erna"
    
  regsub -all {\"&([^"=]+=[^"]+)"} $str {[my_replace \1]} str2
  puts "str: $str"
  puts "str2: $str2"
  puts "str3: [subst $str2]"
}

proc my_replace {str} {
  return "replaced '$str' with 'newstring'"
}

main