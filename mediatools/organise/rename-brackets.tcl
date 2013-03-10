foreach filename [glob *.mp3] {
  set fn2 $filename
  regsub -all {\[} $fn2 "(" fn2
  regsub -all {\]} $fn2 ")" fn2
  puts "Rename $filename -> $fn2"
  file rename $filename $fn2
}
