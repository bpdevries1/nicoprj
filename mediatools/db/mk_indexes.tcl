proc main {} {
  # stdin->stdout
  while {![eof stdin]} {
    gets stdin line
    if {[regexp {^CREATE TABLE ([^ ]+)} $line z table]} {
      # puts "-- $line"
      puts "CREATE INDEX ix_${table}_id on $table (id);"
    }
    if {[regexp {CONSTRAINT ([^ ]+)_ibfk_\d+ FOREIGN KEY \(([^ ]+?)\) } $line z table field]} {
      # puts "-- $line"
      puts "CREATE INDEX ix_${table}_${field} on $table \(${field}\);"
    }
  }
}

main
