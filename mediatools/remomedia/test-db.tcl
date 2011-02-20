# test database connection with perftoolset like CDatabase etc.

# source all C*.tcl files in the same dir
foreach filename [glob -directory [file dirname [info script]] C*.tcl] {
  source $filename 
}

proc main {} {
  set db [CDatabase::get_database]
  set mf [$db find_objects musicfile -id 1550]
  puts "musicfiles found: $mf"
  set pl [$db find_objects played -kind testje]
  puts "played found: $pl"
}

main
