proc main {argv} {
  global argv0
  puts "main called"
  puts "argv0: $argv0"
  puts "argv: $argv"
}

main $argv

