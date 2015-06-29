# Keeping orig: /media/nico/Iomega HDD/media/Series/Boston Public/Season 3/Boston Public 03x14 - Chapter 58.mpg

proc main {} {
  while {![eof stdin]} {
    gets stdin line
    if {[regexp "Keeping orig: (.+)$" $line z filename]} {
      puts "delete: $filename"
      file delete $filename
    }
  }
}

main
